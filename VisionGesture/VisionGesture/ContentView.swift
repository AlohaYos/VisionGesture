//
//  ContentView.swift
//  
//  Copyright © 2023 Yos. All rights reserved.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

	@State private var showImmersiveSpace = false
	@State private var remoteHands = false
	@State private var rotateHands = false

	@Environment(\.openImmersiveSpace) var openImmersiveSpace
	@Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

	@State var logText: String = "Ready..."
	
	var body: some View {

		VStack {
			Text(logText)
				.multilineTextAlignment(.leading)
				.opacity(0.3)
			Toggle("Toggle Immersive", isOn: $showImmersiveSpace)
				.toggleStyle(.button)
				.padding(.top, 10)
				.opacity(0.3)
			Toggle("Remote Hand", isOn: $remoteHands)
				.padding(.top, 10)
				.padding(.bottom, 10)
				.opacity(0.3)
//			Toggle("Hand Rotate", isOn: $rotateHands)
//				.padding(.top, 10)
//				.padding(.bottom, 10)
//				.opacity(0.3)
		}
		.onChange(of: showImmersiveSpace) { _, newValue in
			Task {
				if newValue {
					textLog("Open Immersive")
					await openImmersiveSpace(id: "ImmersiveSpace")
				} else {
					textLog("Dismiss Immersive")
					await dismissImmersiveSpace()
				}
			}
		}
		.onChange(of: remoteHands) { _, newValue in
			if newValue {
				zDepth = -1.0
			}
			else {
				zDepth = 0.25
			}
		}
		.onChange(of: rotateHands) { _, newValue in
			handTrackFake.rotateHands = newValue
		}
		.task {
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
				showImmersiveSpace = true
			}
		}
	}
	
	func textLog(_ message: String) {
		logText = message+"\r"+logText
	}

}

#Preview {
	ContentView()
}
