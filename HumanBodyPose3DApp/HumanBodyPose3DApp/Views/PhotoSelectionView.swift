/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that creates the NavigationStack between photo selection views and Skeleton Scene rendering views.
*/

import Foundation
import PhotosUI
import SwiftUI

struct PhotoSelectionView: View {
    var body: some View {
        PhotoSelectorView()
    }
}

func requestAuthorization() {
    switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
    case .notDetermined:
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { code in
            if code == .authorized {
                print("Photos Permissions granted.")
            }
        }

    case .restricted, .denied:
        print("Please allow access to Photos to use the app.")
    case .authorized:
        print("Authorized for Photos access.")
    case .limited:
        print("Limited Photos access.")
    @unknown default:
        print("Unable to access Photos.")
    }
}

struct PhotoSelectorView: View {
    @StateObject var viewModel = HumanBodyPoseImageModel()
    @StateObject var skeletonModel = HumanBodyPose3DDetector()
    @State private var showSkeleton = false
    @State private var buttonPrompt: String = "Show Skeleton"

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        HStack {
                            Spacer()
                            SelectablePersonPhotoView(viewModel: viewModel)
                                .onAppear() {
                                    requestAuthorization()
                                }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            
            NavigationLink("Show 3D Skeleton") {
                SkeletonScene(viewModel: skeletonModel)
                    .task(priority: .userInitiated) {
                        await skeletonModel.runHumanBodyPose3DRequestOnImage(fileURL: viewModel.fileURL)
                    }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.fileURL == nil)
        }
    }
}

