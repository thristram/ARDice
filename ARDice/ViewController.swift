//
//  ViewController.swift
//  ARDice
//
//  Created by Fangchen Li on 10/25/18.
//  Copyright © 2018 Fangchen Li. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var trackerNode: SCNNode!
    var diceNodes: [SCNNode] = []
    var numberOfDices: Int = 5
    
    
    var trackingPosition = SCNVector3Make(0.0, 0.0, 0.0)
    var started = false
    var foundSurface = false
    var resultShown:Bool = false
    
    
    struct pos {
        var x: Float
        var z: Float
    }
    var poss: [pos] = []
    var posIndex = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        self.sceneView.scene = scene
        self.sceneView.delegate = self
        self.sceneView.showsStatistics = true
        self.sceneView.scene.physicsWorld.gravity = SCNVector3Make(0, -0.2, 0)
        for i in [0,1,7,8]{
            let xFactor = -2 + Float(i) * 0.5
            for j in 0...4{
                let zFactor = -1 + Float(j) * 0.5
                self.poss.append(pos(x: xFactor, z: zFactor))
                
                
            }
        }
//        print(self.sceneView.scene.physicsWorld.gravity.y)
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sceneView.session.pause()
        
    }
    @IBAction func reInitWorld(_ sender: Any) {
        self.reInitaARSurface()
    }
    func ARDiceNumberInRange(number:Float, factor: Float) -> Bool{
        if(number >= (factor * .pi - .pi/4)) && (number < (factor * .pi + .pi/4)){
            return true
        }
        return false
    }
    func getARDiceNumber(eulerAngles: SCNVector3) -> Int{
        var xString = ""
        var zString = ""
        var fString = ""
        if self.ARDiceNumberInRange(number: eulerAngles.x, factor: -2){
            xString = "-2"
        }   else if self.ARDiceNumberInRange(number: eulerAngles.x, factor: -1.5){
            xString = "-1.5"
        }   else if self.ARDiceNumberInRange(number: eulerAngles.x, factor: -1){
            xString = "-1"
        }   else if self.ARDiceNumberInRange(number: eulerAngles.x, factor: -0.5){
            xString = "-0.5"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.x, factor: 0){
            xString = "0"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.x, factor: 0.5){
            xString = "0.5"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.x, factor: 1){
            xString = "1"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.x, factor: 1.5){
            xString = "1.5"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.x, factor: 2){
            xString = "2"
        } else  {
            print(eulerAngles.x)
            print(eulerAngles.x / .pi)
        }
        
        if self.ARDiceNumberInRange(number: eulerAngles.z, factor: -1){
            zString = "-1"
        }   else if self.ARDiceNumberInRange(number: eulerAngles.z, factor: -0.5){
            zString = "-0.5"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.z, factor: 0){
            zString = "0"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.z, factor: 0.5){
            zString = "0.5"
        }   else if  self.ARDiceNumberInRange(number: eulerAngles.z, factor: 1){
            zString = "1"
        }
        
        fString = xString + "," + zString
//        print(fString)
        
        switch fString {
        case "-1.5,-1", "-1.5,1","-0.5,0","0.5,-1","0.5,1", "1.5,0" :
            return 1
        case "-2,0.5", "-1.5,0.5", "-1,0.5", "-0.5,0.5", "0.5,0.5", "1,0.5", "0,0.5",  "1.5,0.5", "2,0.5":
            return 2
        case "-1.5,0", "-0.5,-1","-0.5,1","0.5,0", "1.5,-1", "1.5,1":
            return 3
        case "-2,-0.5","-1.5,-0.5","-1,-0.5","-0.5,-0.5","0,-0.5","0.5,-0.5","1,-0.5","1.5,-0.5","2,-0.5":
            return 4
        case "-2,0","-1,-1", "-1,1", "0,0", "1,-1", "1,1","2,0":
            return 5
        case "-2,-1","-2,1","-1,0", "0,-1", "0,1", "1,0","2,-1","2,1":
            return 6
        default:
            print(fString)
            return 0
        }
    }
    func rollARDice(dice: SCNNode){
        dice.physicsBody = nil
        if dice.physicsBody == nil {
            
            dice.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            dice.physicsBody?.applyForce(SCNVector3Make(0.06 - 0.001 * Float(arc4random_uniform(6)), -0.1, 0.06 - 0.001 * Float(arc4random_uniform(6))), asImpulse: true)
            dice.physicsBody?.applyTorque(SCNVector4Make(0.05 * Float(arc4random_uniform(6)), 0.01, 0.1, 0.07), asImpulse: true)
            dice.physicsBody?.mass = 90.9
            dice.physicsBody?.restitution = 0.01
            dice.physicsBody?.friction = 0.1
            dice.physicsBody?.rollingFriction = 0
            
        }
    }
    func reInitARSurface(){
        
        self.foundSurface = false
        self.started = false
        for (i,dice) in self.diceNodes.enumerated(){
            if i == 0{
                dice.isHidden = true
            }   else    {
                dice.removeFromParentNode()
            }
        }
        
    }
    func initAREnveroment(){
        if self.foundSurface{
            self.trackerNode.removeFromParentNode()
            self.started = true
            
            let scale: CGFloat = 0.4
            let floorPlane = SCNPlane(width: scale, height: scale)
            //                floorPlane.firstMaterial?.diffuse.contents = UIColor.gray
            floorPlane.firstMaterial?.diffuse.contents = UIColor.clear
            let floorNode = SCNNode(geometry: floorPlane)
            floorNode.position = self.trackingPosition
            floorNode.eulerAngles.x = -.pi * 0.5
            floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            floorNode.physicsBody?.restitution = 0
            floorNode.physicsBody?.friction = 1
            floorNode.physicsBody?.rollingFriction = 0
            self.sceneView.scene.rootNode.addChildNode(floorNode)
            
            
            
            
            let floorPlane_2 = SCNPlane(width: scale, height: scale)
            //                floorPlane_2.firstMaterial?.diffuse.contents = UIColor.green
            floorPlane_2.firstMaterial?.diffuse.contents = UIColor.clear
            let floorNode_2 = SCNNode(geometry: floorPlane)
            floorNode_2.position = SCNVector3Make(self.trackingPosition.x, self.trackingPosition.y  + Float(scale * 2), self.trackingPosition.z)
            floorNode_2.eulerAngles.x = .pi * 0.5
            floorNode_2.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            floorNode_2.physicsBody?.restitution = 0
            floorNode_2.physicsBody?.friction = 0.2
            self.sceneView.scene.rootNode.addChildNode(floorNode_2)
            
            let wallPlane_1 = SCNPlane(width: scale, height: scale * 4)
            //                wallPlane_1.firstMaterial?.diffuse.contents = UIColor.white
            wallPlane_1.firstMaterial?.diffuse.contents = UIColor.clear
            let wallNode_1 = SCNNode(geometry: wallPlane_1)
            wallNode_1.position = SCNVector3Make(self.trackingPosition.x, self.trackingPosition.y + Float(scale * 2), self.trackingPosition.z + Float(scale / 2))
            wallNode_1.eulerAngles.x = -.pi
            wallNode_1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wallNode_1.physicsBody?.restitution = 0.1
            wallNode_1.physicsBody?.friction = 0
            wallNode_1.physicsBody?.rollingFriction = 0
            self.sceneView.scene.rootNode.addChildNode(wallNode_1)
            
            
            let wallPlane_2 = SCNPlane(width: scale, height: scale * 4)
            //                wallPlane_2.firstMaterial?.diffuse.contents = UIColor.white
            wallPlane_2.firstMaterial?.diffuse.contents = UIColor.clear
            let wallNode_2 = SCNNode(geometry: wallPlane_2)
            wallNode_2.position = SCNVector3Make(self.trackingPosition.x, self.trackingPosition.y + Float(scale * 2), self.trackingPosition.z - Float(scale / 4))
            //                wallNode_2.eulerAngles.x = -.pi
            wallNode_2.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wallNode_2.physicsBody?.restitution = 0.1
            wallNode_2.physicsBody?.friction = 0
            wallNode_2.physicsBody?.rollingFriction = 0
            self.sceneView.scene.rootNode.addChildNode(wallNode_2)
            
            
            let wallPlane_3 = SCNPlane(width: scale, height: scale * 4)
            //                wallPlane_3.firstMaterial?.diffuse.contents = UIColor.red
            wallPlane_3.firstMaterial?.diffuse.contents = UIColor.clear
            let wallNode_3 = SCNNode(geometry: wallPlane_3)
            wallNode_3.position = SCNVector3Make(self.trackingPosition.x + Float(scale / 3), self.trackingPosition.y + Float(scale * 2), self.trackingPosition.z)
            wallNode_3.eulerAngles = SCNVector3Make(0, -.pi / 2, 0)
            wallNode_3.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wallNode_3.physicsBody?.restitution = 0.1
            wallNode_3.physicsBody?.friction = 0
            wallNode_3.physicsBody?.rollingFriction = 0
            self.sceneView.scene.rootNode.addChildNode(wallNode_3)
            
            
            let wallPlane_4 = SCNPlane(width: scale, height: scale * 4)
            //                wallPlane_4.firstMaterial?.diffuse.contents = UIColor.red
            wallPlane_4.firstMaterial?.diffuse.contents = UIColor.clear
            let wallNode_4 = SCNNode(geometry: wallPlane_4)
            wallNode_4.position = SCNVector3Make(self.trackingPosition.x - Float(scale / 3), self.trackingPosition.y + Float(scale * 2), self.trackingPosition.z)
            wallNode_4.eulerAngles = SCNVector3Make(0, .pi / 2, 0)
            wallNode_4.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            wallNode_4.physicsBody?.restitution = 0.1
            wallNode_4.physicsBody?.friction = 0
            wallNode_4.physicsBody?.rollingFriction = 0
            self.sceneView.scene.rootNode.addChildNode(wallNode_4)
        }
    }
    
    func initARDice(){
        
        
        if self.foundSurface{
            for (i, dice) in self.diceNodes.enumerated(){
                if i != 0{
                    dice.removeFromParentNode()
                }
                
            }
            
            guard let dice = self.sceneView.scene.rootNode.childNode(withName: "dice", recursively: false) else {
                return
            }
            
            self.diceNodes = []
            self.diceNodes.append(dice)
            self.diceNodes[0].position = SCNVector3Make(trackingPosition.x, trackingPosition.y + 0.3, trackingPosition.z)
            
            self.diceNodes[0].isHidden = false
            if self.numberOfDices > 1{
                for i in 1..<self.numberOfDices{
                    self.diceNodes.append(self.diceNodes[0].clone())
                    let offset = 0.3 + Float(i) * 0.025
                    self.diceNodes[i].position.y = trackingPosition.y + offset
                    self.diceNodes[i].eulerAngles = SCNVector3(0, 0, Float.pi / 2)
                    self.sceneView.scene.rootNode.addChildNode(self.diceNodes[i])
                }
            }
        }
        
    }
    func rollARDices(){
        if started{
            self.resultShown = false
            for diceNode in self.diceNodes{
                self.rollARDice(dice: diceNode)
            }
        }
    }
    func testRolling(){
        let position = self.poss[posIndex % 25]
        print("\(position.x),\(position.z)")
        self.diceNodes[0].eulerAngles = SCNVector3(position.x * .pi, 0, position.z * .pi)
        posIndex += 1
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.started{
            self.initARDice()
            self.rollARDices()
//            self.testRolling()
        }   else    {
            self.initAREnveroment()
//            self.initARDice()
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if started{
            if self.diceNodes.count > 0{
                for dice in self.diceNodes{
                    guard dice.physicsBody != nil else {
                        return
                    }
                    guard dice.physicsBody!.isResting else {
                        return
                    }
                    
                }
                if !resultShown{
                    var result: [Int] = []
                    for dice in self.diceNodes{
                        result.append(self.getARDiceNumber(eulerAngles: dice.presentation.eulerAngles))
                    }
                    print(result)
                    self.resultShown = true
                }
            
                
                
                
            }
        }
        
        guard !self.started else {
            return
        }
        
        DispatchQueue.main.async {
            guard let hitTest = self.sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: [.existingPlane, .featurePoint, .estimatedHorizontalPlane]).first else {
                return
            }
            let trans = SCNMatrix4(hitTest.worldTransform)
            self.trackingPosition = SCNVector3Make(trans.m41, trans.m42, trans.m43)
            
            if !self.foundSurface{
                let trackerPlane = SCNPlane(width: 0.2, height: 0.2)
                
                trackerPlane.firstMaterial?.diffuse.contents = UIImage(named: "tracker")
                trackerPlane.firstMaterial?.isDoubleSided = true
                
                self.trackerNode = SCNNode(geometry: trackerPlane)
                self.trackerNode.eulerAngles.x = -.pi/2
                self.sceneView.scene.rootNode.addChildNode(self.trackerNode)
                self.foundSurface = true
            }
            
            self.trackerNode.position = self.trackingPosition
        }
        
        
       
        
        
        
    }


}

