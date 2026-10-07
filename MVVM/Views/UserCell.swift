import UIKit

/// VIEW (MVVM): knows how to display a user; knows nothing about where the user came from.
final class UserCell: UITableViewCell {
    static let reuseIdentifier = "UserCell"

    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let emailLabel = UILabel()
    private let starView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        usernameLabel.font = .preferredFont(forTextStyle: .subheadline)
        usernameLabel.textColor = .secondaryLabel
        emailLabel.font = .preferredFont(forTextStyle: .footnote)
        emailLabel.textColor = .secondaryLabel

        starView.image = UIImage(systemName: "star.fill")
        starView.tintColor = .systemYellow
        starView.setContentHuggingPriority(.required, for: .horizontal)

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, starView, UIView()])
        nameRow.spacing = 6
        nameRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [nameRow, usernameLabel, emailLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The cell renders a ready-made row; it does no formatting of its own.
    func configure(with row: UserRowViewModel) {
        nameLabel.text = row.name
        usernameLabel.text = row.username
        emailLabel.text = row.email
        starView.isHidden = !row.isFavorite
    }
}
