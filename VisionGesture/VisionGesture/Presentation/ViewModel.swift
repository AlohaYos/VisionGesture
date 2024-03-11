//
//  ViewModel.swift
//    Display objects in visionOS simulator
//
//  Copyright © 2023 Yos. All rights reserved.
//

import RealityKit
import Observation

import RealityKitContent
import Foundation
import ARKit
import SceneKit

@Observable
class ViewModel {
	var ball: ModelEntity?
	var thumbTip: Entity?
	var littleTip: Entity?
	var wristTip: Entity?
	var pointArray: [ModelEntity?] = []

	private var contentEntity = Entity()
	
	func setupContentEntity() -> Entity {
		setupObjects()
		return contentEntity
	}
	
	func setupObjects() {
		ball = ModelEntity(mesh: .generateSphere(radius: 0.03), materials: [SimpleMaterial(color: UIColor(.red), isMetallic: false)])
		ball?.physicsBody = PhysicsBodyComponent(massProperties:  .init(mass: 10.0), material: .generate(friction: 0.1, restitution: 0.1), mode: .kinematic)
		ball?.generateCollisionShapes(recursive: false)
		thumbTip = ball?.clone(recursive: true)
		littleTip = ball?.clone(recursive: true)
		wristTip = ball?.clone(recursive: true)

		contentEntity.addChild(thumbTip!)
		contentEntity.addChild(littleTip!)
		contentEntity.addChild(wristTip!)
		
		thumbTip?.isEnabled = false
		littleTip?.isEnabled = false
		wristTip?.isEnabled = false
		
		var tinyBall = ModelEntity(mesh: .generateSphere(radius: 0.005), materials: [SimpleMaterial(color: UIColor(.brown), isMetallic: false)])
		tinyBall.physicsBody = PhysicsBodyComponent(massProperties:  .init(mass: 0.1), material: .generate(friction: 0.5, restitution: 0.1), mode: .dynamic)
		tinyBall.generateCollisionShapes(recursive: true)
		for i in stride(from: 0, to: 100, by: 1) {
			let tb = tinyBall.clone(recursive: true)
			tb.position  = SIMD3(x: 0, y: 1.0, z: -0.5)
			contentEntity.addChild(tb)
		}
	}
	
	func beginAloha() {
		thumbTip?.isEnabled = true
		littleTip?.isEnabled = true
		wristTip?.isEnabled = true
	}
	
	func endAloha() {
		thumbTip?.isEnabled = false
		littleTip?.isEnabled = false
		wristTip?.isEnabled = false
	}
	
	func setPoints(_ point: [SIMD3<Scalar>?]) {
		guard thumbTip != nil else { return }
		guard point.count >= 3 else { return }
		guard let thumbPos = point[0], let littlePos = point[1], let wristPos = point[2] else { return }
		
		thumbTip?.position = thumbPos
		wristTip?.position = wristPos
		littleTip?.position = littlePos
		thumbTip?.scale = [1, 1, 1]
		wristTip?.scale = [1, 1, 1]
		littleTip?.scale = [1, 1, 1]
	}
	
	func addPoint(_ point: SIMD3<Scalar>) {
		guard let b = ball else { return }
		let ent = b.clone(recursive: true)
		ent.scale = [0.3, 0.3, 0.3]
		ent.position = SIMD3(x: point.x, y: point.y, z: point.z)
		contentEntity.addChild(ent)
		pointArray.append(ent)
	}
	
	func clearAllPoint() {
		pointArray.forEach{
			$0?.removeFromParent()
		}
	}
}

