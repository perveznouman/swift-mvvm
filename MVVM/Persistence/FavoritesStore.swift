import CoreData
import Observation

/// Core Data implementation of `FavoritesRepository`. Main-thread (viewContext) to keep the sample simple.
@MainActor @Observable
final class FavoritesStore: FavoritesRepository {
    private(set) var revision = 0

    private let context: NSManagedObjectContext
    private let imageLoader: ImageDataLoading

    init(container: NSPersistentContainer, imageLoader: ImageDataLoading) {
        self.context = container.viewContext
        self.imageLoader = imageLoader
    }

    // MARK: Reading

    func allFavorites() -> [User] {
        let request = FavoriteUserEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
        return ((try? context.fetch(request)) ?? []).map(\.user)
    }

    func isFavorite(_ userID: Int) -> Bool {
        entity(for: userID) != nil
    }

    func avatarData(for userID: Int) -> Data? {
        entity(for: userID)?.avatarData
    }

    func cachedWeather(for userID: Int) -> CachedWeather? {
        guard let entity = entity(for: userID),
              let data = entity.weatherData,
              let date = entity.weatherUpdatedAt,
              let report = try? JSONDecoder().decode(WeatherReport.self, from: data) else { return nil }
        return CachedWeather(report: report, updatedAt: date)
    }

    // MARK: Writing

    /// Adds or removes the user. When adding, the avatar is downloaded in the background and stored too.
    func toggle(_ user: User) {
        if let existing = entity(for: user.id) {
            context.delete(existing)
            save()
        } else {
            let entity = FavoriteUserEntity(context: context)
            entity.apply(user)
            entity.addedAt = Date()
            save()
            Task { await storeAvatar(for: user) }
        }
    }

    func saveWeather(_ report: WeatherReport, for userID: Int) {
        guard let entity = entity(for: userID),
              let data = try? JSONEncoder().encode(report) else { return }
        entity.weatherData = data
        entity.weatherUpdatedAt = Date()
        try? context.save() // no revision bump: lists don't show weather
    }

    // MARK: Private

    private func storeAvatar(for user: User) async {
        guard let data = await imageLoader.data(for: user.avatarURL),
              let entity = entity(for: user.id) else { return }
        entity.avatarData = data
        try? context.save()
    }

    private func entity(for userID: Int) -> FavoriteUserEntity? {
        let request = FavoriteUserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", Int64(userID))
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func save() {
        do {
            try context.save()
        } catch {
            context.rollback()
            assertionFailure("Failed to save favourites: \(error)")
        }
        revision += 1
    }
}
