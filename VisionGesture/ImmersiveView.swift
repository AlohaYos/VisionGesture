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

struct ImmersiveView: View {
	@State var logText: String = "Ready..."
	var gestureProvider = VisionGestureProvider()
	var viewModel: ViewModel = ViewModel()

	init(){
		textLog("init")
	}
	var body: some View {
		ZStack {
			Text(logText)
				.frame(width: 1250, height: 690, alignment: .topLeading)
				.multilineTextAlignment(.leading)
				.background(Color.blue)
				.foregroundColor(Color.white)
//				.background(Color.black)
//				.foregroundColor(Color.green)
			RealityView { content in
				content.add(viewModel.setupContentEntity())
				viewModel.clearText()
				// _ = viewModel.addText(text: "Gesture\nVision ")
			}
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
			}
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
		if gesture is Gesture_Aloha {
			// TODO: そのポイントに点を表示したい
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
}

// MARK: Other job

extension ImmersiveView {

	func textLog(_ message: String) {
		logText = message+"\r"+logText
		_ = viewModel.addText(text: message)
	}

}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
