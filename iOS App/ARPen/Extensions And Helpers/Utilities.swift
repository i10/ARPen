//
//  Utilities.swift
//  ARPen
//
//  Created by Krishna Subramanian on 20.07.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import simd
import ARKit

extension UIViewController {
    func showAlert(title: String,
                   message: String,
                   buttonTitle: String = "OK",
                   showCancel: Bool = false,
                   buttonHandler: ((UIAlertAction) -> Void)? = nil) {
        print(title + "\n" + message)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: buttonHandler))
        if showCancel {
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func makeRoundedCorners(button: UIButton!) {
        button.layer.masksToBounds = true
        button.layer.cornerRadius = button.frame.width/2
    }
}

extension CGImagePropertyOrientation {
    /// Preferred image presentation orientation respecting the native sensor orientation of iOS device camera.
    init(cameraOrientation: UIDeviceOrientation) {
        switch cameraOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = .up
        case .landscapeRight:
            self = .down
        default:
            self = .right
        }
    }
}

@available(iOS 12.0, *)
extension ARWorldMap {
    var snapshotAnchor: SnapshotAnchor? {
        return anchors.compactMap { $0 as? SnapshotAnchor }.first
    }
}

// Setup notification names to be observed
extension Notification.Name {
    static let cameraDidChangeTrackingState = Notification.Name("cameraDidChangeTrackingState")
    static let sessionDidUpdate = Notification.Name("sessionDidUpdate")
    static let virtualObjectDidRenderAtAnchor = Notification.Name("virtualObjectDidRenderAtAnchor")
}

@available(iOS 12.0, *)
extension ARFrame.WorldMappingStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Not Available"
        case .limited:
            return "Limited"
        case .extending:
            return "Extending"
        case .mapped:
            return "Mapped"
        }
    }
}

extension ARCamera.TrackingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .notAvailable:
            return "Not Available"
        case .limited(.initializing):
            return "Initializing"
        case .limited(.excessiveMotion):
            return "Excessive Motion"
        case .limited(.insufficientFeatures):
            return "Insufficient Features"
        case .limited(.relocalizing):
            return "Relocalizing"
        }
    }
}

extension ARCamera.TrackingState {
    var localizedFeedback: String {
        switch self {
        case .normal:
            // No planes detected; provide instructions for this app's AR interactions.
            return "Move around to map the environment."

        case .notAvailable:
            return "Tracking unavailable."

        case .limited(.excessiveMotion):
            return "Move the device more slowly."

        case .limited(.insufficientFeatures):
            return "Point the device at an area with visible surface detail, or improve lighting conditions."

        case .limited(.relocalizing):
            return "Resuming session — move to where you were when the session was interrupted."

        case .limited(.initializing):
            return "Initializing AR session."
        }
    }
}
