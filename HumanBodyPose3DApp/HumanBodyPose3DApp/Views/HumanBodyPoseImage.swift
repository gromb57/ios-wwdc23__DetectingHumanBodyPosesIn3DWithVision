/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The image selection placeholder view and selection state.
*/

import SwiftUI
import PhotosUI
import SceneKit

// The view for each state of image selection.
struct HumanBodyImage: View {
    let imageState: HumanBodyPoseImageModel.ImageState
    var body: some View {
        switch imageState {
        case .success(let image):
            image.resizable()
        case .loading:
            ProgressView()
        case .noneselected:
            Image(systemName: "figure.arms.open")
                .font(.system(size: 80))
                .foregroundColor(.white)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}

struct PersonPlaceholderImageView: View {
    let imageState: HumanBodyPoseImageModel.ImageState
    
    var body: some View {
        HumanBodyImage(imageState: imageState)
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: RoundedCornerStyle.continuous))
            .frame(width: 300, height: 300)
            .background {
                RoundedRectangle(cornerRadius: 8.0, style: RoundedCornerStyle.continuous).fill(
                    LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
    }
}

struct SelectablePersonPhotoView: View {
    @ObservedObject var viewModel: HumanBodyPoseImageModel
    
    // Displays the PhotosPicker view and the corresponding label view.
    var body: some View {
        VStack {
            PersonPlaceholderImageView(imageState: viewModel.imageState)
                .padding(50)
            PhotosPicker(selection: $viewModel.imageSelection,
                         matching: .images,
                         photoLibrary: .shared()) {
                Image(systemName: "photo.stack")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                Text("Select Photo")
            }
            .buttonStyle(.borderless)
        }
    }
}
