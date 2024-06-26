//
//  HandTrackFake.swift
//    VNHumanHandPoseObservation to capture finger movement.
//    Encode capture data into Json.
//    Send Json via Bluetooth (Multipeer connectivity).
//    Receive Json via Bluetooth.
//    Decode Json to 3D hand tracking data.
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreGraphics
import UIKit
import Vision

typealias Scalar = Float

class HandTrackFake: NSObject {
	var enableFake = false
	var rotateHands = false
	var zDepth: Float = 0.0

	private let serviceName = "HandTrackFake"
	private var advertiserName = "HandTrackFakeSender"
	private var browserName    = "HandTrackFakeReceiver"
	private var advertiserPeerID : MCPeerID!
	private var browserPeerID: MCPeerID!
	private var session: MCSession!
	private var advertiser: MCNearbyServiceAdvertiser!
	private var browser: MCNearbyServiceBrowser!
	var currentJsonString: String = ""
	var sessionState: MCSessionState = .notConnected
	
	override init() {
		super.init()
	}
	init(enableFake:Bool) {
		self.enableFake = enableFake
		super.init()
	}
}
	
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

	func sendHandTrackData(_ dt3D: [[[SIMD3<Scalar>?]]]) {
		let dt = HandTrackJson3D(handTrackData: dt3D)
		if dt.jsonStr.count>0 {
			handTrackFake.sendHandTrackData(dt.jsonStr)
		}
	}

	func sendHandTrackData(_ handJoints: [[[VNRecognizedPoint?]]]) {
		let jsonStr = HandTrackJson2D(handTrackData: handJoints).jsonStr
		handTrackFake.sendHandTrackData(jsonStr)
	}

	func sendHandTrackData(_ jsonStr: String) {
		var sendStr: String = jsonStr
		if sendStr.count == 0 {
			sendStr = "__NoData__"
		}
		do {
			try session.send(sendStr.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
		} catch let error {
//			print(error.localizedDescription)
		}
	}

	func receiveHandTrackData() -> [[[SIMD3<Scalar>?]]] {
		var fingerJoints1 = [[SIMD3<Scalar>?]]()
		var fingerJoints2 = [[SIMD3<Scalar>?]]()
		if handTrackFake.currentJsonString.count>0 {
			if let dt3D = HandTrackJson3D(jsonStr: handTrackFake.currentJsonString) {
				let handCount = dt3D.handJoints.count
				if handCount>0 {
					fingerJoints1 = dt3D.handJoints[0]
//					print("\(handTrackFake.currentJsonString)")
				}
				if handCount>1 {
					fingerJoints2 = dt3D.handJoints[1]
				}
			}
		}
		return [fingerJoints1, fingerJoints2]
	}
	
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		guard let message = String(data: data, encoding: .utf8) else { return }
		currentJsonString = message
		if message == "__NoData__" {
			currentJsonString = ""
		}
		DispatchQueue.main.async {
		}
	}

	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		let message: String
		self.sessionState = state
		switch state {
		case .connected:
			message = "\(peerID.displayName) connected."
		case .connecting:
			message = "Connecting \(peerID.displayName)"
		case .notConnected:
			message = "\(peerID.displayName) disconnected."
		@unknown default:
			message = "\(peerID.displayName) status unknown."
		}
		DispatchQueue.main.async {
//			print(message)
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
//		print("receive invitation from \(peerID.description)")
		invitationHandler(true, session)
	}
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
//		print(error.localizedDescription)
	}
}

extension HandTrackFake: MCNearbyServiceBrowserDelegate {

	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		guard let session = session else { return }
		browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
	}

	func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
//		print(error.localizedDescription)
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
//		print("lost peer")
	}
}

// MARK: VNRecognizedPointFake

struct VNRecognizedPointFake: Codable {
	var identifier: String 	//  VNRecognizedPointKey
	var confidence: Float 			//  VNConfidence
	var x: Double
	var y: Double
	var location: CGPoint
	
	enum CodingKeys: String, CodingKey {
		case identifier
		case confidence
		case x
		case y
		case location
	}

	init(identifier: String, confidence: VNConfidence, x: Double, y: Double, location: CGPoint) {
		self.identifier = identifier
		self.confidence = confidence
		self.x = x
		self.y = y
		self.location = location
	}
	
	init(val: VNRecognizedPoint) {
		self.identifier = val.identifier.rawValue
		self.confidence = val.confidence
		self.x = val.x
		self.y = val.y
		self.location = val.location
	}
	
	init(from decoder: Decoder) throws {
	  let values = try decoder.container(keyedBy: CodingKeys.self)
		identifier = try values.decode(String.self, forKey: .identifier)
		confidence = try values.decode(Float.self, forKey: .confidence)
		x = try values.decode(Double.self, forKey: .x)
		y = try values.decode(Double.self, forKey: .y)
		location = try values.decode(CGPoint.self, forKey: .location)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(identifier, forKey: .identifier)
		try container.encode(confidence, forKey: .confidence)
		try container.encode(x, forKey: .x)
		try container.encode(y, forKey: .y)
		try container.encode(location, forKey: .location)
	}
}

