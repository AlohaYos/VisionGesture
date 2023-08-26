//
//  Gesture_Aloha.swift
//  HandGesture
//
//  Created by Yos Hashimoto on 2023/07/30.
//

import Foundation
#if os(visionOS)
import SwiftUI
#else
import UIKit
#endif

class Gesture_Cursor: VisionGestureProcessor
{
    
	enum CursorType: Int {
		case unknown = 0
		case up
		case down
		case right
		case left
		case fire
	}

    override init() {
        super.init()
        stateReset()
    }

	convenience init(delegate: any View) {
		self.init()
		self.delegate = delegate as? any VisionGestureDelegate
	//	self.delegate?.gestureFired(gesture: self, atPoints: [CGPointZero], triggerType: CursorType.fire.rawValue)
	}

    // Gesture judging loop
    override func checkGesture() {
		var pose:CursorType = .unknown
		struct Holder {
			static var lastPose:CursorType = .unknown
		}

		pose = .unknown
		if(isUp())    { pose = .up }
		if(isDown())  { pose = .down }
		if(isRight()) { pose = .right }
		if(isLeft())  { pose = .left }
		if(isFire())  { pose = .fire }

		if Holder.lastPose == pose { return }
		
		switch pose {
		case .up:
			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Fired, trigger: CursorType.up.rawValue))
			break
		case .down:
			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Fired, trigger: CursorType.down.rawValue))
			break
		case .right:
			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Fired, trigger: CursorType.right.rawValue))
			break
		case .left:
			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Fired, trigger: CursorType.left.rawValue))
			break
		case .fire:
			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Fired, trigger: CursorType.fire.rawValue))
			break
		case .unknown:
			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Fired, trigger: pose.rawValue))
			break
		}
		Holder.lastPose = pose
    }
    
	func isUp() -> Bool {
		return isPointingUp(hand: .right, finger: .index)
	}
	func isDown() -> Bool {
		return isPointingDown(hand: .right, finger: .index)
	}
	func isRight() -> Bool {
		return isPointingRight(hand: .right, finger: .index)
	}
	func isLeft() -> Bool {
		return isPointingLeft(hand: .right, finger: .index)
	}
	func isFire() -> Bool {
		if handJoints.count > 0 { // gesture of single hands
			var check = 4
			if isBend(hand: .right, finger: .index) { check -= 1 }
			if isBend(hand: .right, finger: .middle){ check -= 1 }
			if isBend(hand: .right, finger: .ring)  { check -= 1 }
			if isBend(hand: .right, finger: .little){ check -= 1 }
			if check == 0 { return true }
		}
		return false
	}
}
