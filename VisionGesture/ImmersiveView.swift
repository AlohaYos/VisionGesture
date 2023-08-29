//
//  ImmersiveView.swift
//  VisionGesture
//
//  Created by Yos Hashimoto on 2023/08/16.
//

import SwiftUI
#if targetEnvironment(simulator)
import RealityKit
#else
@preconcurrency import RealityKit
#endif
import RealityKitContent
import SceneKit

typealias Scalar = Float

var timerCount = 0
var timerCountQuick = 0
var gesture_Aloha: Gesture_Aloha?
var gesture_Cursor: Gesture_Cursor?

struct ImmersiveView: View {
	@State var logText: String = "Ready..."
	var gestureProvider = VisionGestureProvider()
	var viewModel: ViewModel = ViewModel()
	var handModel: HandModel = HandModel()
	@State var kuma: Entity = Entity()
	@State var rotationA: Angle = .zero

	init(){
		textLog("init")
	}
	var body: some View {
		ZStack {
			// パーティクル
			RealityView { content in
				if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {	// パーティクル
					content.add(scene)
				}
			}
			// TextLogコンソール
			RealityView { content, attachments in
				let ent = Entity()
				ent.scale = [4.0, 4.0, 4.0]
				ent.position = SIMD3(x: 0, y: 1.5, z: -2)
				ent.generateCollisionShapes(recursive: true)
				content.add(ent)
				if let textAttachement = attachments.entity(for: "text_view") {
					textAttachement.position = SIMD3(x: 0, y: 0, z: 0)
					ent.addChild(textAttachement)
				}
			} attachments: {
				Text(logText)
					.frame(width: 1250, height: 690, alignment: .topLeading)
					.multilineTextAlignment(.leading)
					.background(Color.blue)
					.foregroundColor(Color.white)
					//.font(.system(size: 32))
					.tag("text_view")
			}
			.gesture(
				DragGesture().targetedToAnyEntity()
					.onChanged { value in	// 移動
						value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
					}
					.onEnded {_ in
						textLog("DragGesture.onEnded")
					}
				)
			// クマ以外の物体
			RealityView { content in
				do {
					let earth = try await Entity(named: "Sun", in: realityKitContentBundle)
					viewModel.setEarthEntiry(ent: earth)
					let ball = try await Entity(named: "Uranus", in: realityKitContentBundle)
					viewModel.setBallEntiry(ent: ball)
					let plane = try await Entity(named: "ToyBiplane", in: realityKitContentBundle)
					viewModel.setPlaneEntiry(ent: plane)
					let triangle = try await Entity(named: "Triangle", in: realityKitContentBundle)
					viewModel.setTriangleEntiry(ent: triangle)//
					let glove = try await Entity(named: "RubberGlove", in: realityKitContentBundle)
					viewModel.setGloveEntiry(ent: glove)
					let b = try await Entity(named: "Sun", in: realityKitContentBundle)
					handModel.setBallEntiry(ent: b)
				}
				catch { return }
				content.add(handModel.setupContentEntity())	// ハンドトラッキングも描画する
				content.add(viewModel.setupContentEntity())	// 物体
			}
			// クマ
			RealityView { content, attachments in
				do {
					kuma = try await Entity(named: "kuma", in: realityKitContentBundle)
					kuma.scale = [0.15, 0.15, 0.15]
					kuma.position = SIMD3(x: 0, y: 1.5, z: -2)
					kuma.components.set(InputTargetComponent())
					kuma.generateCollisionShapes(recursive: true)
//					content.add(kuma)
					
					if let kumaAttachement = attachments.entity(for: "kuma_label") {
						kumaAttachement.position = SIMD3(x: 0, y: -0.15, z: 2)
						kuma.addChild(kumaAttachement)
					}
				} catch {
					print("Entity encountered an error while loading the model.")
					return
				}
			} attachments: {
				Text("KUMA")
					.foregroundColor(Color.red)
					.font(.system(size: 32))
					.tag("kuma_label")
			}
			.gesture(SpatialEventGesture { events in
				// https://developer.apple.com/documentation/swiftui/spatialeventgesture
						for event in events {
							// SpatialEventCollection.Event
							// https://developer.apple.com/documentation/swiftui/spatialeventcollection
							print("event.id : \(event.id.hashValue)")
							print("event.kind : \(event.kind.hashValue)")
							print("event.location : \(event.location.description)")
							print("event.location3D : \(event.location3D.description)")
							print("event.inputDevicePose : \(event.inputDevicePose.debugDescription)")
//							print("event.modifierKeys : \(event.modifierKeys.debugDescription.description)")
//							print("event.selectionRay : \(event.selectionRay.rawValue.description)")
							print("event.targetedEntity : \(event.targetedEntity.debugDescription)")
							print("event.targetedEntity.transform : \(event.targetedEntity?.transform.translation.debugDescription)")
							print("event.timestamp : \(event.timestamp.debugDescription)")

							let msg = event.location.debugDescription
							switch event.phase {
							case .active:
								textLog("SpatialEventGesture.active")
								textLog("  - \(msg)")
								break
							case .ended:
								textLog("SpatialEventGesture.ended")
								textLog("  - \(msg)")
								break
							case .cancelled:
								textLog("SpatialEventGesture.cancelled")
								textLog("  - \(msg)")
								break
							default:
								break
							}
						}
					}
			)
			.gesture(
				DragGesture()
					.targetedToEntity(kuma)
					.targetedToAnyEntity()
					.onChanged { value in	// 移動
						value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
					}
					.onEnded { event in
						textLog("DragGesture.onEnded")
						let msg = event.location.debugDescription
						textLog("  - \(msg)")
					}
//					.onChanged { _ in		// 回転
//						rotationA.degrees += 5.0
//						let m1 = Transform(pitch: Float(rotationA.radians)).matrix
//						let m2 = Transform(yaw: Float(rotationA.radians)).matrix
//						kuma.transform.matrix = matrix_multiply(m1, m2)
//						kuma.position = SIMD3(x: 0, y: 1.5, z: -2)
//						kuma.scale = [0.15, 0.15, 0.15]
//					}
			)
			.gesture(
				SpatialTapGesture().targetedToAnyEntity()
					.targetedToEntity(kuma)
					.onChanged{ value in
						var desc = value.entity
//						textLog(value.entity)
						textLog("SpatialTapGesture.onChanged")
					}
					.onEnded { event in
						textLog("SpatialTapGesture.onEnded")
						let msg = event.location.debugDescription
						textLog("  - \(msg)")
					}
				)

			 .gesture(
				TapGesture().targetedToAnyEntity()
					.targetedToEntity(kuma)
					.onEnded { event in
						textLog("TapGesture.onEnded")
						let msg = event.gestureValue.entity.debugDescription
						textLog("  - \(msg)")
					}
			)
				//.rotation3DEffect(Angle(degrees: Double(timerCount)), axis: (x: 0, y: 1, z: 0))
			// ↑ クマ：ここまで

		}	// ZStack
		.onAppear {
			textLog("onAppear")
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
				textLog("DispatchQueue.main.asyncAfter")
			}
		}
		.onDisappear {
			textLog("onDisappear")
		}
		.task {
			textLog("gestureProvider.appendGesture")
			gesture_Aloha = Gesture_Aloha(delegate: self)
			gestureProvider.appendGesture(gesture_Aloha!)
//			gesture_Cursor = Gesture_Cursor(delegate: self)
//			gestureProvider.appendGesture(Gesture_Cursor(delegate: self))
			textLog("gestureProvider.start")
			await gestureProvider.start()
		}
		.task {
			textLog("gestureProvider.publishHandTrackingUpdates")
			await gestureProvider.publishHandTrackingUpdates()
		}
		.task {
			textLog("gestureProvider.monitorSessionEvents")
			await gestureProvider.monitorSessionEvents()
		}
		.task {
			Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
				timerCountQuick += 1
//				rotate_kuma()
				displayHandJoints()
			}
		}
		.task {
			Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
				timerCount += 1
//				textLog("timer job : \(timerCount)")c
// --- Sun
				let xPos: Float = Float(timerCount) * 0.02 - 0.8
				viewModel.addPoint(SIMD3(x: xPos, y: 1.5, z: -1))
// --- Biplane
				var delta = timerCount*10
				var joint1 = SIMD3(x: xPos-0.25, y: 1.7, z: -1)	// 底辺左
				var joint2 = SIMD3(x: xPos+0.25, y: 1.7, z: -1)	// 底辺右
				var joint3 = SIMD3(x: xPos,      y: 1.8, z: -1)	// 頂点
				var mtx: simd_float4x4? = triangleCenterWithAxis(joint1:joint1, joint2:joint2, joint3:joint3)
				var rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(delta), 0, 0, 1)	// z軸を中心とした10度回転
				var rotateSimd = matrix_float4x4(rotateMat)
				var mtxOut = mtx! * rotateSimd
				viewModel.addPoint4(mtxOut)	// 飛行機を追加描画
				
				/*
// --- Glove
				delta = timerCount*5
				joint1 = SIMD3(x: xPos-0.25, y: 1.2, z: -1)	// 底辺左
				joint2 = SIMD3(x: xPos+0.25, y: 1.2, z: -1)	// 底辺右
				joint3 = SIMD3(x: xPos,      y: 1.3, z: -1)	// 頂点
				mtx = triangleCenterWithAxis(joint1:joint1, joint2:joint2, joint3:joint3)
				rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(delta), 0, 1, 0)	// Y軸を中心とした10度回転
				rotateSimd = matrix_float4x4(rotateMat)
				mtxOut = mtx! * rotateSimd
				viewModel.moveGlove(mtxOut)	// グローブ移動
// --- finger tips
				delta = timerCount*5
				joint1 = SIMD3(x: xPos-0.05, y: 1.20, z: -1)	// 親指
				joint2 = SIMD3(x: xPos+0.05, y: 1.20, z: -1)	// 小指
				joint3 = SIMD3(x: xPos,      y: 1.15, z: -1)	// 手首
				mtx = triangleCenterWithAxis(joint1:joint1, joint2:joint2, joint3:joint3)
				rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(delta), 0, 1, 0)	// Y軸を中心とした10度回転
				rotateSimd = matrix_float4x4(rotateMat)
				mtxOut = mtx! * rotateSimd
				viewModel.setPoints([
					joint1, joint2, joint3	// 3点を移動
				])
				*/
			}
		}
	}
	
	// クマの回転
	func rotate_kuma() {
		rotationA.degrees += 5.0
		let m1 = Transform(roll: Float(0.0)).matrix
		let m2 = Transform(yaw: Float(rotationA.radians)).matrix
		kuma.transform.matrix = matrix_multiply(m1, m2)
		kuma.position = SIMD3(x: 0, y: 1.5, z: -2)
		kuma.scale = [0.15, 0.15, 0.15]
	}
	
	func add_point(pos: SIMD3<Scalar>?) {
		if let p = pos {
			viewModel.addPoint(p)
		}
	}
	// Alohaの指先
	func set_points(pos: [SIMD3<Scalar>?]) {
		viewModel.setPoints(pos)
	}
	// 未使用
	func add_point4(pos: simd_float4x4?) {
		if let p = pos {
			viewModel.addPoint4(p)
		}
	}
	// ハンドトラッキングの表示
	func displayHandJoints() {
		handModel.setHandJoints(left : gesture_Aloha?.handJoint(RorL: VisionGestureProcessor.WhichHand.left),
								right: gesture_Aloha?.handJoint(RorL: VisionGestureProcessor.WhichHand.right))
		handModel.showFingers()
	}
}

