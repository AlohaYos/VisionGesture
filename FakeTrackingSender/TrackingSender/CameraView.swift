//
//  CameraView.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import UIKit
import AVFoundation

class CameraView: UIView {
	
	var overlayLayer = DrawLayer()	// draw finger point
	var drawLayer = DrawLayer()		// draw path
	
	// MARK: initialize camera layer
	var previewLayer: AVCaptureVideoPreviewLayer {
		return layer as! AVCaptureVideoPreviewLayer
	}
	
	override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupOverlay()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupOverlay()
	}
	
	override func layoutSublayers(of layer: CALayer) {
		super.layoutSublayers(of: layer)
		if layer == previewLayer {
			overlayLayer.frame = layer.bounds
			drawLayer.frame = layer.bounds
		}
	}
	
	private func setupOverlay() {
		setupDrawLayer()
		previewLayer.addSublayer(drawLayer)
		previewLayer.addSublayer(overlayLayer)
		overlayLayer.cameraView = self
	}
		
}

// MARK: draw finger point and path

extension CameraView {
	struct Holder {
		static var drawPath = UIBezierPath()
		static var lastDrawPoint: CGPoint? = nil
		static var pointsPath = UIBezierPath()
	}
	
	// MARK: draw path
	func setupDrawLayer() {
		drawLayer.lineWidth = 5
		drawLayer.backgroundColor = #colorLiteral(red: 0.9999018312, green: 1, blue: 0.9998798966, alpha: 0.5).cgColor
		drawLayer.strokeColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1).cgColor
		drawLayer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
		drawLayer.lineCap = .round
	}
	
	func updatePath(with drawPoint: CGPoint, isLastPoint: Bool) {
				
		if isLastPoint {
			if let lastPoint = Holder.lastDrawPoint {
				if drawPoint != CGPointZero {
					Holder.drawPath.addLine(to: lastPoint)
				}
			}
			Holder.lastDrawPoint = nil
		} else {
			if Holder.lastDrawPoint == nil {
				Holder.lastDrawPoint = drawPoint
				if drawPoint != CGPointZero {
					Holder.drawPath.move(to: drawPoint)
				}
			} else {
				if drawPoint != CGPointZero {
					Holder.drawPath.addLine(to: drawPoint)
				}
			}
		}
		drawLayer.path = Holder.drawPath.cgPath
	}
	
	func clearPath() {
		Holder.lastDrawPoint = nil
		Holder.drawPath.removeAllPoints()
		drawLayer.clearPath()
	}
	
	// MARK: draw finger point dot
	func showPoints(_ points: [CGPoint], color: UIColor) {
		Holder.pointsPath.removeAllPoints()
		for point in points {
			Holder.pointsPath.move(to: point)
			Holder.pointsPath.addArc(withCenter: point, radius: 15, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
		}
		overlayLayer.fillColor = color.cgColor
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		overlayLayer.path = Holder.pointsPath.cgPath
		CATransaction.commit()
	}
	
	func clearPoints() {
		overlayLayer.clearPath()
	}

}
