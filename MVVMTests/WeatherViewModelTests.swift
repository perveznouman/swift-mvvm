import XCTest
@testable import MVVM

@MainActor
final class WeatherViewModelTests: XCTestCase {
    private var service: FakeWeatherService!
    private var favorites: FakeFavoritesRepository!

    override func setUp() {
        super.setUp()
        service = FakeWeatherService()
        favorites = FakeFavoritesRepository()
    }

    private func makeViewModel(user: User = .fixture()) -> WeatherViewModel {
        WeatherViewModel(user: user, weatherService: service, favorites: favorites)
    }

    private func loadedDisplay(_ viewModel: WeatherViewModel, file: StaticString = #filePath, line: UInt = #line) -> WeatherDisplay? {
        guard case .loaded(let display) = viewModel.state else {
            XCTFail("expected loaded, got \(viewModel.state)", file: file, line: line)
            return nil
        }
        return display
    }

    func test_load_requestsUsersCoordinates() async {
        let viewModel = makeViewModel(user: .fixture(lat: "-37.3159", lng: "81.1496"))
        await viewModel.load()
        XCTAssertEqual(service.requestedCoordinates.first?.0, -37.3159)
        XCTAssertEqual(service.requestedCoordinates.first?.1, 81.1496)
    }

    func test_load_success_formatsValues() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        guard let display = loadedDisplay(viewModel) else { return }
        XCTAssertEqual(display.temperature, "12°C")
        XCTAssertEqual(display.condition, "Overcast")
        XCTAssertEqual(display.details.map(\.value), ["7°C", "70%", "29 km/h"])
        XCTAssertEqual(display.forecast.first?.day, "Today")
        XCTAssertEqual(display.forecast.first?.range, "10° / 13°")
        XCTAssertNil(display.offlineBanner)
    }

    func test_load_failure_withoutCache_isRetryableError() async {
        service.result = .failure(TestError())
        let viewModel = makeViewModel()
        await viewModel.load()

        guard case .failed(let message, let canRetry) = viewModel.state else { return XCTFail("expected failure") }
        XCTAssertTrue(canRetry)
        XCTAssertTrue(message.contains("Favourite this user"))
    }

    func test_load_failure_withCachedWeather_showsOfflineBanner() async {
        favorites.toggle(.fixture())
        favorites.weather[1] = CachedWeather(report: .fixture, updatedAt: Date())
        service.result = .failure(TestError())

        let viewModel = makeViewModel()
        await viewModel.load()

        XCTAssertTrue(loadedDisplay(viewModel)?.offlineBanner?.hasPrefix("Offline") == true)
    }

    func test_load_success_forFavourite_savesWeatherForOffline() async {
        favorites.toggle(.fixture())
        await makeViewModel().load()
        XCTAssertEqual(favorites.weather[1]?.report, .fixture)
    }

    func test_load_success_forNonFavourite_doesNotSave() async {
        await makeViewModel().load()
        XCTAssertTrue(favorites.weather.isEmpty)
    }

    func test_invalidCoordinates_failsWithoutRetry() async {
        let viewModel = makeViewModel(user: .fixture(lat: "abc", lng: "81"))
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(message: "This address has no valid coordinates.", canRetry: false))
        XCTAssertTrue(service.requestedCoordinates.isEmpty)
    }
}
