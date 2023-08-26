//
//  SpatialGestureProcessor.swift
//  HandGesture
//
//  Created by Yos Hashimoto on 2023/07/30.
//
import Foundation
import CoreGraphics
import SwiftUI
import Vision
#if targetEnvironment(simulator)
import ARKit
#else
@preconcurrency import ARKit
#endif

// MARK: VisionGestureDelegate (gesture callback)

class VisionGestureDelegateEvent {
	enum EventType: Int {
		case unknown = 0
		case Began
		case Moved2D
		case Moved3D
		case Moved4D
		case Ended
		case Canceled
		case Fired
	}
	
	static var uniqueID: Int = 1
	var id: Int
	var timestamp: TimeInterval
	var type: EventType
	var triggerType: Int
	var location: [Any]
	
	init() {
		self.id = VisionGestureDelegateEvent.uniqueID
		self.timestamp  = NSDate().timeIntervalSince1970
		self.type = .unknown
		self.triggerType = -1
		self.location = []
		VisionGestureDelegateEvent.uniqueID += 1
	}

	init(type: EventType, location: [Any]) {
		self.id = VisionGestureDelegateEvent.uniqueID
		self.timestamp  = NSDate().timeIntervalSince1970
		self.type = type
		self.triggerType = -1
		self.location = location as [Any]
		VisionGestureDelegateEvent.uniqueID += 1
	}
	
	init(type: EventType, trigger: Int) {
		self.id = VisionGestureDelegateEvent.uniqueID
		self.timestamp  = NSDate().timeIntervalSince1970
		self.type = type
		self.triggerType = trigger
		self.location = []
		VisionGestureDelegateEvent.uniqueID += 1
	}
	
}

protocol VisionGestureDelegate {
	func gesture(gesture: VisionGestureProcessor, event: VisionGestureDelegateEvent);
}

extension VisionGestureDelegate {
	func gesture(gesture: VisionGestureProcessor, event: VisionGestureDelegateEvent) {}
}

// MARK: VisionGestureProcessor (Base class of any Gesture)

class VisionGestureProcessor {

	typealias Scalar = Float

// MARK: enum

	enum State {
		case unknown
		case possible
		case detected
		case waitForNextPose
		case waitForRelease
	}
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

// MARK: propaties

	var delegate: VisionGestureDelegate?
	var didChangeStateClosure:((State)->Void)?
	var state = State.unknown {
		didSet {
			didChangeStateClosure?(state)
		}
	}
	var defaultHand = WhichHand.right

	var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	var lastHandJoints: [[[SIMD3<Scalar>?]]] = []		// remember first pose

	private var fingerJoints: [[SIMD3<Scalar>?]] = []			// array of finger joint position (VisionKit coordinates) --> FINGER_JOINTS
//	private var fingerJointsCnv = [[CGPoint?]]()					// array of finger joint position (UIKit coordinates)
	
	init() {
		self.didChangeStateClosure = { [weak self] state in
			self?.handleGestureStateChange(state)
		}
		stateReset()
	}

	convenience init(delegate: any View) {
		self.init()
		self.delegate = (delegate as! any VisionGestureDelegate)
	}
	
	private func handleGestureStateChange(_ state: State) {
	}

	func stateReset() {
		clearHandJoints()
		state = .unknown
	}

	// MARK: Export joint positions
	func handJoint(RorL: WhichHand) -> [[SIMD3<Scalar>?]] {
		guard handJoints != nil, handJoints.count-1 >= RorL.rawValue else { return [] }
		return handJoints[RorL.rawValue]
	}

	// MARK: Compare joint positions

	func cv2(_ pos: SIMD3<Scalar>?) -> CGPoint? {
		guard let p = pos else { return CGPointZero }
		return CGPointMake(CGFloat(p.x),CGFloat(p.y))
	}
	
