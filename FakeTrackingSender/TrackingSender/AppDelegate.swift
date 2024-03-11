//
//  AppDelegate.swift
//
//  Copyright © 2023 Yos. All rights reserved.
//

import UIKit

let handTrackFake = HandTrackFake()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
	}


}

// MARK: - Errors

enum AppError: Error {
	case captureSessionSetup(reason: String)
	case visionError(error: Error)
	case otherError(error: Error)
	
	static func display(_ error: Error, inViewController viewController: UIViewController) {
		if let appError = error as? AppError {
			appError.displayInViewController(viewController)
		} else {
			AppError.otherError(error: error).displayInViewController(viewController)
		}
	}
	
	func displayInViewController(_ viewController: UIViewController) {
		let title: String?
		let message: String?
		switch self {
		case .captureSessionSetup(let reason):
			title = "AVSession Setup Error"
			message = reason
		case .visionError(let error):
			title = "Vision Error"
			message = error.localizedDescription
		case .otherError(let error):
			title = "Error"
			message = error.localizedDescription
		}
		
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		
		viewController.present(alert, animated: true, completion: nil)
	}
}

