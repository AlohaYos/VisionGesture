# VisionGesture
 - Sample code of visionOS HandTracking on real device.
 - Virtual hands entities in immersive space.
 - Make your own spatial gesture!
 - If you don't have real VisionPro device, "[HandTrackFake](https://github.com/AlohaYos/VisionGesture/blob/main/README.md#handtrackfake)" will be a good debugging partner, because "[HandTrackFake](https://github.com/AlohaYos/VisionGesture/blob/main/README.md#handtrackfake)" provides handtracking feature which works on VisionPro simulator.

## VisionGesture Playground
You can do this with VisionGesture. Play and create your own gestures!

https://github.com/AlohaYos/VisionGesture/assets/4338056/0c0584e4-c021-4af2-a1b5-b2d7d392f498

## Make your own spatial gesture

Gesture template code is available.  
Search "TODO: MyGesture" in VisionGesture project on Xcode.  
Gestrue_Draw.swift and Gesture_Aloha.swift are the good example of how to make your own spatial gestures.

### Create the gesture logic in [Gesture_MyGesture.swift](https://github.com/AlohaYos/VisionGesture/blob/main/VisionGesture/VisionGesture/Gesture/Gesture_MyGesture.swift).
- Calculate the positional relationship of finger joints.  
- When the hand make a specific pose, it means the gesture has started.  
- While the gesture is valid, the hand position is used to perform gesture-delegate job.  
- When the hand make another specific pose, it means the gesture has ended.  

```swift
class Gesture_MyGesture: GestureBase
{
	override init() {
		super.init()
	}

	convenience init(delegate: Any) {
		self.init()
		self.delegate = delegate as? any GestureDelegate
	}

	// Gesture judging loop
	override func checkGesture(handJoints: [[[SIMD3<Scalar>?]]]) {
		self.handJoints = handJoints
		switch state {
		case .unknown:	// initial state. waiting for first gesture pose
			// TODO: MyGesture: wait for my gesture to start
			if(isMyGesturePose()) {
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Began, location: [CGPointZero]))
				state = State.waitForRelease
			}
			break
		case .waitForRelease:	// do something while in gesture. wait for release of first pose

			// TODO: MyGesture: do something while in gesture
			let position:SIMD3<Float> = [0,0,0]
			delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Moved3D, location: [position]))

			if(!isMyGesturePose()) {	// wait until pose released
				delegate?.gesture(gesture: self, event: GestureDelegateEvent(type: .Ended, location: [CGPointZero]))
				state = State.unknown
			}
			break
		default:
			break
		}
	}
	
	// TODO: MyGesture: Check the position of the finger joints in space to determine if it is a new gesture
	func isMyGesturePose() -> Bool {
		if HandTrackProcess.handJoints.count > 0 {
			let check = 0
			// joint compare function available in "GestureBase.swift"
//			if isStraight(hand: .right, finger: .thumb){ check += 1 }
//			if isBend(hand: .right, finger: .index){ check += 1 }
//			if isBend(hand: .right, finger: .middle){ check += 1 }
//			if isBend(hand: .right, finger: .ring){ check += 1 }
//			if isStraight(hand: .right, finger: .little){ check += 1 }
			if check == 5 { return true }
		}
		return false
	}
}
```

### Use GestureDelegate(in [ImmersiveView.swift](https://github.com/AlohaYos/VisionGesture/blob/main/VisionGesture/VisionGesture/ImmersiveView.swift)) to create application-specific jobs using gestures.
- GestureDelegate will be called back when Gesture_MyGesture.swift judge specific gestures.  
- Spatial coordinates will be passed to the delegate job.  

```swift
	// TODO: MyGesture: make gesture logic
	func handle_myGesture(event: GestureDelegateEvent) {
		switch event.type {
		case .Moved3D:
			if let pnt = event.location[0] as? SIMD3<Scalar> {
				// pnt ... gesture location in immersive space
			}
		case .Fired:
			break
		case .Moved2D:
			break
		case .Began:
			break
		case .Ended:
			break
		case .Canceled:
			break
		default:
			break
		}
	}
```

### In [GestureBase.swift](https://github.com/AlohaYos/VisionGesture/blob/main/VisionGesture/VisionGesture/Gesture/GestureBase.swift), create a function that becomes the basis for determining gestures.
- Some functions are already provided.  
- To calculate finger joint positions that cannot be determined using existing functions, a new calculation function is required.
- Please look at the sample code to understand how to compare coordinate positions of joints.  

```swift
class GestureBase {
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
}
```

## HandTrackFake
Simulate hand tracking movements in order to debug hand tracking on VisionPro simulator.  
You no longer need real VisionPro device to test your spatial gestures.
This module uses VNHumanHandPoseObservation on Mac to capture finger movement.  
And send that hand tracking data to VisionPro simulator on Mac via bluetooth.  
All you need is Mac (additionally iPhone/iPad as TrackingSender) to debug visionOS hand tracking.  

### HandTrackFake module
HandTrackFake.swift
```swift
// Public properties
var enableFake = true // false:use VisionPro real handtracking.  true:use fake handtracking on Mac
```

### Sample project
#### FakeTrackingSender
 - Capture your hand movement using front camera of Mac (or iPhone/iPad) .
 - Encode hand tracking data (2D) into Json.
 - Send that Json to VisionGesture.app via bluetooth.

https://github.com/AlohaYos/ProjectJarvis/assets/4338056/9ba03b68-99d9-46c4-87be-5b2338081ef4

AppDelegate.swift
```swift
let handTrackFake = HandTrackFake()
```

HandTrackingProvider.swift
```swift
// Activate fake data sender
handTrackFake.initAsAdvertiser()

// Send fake data
handTrackFake.sendHandTrackData(handJoints2D)
```

Info.plist
```
Privacy - Camera Usage Description
Privacy - Local Network Usage Description  
Bonjour services  
 - item 0 : _HandTrackFake._tcp  
 - item 1 : _HandTrackFake._udp  
```

#### VisionGesture (receiver of fake handtracking data)
 - Receive hand tracking data (Json) from FakeTrackingSender.app via bluetooth.
 - Decode Json data into hand tracking data (3D).
 - Display hands (finger positions) on VisionPro simulator display.

https://github.com/AlohaYos/ProjectJarvis/assets/4338056/d6497d50-848b-4ca9-bb9f-bf70078778aa

TrackingReceiverApp.swift
```swift
let handTrackFake = HandTrackFake()
```

ImmersiveView.swift
```swift
// Activate fake data browser
if handTrackFake.enableFake == true {
    handTrackFake.initAsBrowser()
}

// Check connection status
let nowState = handTrackFake.sessionState
```

HandTrackProcess.swift
```swift
// Receive 2D-->3D converted hand tracking data
let handJoint3D = handTrackFake.receiveHandTrackData()
```

Info.plist
```
Privacy - Local Network Usage Description  
Bonjour services  
 - item 0 : _HandTrackFake._tcp  
 - item 1 : _HandTrackFake._udp  
```

