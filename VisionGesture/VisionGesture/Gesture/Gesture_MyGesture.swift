//
//  Gesture_MyGesture.swift
//    Make your own spatial gesture!
//

import Foundation
import SwiftUI

class Gesture_MyGesture: GestureBase
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
		case .unknown:	// initial state. waiting for first gesture pose
			// TODO: MyGesture: wait for my gesture to start
			if(isMyGesturePose()) {
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Began, location: [CGPointZero]))
				state = State.waitForRelease
			}
			break
		case .waitForRelease:	// do something while in gesture. wait for release of first pose

			// TODO: MyGesture: do something while in gesture
			let position:SIMD3<Float> = [0,0,0]
			delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Moved3D, location: [position]))

			if(!isMyGesturePose()) {	// wait until pose released
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Ended, location: [CGPointZero]))
				state = State.unknown
			}
			break
		default:
			break
		}
	}
	
	// TODO: MyGesture: Check the position of the finger joints in space to determine if it is a new gesture
	func isMyGesturePose() -> Bool {
		if HandTrackProcess.handJoints.count > 0 {
			var check = 0
			// joint compare function available in "GestureBase.swift"
//			if isStraight(hand: .right, finger: .thumb){ check += 1 }
//			if isBend(hand: .right, finger: .index){ check += 1 }
//			if isBend(hand: .right, finger: .middle){ check += 1 }
//			if isBend(hand: .right, finger: .ring){ check += 1 }
//			if isStraight(hand: .right, finger: .little){ check += 1 }
			if check == 5 { return true }
		}
		return false
	}
}
