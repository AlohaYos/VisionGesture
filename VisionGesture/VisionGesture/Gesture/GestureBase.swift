//
//  GestureHandler.swift
//    Base class for gesture detection
//
//  Copyright © 2023 Yos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import Vision
import ARKit

// MARK: HandGestureDelegate (gesture callback)

class GestureDelegateEvent {
	enum EventType: Int {
		case unknown = 0
		case Began
		case Moved2D
		case Moved3D
		case Moved4D
		case Ended
		case Canceled
		case Fired
	}
	
	static var uniqueID: Int = 1
	var id: Int
	var timestamp: TimeInterval
	var type: EventType
	var triggerType: Int
	var location: [Any]
	
	init() {
		self.id = GestureDelegateEvent.uniqueID
		self.timestamp  = NSDate().timeIntervalSince1970
		self.type = .unknown
		self.triggerType = -1
		self.location = []
		GestureDelegateEvent.uniqueID += 1
	}

	init(type: EventType, location: [Any]) {
		self.id = GestureDelegateEvent.uniqueID
		self.timestamp  = NSDate().timeIntervalSince1970
		self.type = type
		self.triggerType = -1
		self.location = location as [Any]
		GestureDelegateEvent.uniqueID += 1
	}
	
	init(type: EventType, trigger: Int) {
		self.id = GestureDelegateEvent.uniqueID
		self.timestamp  = NSDate().timeIntervalSince1970
		self.type = type
		self.triggerType = trigger
		self.location = []
		GestureDelegateEvent.uniqueID += 1
	}
}

protocol GestureDelegate {
	func gesture(gesture: GestureBase, event: GestureDelegateEvent);
}

extension GestureDelegate {
	func gesture(gesture: GestureBase, event: GestureDelegateEvent) {}
}

// MARK: GestureHandler (Base class of any Gesture)

class GestureBase {

	typealias Scalar = Float

// MARK: enum

	enum State {
		case unknown
		case possible
		case detected
		case waitForNextPose
		case waitForRelease
	}

// MARK: propaties

	var delegate: GestureDelegate?
	var defaultHand = HandTrackProcess.WhichHand.right
	var state = State.unknown
	var handJoints: [[[SIMD3<Scalar>?]]] = []			// array of fingers of both hand (0:right hand, 1:left hand)
	private var fingerJoints: [[SIMD3<Scalar>?]] = []			// array of finger joint position (VisionKit coordinates) --> FINGER_JOINTS
	
	init() {
		state = .unknown
	}

	convenience init(delegate: any View) {
		self.init()
		self.delegate = (delegate as! any GestureDelegate)
	}
	
	// MARK: Gesture analisys

	func checkGesture(handJoints: [[[SIMD3<Scalar>?]]]) {
	}

	// MARK: Compare joint positions

	func cv2(_ pos: SIMD3<Scalar>?) -> CGPoint? {
		guard let p = pos else { return CGPointZero }
		return CGPointMake(CGFloat(p.x),CGFloat(p.y))
	}
	
