//
//  Gesture_Aloha.swift
//    Sample gesture detection : Aloha sign (aka Shaka sign)
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import SwiftUI

class Gesture_Aloha: GestureBase
{
	override init() {
		super.init()
	}

	convenience init(delegate: Any) {
		self.init()
		self.delegate = delegate as? any GestureDelegate
	}

	// Gesture judging loop
	override func checkGesture(handJoints: [[[SIMD3<Scalar>?]]]) {
		self.handJoints = handJoints
		switch state {
		case .unknown:			// initial state
			if(isShakaPose()) {		// wait for first pose (thumb and little finger outstretched, other fingers bending)
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Began, location: [CGPointZero]))
				state = State.waitForRelease
			}
			break
		case .waitForRelease:	// wait for pose release
			// plot tips
			delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Moved3D, location:
				[
					jointPosition(hand:.right, finger:.thumb,  joint: .tip) as Any,
					jointPosition(hand:.right, finger:.little,  joint: .tip) as Any,
					jointPosition(hand:.right, finger:.wrist, joint: .tip) as Any
				]
			  ))

			// center of the gesture
			let pos: SIMD3<Scalar>? = triangleCenter(
				joint1:jointPosition(hand:.right, finger:.thumb,  joint: .tip),
				joint2:jointPosition(hand:.right, finger:.little, joint: .tip),
				joint3:jointPosition(hand:.right, finger:.wrist,  joint: .tip))
			if let p = pos {
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Fired, location:[p as Any]))
			}
			// center vector of the gesture
			let pos4: simd_float4x4? = triangleCenterWithAxis(
				joint1:jointPosition(hand:.right, finger:.thumb, joint: .tip),
				joint2:jointPosition(hand:.right, finger:.little, joint: .tip),
				joint3:jointPosition(hand:.right, finger:.wrist, joint: .tip))
			if let p = pos4 {
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Moved4D, location:[p as Any]))
			}
			
			if(!isShakaPose()) {	// wait until pose released
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Ended, location: [CGPointZero]))
				state = State.unknown
			}
			break
		default:
			break
		}
	}
	
	func isShakaPose() -> Bool {
		if HandTrackProcess.handJoints.count > 0 {
			var check = 0
			if isStraight(hand: .right, finger: .thumb){ check += 1 }
			if isBend(hand: .right, finger: .index){ check += 1 }
			if isBend(hand: .right, finger: .middle){ check += 1 }
			if isBend(hand: .right, finger: .ring){ check += 1 }
			if isStraight(hand: .right, finger: .little){ check += 1 }
			if check == 5 { return true }
		}
		return false
	}
}
