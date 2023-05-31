/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model for image selection from the PhotoPicker and related views.
*/

import Foundation
import PhotosUI
import CoreTransferable
import SwiftUI
import Vision

@MainActor
class HumanBodyPoseImageModel: ObservableObject {

    enum ImageState {
        case noneselected
        case loading(Progress)
        case success(Image)
        case failure(Error)
    }
    
    enum TransferError: Error {
        case importFailed
    }
    
    struct HumanBodyPoseImage: Transferable {
        let image: Image

        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(uiImage: uiImage)
                return HumanBodyPoseImage(image: image)
            }
        }
    }
    
    var selectedAsset: PHAsset? = nil
    @Published private(set) var imageState: ImageState = .noneselected
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .noneselected
            }
        }
    }
    
    @Published var fileURL: URL? = nil
    
    func loadOriginalFileURL(asset: PHAsset) {
        self.getAssetFileURL(asset: asset) { url in
            guard let originalFileURL = url else {
                return
            }
            self.fileURL = originalFileURL
        }

    }
    
    // Determine the original file URL.
    private func getAssetFileURL(asset: PHAsset, completionHandler: @escaping (URL?) -> Void) {
        let option = PHContentEditingInputRequestOptions()
        asset.requestContentEditingInput(with: option) { contentEditingInput, _ in
            completionHandler(contentEditingInput?.fullSizeImageURL)
        }
    }

    private func loadAssetFromID(identifier: String?) -> PHAsset? {
        if let identifier {
            let result = PHAsset.fetchAssets(
                withLocalIdentifiers: [identifier],
                options: nil
            )
            if let asset = result.firstObject {
                return asset
            }
        } else {
            print("No identifer on item.")
        }
        return nil
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: HumanBodyPoseImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let humanBodyImage?):
                    self.imageState = .success(humanBodyImage.image)
                    self.selectedAsset = self.loadAssetFromID(identifier: imageSelection.itemIdentifier)
                    if let asset = self.selectedAsset {
                        self.loadOriginalFileURL(asset: asset)
                    } else {
                        print("Asset not found.")
                    }
                case .success(nil):
                    self.imageState = .noneselected
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
}
