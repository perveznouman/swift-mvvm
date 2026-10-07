import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var container: AppContainer?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let container = AppContainer()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = container.makeRootViewController()
        window.makeKeyAndVisible()
        self.container = container
        self.window = window
    }
}
