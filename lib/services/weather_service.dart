import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherException implements Exception {
  const WeatherException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  // Future representa um resultado que chegará depois da requisição HTTP.
  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const WeatherException(
          'O serviço está indisponível. Tente novamente.',
        );
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic> || json['error'] == true) {
        throw const FormatException('Resposta inválida');
      }
      return json;
    } on WeatherException {
      rethrow;
    } on TimeoutException {
      throw const WeatherException(
        'A consulta demorou demais. Tente novamente.',
      );
    } on FormatException {
      throw const WeatherException(
        'O serviço retornou dados inválidos. Tente novamente.',
      );
    } catch (_) {
      throw const WeatherException(
        'Não foi possível conectar. Verifique sua internet e tente novamente.',
      );
    }
  }

  Future<List<City>> searchCities(String name) async {
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': name.trim(),
        'count': '10',
        'language': 'pt',
        'format': 'json',
      }),
    );
    try {
      return ((json['results'] ?? []) as List)
          .map((item) => City.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const WeatherException(
        'Não foi possível interpretar a lista de cidades.',
      );
    }
  }

  Future<Weather> forecast(City city) async {
    final json = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${city.latitude}',
        'longitude': '${city.longitude}',
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto',
        'forecast_days': '7',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
      }),
    );
    try {
      final weather = Weather.fromJson(json);
      if (weather.days.isEmpty) throw const FormatException('Sem previsão');
      return weather;
    } catch (_) {
      throw const WeatherException(
        'Não foi possível interpretar a previsão. Tente novamente.',
      );
    }
  }

  void close() => _client.close();
}
