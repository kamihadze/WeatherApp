import UIKit

final class CurrentWeatherView: UIView {

    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 96, weight: .thin)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let conditionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let highLowLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let detailsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(current: CurrentWeather, location: Location, today: ForecastDay) {
        cityLabel.text = location.name
        temperatureLabel.text = "\(Int(current.tempC))°"
        conditionLabel.text = current.condition.text
        highLowLabel.text = "Макс.: \(Int(today.day.maxtempC))°, мин.: \(Int(today.day.mintempC))°"

        detailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detailsStack.addArrangedSubview(makeDetailItem(title: "Ощущается", value: "\(Int(current.feelslikeC))°"))
        detailsStack.addArrangedSubview(makeDetailItem(title: "Влажность", value: "\(current.humidity)%"))
        detailsStack.addArrangedSubview(makeDetailItem(title: "Ветер", value: "\(Int(current.windKph)) км/ч"))
        detailsStack.addArrangedSubview(makeDetailItem(title: "УФ-индекс", value: "\(Int(current.uv))"))
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [cityLabel, temperatureLabel, conditionLabel, highLowLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.setCustomSpacing(8, after: highLowLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        addSubview(detailsStack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            detailsStack.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
            detailsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            detailsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            detailsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeDetailItem(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white.withAlphaComponent(0.7)
        titleLabel.textAlignment = .center

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }
}
