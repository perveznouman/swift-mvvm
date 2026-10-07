import UIKit

/// SCREEN 4. Renders a `WeatherDisplay`; every string it shows was formatted by the view model.
final class WeatherViewController: UIViewController {
    private let viewModel: WeatherViewModel
    private let stateView = StateView()
    private let scrollView = UIScrollView()
    private let content = UIStackView()

    init(viewModel: WeatherViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        content.axis = .vertical
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(content)
        view.addSubview(stateView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stateView.topAnchor.constraint(equalTo: view.topAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        stateView.onAction = { [weak self] in self?.load() }

        bind({ [viewModel] in viewModel.state }) { [weak self] state in
            self?.render(state)
        }
        load()
    }

    private func load() {
        Task { await viewModel.load() }
    }

    // MARK: Rendering

    private func render(_ state: WeatherViewState) {
        switch state {
        case .loading:
            scrollView.isHidden = true
            stateView.render(.loading)
        case .failed(let message, let canRetry):
            scrollView.isHidden = true
            stateView.render(.message(symbol: "cloud.slash", text: message, actionTitle: canRetry ? "Try Again" : nil))
        case .loaded(let weather):
            stateView.render(.hidden)
            scrollView.isHidden = false
            show(weather)
        }
    }

    private func show(_ weather: WeatherDisplay) {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if let banner = weather.offlineBanner {
            let label = UILabel()
            label.text = banner
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textColor = .systemOrange
            label.numberOfLines = 0
            label.textAlignment = .center
            content.addArrangedSubview(label)
        }
        content.addArrangedSubview(makeCurrentCard(weather))
        content.addArrangedSubview(makeDetailsCard(weather.details))
        content.addArrangedSubview(makeForecastCard(weather.forecast))
    }

    private func makeCurrentCard(_ weather: WeatherDisplay) -> UIView {
        let place = UILabel()
        place.text = weather.location
        place.font = .preferredFont(forTextStyle: .subheadline)
        place.textColor = .secondaryLabel
        place.textAlignment = .center

        let icon = UIImageView(image: UIImage(systemName: weather.symbol))
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56)
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit

        let temperature = UILabel()
        temperature.text = weather.temperature
        temperature.font = .systemFont(ofSize: 52, weight: .bold)

        let condition = UILabel()
        condition.text = weather.condition
        condition.font = .preferredFont(forTextStyle: .title3)

        let stack = UIStackView(arrangedSubviews: [place, icon, temperature, condition])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return card(containing: stack)
    }

    private func makeDetailsCard(_ details: [WeatherDisplay.Detail]) -> UIView {
        let rows = details.map { detail -> UIView in
            let title = UILabel()
            title.text = detail.title
            title.textColor = .secondaryLabel
            let value = UILabel()
            value.text = detail.value
            value.textAlignment = .right
            return UIStackView(arrangedSubviews: [title, value])
        }
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 10
        return card(containing: stack)
    }

    private func makeForecastCard(_ forecast: [WeatherDisplay.ForecastDay]) -> UIView {
        let title = UILabel()
        title.text = "FORECAST"
        title.font = .preferredFont(forTextStyle: .caption1)
        title.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [title])
        stack.axis = .vertical
        stack.spacing = 10

        for day in forecast {
            let dayLabel = UILabel()
            dayLabel.text = day.day
            dayLabel.widthAnchor.constraint(equalToConstant: 56).isActive = true

            let icon = UIImageView(image: UIImage(systemName: day.symbol))
            icon.tintColor = .systemBlue
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: 28).isActive = true

            let range = UILabel()
            range.text = day.range
            range.textAlignment = .right

            let row = UIStackView(arrangedSubviews: [dayLabel, icon, range])
            row.spacing = 12
            row.alignment = .center
            stack.addArrangedSubview(row)
        }
        return card(containing: stack)
    }

    private func card(containing inner: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        return card
    }
}
