import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clima_agora/models/weather.dart';
import 'package:clima_agora/services/weather_service.dart';

void main() {
  const city = City(
    name: 'Curitiba',
    region: 'Paraná',
    country: 'Brasil',
    latitude: -25.43,
    longitude: -49.27,
  );
  test('busca codifica o nome e converte JSON UTF-8', () async {
    final service = WeatherService(
      client: MockClient((request) async {
        expect(request.url.host, 'geocoding-api.open-meteo.com');
        expect(request.url.queryParameters['name'], 'São Paulo');
        expect(request.url.queryParameters['language'], 'pt');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'results': [
                {
                  'name': 'São Paulo',
                  'admin1': 'São Paulo',
                  'country': 'Brasil',
                  'latitude': -23.55,
                  'longitude': -46.63,
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(service.close);
    final result = await service.searchCities(' São Paulo ');
    expect(result.single.name, 'São Paulo');
    expect(result.single.latitude, -23.55);
  });
  test('busca sem resultados retorna lista vazia', () async {
    final service = WeatherService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(service.close);
    expect(await service.searchCities('xxxxzzzz'), isEmpty);
  });
  test(
    'previsão usa coordenadas, unidades e fuso e trata chance de chuva nula',
    () async {
      final service = WeatherService(
        client: MockClient((request) async {
          expect(request.url.queryParameters['latitude'], '-25.43');
          expect(request.url.queryParameters['timezone'], 'auto');
          expect(request.url.queryParameters['forecast_days'], '7');
          expect(request.url.queryParameters['temperature_unit'], 'celsius');
          return http.Response(
            jsonEncode({
              'timezone': 'America/Sao_Paulo',
              'current': {
                'temperature_2m': 22,
                'apparent_temperature': 23.1,
                'relative_humidity_2m': 60,
                'wind_speed_10m': 10,
                'weather_code': 2,
                'is_day': 1,
                'time': '2026-11-05T14:30',
              },
              'daily': {
                'time': ['2026-11-05'],
                'weather_code': [3],
                'temperature_2m_min': [16],
                'temperature_2m_max': [25.5],
                'precipitation_probability_max': [null],
              },
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      final result = await service.forecast(city);
      expect(result.temperature, 22.0);
      expect(result.time.hour, 14);
      expect(result.days.single.maximum, 25.5);
      expect(result.days.single.rain, isNull);
    },
  );
  for (final status in [400, 429, 500]) {
    test('HTTP $status produz mensagem amigável', () async {
      final service = WeatherService(
        client: MockClient((_) async => http.Response('', status)),
      );
      addTearDown(service.close);
      await expectLater(
        service.searchCities('Curitiba'),
        throwsA(isA<WeatherException>()),
      );
    });
  }
  test('resposta inválida e falta de conexão são tratadas', () async {
    for (final body in ['not json', '{"results":42}']) {
      final service = WeatherService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        service.searchCities('Curitiba'),
        throwsA(isA<WeatherException>()),
      );
      service.close();
    }
    final offline = WeatherService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(offline.close);
    await expectLater(offline.forecast(city), throwsA(isA<WeatherException>()));
  });
  test('timeout é convertido para mensagem de nova tentativa', () async {
    final service = WeatherService(
      client: MockClient((_) async => throw TimeoutException('timeout')),
    );
    addTearDown(service.close);
    await expectLater(
      service.searchCities('Curitiba'),
      throwsA(
        isA<WeatherException>().having(
          (e) => e.message,
          'message',
          contains('demorou'),
        ),
      ),
    );
  });
  test('códigos WMO distinguem noite, neve e trovoadas', () {
    expect(weatherDescription(0, isDay: false), 'Noite de céu limpo');
    expect(weatherDescription(75), 'Neve');
    expect(weatherDescription(99), 'Trovoadas');
    expect(weatherDescription(999), 'Condição não informada');
  });
}
