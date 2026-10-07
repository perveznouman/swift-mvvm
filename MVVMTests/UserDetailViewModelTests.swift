import XCTest
@testable import MVVM

@MainActor
final class UserDetailViewModelTests: XCTestCase {
    func test_fieldsAreFormatted() {
        let viewModel = UserDetailViewModel(user: .fixture(), favorites: FakeFavoritesRepository(),
                                            imageLoader: FakeImageLoader(data: nil))
        XCTAssertEqual(viewModel.fields.map(\.title), ["Name", "Username", "Email", "Phone", "Website"])
        XCTAssertEqual(viewModel.fields[1].value, "@user1")
        XCTAssertEqual(viewModel.addressText, "Apt. 556, Kulas Light, Gwenborough 92998")
    }

    func test_toggleFavorite_updatesIsFavorite() {
        let viewModel = UserDetailViewModel(user: .fixture(), favorites: FakeFavoritesRepository(),
                                            imageLoader: FakeImageLoader(data: nil))
        XCTAssertFalse(viewModel.isFavorite)
        viewModel.toggleFavorite()
        XCTAssertTrue(viewModel.isFavorite)
    }

    func test_favouriteUsesStoredAvatar_withoutDownloading() async {
        let repository = FakeFavoritesRepository()
        repository.toggle(.fixture())
        repository.avatars[1] = Data([1, 2, 3])
        let viewModel = UserDetailViewModel(user: .fixture(), favorites: repository,
                                            imageLoader: FakeImageLoader(data: Data([9])))

        await viewModel.loadAvatar()

        XCTAssertEqual(viewModel.avatarData, Data([1, 2, 3]))
    }

    func test_nonFavourite_downloadsAvatar() async {
        let viewModel = UserDetailViewModel(user: .fixture(), favorites: FakeFavoritesRepository(),
                                            imageLoader: FakeImageLoader(data: Data([9])))
        await viewModel.loadAvatar()
        XCTAssertEqual(viewModel.avatarData, Data([9]))
        XCTAssertFalse(viewModel.isLoadingAvatar)
    }
}
