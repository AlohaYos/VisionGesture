import RealityKit
import Observation

import RealityKitContent
import Foundation
import ARKit
import SceneKit

@Observable
class HandModel {
	private var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	private var fingerObj: [[AnchorEntity?]] = []				// 指の関節描画用Entity
    private var contentEntity = Entity()

	func setupContentEntity() -> Entity {
		return contentEntity
	}

	func setHandJoints(left: [[SIMD3<Scalar>?]]?, right: [[SIMD3<Scalar>?]]?) {
		guard let r = right, let l = left,
			  r.count>0, l.count>0 else { return }
		handJoints[0] = r
		handJoints[1] = l
	}
	
	func showFingers() {
		guard handJoints.count>0 else { return }

		for handNo in 0...1 {
			for fingerNo in 0...4 {
				for jointNo in 0...2 {
					drawBoneBetween(fingerNo: fingerNo, jointNo: jointNo,
									startPoint: handJoints[handNo][fingerNo][jointNo], endPoint: handJoints[handNo][fingerNo][jointNo+1])
				}
			}
		}
	}
	
	func drawBoneBetween(fingerNo: Int, jointNo: Int,  startPoint: SIMD3<Scalar>?, endPoint: SIMD3<Scalar>?) {
		guard let sp = startPoint, let ep = endPoint else { return }
		guard fingerNo<5 && jointNo < 3 else { return }

		var anchor:AnchorEntity? = fingerObj[fingerNo][jointNo]
		if fingerObj[fingerNo][jointNo] == nil  {
			anchor = AnchorEntity()
			contentEntity.addChild(anchor!)
		}
		else {
			let lastRect = anchor?.children
			if let rect = lastRect?[0] {
				anchor?.removeChild(rect)
			}
		}

		let size:Float = distance(sp, ep);
		let boneThickness:Float = 0.003
		let rectangle = ModelEntity(mesh: .generateBox(width: boneThickness, height: boneThickness, depth: size), materials: [SimpleMaterial(color: UIColor(.blue), isMetallic: false)])
		let middlePoint : simd_float3 = simd_float3((sp.x + ep.x)/2, (sp.y + ep.y)/2, (sp.z + ep.z)/2)
				
		anchor?.position = middlePoint
		anchor?.look(at: sp, from: middlePoint, relativeTo: nil)
		anchor?.addChild(rectangle)
	}
}
