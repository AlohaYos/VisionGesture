//
//  VisionGestureProvider.swift
//  HandGesture
//
//  Created by Yos Hashimoto on 2023/08/15.
//

import Foundation
import UIKit
import AVFoundation
import Vision

#if targetEnvironment(simulator)
import ARKit
#else
@preconcurrency import ARKit
#endif

class VisionGestureProvider: NSObject {
	var baseView: UIView? = nil

	let session = ARKitSession()
	var handTracking = HandTrackingProvider()
	struct HandsUpdates {
		var left: HandAnchor?
		var right: HandAnchor?
	}
	var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
	var gestureProcessors = [VisionGestureProcessor]()
	
	init(baseView: UIView? = nil) {
		super.init()
		self.baseView = baseView
	}
	
	override init() {
		super.init()
	}
	
	func terminate() {
	}

	
	func start() async {
		do {
			var auths = HandTrackingProvider.requiredAuthorizations
			if HandTrackingProvider.isSupported {
				print("ARKitSession starting.")
				try await session.run([handTracking])
			}
		} catch {
			print("ARKitSession error:", error)
		}
	}
	
	func publishHandTrackingUpdates() async {
		if handTrackFake.enableFake {
			DispatchQueue.main.async {
				Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
					for processor in self.gestureProcessors {
						processor.processHandPoseObservations(observations: [])
					}
				}
			}
		}
		else {
			for await update in handTracking.anchorUpdates {
				switch update.event {
				case .updated:
					let anchor = update.anchor
					guard anchor.isTracked else { continue }
					
					if anchor.chirality == .left {
						// Update left hand info.
						latestHandTracking.left = anchor
					} else if anchor.chirality == .right {
						// Update right hand info.
						latestHandTracking.right = anchor
					}
				default:
					break
				}
				
				if latestHandTracking.right != nil && latestHandTracking.left != nil {
					for processor in gestureProcessors {
						// ジェスチャー判定
						processor.processHandPoseObservations(observations: [latestHandTracking.right, latestHandTracking.left])
					}
				}
			}
		}
	}
	
	func monitorSessionEvents() async {
		for await event in session.events {
			switch event {
			case .authorizationChanged(let type, let status):
				if type == .handTracking && status != .allowed {
					// Stop the game, ask the user to grant hand tracking authorization again in Settings.
				}
			@unknown default:
				print("Session event \(event)")
			}
		}
	}

	func appendGesture(_ gesture: VisionGestureProcessor) {
		gestureProcessors.append(gesture)
	}

	func layoutSubviews() {
	}
	
	func clearDrawLayer() {
	}
	
}

extension SIMD4 {
	var xyz: SIMD3<Scalar> {
		self[SIMD3(0, 1, 2)]
	}
}
