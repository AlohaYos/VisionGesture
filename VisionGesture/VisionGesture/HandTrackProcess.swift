//
//  HandTrackProcess.swift
//    Manage real/fake hand tracking and make joints array (HandTrackProcess.handJoints)
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import CoreGraphics
import SwiftUI
import Vision
import ARKit

class HandTrackProcess {

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
	static let wristJointIndex = 0

	// Real HandTracking (not Fake)
	let session = ARKitSession()
	var handTracking = HandTrackingProvider()
	static var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	var handAnchorUpdate:AnchorUpdate<HandAnchor>!

	func handTrackingStart() async {
		if handTrackFake.enableFake == false {
			do {
				var auths = HandTrackingProvider.requiredAuthorizations
				if HandTrackingProvider.isSupported {
					print("ARKitSession starting.")
					try await session.run([handTracking])
				}
			} catch {
				print("ARKitSession error:", error)
			}
		}
	}

	// Hand tracking loop
	func publishHandTrackingUpdates(updateJob: @escaping(([[[SIMD3<Scalar>?]]], AnchorUpdate<HandAnchor>?) -> Void)) async {

		// Fake HandTracking
		if handTrackFake.enableFake {
			DispatchQueue.main.async {
				Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
					let dt = handTrackFake.receiveHandTrackData()
					HandTrackProcess.handJoints = dt
					// CALLBACK
					updateJob(dt, nil)
				}
			}
		}
		// Real HandTracking
		else {
			for await update in handTracking.anchorUpdates {
				handAnchorUpdate = update
				
				var rightAnchor: HandAnchor?
				var leftAnchor:  HandAnchor?
				var fingerJoints1 = [[SIMD3<Scalar>?]]()
				var fingerJoints2 = [[SIMD3<Scalar>?]]()

				switch update.event {
				case .updated:
					let anchor = update.anchor
					guard anchor.isTracked else { continue }
					
					if anchor.chirality == .left {
						leftAnchor = anchor
					} else if anchor.chirality == .right {
						rightAnchor = anchor
					}
				default:
					break
				}
				
				do {
					if rightAnchor != nil && leftAnchor != nil {
						fingerJoints1 = try getFingerJoints(with: rightAnchor)
						fingerJoints2 = try getFingerJoints(with: leftAnchor)
					}
					else {
						if rightAnchor != nil {
							fingerJoints1 = try getFingerJoints(with: rightAnchor)
							fingerJoints2 = []
						}
						if leftAnchor != nil {
							fingerJoints2 = try getFingerJoints(with: leftAnchor)
							fingerJoints1 = []
						}
					}
				} catch {
					NSLog("Error")
				}
				
				if rightAnchor != nil || leftAnchor != nil {
					HandTrackProcess.handJoints = [fingerJoints1, fingerJoints2]
					// CALLBACK
					updateJob([fingerJoints1, fingerJoints2], update)
				}
			}
		}
	}
	
	func monitorSessionEvents() async {
		if handTrackFake.enableFake == false {
			for await event in session.events {
				switch event {
				case .authorizationChanged(let type, let status):
					if type == .handTracking && status != .allowed {
						print("Ask the user to grant hand tracking authorization in Settings")
					}
				@unknown default:
					print("Session event \(event)")
					break
				}
			}
		}
	}
	
	func cv(a: HandAnchor, j: HandSkeleton.JointName) -> SIMD3<Scalar>? {
		guard let sk = a.handSkeleton else { return [] }
		let valSIMD4 = matrix_multiply(a.originFromAnchorTransform, sk.joint(j).anchorFromJointTransform).columns.3
		return valSIMD4[SIMD3(0, 1, 2)]
	}
	
	// get finger joint position array (VisionKit coordinate)
	func getFingerJoints(with anchor: HandAnchor?) throws -> [[SIMD3<Scalar>?]] {
		do {
			guard let ac = anchor else { return [] }
			let fingerJoints: [[SIMD3<Scalar>?]] =
			[
				[cv(a:ac,j:.thumbTip),cv(a:ac,j:.thumbIntermediateTip),cv(a:ac,j:.thumbIntermediateBase),cv(a:ac,j:.thumbKnuckle)],
				[cv(a:ac,j:.indexFingerTip),cv(a:ac,j:.indexFingerIntermediateTip),cv(a:ac,j:.indexFingerIntermediateBase),cv(a:ac,j:.indexFingerKnuckle)],
				[cv(a:ac,j:.middleFingerTip),cv(a:ac,j:.middleFingerIntermediateTip),cv(a:ac,j:.middleFingerIntermediateBase),cv(a:ac,j:.middleFingerKnuckle)],
				[cv(a:ac,j:.ringFingerTip),cv(a:ac,j:.ringFingerIntermediateTip),cv(a:ac,j:.ringFingerIntermediateBase),cv(a:ac,j:.ringFingerKnuckle)],
				[cv(a:ac,j:.littleFingerTip),cv(a:ac,j:.littleFingerIntermediateTip),cv(a:ac,j:.littleFingerIntermediateBase),cv(a:ac,j:.littleFingerKnuckle)],
				[cv(a:ac,j:.wrist)]
			]
			return fingerJoints
		} catch {
			NSLog("Error")
		}
		return []
	}

}

