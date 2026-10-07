import Foundation
import Observation
@testable import MVVM

extension User {
    static func fixture(id: Int = 1, name: String = "Leanne Graham", lat: String = "-37.3159", lng: String = "81.1496") -> User {
        User(id: id, name: name, username: "user\(id)", email: "user\(id)@example.com",
             address: Address(street: "Kulas Light", suite: "Apt. 556", city: "Gwenborough", zipcode: "92998",
                              geo: Geo(lat: lat, lng: lng)),
             phone: "123", website: "example.org",
             company: Company(name: "Co", catchPhrase: "Phrase", bs: "bs"))
    }
}

extension WeatherReport {
    static let fixture = WeatherReport(
        current: .init(temperature: 12.4, apparentTemperature: 7.2, humidity: 70, windSpeed: 28.6, weatherCode: 3),
        daily: .init(dates: ["2026-10-07", "2026-10-08"], weatherCodes: [3, 61],
                     maxTemperatures: [12.6, 13], minTemperatures: [10, 11]))
}

struct TestError: LocalizedError {
    var errorDescription: String? { "boom" }
}

final class FakeUserService: UserServicing {
    var result: Result<[User], Error> = .success([])
    func fetchUsers() async throws -> [User] { try result.get() }
}

final class FakeWeatherService: WeatherServicing {
    var result: Result<WeatherReport, Error> = .success(.fixture)
    private(set) var requestedCoordinates: [(Double, Double)] = []
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherReport {
        requestedCoordinates.append((latitude, longitude))
        return try result.get()
    }
}

struct FakeImageLoader: ImageDataLoading {
    var data: Data?
    func data(for url: URL) async -> Data? { data }
}

@MainActor @Observable
final class FakeFavoritesRepository: FavoritesRepository {
    private(set) var revision = 0
    private(set) var users: [User] = []
    var avatars: [Int: Data] = [:]
    var weather: [Int: CachedWeather] = [:]

    func allFavorites() -> [User] { users }
    func isFavorite(_ userID: Int) -> Bool { users.contains { $0.id == userID } }
    func avatarData(for userID: Int) -> Data? { avatars[userID] }
    func cachedWeather(for userID: Int) -> CachedWeather? { weather[userID] }

    func toggle(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users.remove(at: index)
        } else {
            users.insert(user, at: 0)
        }
        revision += 1
    }

    func saveWeather(_ report: WeatherReport, for userID: Int) {
        weather[userID] = CachedWeather(report: report, updatedAt: Date())
    }
}
