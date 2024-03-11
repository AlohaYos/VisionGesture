//
//  Hands.swift
//  TrackingReceiver
//  
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import SwiftUI
import Observation
import RealityKit
import ARKit

@Observable
class Hand {
	private var contentEntity = Entity()
	var leftHand:Entity!
	var rightHand:Entity!
	
	func setupContentEntity() -> Entity {
		return contentEntity
	}
	
	func setHandEntity(leftHand:Entity, rightHand:Entity) {
		self.leftHand = leftHand
		contentEntity.addChild(leftHand)
		self.rightHand = rightHand
		contentEntity.addChild(rightHand)
	}
	
	func show(anchorUpdate:AnchorUpdate<HandAnchor>) {
		if (self.leftHand == nil) { return }
		if (self.rightHand == nil) { return }

		if let skeleton = anchorUpdate.anchor.handSkeleton {
			var hand: Entity
			switch anchorUpdate.anchor.chirality {
			case .left:
				hand = leftHand
			case .right:
				hand = rightHand
			}
			hand.transform = Transform(matrix: anchorUpdate.anchor.originFromAnchorTransform)
			for (index, joint) in skeleton.allJoints.enumerated() {
				let wristFromJoint = joint.anchorFromJointTransform
				hand.children[index].transform = Transform(matrix: wristFromJoint)
			}
		}
	}
}
