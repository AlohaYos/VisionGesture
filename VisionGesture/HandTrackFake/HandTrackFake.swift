//
//  HandTrackFake.swift
//  HandGesture
//
//  Created by Yos Hashimoto on 2023/08/27.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation

let enableHandTrackFake = true
let appGroupName = "group.com.newtonjapan.handtrackfake"

struct HandTrackFake {
	private let fileManager = FileManager.default
	private var fakeRootDirectory = ""

	let handTrackDataKey  = "HandTrackData"

	init() {
		// print("### NSHomeDirectory=[\(NSHomeDirectory())]")
		// /Users/yoshiyuki/Library/Containers/com.newtonjapan.apple-samplecode.HandPose/Data/HandTrackFake
		fakeRootDirectory = NSHomeDirectory() + "/HandTrackFake"

		// Target -> Capabilities -> App Sandbox -> File access -> Downloads folder を Read/Writeに設定すること
		fakeRootDirectory = "/Users/yoshiyuki/Downloads/HandTrackFake"

		createDirectory(atPath: fakeRootDirectory)
		
		let userDefaults = UserDefaults(suiteName: appGroupName)
		userDefaults?.register(defaults: ["JsonStore" : ""])
	}
	
	// MARK: file management
	private func convertPath(_ path: String) -> String {
		if path.hasPrefix("/") {
			return fakeRootDirectory + path
		}
		return fakeRootDirectory + "/" + path
	}

	func createDirectory(atPath path: String) {
		if fileExists(atPath: path) {
			return
		}
		do {
		   try fileManager.createDirectory(atPath: convertPath(path), withIntermediateDirectories: true, attributes: nil)
		} catch let error {
			print(error.localizedDescription)
		}
	}

	func createFile(atPath path: String, contents: String) {
		createFile(atPath: path, contents: contents.data(using: .utf8))
	}

	func createFile(atPath pathS: String, contents: Data?) {
		let path = convertPath(pathS)
		if fileExists(atPath: path) {
			print("already exists file: \(NSString(string: path))")
			return
		}
		if !fileManager.createFile(atPath: convertPath(path), contents: contents, attributes: nil) {
			print("Create file error")
		}
	}
	
	func writeFile(atPath path: String, contents: String) {
		setGroupData(key: "JsonData", jsonStr: contents)
		return
		
		do {
			let path = convertPath(path)
			let url: URL = URL(fileURLWithPath: path)
			try contents.write(to: url, atomically: false, encoding: .utf8)
		}
		catch {}
	}

	func readFile(atPath path: String) -> String {
		guard let ret = groupData(key: "JsonData") as? String else { return "" }
		return ret
		
		var retStr = ""
		let path = convertPath(path)
		if !fileExists(atPath: path) {
			print("file not exist: \(NSString(string: path))")
			retStr = ""
		}
		do {
			let url: URL = URL(fileURLWithPath: path)
			retStr = try String(contentsOf: url, encoding: .utf8)
		}
		catch {
		}
		return retStr
	}
	
	func fileExists(atPath path: String) -> Bool {
		return fileManager.fileExists(atPath: convertPath(path))
	}

	func setGroupData(key: String, jsonStr: String) {
		let userDefaults = UserDefaults(suiteName: appGroupName)
		userDefaults?.setValue(jsonStr, forKey: key)
	}

	func groupData(key: String) -> String? {
		let userDefaults = UserDefaults(suiteName: appGroupName)
		let jsonStr = userDefaults?.object(forKey: key) as? String
		return jsonStr
	}
	
}

