import XCTest
@testable import MVVM

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    func test_noFavorites_showsEmptyState() {
        let viewModel = FavoritesViewModel(favorites: FakeFavoritesRepository())
        guard case .empty = viewModel.state else { return XCTFail("expected empty, got \(viewModel.state)") }
        XCTAssertTrue(viewModel.rows.isEmpty)
    }

    func test_rowsFollowRepositoryChanges() {
        let repository = FakeFavoritesRepository()
        let viewModel = FavoritesViewModel(favorites: repository)

        repository.toggle(.fixture(id: 1))
        repository.toggle(.fixture(id: 2, name: "Ervin Howell"))

        XCTAssertEqual(viewModel.state, .content)
        XCTAssertEqual(viewModel.rows.map(\.name), ["Ervin Howell", "Leanne Graham"]) // newest first
        XCTAssertTrue(viewModel.rows.allSatisfy(\.isFavorite))
    }

    func test_remove_deletesFromRepository() {
        let repository = FakeFavoritesRepository()
        repository.toggle(.fixture(id: 1))
        let viewModel = FavoritesViewModel(favorites: repository)

        viewModel.remove(at: 0)

        XCTAssertTrue(viewModel.rows.isEmpty)
        XCTAssertFalse(repository.isFavorite(1))
    }
}
