//
//  Gesture_Draw.swift
//    Sample gesture detection : Aloha sign (aka Shaka sign)
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import SwiftUI

class Gesture_Draw: GestureBase
{
	enum TriggerType: Int {
		case canvasClear
	}

	var checkDistance:Float = 0.1

	override init() {
		super.init()
		if handTrackFake.enableFake == false {
			checkDistance *= 0.2
		}
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
			if(isPencilPose()) {		// wait for first pose
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Began, location: [CGPointZero]))
				state = State.waitForRelease
			}
			if(isClearCanvasPose()) {	// wait for canvas clear pose (open hand)
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Fired, trigger: TriggerType.canvasClear.rawValue))
				state = State.unknown
			}
			break
		case .waitForRelease:	// wait for pose release
			delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Moved3D, location: [IndexTip() as Any]))
			if(!isPencilPose()) {	// wait until pose released
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Ended, location: [CGPointZero]))
				state = State.unknown
			}
			break
		default:
			break
		}
	}
	
	func isPencilPose() -> Bool {	// make pencil gesture ==> touch thumb tip to the second joint of index finger
		if handJoints.count > 0 {
			if isStraight(hand: .right, finger: .index) {
				if isNear(pos1: jointPosition(hand: .right, finger: .thumb, joint: .tip), pos2: jointPosition(hand: .right, finger: .index, joint: .pip), value: checkDistance) {
					return true
				}
			}
		}
		return false
	}

	func isClearCanvasPose() -> Bool {	// open hand
		if handJoints.count > 0 {
			var check = 0
			if isStraight(hand: .right, finger: .index){ check += 1 }
			if isStraight(hand: .right, finger: .middle){ check += 1 }
			if isStraight(hand: .right, finger: .ring){ check += 1 }
			if isStraight(hand: .right, finger: .little){ check += 1 }
			if check == 4 { return true }
		}
		return false
	}

	func IndexTip() -> SIMD3<Float> {
		let posIndex: SIMD3<Float>? = jointPosition(hand: .right, finger: .index, joint: .tip)
		guard let posIndex else { return SIMD3<Float>() }
		return posIndex
	}
}
