//
//  VisionGestureApp.swift
//  VisionGesture
//
//  Created by Yos Hashimoto on 2023/08/16.
//

import SwiftUI

@main
struct VisionGestureApp: App {
    var body: some Scene {
        WindowGroup {
			ImmersiveView()
            //ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
