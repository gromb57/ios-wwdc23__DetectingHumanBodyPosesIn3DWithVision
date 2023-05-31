/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The detector serves as the view model for the scene and interfaces with the Vision framework to run the request and related  calculations.
*/

import Foundation
import Vision
import SceneKit
import AVFoundation
import Photos
import simd

class HumanBodyPose3DDetector: NSObject, ObservableObject {

    @Published var humanObservation: VNHumanBodyPose3DObservation? = nil
    var fileURL: URL? = URL(string: "")

    // MARK: - The angle from the child joint to the parent joint.
    public func calculateLocalAngleToParent(joint: VNHumanBodyPose3DObservation.JointName) -> simd_float3 {
        var angleVector: simd_float3 = simd_float3()
        do {
            if let observation = self.humanObservation {
                let recognizedPoint = try observation.recognizedPoint(joint)
                let childPosition = recognizedPoint.localPosition
                let translationC  = childPosition.translationVector
                // The rotation for x, y, z.
                // Rotate 90 degrees from the default orientation of the node. Add yaw and pitch, and connect the child to the parent.
                let pitch = (Float.pi / 2)
                let yaw = acos(translationC.z / simd_length(translationC))
                let roll = atan2((translationC.y), (translationC.x))
                angleVector = simd_float3(pitch, yaw, roll)
            }
        } catch {
            print("Unable to return point: \(error).")
        }
        return angleVector
    }

    // MARK: - Create and run the request on the asset URL.
    public func runHumanBodyPose3DRequestOnImage(fileURL: URL?) async {
        await Task(priority: .userInitiated) {
            guard let assetURL = fileURL else {
                return
            }
            let request = VNDetectHumanBodyPose3DRequest()
            self.fileURL = fileURL
            let requestHandler = VNImageRequestHandler(url: assetURL)
            do {
                try requestHandler.perform([request])
                if let returnedObservation = request.results?.first {
                    Task { @MainActor in
                        self.humanObservation = returnedObservation
                    }
                }
            } catch {
                print("Unable to perform the request: \(error).")
            }
        }.value
    }
}
