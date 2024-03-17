//
//  TrackingReceiverApp.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import SwiftUI

let handTrackFake = HandTrackFake()

@main
struct TrackingReceiverApp: App {
    var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.defaultSize(width: 100, height: 200)
		.windowStyle(.plain)

		ImmersiveSpace(id: "ImmersiveSpace") {
			ImmersiveView()
		}
		.immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
