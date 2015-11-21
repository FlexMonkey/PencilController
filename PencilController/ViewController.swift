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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        
        view.addSubview(imageView)
         view.addSubview(label)
        view.addSubview(sceneKitView)
       
        label.font = UIFont.monospacedDigitSystemFontOfSize(36, weight: 1)
        
        label.textAlignment = NSTextAlignment.Center
        label.text = "flexmonkey.blogspot.co.uk"
        label.textColor = UIColor.whiteColor()
        
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
        
        applyFilter(hueAngle: 0, saturation: 1)
    }

  
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where
            touch.type == UITouchType.Stylus else
        {
            return
        }
        
        pencilTouchHandler(touch)
        
        SCNTransaction.setAnimationDuration(0.25)
        cylinderNode.opacity = 1
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where
            touch.type == UITouchType.Stylus else
        {
            return
        }
        
        pencilTouchHandler(touch)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
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
        
        applyFilter(hueAngle: pi + touch.azimuthAngleInView(view),
            saturation: 8 * ((halfPi - touch.altitudeAngle) / halfPi))
    }

    func applyFilter(hueAngle hueAngle: CGFloat, saturation: CGFloat)
    {
        hueAdjust.setValue(coreImage, forKey: kCIInputImageKey)
        hueAdjust.setValue(hueAngle, forKey: kCIInputAngleKey)
        
        colorControls.setValue(hueAdjust.valueForKey(kCIOutputImageKey) as! CIImage, forKey: kCIInputImageKey)
        colorControls.setValue(saturation, forKey: kCIInputSaturationKey)
        
        let cgImage = self.ciContext.createCGImage(colorControls.valueForKey(kCIOutputImageKey) as! CIImage, fromRect: coreImage.extent)
        
        imageView.image =  UIImage(CGImage: cgImage)
        
        label.text = String(format: "Hue: %.2f°", hueAngle * 180 / pi) + "      " +  String(format: "Saturation: %.2f", saturation)
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
    }

}

