class City {
  const City({
    required this.name,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
  final String name, region, country;
  final double latitude, longitude;
  String get subtitle =>
      [region, country].where((s) => s.isNotEmpty).join(', ');
  factory City.fromJson(Map<String, dynamic> json) => City(
    name: json['name'] as String,
    region: json['admin1'] as String? ?? '',
    country: json['country'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}

class ForecastDay {
  const ForecastDay(
    this.date,
    this.code,
    this.minimum,
    this.maximum,
    this.rain,
  );
  final DateTime date;
  final int code;
  final double minimum, maximum;
  final int? rain;
}

class Weather {
  const Weather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.code,
    required this.isDay,
    required this.time,
    required this.timezone,
    required this.days,
  });
  final double temperature, feelsLike, wind;
  final int humidity, code;
  final bool isDay;
  // A hora recebida já está no fuso da cidade; não converter para o fuso do aparelho.
  final DateTime time;
  final String timezone;
  final List<ForecastDay> days;
  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List;
    return Weather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      wind: (current['wind_speed_10m'] as num).toDouble(),
      code: (current['weather_code'] as num).toInt(),
      isDay: current['is_day'] == 1,
      time: DateTime.parse(current['time'] as String),
      timezone: json['timezone'] as String,
      days: List.generate(
        dates.length,
        (i) => ForecastDay(
          DateTime.parse(dates[i] as String),
          (daily['weather_code'][i] as num).toInt(),
          (daily['temperature_2m_min'][i] as num).toDouble(),
          (daily['temperature_2m_max'][i] as num).toDouble(),
          (daily['precipitation_probability_max'][i] as num?)?.toInt(),
        ),
      ),
    );
  }
}

String weatherDescription(int code, {bool isDay = true}) => switch (code) {
  0 => isDay ? 'Céu limpo' : 'Noite de céu limpo',
  1 => 'Predominantemente limpo',
  2 => 'Parcialmente nublado',
  3 => 'Nublado',
  45 || 48 => 'Nevoeiro',
  51 || 53 || 55 => 'Garoa',
  56 || 57 => 'Garoa congelante',
  61 || 63 || 65 => 'Chuva',
  66 || 67 => 'Chuva congelante',
  71 || 73 || 75 || 77 => 'Neve',
  80 || 81 || 82 => 'Pancadas de chuva',
  85 || 86 => 'Pancadas de neve',
  95 || 96 || 99 => 'Trovoadas',
  _ => 'Condição não informada',
};
