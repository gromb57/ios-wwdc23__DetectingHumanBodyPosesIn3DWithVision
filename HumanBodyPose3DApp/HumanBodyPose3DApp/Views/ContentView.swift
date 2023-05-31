/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the app that creates the PhotoSelectionView.
*/

import SwiftUI
import SceneKit
import UIKit
import Vision
import simd
import Photos

struct ContentView: View {
    var body: some View {
        VStack {
            PhotoSelectionView()
        }
        .padding()
    }
}
