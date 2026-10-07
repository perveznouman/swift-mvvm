import UIKit

/// SCREEN 1. Observes `UsersListViewModel` and renders. It holds no business logic.
final class UsersListViewController: UITableViewController {
    private let viewModel: UsersListViewModel
    private weak var factory: ScreenFactory?
    private let stateView = StateView()
    private var rows: [UserRowViewModel] = []

    init(viewModel: UsersListViewModel, factory: ScreenFactory) {
        self.viewModel = viewModel
        self.factory = factory
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.reuseIdentifier)
        tableView.backgroundView = stateView
        stateView.onAction = { [weak self] in self?.load() }

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)

        bind()
        load()
    }

    private func bind() {
        bind({ [viewModel] in viewModel.rows }) { [weak self] rows in
            self?.rows = rows
            self?.tableView.reloadData()
        }

        bind({ [viewModel] in viewModel.state }) { [weak self] state in
            guard let self else { return }
            switch state {
            case .loading:
                stateView.render(.loading)
            case .content:
                stateView.render(.hidden)
            case .empty(let message):
                stateView.render(.message(symbol: "person.slash", text: message, actionTitle: nil))
            case .error(let message):
                stateView.render(.message(symbol: "wifi.slash", text: message, actionTitle: "Try Again"))
            }
        }
    }

    private func load() {
        Task {
            await viewModel.load()
            refreshControl?.endRefreshing()
        }
    }

    @objc private func pulledToRefresh() { load() }

    // MARK: Table view

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.reuseIdentifier, for: indexPath) as! UserCell
        cell.configure(with: rows[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let next = factory?.makeUserDetailViewController(user: viewModel.user(at: indexPath.row)) else { return }
        navigationController?.pushViewController(next, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let isFavorite = rows[indexPath.row].isFavorite
        let action = UIContextualAction(style: .normal, title: isFavorite ? "Unfavourite" : "Favourite") { [weak self] _, _, done in
            self?.viewModel.toggleFavorite(at: indexPath.row)
            done(true)
        }
        action.image = UIImage(systemName: isFavorite ? "star.slash" : "star.fill")
        action.backgroundColor = .systemOrange
        return UISwipeActionsConfiguration(actions: [action])
    }
}