    // is finger bend or outstretched
    func isBend(pos1: CGPoint?, pos2: CGPoint?, pos3: CGPoint? ) -> Bool {
        guard let p1 = pos1, let p2 = pos2, let p3 = pos3 else { return false }
        if p1.distance(from: p2) > p1.distance(from: p3) { return true }
        return false
    }
	func isBend(hand: WhichHand, finger: WhichFinger) -> Bool {
		let posTip: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .tip))
		let pos2nd: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .pip))
		let posWrist: CGPoint? = cv2(jointPosition(hand:hand, finger:.wrist, joint: .tip))
		guard let posTip, let pos2nd, let posWrist else { return false }

		if posWrist.distance(from: pos2nd) > posWrist.distance(from: posTip) { return true }
		return false
	}
    func isStraight(pos1: CGPoint?, pos2: CGPoint?, pos3: CGPoint? ) -> Bool {
        guard let p1 = pos1, let p2 = pos2, let p3 = pos3 else { return false }
        if p1.distance(from: p2) < p1.distance(from: p3) { return true }
        return false
    }
	func isStraight(hand: WhichHand, finger: WhichFinger) -> Bool {
		let posTip: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .tip))
		let pos2nd: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .pip))
		let posWrist: CGPoint? = cv2(jointPosition(hand:hand, finger:.wrist, joint: .tip))
		guard let posTip, let pos2nd, let posWrist else { return false }

		if posWrist.distance(from: pos2nd) < posWrist.distance(from: posTip) { return true }
		return false
	}

	// is two joints near?
	func isNear(pos1: CGPoint?, pos2: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos1, let p2 = pos2 else { return false }
		if p1.distance(from: p2) < value { return true }
		return false
	}
	// is two joints far enough?
	func isFar(pos1: CGPoint?, pos2: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos1, let p2 = pos2 else { return false }
		if p1.distance(from: p2) > value { return true }
		return false
	}
	
	// is the joint upper than another?
	func isPoint(_ pos: CGPoint?, upperThan: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos, let p2 = upperThan else { return false }
		if (p1 - p2).y < value { return true }
		return false
	}
	// is the joint lower than another?
    func isPoint(_ pos: CGPoint?, lowerThan: CGPoint?, value: Double) -> Bool {
	    guard let p1 = pos, let p2 = lowerThan else { return false }
	    if (p1 - p2).y > value { return true }
	    return false
    }
	// is the joint right of another?
	func isPoint(_ pos: CGPoint?, rightOf: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos, let p2 = rightOf else { return false }
		if (p1 - p2).x > value { return true }
		return false
	}
	// is the joint left of another?
	func isPoint(_ pos: CGPoint?, leftOf: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos, let p2 = leftOf else { return false }
		if (p1 - p2).x < value { return true }
		return false
	}

	// pointing ?
	let compareMultiply = 5.0
	func isPointingUp(hand:WhichHand, finger:WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dy > 0) && (fabs(vector.dy) > fabs(vector.dx)*compareMultiply) {
			return true
		}
		return false
	}
	func isPointingDown(hand:WhichHand, finger:WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dy < 0) && (fabs(vector.dy) > fabs(vector.dx)*compareMultiply) {
			return true
		}
		return false
	}
	func isPointingRight(hand:WhichHand, finger:WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dx > 0) && (fabs(vector.dx) > fabs(vector.dy)*compareMultiply) {
			return true
		}
		return false
	}
	func isPointingLeft(hand:WhichHand, finger:WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dx < 0) && (fabs(vector.dx) > fabs(vector.dy)*compareMultiply) {
			return true
		}
		return false
	}
	func calcPointingXY(hand:WhichHand, finger:WhichFinger) -> CGVector {
		let tip   = cv2(jointPosition(hand:hand, finger:finger, joint: .tip))
		let mcp   = cv2(jointPosition(hand:hand, finger:finger, joint: .mcp))
//		let wrist = cv2(jointPosition(hand:hand, finger:.wrist, joint: WhichJoint.tip))
		guard let p1 = tip, let p2 = mcp else { return CGVectorMake(0, 0) }
		return CGVectorMake((p1-p2).x, (p1-p2).y)
	}
	
	// MARK: Observation processing
	func processHandPoseObservations(observations: [HandAnchor?]) {

		var fingerJoints1 = [[SIMD3<Scalar>?]]()
		var fingerJoints2 = [[SIMD3<Scalar>?]]()
		//var fingerPath = CGMutablePath()
		
		do {
			if observations.count>0 {
				fingerJoints1 = try getFingerJoints(with: observations[0]!)
				//fingerPath.addPath(drawFingers(fingerJoints: fingerJoints1))
			}
			if observations.count>1 {
				fingerJoints2 = try getFingerJoints(with: observations[1]!)
				//fingerPath.addPath(drawFingers(fingerJoints: fingerJoints2))
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
					return
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

//		drawLayer?.path = fingerPath	// draw bones

		checkGesture()
	}

	func checkGesture() {
		
	}
	
	// save joint data array for later use
	func saveHandJoints() {
		lastHandJoints.removeAll()
		lastHandJoints.append(handJoints[0])
		if handJoints.count > 1 {
			lastHandJoints.append(handJoints[1])
		}
	}
	
	// clear last joint data array
	func clearHandJoints() {
		lastHandJoints.removeAll()
	}
	
	func cv(a: HandAnchor, j: HandSkeleton.JointName) -> SIMD3<Scalar>? {
		guard let sk = a.handSkeleton else { return [] }
		return matrix_multiply(a.transform, sk.joint(j).rootTransform).columns.3.xyz
	}
	
	// get finger joint position array (VisionKit coordinate)
	func getFingerJoints(with anchor: HandAnchor?) throws -> [[SIMD3<Scalar>?]] {
		do {
			guard let ac = anchor else { return [] }
			
			fingerJoints = [	// (FINGER_JOINTS)
				[cv(a:ac,j:.thumbTip),cv(a:ac,j:.thumbIntermediateTip),cv(a:ac,j:.thumbIntermediateBase),cv(a:ac,j:.thumbKnuckle)],
				[cv(a:ac,j:.indexFingerTip),cv(a:ac,j:.indexFingerIntermediateTip),cv(a:ac,j:.indexFingerIntermediateBase),cv(a:ac,j:.indexFingerKnuckle)],
				[cv(a:ac,j:.middleFingerTip),cv(a:ac,j:.middleFingerIntermediateTip),cv(a:ac,j:.middleFingerIntermediateBase),cv(a:ac,j:.middleFingerKnuckle)],
				[cv(a:ac,j:.ringFingerTip),cv(a:ac,j:.ringFingerIntermediateTip),cv(a:ac,j:.ringFingerIntermediateBase),cv(a:ac,j:.ringFingerKnuckle)],
				[cv(a:ac,j:.littleFingerTip),cv(a:ac,j:.littleFingerIntermediateTip),cv(a:ac,j:.littleFingerIntermediateBase),cv(a:ac,j:.littleFingerKnuckle)],
				[cv(a:ac,j:.wrist)]
			]
		} catch {
			NSLog("Error")
		}
		return fingerJoints
	}

	// get joint position)
	func jointPosition(hand: [[SIMD3<Scalar>?]], finger: Int, joint: Int) -> SIMD3<Scalar>? {
		if finger==WhichFinger.wrist.rawValue {
			return hand[finger][wristJointIndex]
		}
		else {
			return hand[finger][joint]
		}
	}
	func jointPosition(hand: WhichHand, finger: WhichFinger, joint: WhichJoint) -> SIMD3<Scalar>? {
		
		var jnt = joint.rawValue
		if finger == .wrist { jnt = wristJointIndex }

		switch handJoints.count {
		case 1:
			return jointPosition(hand:handJoints[WhichHand.right.rawValue], finger:finger.rawValue, joint:jnt)
		case 2:
			return jointPosition(hand:handJoints[hand.rawValue], finger:finger.rawValue, joint:jnt)
		default:
			return nil
		}
	}
	func lastJointPosition(hand: WhichHand, finger: WhichFinger, joint: WhichJoint) -> SIMD3<Scalar>? {

		var jnt = joint.rawValue
		if finger == .wrist { jnt = wristJointIndex }

		switch lastHandJoints.count {
		case 1:
			return jointPosition(hand:lastHandJoints[WhichHand.right.rawValue], finger:finger.rawValue, joint:jnt)
		case 2:
			return jointPosition(hand:lastHandJoints[hand.rawValue], finger:finger.rawValue, joint:jnt)
		default:
			return nil
		}
	}

	// conver coordinate : VisionKit --> AVFoundation (video) --> UIKit
	func cnv(_ point: SIMD3<Scalar>?) -> CGPoint? {
		#if os(visionOS)
		return nil
		#else
		guard let point else { return nil }
		if point.confidence < 0.6 { return nil }	// ignore if confidence is low
		
		let point2 = CGPoint(x: point.location.x, y: 1 - point.location.y)
		let previewLayer = cameraView.previewLayer
		let pointConverted = previewLayer.layerPointConverted(fromCaptureDevicePoint: point2)
//		NSLog("%f, %f", pointConverted.x, pointConverted.y)
		return pointConverted
		#endif
	}

	// draw finger bones
	func drawFingers(fingerJoints: [[SIMD3<Scalar>?]]) -> CGMutablePath {
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

	// 指定した３点で構成される三角形の中心座標と軸を計算（j1,j2が底辺、j3が頂点の三角形と仮定する）
	func triangleCenter(joint1:SIMD3<Scalar>?, joint2:SIMD3<Scalar>?, joint3:SIMD3<Scalar>?) -> SIMD3<Scalar>? {
		guard
			let j1 = joint1,
			let j2 = joint2,
			let j3 = joint3
		else {
			return nil
		}
		
		// center of triangle (j1,j2が底辺、j3が頂点の三角形と仮定する)
		let h1 = (j1+j2) / 2	// half point of j1 & j2
		let ct = (h1+j3) / 2	// center point (half point of h1 & j3)
		
		return SIMD3(ct.x, ct.y, ct.z)
	}
	
	func triangleCenterWithAxis(joint1:SIMD3<Scalar>?, joint2:SIMD3<Scalar>?, joint3:SIMD3<Scalar>?) -> simd_float4x4? {
		guard
			let j1 = joint1,
			let j2 = joint2,
			let j3 = joint3
		else {
			return nil
		}
		
//		let rightHandIndexFingerTipWorldPosition = matrix_multiply(rightHandAnchor.transform, rightHandIndexFingerTip.rootTransform).columns.3.xyz

		// center of triangle (j1,j2が底辺、j3が頂点の三角形と仮定する)
		let h1 = (j1+j2) / 2	// half point of j1 & j2
		let ct = (h1+j3) / 2	// center point (half point of h1 & j3)

		let xAxis = normalize(j2 - j1)
		let yAxis = normalize(j3 - h1)
		let zAxis = normalize(cross(xAxis, yAxis))

		let triangleCenterWorldTransform = simd_matrix(
			SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
			SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
			SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
			SIMD4(ct.x, ct.y, ct.z, 1)
		)
		return triangleCenterWorldTransform
	}
}

extension SIMD4 {
	var _xyz: SIMD3<Scalar> {
		self[SIMD3(0, 1, 2)]
	}
}
