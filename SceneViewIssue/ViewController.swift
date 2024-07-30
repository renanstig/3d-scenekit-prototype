//
//  ViewController.swift
//  SceneViewIssue
//
//  Created by Renan Camaforte on 25.07.24.
//

import UIKit
import ARKit
import RoomPlan

class ViewController: UIViewController {
    
    @IBOutlet private weak var sceneView: SCNView!
    var finalRoom: CapturedRoom?
    var roomsArray: [CapturedRoom] = []
    private let structureBuilder = StructureBuilder(options: [.beautifyObjects])
    private var surfaces: [CapturedRoom.Surface] = []
    private var doors: [CapturedRoom.Surface] = []
    private var windows: [CapturedRoom.Surface] = []
    private var openings: [CapturedRoom.Surface] = []
    private var floor: [CapturedRoom.Surface] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        startTestSession()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        // Do any additional setup after loading the view.
    }
    
    private func loadCapturedRoom(from url: URL) throws -> CapturedRoom? {
        let jsonData = try? Data(contentsOf: url)
        guard let data = jsonData else { return nil }
        let capturedRoom = try? JSONDecoder().decode(CapturedRoom.self, from: data)
        return capturedRoom
    }
    
    func startTestSession() {
        guard let filePath = Bundle.main.path(forResource: "capturedRoom", ofType: "json") else {
            print("USDZ file not found")
            return
        }
        
        if let captureRoom = try? loadCapturedRoom(from: URL(fileURLWithPath: filePath)) {
            roomsArray.append(captureRoom)
            Task {[weak self] in
                guard let `self` = self else { return }
                do {
                    let capturedStructure = try await structureBuilder.capturedStructure(from: roomsArray)
                    self.surfaces = capturedStructure.walls
                    self.doors = capturedStructure.doors
                    self.windows = capturedStructure.windows
                    self.openings = capturedStructure.openings
                    self.floor = capturedStructure.floors
                    let scene = SCNScene()
                    let roomNode = convertCapturedRoomToSCNNode()
                    scene.rootNode.addChildNode(roomNode)
                    
                    scene.background.contents = UIColor.black

                    sceneView.scene = scene
                } catch {
                    return
                }
            }
        }
    }
    
    func convertCapturedRoomToSCNNode() -> SCNNode {
        let rootNode = SCNNode()
        
        for floor in self.floor {
            let spaceNode = SCNNode()
            let spaceGeometry = SCNBox(width: CGFloat(floor.dimensions.x),
                                       height: CGFloat(floor.dimensions.y),
                                       length: CGFloat(0.01),
                                       chamferRadius: 0)
                                
            spaceNode.geometry = spaceGeometry
            spaceNode.simdTransform = floor.transform
            spaceNode.geometry?.materials.first?.diffuse.contents = UIImage(named: "floor-texture.jpg")
            spaceNode.name = "Space \(floor.category)"
            spaceNode.name = floor.identifier.uuidString
            rootNode.addChildNode(spaceNode)
        }
        
        for space in self.surfaces {
            let spaceNode = SCNNode()
            let spaceGeometry = SCNBox(width: CGFloat(space.dimensions.x),
                                       height: CGFloat(space.dimensions.y),
                                       length: CGFloat(0.01),
                                       chamferRadius: 0)

            spaceNode.geometry = spaceGeometry
            spaceNode.simdTransform = space.transform

            let wallMaterial = SCNMaterial()
            wallMaterial.diffuse.contents = UIColor.gray

            spaceNode.geometry?.materials = [wallMaterial]
            spaceNode.name = "Space \(space.category)"
            spaceNode.name = space.identifier.uuidString
            rootNode.addChildNode(spaceNode)
        }
        
        for door in self.doors {
            let spaceNode = SCNNode()
            let spaceGeometry = SCNBox(width: CGFloat(door.dimensions.x),
                                       height: CGFloat(door.dimensions.y),
                                       length: CGFloat(0.02),
                                       chamferRadius: 0)
                                
            spaceNode.geometry = spaceGeometry
            spaceNode.simdTransform = door.transform
            spaceNode.geometry?.materials.first?.diffuse.contents = UIImage(named: "door-texture.jpg")
            spaceNode.name = door.identifier.uuidString
            rootNode.addChildNode(spaceNode)
        }
        
        for opening in self.openings {
            let spaceNode = SCNNode()
            let spaceGeometry = SCNBox(width: CGFloat(opening.dimensions.x),
                                       height: CGFloat(opening.dimensions.y),
                                       length: CGFloat(0.02),
                                       chamferRadius: 0)

            spaceNode.geometry = spaceGeometry
            spaceNode.simdTransform = opening.transform
            spaceNode.name = opening.identifier.uuidString
            spaceNode.geometry?.materials.first?.diffuse.contents = UIColor.black
            spaceNode.name = "Space \(opening.category)"
            rootNode.addChildNode(spaceNode)
            
        }
        
        for window in windows {
            let spaceNode = SCNNode()
            let spaceGeometry = SCNBox(width: CGFloat(window.dimensions.x),
                                       height: CGFloat(window.dimensions.y),
                                       length: CGFloat(0.03),
                                       chamferRadius: 0)

            spaceNode.geometry = spaceGeometry
            spaceNode.simdTransform = window.transform
            spaceNode.name = "Space \(window.category)"
            let wallMaterial = SCNMaterial()
            wallMaterial.diffuse.contents = UIImage(named: "window-texture.png")
            wallMaterial.specular.contents = false
            wallMaterial.emission.contents = UIColor.black
            wallMaterial.transparent.contents = true
            wallMaterial.ambientOcclusion.contents = true
            wallMaterial.isDoubleSided = true
            
            
            spaceGeometry.materials = [wallMaterial]
            spaceNode.name = window.identifier.uuidString
            rootNode.addChildNode(spaceNode)
        }
        
        return rootNode
        
    }
}

