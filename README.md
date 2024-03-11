# VisionGesture
 - Sample code of visionOS HandTracking on real device.
 - Virtual hands entities in immersive space.
 - Make your own spatial gesture!
 - If you don't have real VisionPro device, "[HandTrackFake](https://github.com/AlohaYos/VisionGesture/blob/main/README.md#handtrackfake)" will be a good debugging partner, because "[HandTrackFake](https://github.com/AlohaYos/VisionGesture/blob/main/README.md#handtrackfake)" provides handtracking feature which works on VisionPro simulator (see below).

## Play VisionGesture

(video coming soon)

## Make your own spatial gesture

Gesture template code is available.  
Search "TODO: MyGesture" in VisionGesture project on Xcode.  
Gestrue_Draw.swift and Gesture_Aloha.swift are the good example of how to make your own spatial gestures.

## HandTrackFake
Simulate hand tracking movements in order to debug hand tracking on visionOS simulator.  
You no longer need real VisionPro device to test your spatial gestures.
This module uses VNHumanHandPoseObservation on Mac to capture finger movement.  
And send that hand tracking data to visionOS simulator on Mac via bluetooth.  
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
 - Display hands (finger positions) on visionOS simulator display.

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

