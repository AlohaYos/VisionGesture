import RealityKit
import Observation

import RealityKitContent
import Foundation
import ARKit
import SceneKit

@Observable
class ViewModel {
	var logText: String = ""
	var ball: Entity?
	var earch: Entity?
	var plane: Entity?
	var triangle: Entity?
	var glove: Entity?
	var thumbTip: Entity?
	var littleTip: Entity?
	var wristTip: Entity?

    private var contentEntity = Entity()

	func setupContentEntity() -> Entity {
		return contentEntity
	}

	func setBallEntiry(ent: Entity?) {
		ball = ent
		setupJointBalls()
	}
	func setEarthEntiry(ent: Entity?) {
		thumbTip = ent
		littleTip = thumbTip?.clone(recursive: true)
		wristTip = thumbTip?.clone(recursive: true)
		contentEntity.addChild(thumbTip!)
		contentEntity.addChild(littleTip!)
		contentEntity.addChild(wristTip!)
	}
	func setPlaneEntiry(ent: Entity?) {
		plane = ent
	}
	func setTriangleEntiry(ent: Entity?) {
		triangle = ent
	}

	func setPoints(_ point: [SIMD3<Scalar>?]) {
		guard let b = thumbTip else { return }
		guard let thumbPos = point[0], let littlePos = point[1], let wristPos = point[2] else { return }

		thumbTip?.position = thumbPos
		wristTip?.position = wristPos
		littleTip?.position = littlePos
		thumbTip?.scale = [0.1, 0.1, 0.1]
		wristTip?.scale = [0.1, 0.1, 0.1]
		littleTip?.scale = [0.1, 0.1, 0.1]
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
	
	func addPoint4(_ mtx4: simd_float4x4) {
		guard let b = plane else { return }
		let ent = b.clone(recursive: true)

		ent.transform = Transform(matrix: mtx4)
		ent.scale = [0.1, 0.1, 0.1]
		ent.components.set(InputTargetComponent())
		ent.generateCollisionShapes(recursive: true)
		contentEntity.addChild(ent)
	}
	
	func setGloveEntiry(ent: Entity?) {
		glove = ent
		glove?.scale = [0.0, 0.0, 0.0]
		contentEntity.addChild(glove!)
	}

	func moveGlove(_ mtx4: simd_float4x4) {
//		var rotateMat: SCNMatrix4
//		var rotateSimd: simd_float4x4
//		// 以下、回転順序を考慮すること
//		let deltaX: Float = 0.0
//		let deltaY: Float = -45.0
//		let deltaZ: Float = -45.0
//		rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(deltaY), 0, 1, 0)	// Y軸を中心とした回転
//		rotateSimd = matrix_float4x4(rotateMat)
//		rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(deltaX), 1, 0, 0)	// X軸を中心とした回転
//		rotateSimd = matrix_float4x4(rotateMat)
//		rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(deltaX), 0, 0, 1)	// X軸を中心とした回転
//		rotateSimd = matrix_float4x4(rotateMat)
//
//		let mtxOut = mtx4 * rotateSimd
//
//		glove?.transform = Transform(matrix: mtxOut)

		glove?.transform = Transform(matrix: mtx4)
		glove?.scale = [0.5, 0.5, 0.5]
	}
	
	func clearText() {
		for child in contentEntity.children {
			contentEntity.removeChild(child)
		}
	}
	
    func addText(text: String) -> Entity {

		logText = text+"\r"+logText
		clearText()

        let textMeshResource: MeshResource = .generateText(logText,
                                                           extrusionDepth: 0.00,
                                                           font: .systemFont(ofSize: 0.05),
                                                           containerFrame: .zero,
														   alignment: .natural,
                                                           lineBreakMode: .byWordWrapping)

		let material = UnlitMaterial(color: .green)

        let textEntity = ModelEntity(mesh: textMeshResource, materials: [material])
		let offsetX: Float = 0.2
//		let offsetX: Float = -(textMeshResource.bounds.extents.x / 2)
		let offsetY = textMeshResource.bounds.extents.y - 1.4
		textEntity.position = SIMD3(x: offsetX, y: 1.5-offsetY, z: -2)
//		textEntity.position = SIMD3(x: -(textMeshResource.bounds.extents.x / 2), y: 1.5, z: -2)

        contentEntity.addChild(textEntity)

        return textEntity
    }
	
	func setupJointBalls() {
		if let ent1 = ball?.clone(recursive: true) {
			ent1.scale = [0.1, 0.1, 0.1]
			ent1.position = SIMD3(x: 0, y: 0, z: 0)
//			ent1.position = SIMD3(x: 0, y: 1.5, z: -1)
			contentEntity.addChild(ent1)
		}
		if let ent2 = ball?.clone(recursive: true) {
			ent2.scale = [0.001, 0.001, 0.001]
			ent2.position = SIMD3(x: 0, y: 1.8, z: -1)
			contentEntity.addChild(ent2)
		}

		if let b = ball {
			for handNo in 0...1 {
				for fingerNo in 0...4 {
					for jointNo in 0...2 {
						let xx: Float = Float(handNo) * 0.1 + 0.0
						let yy: Float = Float(fingerNo) * 0.1 + 1.5
						let zz: Float = Float(jointNo) * 0.1 - 1.0

						var ent = b.clone(recursive: true)
						ent.scale = [0.001, 0.001, 0.001]
						ent.position = SIMD3(x: xx, y: yy, z: zz)
						ent.components.set(InputTargetComponent())
						ent.generateCollisionShapes(recursive: true)

//						jointObj[handNo][fingerNo][jointNo] = ent
						contentEntity.addChild(ent)
					}
				}
			}
		}
	}

}
