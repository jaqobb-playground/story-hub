import Foundation
import SwiftUI

struct AlertUtils {
    static func presentAlert(
        title: String,
        message: String,
        okTitle: String = NSLocalizedString("OK", comment: "Name for the 'OK' button."),
        okAction: ((UIAlertAction) -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            showAlert(on: getCurrentViewController(), title: title, message: message, okTitle: okTitle, okAction: okAction)
        }
    }

    static func showAlert(
        on viewController: UIViewController?,
        title: String,
        message: String,
        okTitle: String = NSLocalizedString("OK", comment: "Name for the 'OK' button."),
        okAction: ((UIAlertAction) -> Void)? = nil
    ) {
        if let viewController = viewController {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: okTitle, style: .default, handler: okAction)
            alert.addAction(alertAction)

            viewController.present(alert, animated: true, completion: nil)
        }
    }

    private static func getCurrentViewController() -> UIViewController? {
        let activeScenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
        for activeScene in activeScenes {
            if let rootViewController = activeScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                return getTopViewController(rootViewController)
            }
        }

        return nil
    }

    private static func getTopViewController(_ rootViewController: UIViewController) -> UIViewController {
        var topViewController: UIViewController = rootViewController

        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        return topViewController
    }
}
