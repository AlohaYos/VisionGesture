import RealityKit
import Observation

import RealityKitContent
import Foundation
import ARKit
import SceneKit

@Observable
class HandModel {
	var ball: Entity?
	private var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	private var lastHandCount = 0
	private var fingerObj: [[[AnchorEntity?]]] = [				// 指の関節描画用Entity
			[
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil]
			],
			[
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil]
			]
		]
	private var jointObj: [[[Entity?]]] = [				// 指の関節描画用Entity
			[
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil]
			],
			[
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil,nil,nil,nil],
				[nil]
			]
		]
    private var contentEntity = Entity()

	func setupContentEntity() -> Entity {
		return contentEntity
	}

	func setBallEntiry(ent: Entity?) {
		ball = ent
//		setupJointBalls()
	}

	func addPoint(_ point: SIMD3<Scalar>) {
		guard let b = ball else { return }
		let ent = b.clone(recursive: true)
		ent.scale = [0.05, 0.05, 0.05]
		ent.position = SIMD3(x: point.x, y: point.y, z: point.z)
		ent.components.set(InputTargetComponent())
		ent.generateCollisionShapes(recursive: true)
		contentEntity.addChild(ent)
	}

	func setupJointBalls() {
		
		if let b = ball {
			for handNo in 0...1 {
				for fingerNo in 0...4 {
					for jointNo in 0...2 {
						let xx: Float = Float(handNo) * 0.1 + 0.0
						let yy: Float = Float(fingerNo) * 0.1 + 1.5
						let zz: Float = Float(jointNo) * 0.1 - 1.0

						var ent = b.clone(recursive: true)
						ent.scale = [0.1, 0.1, 0.1]
						ent.position = SIMD3(x: xx, y: yy, z: zz)
						ent.components.set(InputTargetComponent())
						ent.generateCollisionShapes(recursive: true)

						jointObj[handNo][fingerNo][jointNo] = ent
						contentEntity.addChild(ent)
					}
				}
			}
		}
	}
	
	func setHandJoints(left: [[SIMD3<Scalar>?]]?, right: [[SIMD3<Scalar>?]]?) {
		handJoints = []
		guard let r = right, r.count>0 else { return }
		handJoints.append(r)
		guard let l = left, l.count>0 else { return }
		handJoints.append(l)
	}
	
	func showFingers() {
		checkFingers()
		guard handJoints.count>0 else { return }

		for handNo in 0...1 {
			guard handNo<handJoints.count ,handJoints[handNo].count > 0 else { continue }
			for fingerNo in 0...5 {
				for jointNo in 0...2 {
					if fingerNo == 5 && jointNo > 0 { continue }
					if false {
						if let sp = handJoints[handNo][fingerNo][jointNo] {
							if let obj = jointObj[handNo][fingerNo][jointNo] {
								obj.scale = [0.2, 0.2, 0.2]
								obj.position = SIMD3(x: sp.x, y: sp.y, z: sp.z)
							}
						}
					}
					else {
						var sp = handJoints[handNo][fingerNo][jointNo]
						var ep = handJoints[handNo][fingerNo][jointNo]
						if !(fingerNo == 5 && jointNo == 0) {
							ep = handJoints[handNo][fingerNo][jointNo+1]
						}
						drawBoneBetween(handNo: handNo, fingerNo: fingerNo, jointNo: jointNo, startPoint: sp, endPoint: ep)
					}
				}
			}
		}
	}
	
	func checkFingers() {
		if handJoints.count == lastHandCount { return }

		// 前回描画時と手の数が違っていたら、いったん消去する
		for handNo in 0...1 {
			for fingerNo in 0...5 {
				for jointNo in 0...2 {
					if fingerNo == 5 && jointNo > 0 { continue }
					
					if let anchor:AnchorEntity = fingerObj[handNo][fingerNo][jointNo] {
						if anchor.children.count>0 {
							let rect = anchor.children[0]
							anchor.removeChild(rect)
						}
					}
				}
			}
		}
		
		lastHandCount = handJoints.count
	}
	
	func drawBoneBetween(handNo: Int, fingerNo: Int, jointNo: Int,  startPoint: SIMD3<Scalar>?, endPoint: SIMD3<Scalar>?) {
		guard let sp = startPoint, let ep = endPoint else { return }
		guard fingerNo<=5 && jointNo < 3 else { return }
		guard fingerObj.count > 0 else { return }
		
		var anchor:AnchorEntity? = fingerObj[handNo][fingerNo][jointNo]
		if anchor == nil  {
			anchor = AnchorEntity()
			fingerObj[handNo][fingerNo][jointNo] = anchor
			contentEntity.addChild(anchor!)
		}
		else {
			let lastRect = anchor?.children
			if lastRect != nil, lastRect!.count>0, let rect = lastRect?[0] {
				anchor?.removeChild(rect)
			}
		}

		let boneThickness:Float = 0.02
		var size:Float = distance(sp, ep)
		if size == 0.0 {
			size = boneThickness
		}
		let rectangle = ModelEntity(mesh: .generateBox(width: boneThickness, height: boneThickness, depth: size), materials: [SimpleMaterial(color: UIColor(.white), isMetallic: false)])
		let middlePoint : simd_float3 = simd_float3((sp.x + ep.x)/2, (sp.y + ep.y)/2, (sp.z + ep.z)/2)
				
		anchor?.position = middlePoint
		anchor?.look(at: sp, from: middlePoint, relativeTo: nil)
		anchor?.addChild(rectangle)
	}
}
