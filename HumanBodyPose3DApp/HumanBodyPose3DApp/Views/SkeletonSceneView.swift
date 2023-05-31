/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates the scene view of a 3D skeleton representation of VNHumanBodyPose3DObservation from the HumanBodyPose3DDetector view model.
*/

import Foundation
import SwiftUI
import SceneKit
import Vision

struct SkeletonScene: View {
    @StateObject var viewModel = HumanBodyPose3DDetector()
    @State private var showCamera = false
    @State private var buttonPrompt: String = "Switch Perspective"
    
    var body : some View {
        var scene: SCNScene? {
            let myScene = SCNScene()
            let renderer = HumanBodySkeletonRenderer()
            
            guard let observation = viewModel.humanObservation else {
                return myScene
            }
            
            var imageNode = SCNNode()
            if let fileURL = viewModel.fileURL {
                imageNode = renderer.createInputImage2DNode(url: fileURL, observation: observation)
                myScene.rootNode.addChildNode(imageNode)
            }
            
            // Create nodes corresponding to recognizedPoints from the observation using the renderer.
            let nodeDict = renderer.createSkeletonNodes(observation: observation)
            
            // Set the background of the image plane node to be the input image and align it with the 3D scene.
            let imagePlaneScale = renderer.relate3DSkeletonProportionToImagePlane(observation: observation)
            renderer.imageNodeSize.width *= CGFloat(imagePlaneScale)
            renderer.imageNodeSize.height *= CGFloat(imagePlaneScale)
            
            let planeGeometry = SCNPlane(width: renderer.imageNodeSize.width,
                                         height: renderer.imageNodeSize.height)
            if let inputImage = imageNode.geometry?.firstMaterial?.diffuse.contents {
                planeGeometry.firstMaterial?.diffuse.contents = inputImage
                planeGeometry.firstMaterial?.isDoubleSided = true
            }
            imageNode.geometry = planeGeometry
            
            let point = renderer.computeOffsetOfRoot(observation: observation)
            imageNode.simdPosition = simd_float3(x: imageNode.simdPosition.x - Float(point.x),
                                                 y: imageNode.simdPosition.y - Float(point.y),
                                                 z: imageNode.simdPosition.z)
            
            // Add camera representations to the scene (pyramid and new scene camera).
            if showCamera {
                myScene.rootNode.addChildNode(renderer.createCameraNode(observation: observation))
            } else {
                myScene.rootNode.addChildNode(renderer.createCameraPyramidNode(observation: observation))
            }
            
            // Add skeleton nodes to the scene.
            let bodyAnchorNode = SCNNode()
            bodyAnchorNode.position = SCNVector3(0, 0, 0)
            myScene.rootNode.addChildNode(bodyAnchorNode)
            for jointName in nodeDict.keys {
                if let jointNode = nodeDict[jointName] {
                    bodyAnchorNode.addChildNode(jointNode)
                }
            }
            
            // Give the head more spherical geometry.
            if let topHead = nodeDict[.topHead], let centerHeadNode = nodeDict[.centerHead], let centerShoulderNode = nodeDict[.centerShoulder] {
                let headHight = CGFloat(topHead.position.y - centerShoulderNode.position.y)
                centerHeadNode.geometry = SCNBox(width: 0.2,
                                                 height: headHight,
                                                 length: 0.2,
                                                 chamferRadius: 0.4)
                centerHeadNode.geometry?.firstMaterial?.diffuse.contents = UIColor(.red)
                topHead.isHidden = true
            }
            
            let jointOrderArray: [VNHumanBodyPose3DObservation.JointName] = [.leftWrist, .leftElbow, .leftShoulder,
                                                                             .rightWrist, .rightElbow, .rightShoulder,
                                                                             .centerShoulder, .spine, .rightAnkle,
                                                                             .rightKnee, .rightHip, .leftAnkle, .leftKnee, .leftHip]
            for jointName in jointOrderArray {
                connectNodeToParent(joint: jointName,
                                    observation: observation,
                                    nodeJointDict: nodeDict,
                                    viewModel)
            }
            return myScene
        }
        
        let options: SceneView.Options = [.autoenablesDefaultLighting, .allowsCameraControl]
        VStack {
            if viewModel.humanObservation != nil {
                SceneView(scene: scene, options: options)
                Button(buttonPrompt) {
                    showCamera.toggle()
                }
                .buttonStyle(.bordered)
                .clipShape(Capsule())
            } else {
                ProgressView()
            }
        }
    }
}

// MARK: - Redraws the skeleton upon model change.
func connectNodeToParent(joint: VNHumanBodyPose3DObservation.JointName, observation: VNHumanBodyPose3DObservation,
                         nodeJointDict: [VNHumanBodyPose3DObservation.JointName: SCNNode], _ viewModel: HumanBodyPose3DDetector) {
    if let parentJointName = observation.parentJointName(joint), let node = nodeJointDict[joint] {
        guard let parentNode = nodeJointDict[parentJointName] else {
            return
        }
        updateLineNode(node: node,
                       joint: joint,
                       fromPoint: node.simdPosition,
                       toPoint: parentNode.simdPosition,
                       detector: viewModel)
    }
}

func updateLineNode(node: SCNNode,
                    joint: VNHumanBodyPose3DObservation.JointName,
                    fromPoint: simd_float3,
                    toPoint: simd_float3,
                    originalCubeWidth: Float = 0.05,
                    detector: HumanBodyPose3DDetector) {
    // Determine the distance between the child and parent nodes.
    let length = max(simd_length(toPoint - fromPoint), 1E-5)
    
    // The distance between the child and parent nodes serves as the length of the limb node geometry.
    let boxGeometry = SCNBox(width: CGFloat(Float(originalCubeWidth)),
                             height: CGFloat(Float(length)),
                             length: CGFloat(originalCubeWidth),
                             chamferRadius: 0.05)
    node.geometry = boxGeometry
    node.geometry?.firstMaterial?.diffuse.contents = UIColor(.red)
    
    // The node is positioned between the child and parent nodes.
    node.simdPosition = (toPoint + fromPoint) / 2
    node.simdEulerAngles = detector.calculateLocalAngleToParent(joint: joint)
}
