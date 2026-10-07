import UIKit

/// How a view controller asks for the next screen without knowing how it is built.
@MainActor
protocol ScreenFactory: AnyObject {
    func makeUserDetailViewController(user: User) -> UIViewController
    func makeWeatherViewController(user: User) -> UIViewController
}

extension AppContainer: ScreenFactory {}
