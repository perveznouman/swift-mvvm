import UIKit

/// Composition root: the only place that knows the concrete types.
/// It builds the object graph and creates every screen with its view model injected.
@MainActor
final class AppContainer {
    private let userService: UserServicing
    private let weatherService: WeatherServicing
    private let favorites: FavoritesRepository
    private let imageLoader: ImageDataLoading

    init() {
        let client = APIClient()
        let imageLoader = ImageLoader(client: client)
        self.imageLoader = imageLoader
        self.userService = UserService(client: client)
        self.weatherService = WeatherService(client: client)
        self.favorites = FavoritesStore(container: PersistenceController().container, imageLoader: imageLoader)
    }

    func makeRootViewController() -> UIViewController {
        let users = UINavigationController(
            rootViewController: UsersListViewController(
                viewModel: UsersListViewModel(userService: userService, favorites: favorites),
                factory: self))
        users.tabBarItem = UITabBarItem(title: "Users", image: UIImage(systemName: "person.3"), tag: 0)

        let favoritesNav = UINavigationController(
            rootViewController: FavoritesViewController(
                viewModel: FavoritesViewModel(favorites: favorites),
                factory: self))
        favoritesNav.tabBarItem = UITabBarItem(title: "Favourites", image: UIImage(systemName: "star"), tag: 1)

        let tabs = UITabBarController()
        tabs.viewControllers = [users, favoritesNav]
        return tabs
    }

    func makeUserDetailViewController(user: User) -> UIViewController {
        UserDetailViewController(
            viewModel: UserDetailViewModel(user: user, favorites: favorites, imageLoader: imageLoader),
            factory: self)
    }

    func makeWeatherViewController(user: User) -> UIViewController {
        WeatherViewController(
            viewModel: WeatherViewModel(user: user, weatherService: weatherService, favorites: favorites))
    }
}
