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
			RealityView { content in
				do {
					var ball = try await Entity(named: "Sun", in: realityKitContentBundle)
					viewModel.setBallEntiry(ent: ball)
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
//					.onChanged { _ in		// 回転
//						rotationA.degrees += 5.0
//						let m1 = Transform(pitch: Float(rotationA.radians)).matrix
//						let m2 = Transform(yaw: Float(rotationA.radians)).matrix
//						kuma.transform.matrix = matrix_multiply(m1, m2)
//						kuma.position = SIMD3(x: 0, y: 1.5, z: -2)
//						kuma.scale = [0.15, 0.15, 0.15]
//					}
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
			gestureProvider.appendGesture(VisionGesture_Cursor(delegate: self))
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
			Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
				timerCount += 1
				textLog("timer job : \(timerCount)")
				var xPos: Float = Float(timerCount) * 0.02
				add_point(pos: SIMD3(x: xPos, y: 1.5, z: -1))
			}
		}
		.task {
			Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
				timerCountQuick += 1
				rotate_kuma()
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
		viewModel.addPoint(pos!)
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
		textLog("gesturePlot")
		if gesture is Gesture_Aloha {
			add_point(pos: atPoints)
		}
	}
	func gesturePlotSIMD4(gesture: VisionGestureProcessor, atPoints:simd_float4x4) {
		textLog("gesturePlot")
		if gesture is Gesture_Aloha {
			// TODO: そのポイントに点を表示したい
		}
	}

}

// MARK: Other job

extension ImmersiveView {

	func textLog(_ message: String) {
		logText = message+"\r"+logText
//		_ = viewModel.addText(text: message)
	}

}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
