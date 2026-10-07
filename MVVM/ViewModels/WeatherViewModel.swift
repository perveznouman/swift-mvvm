import Foundation
import Observation

/// Display-ready weather. All string formatting happens in the view model, not the view controller.
struct WeatherDisplay: Equatable {
    struct Detail: Equatable {
        let title: String
        let value: String
    }

    struct ForecastDay: Equatable {
        let day: String
        let symbol: String
        let range: String
    }

    let location: String
    let symbol: String
    let temperature: String
    let condition: String
    let details: [Detail]
    let forecast: [ForecastDay]
    /// Set when showing a saved report because the network request failed.
    let offlineBanner: String?
}

enum WeatherViewState: Equatable {
    case loading
    case loaded(WeatherDisplay)
    case failed(message: String, canRetry: Bool)
}

@MainActor @Observable
final class WeatherViewModel {
    private(set) var state: WeatherViewState = .loading

    let title = "Weather"

    private let user: User
    private let weatherService: WeatherServicing
    private let favorites: FavoritesRepository

    init(user: User, weatherService: WeatherServicing, favorites: FavoritesRepository) {
        self.user = user
        self.weatherService = weatherService
        self.favorites = favorites
    }

    func load() async {
        guard let latitude = user.address.geo.latitude, let longitude = user.address.geo.longitude else {
            state = .failed(message: "This address has no valid coordinates.", canRetry: false)
            return
        }
        state = .loading
        do {
            let report = try await weatherService.fetchWeather(latitude: latitude, longitude: longitude)
            if favorites.isFavorite(user.id) { favorites.saveWeather(report, for: user.id) }
            state = .loaded(display(for: report, staleSince: nil))
        } catch {
            if let cached = favorites.cachedWeather(for: user.id) {
                state = .loaded(display(for: cached.report, staleSince: cached.updatedAt))
            } else {
                let hint = favorites.isFavorite(user.id)
                    ? ""
                    : "\n\nFavourite this user while online to keep their weather offline."
                state = .failed(message: "Couldn't load the weather.\n\(error.localizedDescription)\(hint)", canRetry: true)
            }
        }
    }

    // MARK: Formatting

    private func display(for report: WeatherReport, staleSince: Date?) -> WeatherDisplay {
        let current = report.current
        return WeatherDisplay(
            location: "\(user.address.city)  (\(user.address.geo.lat), \(user.address.geo.lng))",
            symbol: WeatherCondition.symbol(for: current.weatherCode),
            temperature: "\(Int(current.temperature.rounded()))°C",
            condition: WeatherCondition.description(for: current.weatherCode),
            details: [
                .init(title: "Feels like", value: "\(Int(current.apparentTemperature.rounded()))°C"),
                .init(title: "Humidity", value: "\(current.humidity)%"),
                .init(title: "Wind", value: "\(Int(current.windSpeed.rounded())) km/h")
            ],
            forecast: forecast(for: report.daily),
            offlineBanner: staleSince.map {
                "Offline: showing weather saved \($0.formatted(date: .abbreviated, time: .shortened))"
            }
        )
    }

    private func forecast(for daily: WeatherReport.Daily) -> [WeatherDisplay.ForecastDay] {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        let weekday = DateFormatter()
        weekday.dateFormat = "EEE"

        return daily.dates.indices.prefix(5).map { index in
            let name = index == 0
                ? "Today"
                : (parser.date(from: daily.dates[index]).map(weekday.string(from:)) ?? daily.dates[index])
            return WeatherDisplay.ForecastDay(
                day: name,
                symbol: WeatherCondition.symbol(for: daily.weatherCodes[index]),
                range: "\(Int(daily.minTemperatures[index].rounded()))° / \(Int(daily.maxTemperatures[index].rounded()))°"
            )
        }
    }
}