	// is finger bend or outstretched
	func isBend(pos1: CGPoint?, pos2: CGPoint?, pos3: CGPoint? ) -> Bool {
		guard let p1 = pos1, let p2 = pos2, let p3 = pos3 else { return false }
		if p1.distance(from: p2) > p1.distance(from: p3) { return true }
		return false
	}
	func isBend(hand: HandTrackProcess.WhichHand, finger: HandTrackProcess.WhichFinger) -> Bool {
		let posTip: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .tip))
		let pos2nd: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .pip))
		let posWrist: CGPoint? = cv2(jointPosition(hand:hand, finger:.wrist, joint: .tip))
		guard let posTip, let pos2nd, let posWrist else { return false }

		if posWrist.distance(from: pos2nd) > posWrist.distance(from: posTip) { return true }
		return false
	}
	func isStraight(pos1: CGPoint?, pos2: CGPoint?, pos3: CGPoint? ) -> Bool {
		guard let p1 = pos1, let p2 = pos2, let p3 = pos3 else { return false }
		if p1.distance(from: p2) < p1.distance(from: p3) { return true }
		return false
	}
	func isStraight(hand: HandTrackProcess.WhichHand, finger: HandTrackProcess.WhichFinger) -> Bool {
		let posTip: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .tip))
		let pos2nd: CGPoint? = cv2(jointPosition(hand:hand, finger:finger, joint: .pip))
		let posWrist: CGPoint? = cv2(jointPosition(hand:hand, finger:.wrist, joint: .tip))
		guard let posTip, let pos2nd, let posWrist else { return false }

		if posWrist.distance(from: pos2nd) < posWrist.distance(from: posTip) { return true }
		return false
	}

	// is two joints near?
	func isNear(pos1: CGPoint?, pos2: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos1, let p2 = pos2 else { return false }
		if p1.distance(from: p2) < value { return true }
		return false
	}
	func isNear(pos1: SIMD3<Float>?, pos2: SIMD3<Float>?, value: Float) -> Bool {
		guard let p1:SIMD3<Float> = pos1, let p2:SIMD3<Float> = pos2 else { return false }
		if distance(p1, p2) < value { return true }
		return false
	}
	// is two joints far enough?
	func isFar(pos1: CGPoint?, pos2: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos1, let p2 = pos2 else { return false }
		if p1.distance(from: p2) > value { return true }
		return false
	}
	
	// is the joint upper than another?
	func isPoint(_ pos: CGPoint?, upperThan: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos, let p2 = upperThan else { return false }
		if (p1 - p2).y < value { return true }
		return false
	}
	// is the joint lower than another?
	func isPoint(_ pos: CGPoint?, lowerThan: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos, let p2 = lowerThan else { return false }
		if (p1 - p2).y > value { return true }
		return false
	}
	// is the joint right of another?
	func isPoint(_ pos: CGPoint?, rightOf: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos, let p2 = rightOf else { return false }
		if (p1 - p2).x > value { return true }
		return false
	}
	// is the joint left of another?
	func isPoint(_ pos: CGPoint?, leftOf: CGPoint?, value: Double) -> Bool {
		guard let p1 = pos, let p2 = leftOf else { return false }
		if (p1 - p2).x < value { return true }
		return false
	}

	// pointing ?
	let compareMultiply = 5.0
	func isPointingUp(hand:HandTrackProcess.WhichHand, finger:HandTrackProcess.WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dy > 0) && (fabs(vector.dy) > fabs(vector.dx)*compareMultiply) {
			return true
		}
		return false
	}
	func isPointingDown(hand:HandTrackProcess.WhichHand, finger:HandTrackProcess.WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dy < 0) && (fabs(vector.dy) > fabs(vector.dx)*compareMultiply) {
			return true
		}
		return false
	}
	func isPointingRight(hand:HandTrackProcess.WhichHand, finger:HandTrackProcess.WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dx > 0) && (fabs(vector.dx) > fabs(vector.dy)*compareMultiply) {
			return true
		}
		return false
	}
	func isPointingLeft(hand:HandTrackProcess.WhichHand, finger:HandTrackProcess.WhichFinger) -> Bool {
		let vector = calcPointingXY(hand: hand, finger: finger)
		if (vector.dx < 0) && (fabs(vector.dx) > fabs(vector.dy)*compareMultiply) {
			return true
		}
		return false
	}
	func calcPointingXY(hand:HandTrackProcess.WhichHand, finger:HandTrackProcess.WhichFinger) -> CGVector {
		let tip   = cv2(jointPosition(hand:hand, finger:finger, joint: .tip))
		let mcp   = cv2(jointPosition(hand:hand, finger:finger, joint: .mcp))
		guard let p1 = tip, let p2 = mcp else { return CGVectorMake(0, 0) }
		return CGVectorMake((p1-p2).x, (p1-p2).y)
	}
	
	// get joint position
	func jointPosition(hand: [[SIMD3<Scalar>?]], finger: Int, joint: Int) -> SIMD3<Scalar>? {
		if finger==HandTrackProcess.WhichFinger.wrist.rawValue {
			return hand[finger][HandTrackProcess.wristJointIndex]
		}
		else {
			return hand[finger][joint]
		}
	}
	func jointPosition(hand: HandTrackProcess.WhichHand, finger: HandTrackProcess.WhichFinger, joint: HandTrackProcess.WhichJoint) -> SIMD3<Scalar>? {
		
		var jnt = joint.rawValue
		if finger == .wrist { jnt = HandTrackProcess.wristJointIndex }

		switch handJoints.count {
		case 1:
			let hd = handJoints[HandTrackProcess.WhichHand.right.rawValue]
			if hd.count==0 { return nil }
			return jointPosition(hand:hd, finger:finger.rawValue, joint:jnt)
		case 2:
			let hd = handJoints[hand.rawValue]
			if hd.count==0 { return nil }
			return jointPosition(hand:hd, finger:finger.rawValue, joint:jnt)
		default:
			return nil
		}
	}

	func triangleCenter(joint1:SIMD3<Scalar>?, joint2:SIMD3<Scalar>?, joint3:SIMD3<Scalar>?) -> SIMD3<Scalar>? {
		guard
			let j1 = joint1,
			let j2 = joint2,
			let j3 = joint3
		else {
			return nil
		}
		
		// center of triangle
		let h1 = (j1+j2) / 2	// half point of j1 & j2
		let ct = (h1+j3) / 2	// center point (half point of h1 & j3)
		
		return SIMD3(ct.x, ct.y, ct.z)
	}
	
	func triangleCenterWithAxis(joint1:SIMD3<Scalar>?, joint2:SIMD3<Scalar>?, joint3:SIMD3<Scalar>?) -> simd_float4x4? {
		guard
			let j1 = joint1,
			let j2 = joint2,
			let j3 = joint3
		else {
			return nil
		}
		
		let h1 = (j1+j2) / 2	// half point of j1 & j2
		let ct = (h1+j3) / 2	// center point (half point of h1 & j3)

		let xAxis = normalize(j2 - j1)
		let yAxis = normalize(j3 - h1)
		let zAxis = normalize(cross(xAxis, yAxis))

		let triangleCenterWorldTransform = simd_matrix(
			SIMD4(xAxis.x, xAxis.y, xAxis.z, 0),
			SIMD4(yAxis.x, yAxis.y, yAxis.z, 0),
			SIMD4(zAxis.x, zAxis.y, zAxis.z, 0),
			SIMD4(ct.x, ct.y, ct.z, 1)
		)
		return triangleCenterWorldTransform
	}
}

// MARK: Extensions

extension SIMD4 {
	var _xyz: SIMD3<Scalar> {
		self[SIMD3(0, 1, 2)]
	}
}

extension CGPoint {
	public var length: CGFloat {
		return hypot(x, y)
	}

	public func distance(from point: CGPoint) -> CGFloat {
		return (self - point).length
	}

	public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}
}
