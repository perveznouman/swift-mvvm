import Foundation

/// What a list-style screen should currently show. The view just switches on it.
enum ScreenState: Equatable {
    case loading
    case content
    case empty(message: String)
    case error(message: String)
}

/// Display-ready data for one row in a user list.
struct UserRowViewModel: Equatable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let isFavorite: Bool

    init(user: User, isFavorite: Bool) {
        id = user.id
        name = user.name
        username = "@\(user.username)"
        email = user.email
        self.isFavorite = isFavorite
    }
}
