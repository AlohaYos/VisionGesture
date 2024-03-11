//
//  CameraViewController.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

// MARK: CameraViewController

class CameraViewController: UIViewController {

	@IBOutlet weak var sliderZ: UISlider!
	
	private var gestureProvider: HandTrackingProvider?
		
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		gestureProvider = HandTrackingProvider(baseView: self.view)
	}
	
	override func viewDidLayoutSubviews() {
		gestureProvider?.layoutSubviews()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		gestureProvider?.terminate()
		super.viewWillDisappear(animated)
	}
	
	// MARK: Slider Job
	@IBAction func sliderZ_ValueChanged(_ sender: UISlider) {
//		print("Z=\(sender.value)")
		handTrackFake.zDepth = sender.value
	}
	
	
}

