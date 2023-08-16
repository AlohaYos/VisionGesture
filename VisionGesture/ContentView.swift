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

    @State private var showImmersiveSpace = true

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

	@State var logText: String = "Ready..."
	
    var body: some View {
//        NavigationSplitView {
//            List {
//                Text("Item")
//            }
//            .navigationTitle("Sidebar")
//        } detail: {
            VStack {
//                Model3D(named: "Scene", bundle: realityKitContentBundle)
//                    .padding(.bottom, 50)

                Text(logText)
					.multilineTextAlignment(.leading)

                Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
                    .toggleStyle(.button)
                    .padding(.top, 50)
            }
//            .navigationTitle("Content")
//            .padding()
//        }
//			.frame(width: 100, height: 100)
//			.opacity(0.3)
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
			await openImmersiveSpace(id: "ImmersiveSpace")
		}
    }
	
	func textLog(_ message: String) {
		logText = message+"\r"+logText
	}

}

#Preview {
    ContentView()
}
