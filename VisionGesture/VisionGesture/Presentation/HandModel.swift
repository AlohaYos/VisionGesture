//
//  HandModel.swift
//    Display hand joints in spatial world
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import Observation
import RealityKit
import RealityKitContent
import ARKit
import SceneKit

@Observable
class HandModel {
	var ball: Entity?
	private var reentryFlag = false
	private var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	private var lastHandCount = 0
	private var fingerObj: [[[ModelEntity?]]] = [
			[
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil]
			],
			[
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil]
			]
		]
    private var contentEntity = Entity()
	private var showFingerInterval = 1000
	private var showFingerCount = 0
	private var hideFingerObject = false

	func setupContentEntity() -> Entity {
		return contentEntity
	}

	var whichHanded:Int = 1	// 0:left, 1:right handed
	func setWhichHanded(_ which:Int) {
		whichHanded = which
	}
	
	var handDataExist:[Bool] = [false, false]

	func setHandJoints(left: [[SIMD3<Scalar>?]]?, right: [[SIMD3<Scalar>?]]?) {
		handDataExist = [false, false]
		handJoints = []
		if let r=right, r.count>0 {
			handJoints.append(r)
			handDataExist[0] = true
		}
		else {
			handJoints.append([])
		}
		if let l=left, l.count>0 {
			handJoints.append(l)
			handDataExist[1] = true
		}
		else {
			handJoints.append([])
		}
	}
	
	func showFingers() {
		if showFingerInterval < showFingerCount {
			showFingerCount = 0
			return
		}
		showFingerCount += 1
		
		checkFingers()
		guard handJoints.count>0 else { return }

		for handNo in 0...1 {
			guard handNo<handJoints.count ,handJoints[handNo].count > 0 else { continue }
			for fingerNo in 0...5 {
				for jointNo in 0...2 {
					if fingerNo == 5 && jointNo > 1 { continue }
					var sp:SIMD3<Float>? = [0,0,0]
					var ep:SIMD3<Float>? = [0,0,0]
					if fingerNo==5 && jointNo==1 {
						let middleRoot = handJoints[handNo][2][2]
						let wristPos = handJoints[handNo][5][0]
						let div:Float = 2.0
						sp = [
							(middleRoot!.x+wristPos!.x)/div,
							(middleRoot!.y+wristPos!.y)/div,
							(middleRoot!.z+wristPos!.z)/div
						]
						ep = sp
					}
					else {
						sp = handJoints[handNo][fingerNo][jointNo]
						ep = handJoints[handNo][fingerNo][jointNo]
						if !(fingerNo == 5 && jointNo == 0) {
							ep = handJoints[handNo][fingerNo][jointNo+1]
						}
					}
					drawBoneBetween(handNo: handNo, fingerNo: fingerNo, jointNo: jointNo, startPoint: sp, endPoint: ep)
				}
			}
		}
		
		
	}
	
	func checkFingers() {
		for handNo in 0...1 {
			if handDataExist[handNo] == false {
				for fingerNo in 0...5 {
					for jointNo in 0...2 {
						if fingerNo == 5 && jointNo > 1 { continue }

						if let rectangle:ModelEntity = fingerObj[handNo][fingerNo][jointNo] {
							rectangle.isEnabled = false
						}
					}
				}
			}
		}
	}
	
	func drawBoneBetween(handNo: Int, fingerNo: Int, jointNo: Int,  startPoint: SIMD3<Scalar>?, endPoint: SIMD3<Scalar>?) {
		
		if reentryFlag == true { return }
		reentryFlag = true
		
		guard let sp = startPoint, let ep = endPoint else { return }
		guard fingerNo<=5 && jointNo < 3 else { return }
		guard fingerObj.count > 0 else { return }

		let boneThickness:Float = 0.025
		var size:Float = distance(sp, ep)
		if size == 0.0 {
			size = boneThickness
		}

		if var rectangle:ModelEntity = fingerObj[handNo][fingerNo][jointNo] {
			rectangle.isEnabled = true

			if hideFingerObject {
				// opacity = 0.0
				var material = OcclusionMaterial()
				rectangle.model?.materials = [material]
			}
			else {
				// opacity = 1.0
				var material = SimpleMaterial()
				material.color = .init(tint: .cyan)
				rectangle.model?.materials = [material]
			}

			let middlePoint = SIMD3(x: (sp.x + ep.x)/2, y: (sp.y + ep.y)/2, z: (sp.z + ep.z)/2)
			rectangle.setPosition(middlePoint, relativeTo: nil)
			
			if handTrackFake.enableFake {
				rectangle.setScale(SIMD3(x: 0.8, y: 0.8, z: size*50) , relativeTo: contentEntity)
			}
			else {
				rectangle.setScale(SIMD3(x: 0.8, y: 0.8, z: 1.0) , relativeTo: contentEntity)
			}
			if fingerNo == 5 && jointNo == 1 {	// palm
				rectangle.isEnabled = false
				if var wristPos = handJoints[handNo][HandTrackProcess.WhichFinger.wrist.rawValue][HandTrackProcess.WhichJointNo.top.rawValue],
				   let indexPos = handJoints[handNo][HandTrackProcess.WhichFinger.index.rawValue][HandTrackProcess.WhichJointNo.third.rawValue],
				   let littlePos = handJoints[handNo][HandTrackProcess.WhichFinger.ring.rawValue][HandTrackProcess.WhichJointNo.third.rawValue]
				{
					if let mtx4: simd_float4x4 = triangleCenterWithAxis(joint1:littlePos, joint2:indexPos, joint3:wristPos) {
						rectangle.transform = Transform(matrix: mtx4)
					}
				}
			}
			else {
				rectangle.look(at: sp, from: middlePoint, relativeTo: nil)
			}
		}
		reentryFlag = false
	}
	
	func setupBones() {
		for handNo in 0...1 {
			for fingerNo in 0...5 {
				for jointNo in 0...2 {
					if fingerNo == 5 && jointNo > 1 { continue }	// fingerNo==5 and jointNo=1  palm

					var material = SimpleMaterial()
					material.color = .init(tint: .cyan)

					let boneThickness:Float = 0.025
					var rectangle:ModelEntity!
					if fingerNo == 5 && jointNo == 1 {	// palm
						rectangle = ModelEntity(mesh: .generateBox(size: SIMD3(x: boneThickness*2, y: boneThickness*2, z: boneThickness*0.25), cornerRadius: 50.0 ), materials: [material])
					}
					else {
						rectangle = ModelEntity(mesh: .generateBox(size: SIMD3(x: boneThickness, y: boneThickness, z: boneThickness), cornerRadius: boneThickness/3.0 ), materials: [material])
					}
					rectangle.physicsBody = PhysicsBodyComponent(massProperties:  .init(mass: 10.0), material: .generate(friction: 0.5, restitution: 0.1), mode: .kinematic)
					rectangle.generateCollisionShapes(recursive: true)

					contentEntity.addChild(rectangle)
					fingerObj[handNo][fingerNo][jointNo] = rectangle
				}
			}
		}
	}
	
	func triangleCenterWithAxis(joint1:SIMD3<Scalar>?, joint2:SIMD3<Scalar>?, joint3:SIMD3<Scalar>?) -> simd_float4x4? {
		guard
			var j1 = joint1,
			var j2 = joint2,
			var j3 = joint3
		else {
			return nil
		}

		var zOffset = -0.34	// palm position offset
		j1.z += Float(zOffset)
		j2.z += Float(zOffset)
		j3.z += Float(zOffset)

		// center of triangle
		let h1 = (j1+j2) / 2	// half point of j1 & j2
		let ct = (h1+j3) / 2	// center point (half point of h1 & j3)

		var xAxis = normalize(j2 - j1)
		var yAxis = normalize(j3 - h1)
		var zAxis = normalize(cross(xAxis, yAxis))

		let triangleCenterWorldTransform = simd_matrix(
			SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
			SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
			SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
			SIMD4(ct.x, ct.y, ct.z, 1)
		)
		return triangleCenterWorldTransform
	}

}
