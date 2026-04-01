import UIKit

final class WeatherViewController: UIViewController {

    private enum State {
        case loading
        case loaded(ForecastResponse)
        case error(String)
    }

    private let locationService = LocationService()
    private let weatherService = WeatherService()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let currentWeatherView = CurrentWeatherView()
    private let hourlyTitleView = WeatherViewController.makeSectionTitle("ПОЧАСОВОЙ ПРОГНОЗ")

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

    private let dailyTitleView = WeatherViewController.makeSectionTitle("ПРОГНОЗ НА 3 ДНЯ")

    private let dailyForecastView: DailyForecastView = {
        let view = DailyForecastView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let errorView: ErrorView = {
        let view = ErrorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private var hourlyData: [HourWeather] = []

    private let gradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupLayout()
        setupErrorHandler()
        locationService.delegate = self
        updateState(.loading)
        locationService.requestLocation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.28, green: 0.52, blue: 0.83, alpha: 1.0).cgColor,
            UIColor(red: 0.18, green: 0.36, blue: 0.68, alpha: 1.0).cgColor,
            UIColor(red: 0.12, green: 0.24, blue: 0.50, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(loadingIndicator)
        view.addSubview(errorView)

        currentWeatherView.translatesAutoresizingMaskIntoConstraints = false
        hourlyTitleView.translatesAutoresizingMaskIntoConstraints = false
        hourlyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        dailyTitleView.translatesAutoresizingMaskIntoConstraints = false

        let hourlySeparator = makeSeparator()
        let dailySeparator = makeSeparator()

        contentStack.addArrangedSubview(currentWeatherView)
        contentStack.addArrangedSubview(hourlySeparator)
        contentStack.addArrangedSubview(hourlyTitleView)
        contentStack.addArrangedSubview(hourlyCollectionView)
        contentStack.addArrangedSubview(dailySeparator)
        contentStack.addArrangedSubview(dailyTitleView)
        contentStack.addArrangedSubview(dailyForecastView)

        contentStack.setCustomSpacing(24, after: currentWeatherView)
        contentStack.setCustomSpacing(8, after: hourlyTitleView)
        contentStack.setCustomSpacing(8, after: dailyTitleView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            hourlyCollectionView.heightAnchor.constraint(equalToConstant: 100),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupErrorHandler() {
        errorView.onRetry = { [weak self] in
            self?.updateState(.loading)
            self?.locationService.requestLocation()
        }
    }

    private func updateState(_ state: State) {
        switch state {
        case .loading:
            loadingIndicator.startAnimating()
            scrollView.isHidden = true
            errorView.isHidden = true

        case .loaded(let data):
            loadingIndicator.stopAnimating()
            scrollView.isHidden = false
            errorView.isHidden = true
            populateUI(with: data)

        case .error(let message):
            loadingIndicator.stopAnimating()
            scrollView.isHidden = true
            errorView.isHidden = false
            errorView.configure(message: message)
        }
    }

    private func populateUI(with data: ForecastResponse) {
        guard let today = data.forecast.forecastday.first else { return }
        currentWeatherView.configure(current: data.current, location: data.location, today: today)
        hourlyData = buildHourlyData(from: data)
        hourlyCollectionView.reloadData()
        dailyForecastView.configure(forecastDays: data.forecast.forecastday)
    }

    private func buildHourlyData(from data: ForecastResponse) -> [HourWeather] {
        let currentHour = extractCurrentHour(from: data.location.localtime)
        var hours: [HourWeather] = []

        if let today = data.forecast.forecastday.first {
            let remaining = today.hour.filter { extractHour(from: $0.time) >= currentHour }
            hours.append(contentsOf: remaining)
        }

        if data.forecast.forecastday.count > 1 {
            hours.append(contentsOf: data.forecast.forecastday[1].hour)
        }

        return hours
    }

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func extractCurrentHour(from localtime: String) -> Int {
        guard let date = Self.dateTimeFormatter.date(from: localtime) else { return 0 }
        return Calendar.current.component(.hour, from: date)
    }

    private func extractHour(from timeString: String) -> Int {
        guard let date = Self.dateTimeFormatter.date(from: timeString) else { return 0 }
        return Calendar.current.component(.hour, from: date)
    }

    private static func makeSectionTitle(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.6)
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .white.withAlphaComponent(0.2)
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
        return container
    }
}

extension WeatherViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hourlyData.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HourlyForecastCell.reuseIdentifier,
            for: indexPath
        ) as! HourlyForecastCell
        cell.configure(hour: hourlyData[indexPath.item], isNow: indexPath.item == 0)
        return cell
    }
}

extension WeatherViewController: LocationServiceDelegate {

    func locationService(_ service: LocationService, didUpdateLocation latitude: Double, longitude: Double) {
        weatherService.fetchForecast(latitude: latitude, longitude: longitude) { [weak self] result in
            switch result {
            case .success(let data):
                self?.updateState(.loaded(data))
            case .failure(let error):
                self?.updateState(.error(error.localizedDescription))
            }
        }
    }

    func locationService(_ service: LocationService, didFailWithError error: Error) {
        updateState(.error("Не удалось определить местоположение"))
    }
}
