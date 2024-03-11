//
//  ImmersiveView.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent
import MultipeerConnectivity

var gestureAloha: Gesture_Aloha?
var gestureDraw: Gesture_Draw?
var zDepth:Float = 0.25

struct ImmersiveView: View {
	let handTrackProcess: HandTrackProcess = HandTrackProcess()
	let hand = Hand()
	let handModel = HandModel()
	let viewModel = ViewModel()
	@State var logText: String = "Ready..."
	var worldAnchor: AnchorEntity?

	init(){
		textLog("init")
		handTrackFake.initAsBrowser()
		worldAnchor = AnchorEntity(world: [0,0,0])
	}
	var body: some View {
		ZStack {
			RealityView { content in
				if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
					scene.position = SIMD3(x: 0, y: 0.4, z: -1.5)
					content.add(scene)
				}
				if let hands = try? await Entity(named: "hands", in: realityKitContentBundle) {
					if let leftHand = hands.findEntity(named: "LeftHand"), let rightHand = hands.findEntity(named: "RightHand") {
						hand.setHandEntity(leftHand: leftHand, rightHand: rightHand)
						if handTrackFake.enableFake == true {
							leftHand.isEnabled = false
							rightHand.isEnabled = false
						}
					}
					let handEntify = hand.setupContentEntity()
					handEntify.position = SIMD3(x: 0, y: 0.0, z: zDepth)
					content.add(handEntify)
				}
				let handEntity = handModel.setupContentEntity()
				content.add(handEntity)
				handModel.setupBones()
				let modelEntity = viewModel.setupContentEntity()
				modelEntity.position = SIMD3(x: 0, y: 0.0, z: zDepth)
				content.add(modelEntity)
			}
			RealityView { content, attachments in
				let ent = Entity()
				ent.scale = [4.0, 4.0, 4.0]
				ent.position = SIMD3(x: 0, y: 1.9, z: -2.45)
				ent.generateCollisionShapes(recursive: true)
				content.add(ent)
				if let textAttachement = attachments.entity(for: "text_view") {
					textAttachement.position = SIMD3(x: 0, y: 0, z: 0)
					ent.addChild(textAttachement)
				}
			} attachments: {
				Attachment(id: "text_view") {
					Text(logText)
						.frame(width: 1000, height: 690, alignment: .topLeading)
						.multilineTextAlignment(.leading)
						.background(Color.blue)
						.foregroundColor(Color.white)
				}
			}
		}	// ZStack
		.task {
			await handTrackProcess.handTrackingStart()
			gestureDraw = Gesture_Draw(delegate: self)
			gestureAloha = Gesture_Aloha(delegate: self)
		}
		.task {
			await handTrackProcess.monitorSessionEvents()
		}
		.task {
			// Hand tracking loop
			await handTrackProcess.publishHandTrackingUpdates(updateJob: { (fingerJoints, updates) -> Void in
				DispatchQueue.main.async {
					if handTrackFake.enableFake == true {
						displayHandJoints(handJoints: fingerJoints)
					}
					else {
						hand.show(anchorUpdate:updates!)
					}
					gestureDraw?.checkGesture(handJoints: fingerJoints)
					gestureAloha?.checkGesture(handJoints: fingerJoints)
				}
			})
		}
	}
	
	// Display hand tracking
	static var lastState = MCSessionState.notConnected
	func displayHandJoints(handJoints: [[[SIMD3<Scalar>?]]]) {
		let nowState = handTrackFake.sessionState
		if nowState != ImmersiveView.lastState {
			switch nowState {
			case .connected:
				textLog("HandTrackFake connected.")
			case .connecting:
				textLog("HandTrackFake connecting...")
			default:
				textLog("HandTrackFake not connected.")
			}
			ImmersiveView.lastState = nowState
		}

		switch handJoints.count {
		case 1:
			handModel.setHandJoints(left : handJoints[0], right: nil)
			handModel.showFingers()
		case 2:
			handModel.setHandJoints(left : handJoints[0], right: handJoints[1])
			handModel.showFingers()
		default:
			handModel.setHandJoints(left : nil, right: nil)
			handModel.showFingers()
		}
		if HandTrackProcess.handJoints.count < 2 {
			HandTrackProcess.handJoints.append([])
		}
	}
}

// MARK: Gesture delegate job

extension ImmersiveView: GestureDelegate {

	func gesture(gesture: GestureBase, event: GestureDelegateEvent) {
		if gesture is Gesture_Aloha {
			handle_gestureAloha(event: event)
		}
		if gesture is Gesture_Draw {
			handle_gestureDraw(event: event)
		}
	}
	
	// Draw
	func handle_gestureDraw(event: GestureDelegateEvent) {
		switch event.type {
		case .Moved3D:
			if let pnt = event.location[0] as? SIMD3<Scalar> {
				viewModel.addPoint(pnt)
			}
		case .Fired:
//			viewModel.clearAllPoint()
			break
		case .Moved2D:
			break
		case .Began:
			break
		case .Ended:
			break
		case .Canceled:
			break
		default:
			break
		}
	}
	// Aloha
	func handle_gestureAloha(event: GestureDelegateEvent) {
		switch event.type {
		case .Moved3D:
			viewModel.setPoints(event.location as! [SIMD3<Scalar>?])
		case .Fired:
			viewModel.clearAllPoint()
//			if let pnt = event.location[0] as? SIMD3<Scalar> {
//				viewModel.addPoint(pnt)
//			}
			break
		case .Moved2D:
			break
		case .Began:
			viewModel.beginAloha()
			break
		case .Ended:
			viewModel.endAloha()
			break
		case .Canceled:
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
		}
	}
}

// MARK: Preview

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
