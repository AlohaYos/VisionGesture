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

var timerCount = 0
var timerCountQuick = 0

struct ImmersiveView: View {
	@State var logText: String = "Ready..."
	var gestureProvider = VisionGestureProvider()
	var viewModel: ViewModel = ViewModel()
	@State var kuma: Entity = Entity()
	@State var rotationA: Angle = .zero

	init(){
		textLog("init")
	}
	var body: some View {
		ZStack {
			RealityView { content in
				if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {	// パーティクル
//					scene.scale = [0.15, 0.15, 0.15]
//					scene.position = SIMD3(x: 0, y: 1.5, z: -1)
					content.add(scene)
				}
			}
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
//					let glove = try await Entity(named: "RubberGlove", in: realityKitContentBundle)
					viewModel.setGloveEntiry(ent: glove)
				}
				catch { return }
				content.add(viewModel.setupContentEntity())
//				viewModel.clearText()
			}
			RealityView { content, attachments in
				do {
					kuma = try await Entity(named: "kuma", in: realityKitContentBundle)
					kuma.scale = [0.15, 0.15, 0.15]
					kuma.position = SIMD3(x: 0, y: 1.5, z: -2)
					kuma.components.set(InputTargetComponent())
					kuma.generateCollisionShapes(recursive: true)
					content.add(kuma)
					
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
			/*
			.gesture(SpatialEventGesture { events in
				// https://developer.apple.com/documentation/swiftui/spatialeventgesture
						for event in events {
							// SpatialEventCollection.Event
							// https://developer.apple.com/documentation/swiftui/spatialeventcollection
							/*
							event.location
							event.id
							event.kind
							event.inputDevicePose
							event.location3D
							event.modifierKeys
							event.selectionRay
							event.targetedEntity
							event.timestamp
							*/
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
			*/
			.gesture(
				SpatialEventGesture(action: { events in })
					.targetedToAnyEntity()
					.targetedToEntity(kuma)
					.onEnded({ value in	// action: (EntityTargetValue<EntityTargetValue<SpatialEventGesture.Value>>) -> Void

					})
//					.onChanged{ value in
//						textLog("SpatialTapGesture.onChanged")
//						value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
//					}
					.onEnded { value in
						textLog("SpatialEventGesture.onEnded")
//						value.gestureValue	// EntityTargetValue<SpatialEventGesture.Value>
						let msg = value.entity.debugDescription
						let pos = value.entity.position.debugDescription
						textLog("  - \(msg)")
						textLog("  - \(pos)")
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

		}
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
			gestureProvider.appendGesture(Gesture_Aloha(delegate: self))
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
				rotate_kuma()
			}
		}
		.task {
			Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
				let gesDum = Gesture_Aloha(delegate: self)
				timerCount += 1
				textLog("timer job : \(timerCount)")
// --- Sun
				let xPos: Float = Float(timerCount) * 0.02 - 0.8
				viewModel.addPoint(SIMD3(x: xPos, y: 1.5, z: -1))
// --- Biplane
				var delta = timerCount*10
				var joint1 = SIMD3(x: xPos-0.25, y: 1.7, z: -1)	// 底辺左
				var joint2 = SIMD3(x: xPos+0.25, y: 1.7, z: -1)	// 底辺右
				var joint3 = SIMD3(x: xPos,      y: 1.8, z: -1)	// 頂点
				var mtx: simd_float4x4? = gesDum.triangleCenterWithAxis(joint1:joint1, joint2:joint2, joint3:joint3)
				var rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(delta), 0, 0, 1)	// z軸を中心とした10度回転
				var rotateSimd = matrix_float4x4(rotateMat)
				var mtxOut = mtx! * rotateSimd
				viewModel.addPoint4(mtxOut)
// --- Glove
				delta = timerCount*5
				joint1 = SIMD3(x: xPos-0.25, y: 1.2, z: -1)	// 底辺左
				joint2 = SIMD3(x: xPos+0.25, y: 1.2, z: -1)	// 底辺右
				joint3 = SIMD3(x: xPos,      y: 1.3, z: -1)	// 頂点
				mtx = gesDum.triangleCenterWithAxis(joint1:joint1, joint2:joint2, joint3:joint3)
				rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(delta), 0, 1, 0)	// Y軸を中心とした10度回転
				rotateSimd = matrix_float4x4(rotateMat)
				mtxOut = mtx! * rotateSimd
				viewModel.moveGlove(mtxOut)
// --- finger tips
				delta = timerCount*5
				joint1 = SIMD3(x: xPos-0.05, y: 1.20, z: -1)	// 親指
				joint2 = SIMD3(x: xPos+0.05, y: 1.20, z: -1)	// 小指
				joint3 = SIMD3(x: xPos,      y: 1.15, z: -1)	// 手首
				mtx = gesDum.triangleCenterWithAxis(joint1:joint1, joint2:joint2, joint3:joint3)
				rotateMat = SCNMatrix4MakeRotation(.pi/180*Float(delta), 0, 1, 0)	// Y軸を中心とした10度回転
				rotateSimd = matrix_float4x4(rotateMat)
				mtxOut = mtx! * rotateSimd
				viewModel.setPoints([
					joint1, joint2, joint3
				])
			}
		}
	}
	
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
	func set_points(pos: [SIMD3<Scalar>?]) {
		viewModel.setPoints(pos)
	}
	func add_point4(pos: simd_float4x4?) {
		if let p = pos {
			viewModel.addPoint4(p)
		}
	}
}

// MARK: VisionGestureDelegate job

extension ImmersiveView: VisionGestureDelegate {
	func gestureBegan(gesture: VisionGestureProcessor, atPoints:[CGPoint]) {
		textLog("gestureBegan at point")
		for point:CGPoint in atPoints {
			textLog("    (\(point.x),\(point.y)")
		}
	}
	func gestureMoved(gesture: VisionGestureProcessor, atPoints:[CGPoint]) {
		textLog("gestureMoved at point")
		for point:CGPoint in atPoints {
			textLog("    (\(point.x),\(point.y)")
		}
	}
	func gestureFired(gesture: VisionGestureProcessor, atPoints:[CGPoint], triggerType: Int) {
		textLog("gestureFired at point")
		for point:CGPoint in atPoints {
			textLog("    (\(point.x),\(point.y)")
		}
	}
	func gestureEnded(gesture: VisionGestureProcessor, atPoints:[CGPoint]) {
		textLog("gestureEnded at point")
		for point:CGPoint in atPoints {
			textLog("    (\(point.x),\(point.y)")
		}
	}
	func gestureCanceled(gesture: VisionGestureProcessor, atPoints:[CGPoint]) {
		textLog("gestureCanceled at point")
		for point:CGPoint in atPoints {
			textLog("    (\(point.x),\(point.y)")
		}
	}
	func gesturePlotSIMD3(gesture: VisionGestureProcessor, atPoints:SIMD3<Scalar>) {
		textLog("gesturePlot3")
		if gesture is Gesture_Aloha {
			add_point(pos: atPoints)
		}
	}
	func gesturePlotSIMD3s(gesture: VisionGestureProcessor, atPoints:[SIMD3<Scalar>]) {
		textLog("gesturePlot3s")
		if gesture is Gesture_Aloha {
			set_points(pos: atPoints)
		}
	}
	func gesturePlotSIMD4(gesture: VisionGestureProcessor, atPoints:simd_float4x4) {
		textLog("gesturePlot4")
		if gesture is Gesture_Aloha {
			viewModel.moveGlove(atPoints)
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

}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
