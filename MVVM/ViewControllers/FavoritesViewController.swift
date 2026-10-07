import UIKit

/// SCREEN 2. Favourites come from the repository (Core Data) via the view model, so no network is needed.
final class FavoritesViewController: UITableViewController {
    private let viewModel: FavoritesViewModel
    private weak var factory: ScreenFactory?
    private let stateView = StateView()
    private var rows: [UserRowViewModel] = []

    init(viewModel: FavoritesViewModel, factory: ScreenFactory) {
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

        bind({ [viewModel] in viewModel.rows }) { [weak self] rows in
            self?.rows = rows
            self?.tableView.reloadData()
        }

        bind({ [viewModel] in viewModel.state }) { [weak self] state in
            if case .empty(let message) = state {
                self?.stateView.render(.message(symbol: "star", text: message, actionTitle: nil))
            } else {
                self?.stateView.render(.hidden)
            }
        }
    }

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

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete { viewModel.remove(at: indexPath.row) }
    }

    override func tableView(_ tableView: UITableView,
                            titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? { "Remove" }
}
