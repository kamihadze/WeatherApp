import UIKit

final class DailyForecastView: UIView {

    private let daysStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(daysStack)
        NSLayoutConstraint.activate([
            daysStack.topAnchor.constraint(equalTo: topAnchor),
            daysStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            daysStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            daysStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(forecastDays: [ForecastDay]) {
        daysStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let globalMin = forecastDays.map(\.day.mintempC).min() ?? 0
        let globalMax = forecastDays.map(\.day.maxtempC).max() ?? 0

        for (index, day) in forecastDays.enumerated() {
            let item = ExpandableDayView()
            item.configure(
                forecastDay: day,
                globalMin: globalMin,
                globalMax: globalMax,
                isToday: index == 0
            )
            item.onToggle = { [weak self] in
                UIView.animate(withDuration: 0.3) {
                    self?.layoutIfNeeded()
                    self?.superview?.layoutIfNeeded()
                }
            }

            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = .white.withAlphaComponent(0.2)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

                let container = UIView()
                container.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                    separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                    separator.topAnchor.constraint(equalTo: container.topAnchor),
                    separator.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
                daysStack.addArrangedSubview(container)
            }

            daysStack.addArrangedSubview(item)
        }
    }
}
