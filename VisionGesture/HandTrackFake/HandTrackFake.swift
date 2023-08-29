//
//  HandTrackFake.swift
//  HandGesture
//
//  Created by Yos Hashimoto on 2023/08/27.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import MultipeerConnectivity

let enableHandTrackFake = true
let appGroupName = "group.com.newtonjapan.handtrackfake"

extension HandTrackFake : MCSessionDelegate {
	// MARK: Multipeer connectivity
	
	func initAsAdvertiser() {
		advertiserPeerID = MCPeerID(displayName: advertiserName)
		session = MCSession(peer: advertiserPeerID)
		session.delegate = self
		advertiser = MCNearbyServiceAdvertiser(peer: advertiserPeerID, discoveryInfo: nil, serviceType: serviceName)
		advertiser.delegate = self
		advertiser.startAdvertisingPeer()
	}

	func initAsBrowser() {
		browserPeerID = MCPeerID(displayName: browserName)
		session = MCSession(peer: browserPeerID)
		session.delegate = self
		browser = MCNearbyServiceBrowser(peer: browserPeerID, serviceType: serviceName)
		browser.delegate = self
		browser.startBrowsingForPeers()
	}

	func isSessionActive() -> Bool {
		return (sessionState == .connected)
	}
	
	func sendHandTrackData(_ jsonStr: String) {
		do {
			try session.send(jsonStr.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
		} catch let error {
			print(error.localizedDescription)
		}
	}

	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		guard let message = String(data: data, encoding: .utf8) else { return }
		currentJsonString = message
		DispatchQueue.main.async {
		}
	}

	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		let message: String
		switch state {
		case .connected:
			message = "\(peerID.displayName)が接続されました"
		case .connecting:
			message = "\(peerID.displayName)が接続中です"
		case .notConnected:
			message = "\(peerID.displayName)が切断されました"
		@unknown default:
			message = "\(peerID.displayName)が想定外の状態です"
		}
		DispatchQueue.main.async {
			print(message)
		}

	}
	
	
	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
	}
	
	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
	}
	
	func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
	}

}

extension HandTrackFake: MCNearbyServiceAdvertiserDelegate {
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		print("receive invitation from \(peerID.description)")
		invitationHandler(true, session)
	}
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		print(error.localizedDescription)
	}
}

extension HandTrackFake: MCNearbyServiceBrowserDelegate {

	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		guard let session = session else { return }
		browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
	}

	func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
		print(error.localizedDescription)
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		print("lost peer")
	}
}
class HandTrackFake: NSObject {
	private let fileManager = FileManager.default
	private var fakeRootDirectory = ""

	private let serviceName = "HandTrackFake"
	private var advertiserName = "HandTrackFakeSender"
	private var browserName    = "HandTrackFakeReceiver"
	private var advertiserPeerID : MCPeerID!
	private var browserPeerID: MCPeerID!
	private var session: MCSession!
	private var sessionState: MCSessionState = .notConnected
	private var advertiser: MCNearbyServiceAdvertiser!
	private var browser: MCNearbyServiceBrowser!
	var currentJsonString: String = ""
	
	let handTrackDataKey  = "HandTrackData"

	override init() {
		super.init()
		
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

