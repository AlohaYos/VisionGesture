//
//  HandTrackingProvider.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Vision

class HandTrackingProvider: NSObject {

	enum WhichHand: Int {
		case right = 0
		case left  = 1
	}
	enum WhichFinger: Int {
		case thumb  = 0
		case index
		case middle
		case ring
		case little
		case wrist
	}
	enum WhichJoint: Int {
		case tip = 0	// finger top
		case dip = 1	// first joint
		case pip = 2	// second joint
		case mcp = 3	// third joint
	}
	enum WhichJointNo: Int {
		case top = 0	// finger top
		case first = 1	// first joint
		case second = 2	// second joint
		case third = 3	// third joint
	}
	let wristJointIndex = 0
	var defaultHand = WhichHand.right

	let devicePosition: AVCaptureDevice.Position = .front	// .front / .back
	var baseView: UIView? = nil
	var cameraView: CameraView!
	private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
	private var cameraFeedSession: AVCaptureSession?
	private let drawLayer = DrawLayer()
	private var handPoseRequest = VNDetectHumanHandPoseRequest()
	
	var handJoints: [[[VNRecognizedPoint?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	private var fingerJoints: [[VNRecognizedPoint?]] = []			// array of finger joint position (VisionKit coordinates) --> FINGER_JOINTS

	init(baseView: UIView? = nil) {
		super.init()

		handPoseRequest.maximumHandCount = 2	// both hands

		self.baseView = baseView
		self.cameraView = baseView as! CameraView
		if let view = baseView {
			drawLayer.frame = view.layer.bounds
			drawLayer.prepare()
			view.layer.addSublayer(drawLayer)
		}
		
		do {
			if cameraFeedSession == nil {
				cameraView.previewLayer.videoGravity = .resizeAspectFill
				try setupAVSession()
				cameraView.previewLayer.session = cameraFeedSession
			}
			DispatchQueue.global(qos: .background).async {
				self.cameraFeedSession?.startRunning()
			}
		} catch {
			NSLog("camera session could not run")
		}

		handTrackFake.initAsAdvertiser()
	}
	
	func terminate() {
		cameraFeedSession?.stopRunning()
	}
	
	func layoutSubviews() {
		drawLayer.frame = (baseView?.layer.bounds)!
	}
	
	func clearDrawLayer() {
		drawLayer.clearPath()
	}
	
	func setupAVSession() throws {
		guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else {
			throw AppError.captureSessionSetup(reason: "Could not find a front facing camera.")
		}
		guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
			throw AppError.captureSessionSetup(reason: "Could not create video device input.")
		}
		
		let session = AVCaptureSession()
		session.beginConfiguration()
		session.sessionPreset = AVCaptureSession.Preset.high
		
		guard session.canAddInput(deviceInput) else {
			throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
		}
		session.addInput(deviceInput)
		
		let dataOutput = AVCaptureVideoDataOutput()
		if session.canAddOutput(dataOutput) {
			session.addOutput(dataOutput)
			dataOutput.alwaysDiscardsLateVideoFrames = true
			dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
			dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
		} else {
			throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
		}
		session.commitConfiguration()
		cameraFeedSession = session
	}
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

extension HandTrackingProvider: AVCaptureVideoDataOutputSampleBufferDelegate {
	public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		var handPoseObservation: VNHumanHandPoseObservation?
		defer {
			DispatchQueue.main.sync {
				guard let observations = handPoseRequest.results else {
					return
				}
				var joints = processHandPoseObservations(observations: observations)

				// HandTrackFake
				handTrackFake.sendHandTrackData(joints)
			}
		}
		
		let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
		do {
			try handler.perform([handPoseRequest])
			guard let observation = handPoseRequest.results?.first else { // observation: VNHumanHandPoseObservation
				handPoseObservation = nil
				return
			}
			handPoseObservation = observation
		} catch {
			cameraFeedSession?.stopRunning()
			let error = AppError.visionError(error: error)
			DispatchQueue.main.async {
				NSLog("image handling error")
			}
		}
	}
	
	// MARK: Observation processing
	func processHandPoseObservations(observations: [VNHumanHandPoseObservation]) -> [[[VNRecognizedPoint?]]] {

		var fingerJoints1 = [[VNRecognizedPoint?]]()
		var fingerJoints2 = [[VNRecognizedPoint?]]()
		var fingerPath = CGMutablePath()
		
		do {
			if observations.count>0 {
				fingerJoints1 = try getFingerJoints(with: observations[0])
				fingerPath.addPath(drawFingers(fingerJoints: fingerJoints1))
			}
			if observations.count>1 {
				fingerJoints2 = try getFingerJoints(with: observations[1])
				fingerPath.addPath(drawFingers(fingerJoints: fingerJoints2))
			}

			// decide which hand is right/left
			switch observations.count {
			case 1:
				handJoints.removeAll()
				handJoints.insert(fingerJoints1, at: defaultHand.rawValue)
			case 2:
				let thumbPos1 = jointPosition(hand: fingerJoints1, finger: WhichFinger.thumb.rawValue, joint: WhichJoint.tip.rawValue)
				let thumbPos2 = jointPosition(hand: fingerJoints2, finger: WhichFinger.thumb.rawValue, joint: WhichJoint.tip.rawValue)
				guard let pos1=thumbPos1, let pos2=thumbPos2 else {
					return []
				}
				handJoints.removeAll()
				if pos1.x < pos2.x {
					handJoints.append(fingerJoints2)	// WhichHand.right
					handJoints.append(fingerJoints1)
				}
				else {
					handJoints.append(fingerJoints1)	// WhichHand.right
					handJoints.append(fingerJoints2)
				}
			default:
				handJoints.removeAll()
			}
			
		} catch {
			NSLog("Error")
		}

		drawLayer.path = fingerPath	// draw bones
		
		return handJoints
	}

	// get finger joint position array (VisionKit coordinate)
	func getFingerJoints(with observation: VNHumanHandPoseObservation) throws -> [[VNRecognizedPoint?]] {
		do {
			let fingers = try observation.recognizedPoints(.all)
			// get all finger joint point in VisionKit coordinate (VNRecognizedPoint)
			fingerJoints = [	// (FINGER_JOINTS)
				[fingers[.thumbTip], fingers[.thumbIP],  fingers[.thumbMP],  fingers[.thumbCMC]],
				[fingers[.indexTip], fingers[.indexDIP], fingers[.indexPIP], fingers[.indexMCP]],
				[fingers[.middleTip],fingers[.middleDIP],fingers[.middlePIP],fingers[.middleMCP]],
				[fingers[.ringTip],  fingers[.ringDIP],  fingers[.ringPIP],  fingers[.ringMCP]],
				[fingers[.littleTip],fingers[.littleDIP],fingers[.littlePIP],fingers[.littleMCP]],
				[fingers[.wrist]]	// <-- wrist joint here
			]
		} catch {
			NSLog("Error")
		}
		return fingerJoints
	}

	// get joint position (UIKit coordinates)
	func jointPosition(hand: [[VNRecognizedPoint?]], finger: Int, joint: Int) -> CGPoint? {
		if finger==WhichFinger.wrist.rawValue {
			return cnv(hand[finger][wristJointIndex])
		}
		else {
			return cnv(hand[finger][joint])
		}
	}

	// conver coordinate : VisionKit --> AVFoundation (video) --> UIKit
	func cnv(_ point: VNRecognizedPoint?) -> CGPoint? {
		guard let point else { return nil }
		if point.confidence < 0.6 { return nil }	// ignore if confidence is low
		
		let point2 = CGPoint(x: point.location.x, y: 1 - point.location.y)
		let previewLayer = cameraView.previewLayer
		let pointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: point2)
//		NSLog("%f, %f", pointConverted.x, pointConverted.y)
		return pointConverted
	}

	// MARK: Draw fingers
	
	// draw finger bones
	func drawFingers(fingerJoints: [[VNRecognizedPoint?]]) -> CGMutablePath {
		let path = CGMutablePath()
		for fingerjoint in fingerJoints {
			var i = 0
			for joint in fingerjoint {
				let point = cnv(joint)
				guard let point else { continue }
				if i>0 {
					path.addLine(to: point)			// Line
				}
				path.addPath(drawJoint(at: point))	// Dot
				if i==WhichFinger.wrist.rawValue { break }
				path.move(to: point)
				i += 1
			}
		}
		
		if !path.isEmpty {
			path.closeSubpath()
		}
		
		return path
	}

	func drawJoint(at point: CGPoint) -> CGPath {
		return CGPath(roundedRect: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10), cornerWidth: 5, cornerHeight: 5, transform: nil)
	}

}
