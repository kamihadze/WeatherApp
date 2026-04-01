import UIKit

final class HourlyForecastCell: UICollectionViewCell {

    static let reuseIdentifier = "HourlyForecastCell"

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(hour: HourWeather, isNow: Bool) {
        timeLabel.text = isNow ? "Сейчас" : formatTime(hour.time)
        tempLabel.text = "\(Int(hour.tempC))°"
        loadIcon(from: hour.condition.icon)
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [timeLabel, iconImageView, tempLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    private func formatTime(_ timeString: String) -> String {
        let parts = timeString.split(separator: " ")
        guard parts.count == 2 else { return timeString }
        let timeParts = parts[1].split(separator: ":")
        guard let hour = timeParts.first else { return timeString }
        return "\(hour):00"
    }

    private func loadIcon(from urlString: String) {
        ImageCache.shared.loadImage(from: urlString) { [weak self] image in
            self?.iconImageView.image = image
        }
    }
}
