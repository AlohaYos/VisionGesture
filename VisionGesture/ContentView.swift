//
//  ContentView.swift
//  VisionGesture
//
//  Created by Yos Hashimoto on 2023/08/16.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false

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
				.padding(.top, 50)
				.opacity(0.3)
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
		.task {
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
				print("### NSHomeDirectory=[\(NSHomeDirectory())]")
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