// MARK: VisionGestureDelegate job

extension ImmersiveView: VisionGestureDelegate {
	
	typealias Scalar = Float

	func gesture(gesture: VisionGestureProcessor, event: VisionGestureDelegateEvent) {
		if gesture is Gesture_Aloha {
			handle_gestureAloha(event: event)
		}
	}
	
	// Aloha
	func handle_gestureAloha(event: VisionGestureDelegateEvent) {
		switch event.type {
		case .Moved2D:
			textLog("Aloha: gesture 2D")
			if let pnt = event.location[0] as? SIMD3<Scalar> {
				add_point(pos: pnt)
			}
		case .Moved3D:
			textLog("Aloha: gesture 3D")
			set_points(pos: event.location as! [SIMD3<Scalar>])
		case .Moved4D:
			textLog("Aloha: gesture 4D")
			if let pnt = event.location[0] as? simd_float4x4 {
				viewModel.moveGlove(pnt)
			}
		case .Began:
			textLog("Aloha: gesture began")
		case .Ended:
			textLog("Aloha: gesture ended")
		case .Canceled:
			textLog("Aloha: gesture canceled")
		case .Fired:
			textLog("Aloha: gesture fired")
			break
		default:
			break
		}
	}
	
	// Cursor
	func handle_gestureCursor(event: VisionGestureDelegateEvent) {
		switch event.type {
		case .Moved2D:
			textLog("Cursor: gesture 2D")
		case .Moved3D:
			textLog("Cursor: gesture 3D")
		case .Moved4D:
			textLog("Cursor: gesture 4D")
		case .Began:
			textLog("Cursor: gesture began")
		case .Ended:
			textLog("Cursor: gesture ended")
		case .Canceled:
			textLog("Cursor: gesture canceled")
		case .Fired:
			textLog("Cursor: gesture fired")
			var typeStr: String = ""
			switch event.triggerType {
			case Gesture_Cursor.CursorType.up.rawValue:
				typeStr = "UP"
			case Gesture_Cursor.CursorType.down.rawValue:
				typeStr = "DOWN"
			case Gesture_Cursor.CursorType.left.rawValue:
				typeStr = "LEFT"
			case Gesture_Cursor.CursorType.right.rawValue:
				typeStr = "RIGHT"
			case Gesture_Cursor.CursorType.fire.rawValue:
				typeStr = "FIRE"
			case Gesture_Cursor.CursorType.unknown.rawValue:
				typeStr = "UNKNOWN"
				break
			default:
				typeStr = "DEFAULT"
				break
			}
			textLog("    [\(typeStr)]")
			break
		default:
			break
		}
	}
	
}

