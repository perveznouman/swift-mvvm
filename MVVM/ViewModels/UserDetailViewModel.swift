import Foundation
import Observation

@MainActor @Observable
final class UserDetailViewModel {
    struct Field: Equatable {
        let title: String
        let value: String
    }

    private(set) var avatarData: Data?
    private(set) var isLoadingAvatar = false

    let user: User
    let title: String
    let name: String
    let fields: [Field]
    let addressText: String

    private let favorites: FavoritesRepository
    private let imageLoader: ImageDataLoading

    init(user: User, favorites: FavoritesRepository, imageLoader: ImageDataLoading) {
        self.user = user
        self.favorites = favorites
        self.imageLoader = imageLoader

        title = user.name
        name = user.name
        fields = [
            Field(title: "Name", value: user.name),
            Field(title: "Username", value: "@\(user.username)"),
            Field(title: "Email", value: user.email),
            Field(title: "Phone", value: user.phone),
            Field(title: "Website", value: user.website)
        ]
        addressText = user.address.formatted

        // Favourites carry their avatar with them, which is what makes this screen work offline.
        avatarData = favorites.avatarData(for: user.id)
    }

    var isFavorite: Bool {
        _ = favorites.revision // re-evaluate observers whenever favourites change
        return favorites.isFavorite(user.id)
    }

    func loadAvatar() async {
        guard avatarData == nil else { return }
        isLoadingAvatar = true
        avatarData = await imageLoader.data(for: user.avatarURL)
        isLoadingAvatar = false
    }

    func toggleFavorite() {
        favorites.toggle(user)
    }
}
