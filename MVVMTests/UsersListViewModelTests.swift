import XCTest
@testable import MVVM

@MainActor
final class UsersListViewModelTests: XCTestCase {
    private var service: FakeUserService!
    private var favorites: FakeFavoritesRepository!
    private var viewModel: UsersListViewModel!

    override func setUp() {
        super.setUp()
        service = FakeUserService()
        favorites = FakeFavoritesRepository()
        viewModel = UsersListViewModel(userService: service, favorites: favorites)
    }

    func test_initialState_isLoading() {
        XCTAssertEqual(viewModel.state, .loading)
        XCTAssertTrue(viewModel.rows.isEmpty)
    }

    func test_load_success_buildsFormattedRows() async {
        service.result = .success([.fixture(id: 1), .fixture(id: 2, name: "Ervin Howell")])
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .content)
        XCTAssertEqual(viewModel.rows.map(\.name), ["Leanne Graham", "Ervin Howell"])
        XCTAssertEqual(viewModel.rows.first?.username, "@user1")
    }

    func test_load_emptyList_showsEmptyState() async {
        service.result = .success([])
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .empty(message: "No users found."))
    }

    func test_load_failure_showsErrorWithMessage() async {
        service.result = .failure(TestError())
        await viewModel.load()

        guard case .error(let message) = viewModel.state else { return XCTFail("expected error, got \(viewModel.state)") }
        XCTAssertTrue(message.contains("boom"))
    }

    func test_refreshFailure_keepsExistingRows() async {
        service.result = .success([.fixture()])
        await viewModel.load()
        service.result = .failure(TestError())
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .content)
        XCTAssertEqual(viewModel.rows.count, 1)
    }

    func test_toggleFavorite_updatesRowWithoutReloading() async {
        service.result = .success([.fixture(id: 1), .fixture(id: 2)])
        await viewModel.load()
        XCTAssertEqual(viewModel.rows.map(\.isFavorite), [false, false])

        viewModel.toggleFavorite(at: 1)
        XCTAssertEqual(viewModel.rows.map(\.isFavorite), [false, true])

        viewModel.toggleFavorite(at: 1)
        XCTAssertEqual(viewModel.rows.map(\.isFavorite), [false, false])
    }

    func test_rowsReflectFavoritesChangedElsewhere() async {
        service.result = .success([.fixture(id: 1)])
        await viewModel.load()

        favorites.toggle(.fixture(id: 1)) // e.g. from the detail screen
        XCTAssertEqual(viewModel.rows.first?.isFavorite, true)
    }
}
