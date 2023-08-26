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

class Gesture_Aloha: VisionGestureProcessor
{
	override init() {
        super.init()
        stateReset()
    }

	convenience init(delegate: UIViewController) {
		self.init()
#if os(visionOS)
		self.delegate = delegate as? any VisionGestureDelegate
#else
		self.delegate = delegate as? any SpatialGestureDelegate
#endif
	}

    // Gesture judging loop
    override func checkGesture() {
        switch state {
        case .unknown:			// initial state
            if(isShakaPose()) {		// wait for first pose (thumb and little finger outstretched, other fingers bending)
				delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Began, location: [CGPointZero]))
                state = State.waitForRelease
            }
            break
        case .waitForRelease:	// wait for pose release
//			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Moved, location: shakaTips()))

			// 指先のプロット
			delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Moved3D, location:
				[
					jointPosition(hand:.right, finger:.thumb,  joint: .tip) as Any,
					jointPosition(hand:.right, finger:.little,  joint: .tip) as Any,
					jointPosition(hand:.right, finger:.wrist, joint: .tip) as Any
				]
			  ))

			// ジェスチャーの中心位置
			let pos: SIMD3<Scalar>? = triangleCenter(
				joint1:jointPosition(hand:.right, finger:.thumb,  joint: .tip),
				joint2:jointPosition(hand:.right, finger:.little, joint: .tip),
				joint3:jointPosition(hand:.right, finger:.wrist,  joint: .tip))
			if let p = pos {
				delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Moved3D, location:[p as Any]))
			}
			// ジェスチャーの中心ベクトル
			let pos4: simd_float4x4? = triangleCenterWithAxis(
				joint1:jointPosition(hand:.right, finger:.thumb, joint: .tip),
				joint2:jointPosition(hand:.right, finger:.little, joint: .tip),
				joint3:jointPosition(hand:.right, finger:.wrist, joint: .tip))
			if let p = pos4 {
				delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Moved4D, location:[p as Any]))
			}
			
            if(!isShakaPose()) {	// wait until pose released
				delegate?.gesture(gesture: self, event: VisionGestureDelegateEvent(type: .Ended, location: [CGPointZero]))
                state = State.unknown
            }
            break
        default:
            break
        }
    }
    
    func isShakaPose() -> Bool {
        if handJoints.count > 0 { // gesture of single hands
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
	
	func centerOfShaka() -> CGPoint {
		let posThumb: CGPoint? = cv2(jointPosition(hand: .right, finger: .thumb, joint: .tip))
		let posLittle:  CGPoint? = cv2(jointPosition(hand: .left, finger: .little, joint: .tip))
		guard let posThumb, let posLittle else { return CGPointZero }

		return CGPoint.midPoint(p1: posThumb, p2: posLittle)
	}

	func shakaTips() -> [CGPoint] {
		let posThumb: CGPoint? = cv2(jointPosition(hand: .right, finger: .thumb, joint: .tip))
		let posLittle:  CGPoint? = cv2(jointPosition(hand: .left, finger: .little, joint: .tip))
		guard let posThumb, let posLittle else { return [CGPointZero] }
		return [posThumb, posLittle]
	}
	
}
