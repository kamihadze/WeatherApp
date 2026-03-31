import UIKit

final class DailyForecastCell: UITableViewCell {

    static let reuseIdentifier = "DailyForecastCell"

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
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

    private let minTempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.6)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let maxTempLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tempBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        view.backgroundColor = .white.withAlphaComponent(0.2)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tempBarFill: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var leadingFraction: CGFloat = 0
    private var trailingFraction: CGFloat = 0
    private var fillLeading: NSLayoutConstraint?
    private var fillTrailing: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(forecastDay: ForecastDay, globalMin: Double, globalMax: Double, isToday: Bool) {
        dayLabel.text = isToday ? "Сегодня" : formatDay(forecastDay.date)
        minTempLabel.text = "\(Int(forecastDay.day.mintempC))°"
        maxTempLabel.text = "\(Int(forecastDay.day.maxtempC))°"
        loadIcon(from: forecastDay.day.condition.icon)

        let range = globalMax - globalMin
        if range > 0 {
            leadingFraction = CGFloat((forecastDay.day.mintempC - globalMin) / range)
            trailingFraction = CGFloat((globalMax - forecastDay.day.maxtempC) / range)
        } else {
            leadingFraction = 0
            trailingFraction = 0
        }

        let avgTemp = (forecastDay.day.mintempC + forecastDay.day.maxtempC) / 2
        tempBarFill.backgroundColor = colorForTemperature(avgTemp)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let barWidth = tempBar.bounds.width
        fillLeading?.constant = barWidth * leadingFraction
        fillTrailing?.constant = -(barWidth * trailingFraction)
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(dayLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(minTempLabel)
        contentView.addSubview(tempBar)
        contentView.addSubview(maxTempLabel)
        tempBar.addSubview(tempBarFill)

        fillLeading = tempBarFill.leadingAnchor.constraint(equalTo: tempBar.leadingAnchor)
        fillTrailing = tempBarFill.trailingAnchor.constraint(equalTo: tempBar.trailingAnchor)
        fillLeading?.isActive = true
        fillTrailing?.isActive = true

        NSLayoutConstraint.activate([
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dayLabel.widthAnchor.constraint(equalToConstant: 90),

            iconImageView.leadingAnchor.constraint(equalTo: dayLabel.trailingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            minTempLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            minTempLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            minTempLabel.widthAnchor.constraint(equalToConstant: 36),

            tempBar.leadingAnchor.constraint(equalTo: minTempLabel.trailingAnchor, constant: 8),
            tempBar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tempBar.heightAnchor.constraint(equalToConstant: 5),

            maxTempLabel.leadingAnchor.constraint(equalTo: tempBar.trailingAnchor, constant: 8),
            maxTempLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            maxTempLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            maxTempLabel.widthAnchor.constraint(equalToConstant: 36),

            tempBarFill.topAnchor.constraint(equalTo: tempBar.topAnchor),
            tempBarFill.bottomAnchor.constraint(equalTo: tempBar.bottomAnchor)
        ])
    }

    private func formatDay(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ru_RU")
        guard let date = formatter.date(from: dateString) else { return dateString }
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ru_RU")
        dayFormatter.dateFormat = "EE"
        return dayFormatter.string(from: date).capitalized
    }

    private func colorForTemperature(_ temp: Double) -> UIColor {
        switch temp {
        case ..<(-10): return UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        case -10..<0: return UIColor(red: 0.5, green: 0.75, blue: 1.0, alpha: 1.0)
        case 0..<10: return UIColor(red: 0.6, green: 0.85, blue: 0.6, alpha: 1.0)
        case 10..<20: return UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        case 20..<30: return UIColor(red: 1.0, green: 0.65, blue: 0.2, alpha: 1.0)
        default: return UIColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)
        }
    }

    private func loadIcon(from urlString: String) {
        let fullURL = urlString.hasPrefix("http") ? urlString : "https:\(urlString)"
        guard let url = URL(string: fullURL) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.iconImageView.image = image
            }
        }.resume()
    }
}
