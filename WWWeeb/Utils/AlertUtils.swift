import Foundation
import SwiftUI

struct AlertUtils {
    static func showAlert(title: String, message: String, okAction: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: okAction))

            if let window = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .first {
                window.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
}
