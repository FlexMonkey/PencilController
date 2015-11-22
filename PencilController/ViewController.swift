//
//  ViewController.swift
//  PencilController
//
//  Created by Simon Gladman on 21/11/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController
{
    let label = UILabel()
    
    let halfPi = CGFloat(M_PI_2)
    let pi = CGFloat(M_PI)
    
    let ciContext = CIContext(EAGLContext: EAGLContext(API: EAGLRenderingAPI.OpenGLES2),
        options: [kCIContextWorkingColorSpace: NSNull()])

    let coreImage = CIImage(image: UIImage(named: "DSCF0786.jpg")!)!
    
    let imageView = UIImageView()
    
    let sceneKitView = SCNView()
    let scene = SCNScene()
    let cylinderNode = SCNNode(geometry: SCNCapsule(capRadius: 0.05, height: 1))
    let plane = SCNNode(geometry: SCNPlane(width: 20, height: 20))
    
    let hueAdjust = CIFilter(name: "CIHueAdjust")!
    let colorControls = CIFilter(name: "CIColorControls")!
    let gammaAdjust = CIFilter(name: "CIGammaAdjust")!
    let exposureAdjust = CIFilter(name: "CIExposureAdjust")!
    
    let hueSaturationButton = ChunkyButton(title: "Hue\nSaturation", filteringMode: .HueSaturation)
    let brightnessContrastButton = ChunkyButton(title: "Brightness\nContrast", filteringMode: .BrightnessContrast)
    let gammaExposureButton = ChunkyButton(title: "Gamma\nExposure", filteringMode: .GammaExposure)
    
    var hueAngle: CGFloat = 0
    var saturation: CGFloat = 1
    var brightness: CGFloat = 0
    var contrast: CGFloat = 1
    var gamma: CGFloat = 1
    var exposure: CGFloat = 0
    
    var pencilOn = false
    
    var filteringMode = FilteringMode.Off
    {
        didSet
        {
            label.hidden = filteringMode == .Off
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        
        view.addSubview(imageView)
        view.addSubview(label)
        view.addSubview(sceneKitView)
        
        view.addSubview(hueSaturationButton)
        view.addSubview(brightnessContrastButton)
        view.addSubview(gammaExposureButton)
       
        label.font = UIFont.monospacedDigitSystemFontOfSize(36, weight: UIFontWeightSemibold)
        
        label.textAlignment = NSTextAlignment.Center
        label.text = "flexmonkey.blogspot.co.uk"
        label.textColor = UIColor.whiteColor()
        label.hidden = true
        
        imageView.contentMode = UIViewContentMode.Center
        
        sceneKitView.scene = scene
        sceneKitView.backgroundColor = UIColor.clearColor()
        addLights()
        
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true

        camera.xFov = 45
        camera.yFov = 45
        
        let cameraNode = SCNNode()
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 20)
        
        cylinderNode.position = SCNVector3(0, 0, 0)
        cylinderNode.pivot = SCNMatrix4MakeTranslation(0, 0.5, 0)
        
        plane.opacity = 0.000001
        
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cylinderNode)
        scene.rootNode.addChildNode(plane)
        
        cylinderNode.opacity = 0
        
        applyFilter()
        
        hueSaturationButton.addTarget(self, action: "filterButtonTouchDown:", forControlEvents: UIControlEvents.TouchDown)
        hueSaturationButton.addTarget(self, action: "filterButtonTouchEnded:", forControlEvents: UIControlEvents.TouchUpInside)
        
        brightnessContrastButton.addTarget(self, action: "filterButtonTouchDown:", forControlEvents: UIControlEvents.TouchDown)
        brightnessContrastButton.addTarget(self, action: "filterButtonTouchEnded:", forControlEvents: UIControlEvents.TouchUpInside)
        
        gammaExposureButton.addTarget(self, action: "filterButtonTouchDown:", forControlEvents: UIControlEvents.TouchDown)
        gammaExposureButton.addTarget(self, action: "filterButtonTouchEnded:", forControlEvents: UIControlEvents.TouchUpInside)
    }

    func filterButtonTouchDown(button: ChunkyButton)
    {
        filteringMode = button.filteringMode
        
        updateLabel()
        
        if pencilOn
        {
            SCNTransaction.setAnimationDuration(0.25)
            cylinderNode.opacity = 1
        }
    }
    
    func filterButtonTouchEnded(button: ChunkyButton)
    {
        filteringMode = .Off
        
        SCNTransaction.setAnimationDuration(0.25)
        cylinderNode.opacity = 0
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where
            filteringMode != .Off &&
            touch.type == UITouchType.Stylus else
        {
            return
        }
        
        pencilOn = true
        
        pencilTouchHandler(touch)
        
        SCNTransaction.setAnimationDuration(0.25)
        cylinderNode.opacity = 1
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where
            filteringMode != .Off &&
            touch.type == UITouchType.Stylus else
        {
            return
        }
        
        pencilTouchHandler(touch)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard touches.first?.type == UITouchType.Stylus else
        {
            return
        }
        
        pencilOn = false
        SCNTransaction.setAnimationDuration(0.25)
        cylinderNode.opacity = 0
    }
    
    func pencilTouchHandler(touch: UITouch)
    {
        guard let hitTestResult:SCNHitTestResult = sceneKitView.hitTest(touch.locationInView(view), options: nil).filter( { $0.node == plane }).first else
        {
            return
        }
        
        SCNTransaction.setAnimationDuration(0)
        
        cylinderNode.position = SCNVector3(hitTestResult.localCoordinates.x, hitTestResult.localCoordinates.y, 0)
        cylinderNode.eulerAngles = SCNVector3(touch.altitudeAngle, 0.0, 0 - touch.azimuthAngleInView(view) - halfPi)
        
        switch filteringMode
        {
        case .HueSaturation:
            hueAngle = pi + touch.azimuthAngleInView(view)
            saturation = 8 * ((halfPi - touch.altitudeAngle) / halfPi)
            
        case .BrightnessContrast:
            brightness = touch.azimuthUnitVectorInView(view).dx * ((halfPi - touch.altitudeAngle) / halfPi)
            contrast = 1 + touch.azimuthUnitVectorInView(view).dy * -((halfPi - touch.altitudeAngle) / halfPi)

        case .GammaExposure:
            gamma = 1 + touch.azimuthUnitVectorInView(view).dx * ((halfPi - touch.altitudeAngle) / halfPi)
            exposure = touch.azimuthUnitVectorInView(view).dy * -((halfPi - touch.altitudeAngle) / halfPi)
            
        case .Off:
            ()
        }
        
        updateLabel()
        applyFilter()
    }


    
    func applyFilter()
    {
        hueAdjust.setValue(coreImage,
            forKey: kCIInputImageKey)
        hueAdjust.setValue(hueAngle,
            forKey: kCIInputAngleKey)
        
        colorControls.setValue(hueAdjust.valueForKey(kCIOutputImageKey) as! CIImage,
            forKey: kCIInputImageKey)
        colorControls.setValue(saturation,
            forKey: kCIInputSaturationKey)
        colorControls.setValue(brightness,
            forKey: kCIInputBrightnessKey)
        colorControls.setValue(contrast,
            forKey: kCIInputContrastKey)
        
        exposureAdjust.setValue(colorControls.valueForKey(kCIOutputImageKey) as! CIImage,
            forKey: kCIInputImageKey)
        exposureAdjust.setValue(exposure,
            forKey: kCIInputEVKey)
        
        gammaAdjust.setValue(exposureAdjust.valueForKey(kCIOutputImageKey) as! CIImage,
            forKey: kCIInputImageKey)
        gammaAdjust.setValue(gamma,
            forKey: "inputPower")

        
        let cgImage = ciContext.createCGImage(gammaAdjust.valueForKey(kCIOutputImageKey) as! CIImage,
            fromRect: coreImage.extent)
        
        imageView.image =  UIImage(CGImage: cgImage)
    }
    
    func updateLabel()
    {
        switch filteringMode
        {
        case .HueSaturation:
            label.text = String(format: "↻Hue: %.2f°", hueAngle * 180 / pi) + "      " +  String(format: "∢Saturation: %.2f", saturation)
            
        case .BrightnessContrast:
            label.text = String(format: "⇔Brightness: %.2f", brightness) + "      " +  String(format: "⇕Contrast: %.2f", contrast)

        case .GammaExposure:
            label.text = String(format: "⇔Gamma: %.2f", gamma) + "      " +  String(format: "⇕Exposure: %.2f", exposure)
            
        case .Off:
            ()
        }
    }
    
    func addLights()
    {
        // ambient light...
        
        let ambientLight = SCNLight()
        ambientLight.type = SCNLightTypeAmbient
        ambientLight.color = UIColor(white: 0.15, alpha: 1.0)
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        
        scene.rootNode.addChildNode(ambientLightNode)
        
        // omni light...
        
        let omniLight = SCNLight()
        omniLight.type = SCNLightTypeOmni
        omniLight.color = UIColor(white: 1.0, alpha: 1.0)
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: -10, y: 10, z: 30)
        
        scene.rootNode.addChildNode(omniLightNode)
    }
    
    override func viewDidLayoutSubviews()
    {
        label.frame = CGRect(x: 0,
            y: topLayoutGuide.length,
            width: view.frame.width,
            height: label.intrinsicContentSize().height)
        
        imageView.frame = view.bounds
        sceneKitView.frame = view.bounds
        
        // Slightly cobbled together layout :)
        
        hueSaturationButton.frame = CGRect(x: 0,
            y: view.frame.height - hueSaturationButton.intrinsicContentSize().height,
            width: hueSaturationButton.intrinsicContentSize().width,
            height: hueSaturationButton.intrinsicContentSize().height)
        
        brightnessContrastButton.frame = CGRect(x: hueSaturationButton.intrinsicContentSize().width + 20,
            y: view.frame.height - hueSaturationButton.intrinsicContentSize().height,
            width: hueSaturationButton.intrinsicContentSize().width,
            height: hueSaturationButton.intrinsicContentSize().height)
        
        gammaExposureButton.frame = CGRect(x: hueSaturationButton.intrinsicContentSize().width + 20 + hueSaturationButton.intrinsicContentSize().width + 20,
            y: view.frame.height - hueSaturationButton.intrinsicContentSize().height,
            width: hueSaturationButton.intrinsicContentSize().width,
            height: hueSaturationButton.intrinsicContentSize().height)
    }

}

enum FilteringMode
{
    case Off
    case HueSaturation
    case BrightnessContrast
    case GammaExposure
}

class ChunkyButton: UIButton
{
    let defaultColor = UIColor(red: 0.25, green: 0.25, blue: 0.75, alpha: 0.5)
    let highlightedColor = UIColor(red: 0.25, green: 0.25, blue: 0.75, alpha: 1)
    
    let filteringMode: FilteringMode
    
    required init(title: String, filteringMode: FilteringMode)
    {
        self.filteringMode = filteringMode
        
        super.init(frame: CGRectZero)
        
        titleLabel?.numberOfLines = 2
        setTitle(title, forState: UIControlState.Normal)
        titleLabel?.font = UIFont.boldSystemFontOfSize(24)
        
        backgroundColor = defaultColor
        setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.borderWidth = 2
        layer.cornerRadius = 5
    }
    
    override var highlighted: Bool
    {
        didSet
        {
            backgroundColor = highlighted ? highlightedColor : defaultColor
        }
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func intrinsicContentSize() -> CGSize
    {
        return CGSize(width: super.intrinsicContentSize().width + 20,
            height: super.intrinsicContentSize().height + 10)
    }
}

