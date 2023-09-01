//
//  VisionGestureApp.swift
//  VisionGesture
//
//  Created by Yos Hashimoto on 2023/08/16.
//

import SwiftUI

let handTrackFake = HandTrackFake()

@main
struct VisionGestureApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.defaultSize(width: 100, height: 100)
		.windowStyle(.plain)
		
		ImmersiveSpace(id: "ImmersiveSpace") {
			ImmersiveView()
		}.immersionStyle(selection: .constant(.full), in: .automatic)	// .automaticにすれば、デジタルクラウンでイマーシブ度を調整できる
	}
	
}