// MARK: HandTrackTransferData

struct HandTrackTransferData: Codable {
	var points: [[[VNRecognizedPointFake?]]] = []
	var zDepth: Float = 0.0
}

// MARK: HandTrackJson2D

struct HandTrackJson2D: Codable {
	var handJoints: [[[VNRecognizedPoint?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	var handJointsFake: [[[VNRecognizedPointFake?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)

	// IN : 3D data
	init(handTrackData: [[[VNRecognizedPoint?]]]) {
		handJoints = handTrackData
	}

	// IN : Json data (String)
	init?(jsonStr: String) {
		guard let jsonData = jsonStr.data(using: .utf8) else { return nil }
		if let newValue = try? JSONDecoder().decode([[[VNRecognizedPointFake?]]].self, from: jsonData) {
		} else {
			return nil
		}
	}
	
	// IN : Json data (Data)
	init?(json: Data) {
		if let newValue = try? JSONDecoder().decode([[[VNRecognizedPointFake?]]].self, from: json) {
			handJointsFake = newValue as [[[VNRecognizedPointFake?]]]
		} else {
			return nil
		}
	}
	
	// IN : Json data (Data)
	init?(points: [[[VNRecognizedPointFake?]]]) {
		handJointsFake = points
	}
	
	// OUT : Json data (String)
	var jsonStr: String {
		var jsonString = ""
		let encoder = JSONEncoder()
		
		if handJoints.count == 0 { return jsonString }
		
		do {
			var transData = HandTrackTransferData()
			transData.points = convertFake(handJoints)
			transData.zDepth = handTrackFake.zDepth
			let jsonData = try encoder.encode(transData)
			jsonString = String(data: jsonData, encoding: .utf8)!
		}
		catch {
		}
		
		return jsonString
	}
	
	// OUT : Json data (Data)
	var json: Data? {
		return try? JSONEncoder().encode(self)
	}
	
	// VNRecognizedPoint(read only) --> VNRecognizedPointFake(r/w)
	func convertFake(_ org: [[[VNRecognizedPoint?]]]) -> [[[VNRecognizedPointFake?]]]{
		var hj: [[[VNRecognizedPointFake?]]] =
			[
				[
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil]
				],
				[
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil]
				]
			]
		if org.count > 0 {
			for hand in 0...org.count-1 {	// right, left
				for finger in 0...5 {	// thumb, index, middle, ring, little, wrist
					for joint in 0...3 {	// tip, dip, pip, mcp (tip, intermediateTip, intermediateBase, knuckle)
						if finger == 5 && joint > 0 {
							continue
						}
						if let dt2D = org[hand][finger][joint] {
							let dtFake = VNRecognizedPointFake(identifier: dt2D.identifier.rawValue, confidence: dt2D.confidence, x: dt2D.x, y: dt2D.y, location: dt2D.location)
							hj[hand][finger][joint] = dtFake
						}
					}
				}
			}
		}
		return hj
	}
	
	init(from decoder: Decoder) throws {
	}
	
	func encode(to encoder: Encoder) throws {
	}
}

// MARK: HandTrackJson3D

struct HandTrackJson3D: Codable {
	
	typealias Scalar = Float

	var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	var rotateHands: Bool = false
	var offset3D:SIMD3<Scalar> = SIMD3(0.5, 0.0, -1.0)

	// IN : 3D data
	init(handTrackData: [[[SIMD3<Scalar>?]]]) {
		handJoints = handTrackData
	}
	
	// IN : 2D data (convert to 3D data)
	init(handTrackData2D: [[[VNRecognizedPoint?]]]) {
		for hand in 0...1 {	// right, left
			for finger in 0...5 {	// thumb, index, middle, ring, little, wrist
				for joint in 0...3 {	// tip, dip, pip, mcp (tip, intermediateTip, intermediateBase, knuckle)
					if finger == 5 && joint > 0 {
						continue
					}
					if let dt2D = handTrackData2D[hand][finger][joint] {
						handJoints[hand][finger][joint] = convertVNRecognizedPointToHandTrackingProvider(p: VNRecognizedPointFake(val: dt2D))
					}
				}
			}
		}
	}
	
	mutating func convert2Dto3D(handTrackData2D: [[[VNRecognizedPointFake?]]]) -> [[[SIMD3<Scalar>?]]] {
		var hj: [[[SIMD3<Scalar>?]]] =
			[
				[
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil]
				],
				[
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil,nil,nil,nil],
					[nil]
				]
			]
		
		guard handTrackData2D.count > 0 else { return [] }
		
		for hand in 0...1 {	// right, left
			for finger in 0...5 {	// thumb, index, middle, ring, little, wrist
				for joint in 0...3 {	// tip, dip, pip, mcp (tip, intermediateTip, intermediateBase, knuckle)
					if finger == 5 && joint > 0 {
						continue
					}
					if let dt2D = handTrackData2D[hand][finger][joint] {
						hj[hand][finger][joint] = convertVNRecognizedPointToHandTrackingProvider(p: dt2D)
					}
				}
			}
		}
		handJoints = []
		if hj[0][0][0] != nil {
			handJoints.append(hj[0])
		}
		if hj[1][0][0] != nil {
			handJoints.append(hj[1])
		}
		
		return handJoints
	}

	mutating func rotate3D(dt3D: [[[SIMD3<Scalar>?]]]) -> [[[SIMD3<Scalar>?]]] {
		let deg: Float = 0
		let rad: Float = Float.pi/180*deg
		let s: Float = sin(rad)
		let c: Float = cos(rad)
		let rotateX: simd_float3x3 =
			simd_float3x3(	simd_float3( 1, 0, 0),
							simd_float3( 0, c,-s),
							simd_float3( 0, s, c))
		let rotateY: simd_float3x3 =
			simd_float3x3(	simd_float3( c, 0, s),
							simd_float3( 0, 1, 0),
							simd_float3(-s, 0, c))
		let rotateZ: simd_float3x3 =
			simd_float3x3(	simd_float3( c,-s, 0),
							simd_float3( s, c, 0),
							simd_float3( 0, 0, 1))

		for hand in 0...1 {	// right, left
			if dt3D.count<=hand { continue }
			for finger in 0...5 {	// thumb, index, middle, ring, little, wrist
				for joint in 0...3 {	// tip, dip, pip, mcp (tip, intermediateTip, intermediateBase, knuckle)
					if finger == 5 && joint > 0 {
						continue
					}
					if let pos = dt3D[hand][finger][joint] {
						let rotatedVector = rotateZ * rotateY * pos
						let shiftedVector = shift3D(rotatedVector)
						handJoints[hand][finger][joint] = shiftedVector
					}
				}
			}
		}
		return handJoints
	}

	func setOffset3D(x:Float, y:Float, z:Float) {
		var offset3D:SIMD3<Scalar> = SIMD3(x: x, y: y, z: z)
	}
	
	func shift3D(_ pos: SIMD3<Scalar>) -> SIMD3<Scalar> {
		var offset3D:SIMD3<Scalar> = SIMD3(x: 0.5, y: 0.0, z: -0.8)
		return simd_float3(pos.x+offset3D.x, pos.y+offset3D.y, pos.z+offset3D.z)
	}

	// Convert VisionKit coordinate on iOS -> world coordinate on visionOS
	func convertVNRecognizedPointToHandTrackingProvider(p: VNRecognizedPointFake) -> SIMD3<Scalar> {
		var pp = p
		if rotateHands {
			pp.x = -pp.x
			pp.y = -pp.y
		}

		let y_shift:Double = 0.5
		pp.y += y_shift

		return SIMD3(x: Float(-pp.x), y: (Float(pp.y)), z: handTrackFake.zDepth)
	}

	// IN : Json data (String)
	init?(jsonStr: String, rotate: Bool = false) {
		rotateHands = rotate
		guard let jsonData = jsonStr.data(using: .utf8) else { return nil }
		do {
			let decoder = JSONDecoder()
			var transData:HandTrackTransferData = try decoder.decode(HandTrackTransferData.self, from: jsonData)
			handTrackFake.zDepth = transData.zDepth
			guard let dt2D = HandTrackJson2D(points: transData.points) else { return nil }
			guard dt2D.handJointsFake.count > 0 else { return }
			handJoints = convert2Dto3D(handTrackData2D: dt2D.handJointsFake)
			handJoints = rotate3D(dt3D: handJoints)
		} catch {
			
		}
	}

	// IN : Json data (Data)
	init?(json: Data) {
		if let newValue = try? JSONDecoder().decode(HandTrackJson3D.self, from: json) {
			self = newValue
		} else {
			return nil
		}
	}
	
	// OUT : Json data (String)
	var jsonStr: String {
		var jsonString = ""
		let encoder = JSONEncoder()
		//		encoder.outputFormatting = .prettyPrinted
		
		do {
			let jsonData = try encoder.encode(self)
			jsonString = String(data: jsonData, encoding: .utf8)!
		}
		catch {
		}
		
		return jsonString
	}
		
	// OUT : Json data (Data)
	var json: Data? {
		return try? JSONEncoder().encode(self)
	}
	
	init(from decoder: Decoder) throws {}
	func encode(to encoder: Encoder) throws {}
}

