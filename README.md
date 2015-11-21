# PencilController
##### Using Apple Pencil as a 3D Controller for Image Editing

#####_ Companion project to this blog post: http://flexmonkey.blogspot.co.uk/2015/11/pencilcontroller-using-apple-pencil-as.html_

Despite Jony Ive describing the Pencil as being designed for marking and not as a stylus finger replacement in Wallpaper*, I've decided to explore a few unconventional uses for mine. Yesterday saw a slightly ramshackle looking Pencil based electronic scale and today I'm using it as a joystick of sorts for controlling parameters on image filters.

My PencilController project is a Swift app for iPad Pro that applies two Core Image filters to an image: a hue adjustment and a colour controls which I use to control the saturation.

The Pencil's orientation in space is described by the Horizontal Coordinate System with azimuth and altitude angles.

The hue filter's value is controlled by the azimuth angle and the saturation is controlled by the altitude angle: when the pencil is vertical, the saturation is zero and when it's horizontal the saturation is eight (although when the pencil is totally horizontal, its tip isn't actually touching the screen, so the highest saturation the app can set is about six and three quarters).

To jazz up the user interface, I've also added a rounded cylinder using SceneKit which mirrors the Pencil's position and orientation.

## Controlling Core Image Filter Parameters with Pencil

Setting the values for the two Core Image filters is pretty simple stuff.  Both filters are declared as constants at the top of my view controller along with a Core Image context (without colour management for performance) and a Core Image image:

```swift
    let hueAdjust = CIFilter(name: "CIHueAdjust")!
    let colorControls = CIFilter(name: "CIColorControls")!

    let ciContext = CIContext(EAGLContext: EAGLContext(API: EAGLRenderingAPI.OpenGLES2),
        options: [kCIContextWorkingColorSpace: NSNull()])

    let coreImage = CIImage(image: UIImage(named: "DSCF0786.jpg")!)!
```

When the touch either starts or changes, I want to ensure it originates from a Pencil by checking its type and then invoke `applyFilter()` via `pencilTouchHandler()` method:

```swift
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where
            touch.type == UITouchType.Stylus else
        {
            return
        }
        
        pencilTouchHandler(touch)
    }
```

`pencilTouchHandler()` extracts the azimuth and altitude angles from the `UITouch`, does some simple arithmetic and passes those values to `applyFilter()`:

```swift
    applyFilter(hueAngle: pi + touch.azimuthAngleInView(view),
        saturation: 8 * ((halfPi - touch.altitudeAngle) / halfPi))
```

It's `applyFilter()` that uses those two values to set the parameters on the filters and display the output in a UIImageView:

```swift
    func applyFilter(hueAngle hueAngle: CGFloat, saturation: CGFloat)
    {
        hueAdjust.setValue(coreImage,
            forKey: kCIInputImageKey)
        hueAdjust.setValue(hueAngle,
            forKey: kCIInputAngleKey)
        
        colorControls.setValue(hueAdjust.valueForKey(kCIOutputImageKey) as! CIImage,
            forKey: kCIInputImageKey)
        colorControls.setValue(saturation,
            forKey: kCIInputSaturationKey)
        
        let cgImage = ciContext.createCGImage(colorControls.valueForKey(kCIOutputImageKey) as! CIImage,
            fromRect: coreImage.extent)
        
        imageView.image =  UIImage(CGImage: cgImage)
        
        label.text = String(format: "Hue: %.2f°", hueAngle * 180 / pi) + "      " +  String(format: "Saturation: %.2f", saturation)
    }
```

On my iPad Pro this filtering is fast enough on a near full screen image that I don't have to worry about doing this work in a background thread.

## Controlling SceneKit Geometry with Pencil

The next piece of work is to orient and position the "virtual pencil" so it mirrors the real one. I've overlaid a `SCNView` above the `UIImageView` and added a capsule geometry (which is a cylinder with rounded ends, not unlike a Pencil). Importantly, I've also added a flat plane which is used to capture the Pencil's location in the SceneKit 3D space:

```swift
    let sceneKitView = SCNView()
    let scene = SCNScene()
    let cylinderNode = SCNNode(geometry: SCNCapsule(capRadius: 0.05, height: 1))
    let plane = SCNNode(geometry: SCNPlane(width: 20, height: 20))

    // in init()
    sceneKitView.scene = scene
    scene.rootNode.addChildNode(cameraNode)
    scene.rootNode.addChildNode(cylinderNode)
    scene.rootNode.addChildNode(plane)
```

Inside the `pencilTouchHandler()`, I use the SceneKit view's `hitTest()` method to find the x and y positions of the Pencil on the screen in SceneKit's 3D space on the plane:

```swift
    func pencilTouchHandler(touch: UITouch)
    {
        guard let hitTestResult:SCNHitTestResult = sceneKitView.hitTest(touch.locationInView(view), options: nil)
            .filter( { $0.node == plane })
            .first else
        {
            return
        }
    [...]
```

...and with the results of that hit test, I can position the cylinder underneath the Pencil's touch location:

```swift
    [...]
    cylinderNode.position = SCNVector3(hitTestResult.localCoordinates.x,
        hitTestResult.localCoordinates.y, 
        0)
    [...]
```

Finally, with the altitude and azimuth angles of the touch, I can set the Euler angles of the cylinder to match the Pencil:

```swift
    [...]
    cylinderNode.eulerAngles = SCNVector3(touch.altitudeAngle, 
        0.0, 
        0 - touch.azimuthAngleInView(view) - halfPi)
    [...]
```

I've made the SceneKit camera orthographic, a perspective camera adds unwanted rotation to the "virtual pencil" as it moves across the screen. 

## Conclusion

Despite what Jony Ive may say, the Pencil offers some user interaction patterns impossible with a simple touch screen and I hope other developers start exploring new ideas. In addition to the two angles, the Pencil also has x and y coordinates and its force, so that's five different values that could potentially be used for controlling anything, from image filters to an audio synthesiser!

As always, the source code for this project is available at my GitHub repository here. Enjoy!
