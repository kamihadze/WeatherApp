import Foundation

struct ForecastResponse: Decodable {
    let location: Location
    let current: CurrentWeather
    let forecast: Forecast
}

struct Location: Decodable {
    let name: String
    let region: String
    let country: String
    let localtime: String
}

struct CurrentWeather: Decodable {
    let tempC: Double
    let feelslikeC: Double
    let humidity: Int
    let windKph: Double
    let condition: Condition
    let uv: Double

    enum CodingKeys: String, CodingKey {
        case tempC = "temp_c"
        case feelslikeC = "feelslike_c"
        case humidity
        case windKph = "wind_kph"
        case condition
        case uv
    }
}

struct Condition: Decodable {
    let text: String
    let icon: String
    let code: Int
}

struct Forecast: Decodable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Decodable {
    let date: String
    let day: Day
    let hour: [HourWeather]
}

struct Day: Decodable {
    let maxtempC: Double
    let mintempC: Double
    let condition: Condition

    enum CodingKeys: String, CodingKey {
        case maxtempC = "maxtemp_c"
        case mintempC = "mintemp_c"
        case condition
    }
}

struct HourWeather: Decodable {
    let time: String
    let tempC: Double
    let condition: Condition

    enum CodingKeys: String, CodingKey {
        case time
        case tempC = "temp_c"
        case condition
    }
}
