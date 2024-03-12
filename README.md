# VisionGesture
 - Sample code of visionOS HandTracking on real device.
 - Virtual hands entities in immersive space.
 - Make your own spatial gesture!
 - If you don't have real VisionPro device, "[HandTrackFake](https://github.com/AlohaYos/VisionGesture/blob/main/README.md#handtrackfake)" will be a good debugging partner, because "[HandTrackFake](https://github.com/AlohaYos/VisionGesture/blob/main/README.md#handtrackfake)" provides handtracking feature which works on VisionPro simulator.

## Play VisionGesture
You can do this with VisionGesture!

https://github.com/AlohaYos/VisionGesture/assets/4338056/0c0584e4-c021-4af2-a1b5-b2d7d392f498

## Make your own spatial gesture

Gesture template code is available.  
Search "TODO: MyGesture" in VisionGesture project on Xcode.  
Gestrue_Draw.swift and Gesture_Aloha.swift are the good example of how to make your own spatial gestures.

### Create the gesture logic in [Gesture_MyGesture.swift](https://github.com/AlohaYos/VisionGesture/blob/main/VisionGesture/VisionGesture/Gesture/Gesture_MyGesture.swift).
・Calculate the positional relationship of finger joints.  
・When the hand make a specific pose, it means the gesture has started.  
・While the gesture is valid, the hand position is used to perform gesture-delegate job.  
・When the hand make another specific pose, it means the gesture has ended.  

![01](https://github.com/AlohaYos/VisionGesture/assets/4338056/7b862de3-7fee-45aa-a4c2-21cbbea8c72c)

### Use GestureDelegate(in [ImmersiveView.swift](https://github.com/AlohaYos/VisionGesture/blob/main/VisionGesture/VisionGesture/ImmersiveView.swift)) to create application-specific jobs using gestures.
- GestureDelegate will be called back when Gesture_MyGesture.swift judge specific gestures.  
- Spatial coordinates will be passed to the delegate job.  

![03](https://github.com/AlohaYos/VisionGesture/assets/4338056/d39feeef-d6a6-48fc-93b1-4a60f3b18d93)

### In [GestureBase.swift](https://github.com/AlohaYos/VisionGesture/blob/main/VisionGesture/VisionGesture/Gesture/GestureBase.swift), create a function that becomes the basis for determining gestures.
- Some functions are already provided.  
- To calculate finger joint positions that cannot be determined using existing functions, a new calculation function is required.

![02](https://github.com/AlohaYos/VisionGesture/assets/4338056/92f03ea1-df86-4f9e-86e8-a16ac68789f8)

- Please look at the sample code to understand how to compare coordinate positions of joints.  

![04](https://github.com/AlohaYos/VisionGesture/assets/4338056/b65d7079-dc50-4906-9087-6731aebf00c5)

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

