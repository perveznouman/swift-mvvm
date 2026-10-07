import Observation
import UIKit

extension UIViewController {
    /// Bridges `@Observable` view models to UIKit.
    ///
    /// `read` touches the view-model properties you care about and returns a value; `apply` pushes that value
    /// into the UI. It runs once now and again after every change to a property that `read` touched.
    ///
    /// `withObservationTracking` fires its `onChange` *before* the new value is stored and only once, so we hop
    /// to the next main-actor turn and re-arm, which also reads the fresh value.
    /// (iOS 18+ can do this automatically inside `updateProperties()`; iOS 17 needs this helper.)
    func bind<Value>(_ read: @escaping () -> Value, apply: @escaping (Value) -> Void) {
        let value = withObservationTracking(read) { [weak self] in
            Task { @MainActor in self?.bind(read, apply: apply) }
        }
        apply(value)
    }
}
