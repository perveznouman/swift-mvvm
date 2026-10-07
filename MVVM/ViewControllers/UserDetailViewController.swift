import UIKit

/// SCREEN 3. Builds its layout from the view model's fields and reacts to favourite / avatar changes.
final class UserDetailViewController: UIViewController {
    private let viewModel: UserDetailViewModel
    private weak var factory: ScreenFactory?
    private let avatarView = UIImageView()
    private let avatarSpinner = UIActivityIndicatorView(style: .medium)

    init(viewModel: UserDetailViewModel, factory: ScreenFactory) {
        self.viewModel = viewModel
        self.factory = factory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        buildLayout()
        bind()
        Task { await viewModel.loadAvatar() }
    }

    private func bind() {
        bind({ [viewModel] in viewModel.isFavorite }) { [weak self] isFavorite in
            self?.showFavoriteButton(isFavorite)
        }

        bind({ [viewModel] in viewModel.avatarData }) { [weak self] data in
            guard let self, let data, let image = UIImage(data: data) else { return }
            avatarView.contentMode = .scaleAspectFill
            avatarView.image = image
        }

        bind({ [viewModel] in viewModel.isLoadingAvatar }) { [weak self] isLoading in
            if isLoading { self?.avatarSpinner.startAnimating() } else { self?.avatarSpinner.stopAnimating() }
        }
    }

    // MARK: Layout

    private func buildLayout() {
        avatarView.contentMode = .scaleAspectFit
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 60
        avatarView.backgroundColor = .tertiarySystemFill
        avatarView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarView.tintColor = .tertiaryLabel
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        avatarView.isAccessibilityElement = true
        avatarView.accessibilityLabel = "Profile picture of \(viewModel.name)"

        avatarSpinner.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarSpinner)
        avatarSpinner.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor).isActive = true
        avatarSpinner.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor).isActive = true

        let nameLabel = UILabel()
        nameLabel.text = viewModel.name
        nameLabel.font = .preferredFont(forTextStyle: .title2).bold()
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0

        let header = UIStackView(arrangedSubviews: [avatarView, nameLabel])
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 12

        var rowViews: [UIView] = viewModel.fields.map { DetailRowView(title: $0.title, value: $0.value) }
        rowViews.append(DetailRowView(title: "Address", value: viewModel.addressText) { [weak self] in self?.showWeather() })
        let rows = UIStackView(arrangedSubviews: rowViews)
        rows.axis = .vertical
        rows.spacing = 8

        let content = UIStackView(arrangedSubviews: [header, rows])
        content.axis = .vertical
        content.spacing = 24
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        content.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(content)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor)
        ])
    }

    // MARK: Actions

    private func showFavoriteButton(_ isFavorite: Bool) {
        let item = UIBarButtonItem(image: UIImage(systemName: isFavorite ? "star.fill" : "star"),
                                   style: .plain, target: self, action: #selector(toggleFavorite))
        item.tintColor = isFavorite ? .systemYellow : nil
        item.accessibilityLabel = isFavorite ? "Remove from favourites" : "Add to favourites"
        navigationItem.rightBarButtonItem = item
    }

    @objc private func toggleFavorite() { viewModel.toggleFavorite() }

    private func showWeather() {
        guard let next = factory?.makeWeatherViewController(user: viewModel.user) else { return }
        navigationController?.pushViewController(next, animated: true)
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
