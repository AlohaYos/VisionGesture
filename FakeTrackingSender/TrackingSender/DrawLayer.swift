//
//  DrawLayer.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

private let drawPath = UIBezierPath()

class DrawLayer: CAShapeLayer {
	var cameraView: CameraView!

	func prepare() {
		lineWidth = 5
//		backgroundColor = #colorLiteral(red: 0.9999018312, green: 1, blue: 0.9998798966, alpha: 0.5).cgColor
		strokeColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1).cgColor
//		fillColor = #colorLiteral(red: 0.9999018312, green: 1, blue: 0.9998798966, alpha: 0).cgColor
		lineCap = .round
	}

	func clearPath() {
		drawPath.removeAllPoints()
		self.path = drawPath.cgPath
	}
	
}
