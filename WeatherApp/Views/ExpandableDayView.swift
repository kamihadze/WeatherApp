import UIKit

final class ExpandableDayView: UIView {

    var onToggle: (() -> Void)?

    private var isExpanded = false

    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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

    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = .white.withAlphaComponent(0.5)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
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

    private let detailContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private lazy var hourlyCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 90)
        layout.minimumInteritemSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(HourlyForecastCell.self, forCellWithReuseIdentifier: HourlyForecastCell.reuseIdentifier)
        cv.dataSource = self
        return cv
    }()

    private let detailStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var hours: [HourWeather] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(forecastDay: ForecastDay, globalMin: Double, globalMax: Double, isToday: Bool) {
        self.hours = forecastDay.hour

        dayLabel.text = isToday ? "Сегодня" : formatDay(forecastDay.date)
        minTempLabel.text = "\(Int(forecastDay.day.mintempC))°"
        maxTempLabel.text = "\(Int(forecastDay.day.maxtempC))°"

        ImageCache.shared.loadImage(from: forecastDay.day.condition.icon) { [weak self] image in
            self?.iconImageView.image = image
        }

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

        detailStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detailStack.addArrangedSubview(makeDetailItem(title: "Влажность", value: "\(forecastDay.day.avgHumidity)%"))
        detailStack.addArrangedSubview(makeDetailItem(title: "Макс. ветер", value: "\(Int(forecastDay.day.maxwindKph)) км/ч"))
        detailStack.addArrangedSubview(makeDetailItem(title: "Осадки", value: "\(forecastDay.day.totalPrecipMm) мм"))
        detailStack.addArrangedSubview(makeDetailItem(title: "УФ-индекс", value: "\(Int(forecastDay.day.uv))"))

        hourlyCollectionView.reloadData()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let barWidth = tempBar.bounds.width
        fillLeading?.constant = barWidth * leadingFraction
        fillTrailing?.constant = -(barWidth * trailingFraction)
    }

    private func setupUI() {
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        mainStack.addArrangedSubview(headerView)
        mainStack.addArrangedSubview(detailContainer)

        headerView.addSubview(dayLabel)
        headerView.addSubview(iconImageView)
        headerView.addSubview(minTempLabel)
        headerView.addSubview(tempBar)
        headerView.addSubview(maxTempLabel)
        headerView.addSubview(chevronImageView)
        tempBar.addSubview(tempBarFill)

        fillLeading = tempBarFill.leadingAnchor.constraint(equalTo: tempBar.leadingAnchor)
        fillTrailing = tempBarFill.trailingAnchor.constraint(equalTo: tempBar.trailingAnchor)
        fillLeading?.isActive = true
        fillTrailing?.isActive = true

        detailContainer.addSubview(hourlyCollectionView)
        detailContainer.addSubview(detailStack)

        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: 55),

            dayLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            dayLabel.widthAnchor.constraint(equalToConstant: 80),

            iconImageView.leadingAnchor.constraint(equalTo: dayLabel.trailingAnchor, constant: 4),
            iconImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            minTempLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 4),
            minTempLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            minTempLabel.widthAnchor.constraint(equalToConstant: 36),

            tempBar.leadingAnchor.constraint(equalTo: minTempLabel.trailingAnchor, constant: 8),
            tempBar.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            tempBar.heightAnchor.constraint(equalToConstant: 5),

            maxTempLabel.leadingAnchor.constraint(equalTo: tempBar.trailingAnchor, constant: 8),
            maxTempLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            maxTempLabel.widthAnchor.constraint(equalToConstant: 36),

            chevronImageView.leadingAnchor.constraint(equalTo: maxTempLabel.trailingAnchor, constant: 4),
            chevronImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14),

            tempBarFill.topAnchor.constraint(equalTo: tempBar.topAnchor),
            tempBarFill.bottomAnchor.constraint(equalTo: tempBar.bottomAnchor),

            hourlyCollectionView.topAnchor.constraint(equalTo: detailContainer.topAnchor, constant: 4),
            hourlyCollectionView.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
            hourlyCollectionView.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor),
            hourlyCollectionView.heightAnchor.constraint(equalToConstant: 100),

            detailStack.topAnchor.constraint(equalTo: hourlyCollectionView.bottomAnchor, constant: 8),
            detailStack.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor, constant: 16),
            detailStack.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor, constant: -16),
            detailStack.bottomAnchor.constraint(equalTo: detailContainer.bottomAnchor, constant: -8)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        headerView.addGestureRecognizer(tap)
    }

    @objc private func headerTapped() {
        isExpanded.toggle()
        detailContainer.isHidden = !isExpanded

        UIView.animate(withDuration: 0.25) {
            self.chevronImageView.transform = self.isExpanded
                ? CGAffineTransform(rotationAngle: .pi)
                : .identity
        }

        onToggle?()
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

    private func makeDetailItem(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .white.withAlphaComponent(0.6)
        titleLabel.textAlignment = .center

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        return stack
    }
}

extension ExpandableDayView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hours.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HourlyForecastCell.reuseIdentifier,
            for: indexPath
        ) as! HourlyForecastCell
        cell.configure(hour: hours[indexPath.item], isNow: false)
        return cell
    }
}
