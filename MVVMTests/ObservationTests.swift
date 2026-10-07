import Observation
import XCTest
@testable import MVVM

/// Verifies the contract the view controllers rely on: reading a view-model property inside
/// `withObservationTracking` registers it, and a later change fires `onChange`.
@MainActor
final class ObservationTests: XCTestCase {
    private final class Flag: @unchecked Sendable { var fired = false }

    private func isTriggered<T>(reading read: () -> T, by change: () async -> Void) async -> Bool {
        let flag = Flag()
        _ = withObservationTracking(read) { flag.fired = true }
        await change()
        return flag.fired
    }

    func test_usersState_isObservable() async {
        let service = FakeUserService()
        service.result = .success([.fixture()])
        let viewModel = UsersListViewModel(userService: service, favorites: FakeFavoritesRepository())

        let fired = await isTriggered(reading: { viewModel.state }, by: { await viewModel.load() })
        XCTAssertTrue(fired)
    }

    func test_usersRows_changeWhenFavouriteToggledElsewhere() async {
        let service = FakeUserService()
        service.result = .success([.fixture()])
        let repository = FakeFavoritesRepository()
        let viewModel = UsersListViewModel(userService: service, favorites: repository)
        await viewModel.load()

        let fired = await isTriggered(reading: { viewModel.rows }, by: { repository.toggle(.fixture()) })
        XCTAssertTrue(fired)
    }

    func test_detailIsFavorite_isObservable() async {
        let repository = FakeFavoritesRepository()
        let viewModel = UserDetailViewModel(user: .fixture(), favorites: repository, imageLoader: FakeImageLoader(data: nil))

        let fired = await isTriggered(reading: { viewModel.isFavorite }, by: { viewModel.toggleFavorite() })
        XCTAssertTrue(fired)
    }

    func test_favouritesRows_areObservable() async {
        let repository = FakeFavoritesRepository()
        let viewModel = FavoritesViewModel(favorites: repository)

        let fired = await isTriggered(reading: { viewModel.rows }, by: { repository.toggle(.fixture()) })
        XCTAssertTrue(fired)
    }

    func test_weatherState_isObservable() async {
        let viewModel = WeatherViewModel(user: .fixture(), weatherService: FakeWeatherService(), favorites: FakeFavoritesRepository())
        let fired = await isTriggered(reading: { viewModel.state }, by: { await viewModel.load() })
        XCTAssertTrue(fired)
    }
}
