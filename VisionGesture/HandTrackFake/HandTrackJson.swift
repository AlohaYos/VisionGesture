//
//  HandTrackJson.swift
//  HandGesture
//
//  Created by Yos Hashimoto on 2023/08/27.
//  Copyright © 2023 Apple. All rights reserved.
//

import CoreGraphics
import UIKit
import Vision

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
//			handJointsFake = newValue
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
	
	// OUT : Json data (String)
	var jsonStr: String {
		var jsonString = ""
		let encoder = JSONEncoder()
		
		if handJoints.count == 0 { return jsonString }
		
		do {
			let jsonData = try encoder.encode(convertFake(handJoints))
//			let jsonData = try encoder.encode(handJoints)
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
							var dtFake = VNRecognizedPointFake(identifier: dt2D.identifier.rawValue, confidence: dt2D.confidence, x: dt2D.x, y: dt2D.y, location: dt2D.location)
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
						handJoints[hand][finger][joint] = SIMD3(x: Float(dt2D.x), y: Float(dt2D.y), z: 0.0)
					}
				}
			}
		}
	}
	
	mutating func convert2Dto3D(handTrackData2D: [[[VNRecognizedPointFake?]]]) {
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
		
		guard handTrackData2D.count > 0 else { return }
		
		for hand in 0...1 {	// right, left
			for finger in 0...5 {	// thumb, index, middle, ring, little, wrist
				for joint in 0...3 {	// tip, dip, pip, mcp (tip, intermediateTip, intermediateBase, knuckle)
					if finger == 5 && joint > 0 {
						continue
					}
					if let dt2D = handTrackData2D[hand][finger][joint] {
						hj[hand][finger][joint] = convertVNRecognizedPointToHandTrackingProvider(p: dt2D)
//						hj[hand][finger][joint] = SIMD3(x: Float(dt2D.x), y: Float(dt2D.y), z: 0.0)
					}
				}
			}
		}
		handJoints = hj
		
		handJoints = []
		if hj[0][0][0] != nil {
			handJoints.append(hj[0])
		}
		if hj[1][0][0] != nil {
			handJoints.append(hj[1])
		}
	}

	// iOSのVisionKit座標からvisionOSのワールド座標への変換
	func convertVNRecognizedPointToHandTrackingProvider(p: VNRecognizedPointFake) -> SIMD3<Scalar> {
		return SIMD3(x: Float(p.x-0.7), y: -(Float(p.y)-2.5), z: Float(-2.0))
//		return SIMD3(x: Float(p.x), y: Float(p.y), z: Float(0.0))
	}
	

	// IN : Json data (String)
	init?(jsonStr: String) {
		guard let jsonData = jsonStr.data(using: .utf8) else { return nil }
		guard let dt2D = HandTrackJson2D(json: jsonData) else { return nil }
		guard dt2D.handJointsFake.count > 0 else { return }
		
		convert2Dto3D(handTrackData2D: dt2D.handJointsFake)
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

