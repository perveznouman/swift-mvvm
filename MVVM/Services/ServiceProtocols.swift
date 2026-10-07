import Foundation

// Abstractions the view models depend on. Concrete types are chosen in AppContainer;
// tests pass fakes. This is what removes the singletons from MVC.

protocol UserServicing {
    func fetchUsers() async throws -> [User]
}

protocol WeatherServicing {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherReport
}

protocol ImageDataLoading {
    func data(for url: URL) async -> Data?
}

struct CachedWeather: Equatable {
    let report: WeatherReport
    let updatedAt: Date
}

/// Offline storage of favourite users (and the avatar + last weather that go with them).
@MainActor
protocol FavoritesRepository: AnyObject {
    /// Bumped after every add / remove. Implementations are `@Observable`, so a view model that reads
    /// `revision` inside a computed property is re-evaluated whenever favourites change.
    /// (Replaces MVC's NotificationCenter broadcast.)
    var revision: Int { get }

    func allFavorites() -> [User]
    func isFavorite(_ userID: Int) -> Bool
    func avatarData(for userID: Int) -> Data?
    func cachedWeather(for userID: Int) -> CachedWeather?
    func toggle(_ user: User)
    func saveWeather(_ report: WeatherReport, for userID: Int)
}