// MARK: Other job

extension ImmersiveView {

	func textLog(_ message: String) {
		DispatchQueue.main.async {
			logText = message+"\r"+logText
	//		_ = viewModel.addText(text: message)
		}
	}

	func triangleCenterWithAxis(joint1:SIMD3<Scalar>?, joint2:SIMD3<Scalar>?, joint3:SIMD3<Scalar>?) -> simd_float4x4? {
		guard
			let j1 = joint1,
			let j2 = joint2,
			let j3 = joint3
		else {
			return nil
		}
		
//		let rightHandIndexFingerTipWorldPosition = matrix_multiply(rightHandAnchor.transform, rightHandIndexFingerTip.rootTransform).columns.3.xyz

		// center of triangle (j1,j2が底辺、j3が頂点の三角形と仮定する)
		let h1 = (j1+j2) / 2	// half point of j1 & j2
		let ct = (h1+j3) / 2	// center point (half point of h1 & j3)

		let xAxis = normalize(j2 - j1)
		let yAxis = normalize(j3 - h1)
		let zAxis = normalize(cross(xAxis, yAxis))

		let triangleCenterWorldTransform = simd_matrix(
			SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
			SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
			SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
			SIMD4(ct.x, ct.y, ct.z, 1)
		)
		return triangleCenterWorldTransform
	}

}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
