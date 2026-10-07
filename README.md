# MVVM: Users, Favourites & Weather (UIKit + Observation + Core Data)

Same app and features as the MVC version (sibling repo) (users list, favourites available offline, detail screen, weather for the address lat/long), restructured as MVVM.
Open `MVVM.xcodeproj`, run on an iPhone simulator (iOS 17+). Run tests with Cmd+U.

## What changed vs MVC
| Concern | MVC | MVVM |
|---|---|---|
| Screen state & formatting | In the view controller | In an **`@Observable` view model** (`ViewModels/`) |
| View controller job | Fetch, decide, format, render | **Bind and render only** (`ViewControllers/`) |
| Dependencies | Singletons (`.shared`) | **Protocols + constructor injection**, wired in `App/AppContainer.swift` (composition root) |
| Cross-screen updates | `NotificationCenter` | Observable `FavoritesRepository.revision`, read inside view-model computed properties |
| Binding VM to UIKit | n/a | `bind(_:apply:)` helper over `withObservationTracking` (`ViewControllers/ObservationBinding.swift`) |
| Navigation to next screen | VC creates the next VC | VC asks a `ScreenFactory` (implemented by `AppContainer`) |
| Testability | Hard (singletons, UIKit in logic) | View models have **26 unit tests** using fakes (`MVVMTests/`) |

## Layers
- **Model**: `Models/`, `Services/` (`APIClient`, `UserService`, `WeatherService`, `ImageLoader`), `Persistence/` (Core Data, `FavoritesStore`)
- **View**: `Views/` + `ViewControllers/` (UIKit, no logic)
- **ViewModel**: `ViewModels/` (no `import UIKit`)

## Rules of thumb used here
- A view model never imports UIKit. Images travel as `Data`, icons as SF Symbol names.
- The view model exposes *display-ready* values (`"12°C"`, `"@Bret"`), so the view does zero formatting.
- `withObservationTracking` fires `onChange` once, *before* the new value is stored. `bind` therefore re-arms on the next main-actor turn and re-reads, so the UI always sees the new value.
- Only properties actually *read* inside the `read` closure are tracked. Derived values (`rows`, `isFavorite`) read `favorites.revision` so they refresh when favourites change.
- iOS 18+ UIKit can track `@Observable` automatically inside `updateProperties()` / `viewWillLayoutSubviews`; iOS 17 needs the helper. SwiftUI would need neither.
- Only `AppContainer` knows concrete types.

## Things MVVM does not solve (motivation for Clean Architecture)
- View models still talk to services/repositories directly. There is no use-case layer for business rules (for example "favourite + cache avatar + cache weather").
- The `FavoritesRepository` protocol lives next to its implementation and exposes `CachedWeather`, a persistence-flavoured type. Clean Architecture puts such contracts in an inner domain layer.
