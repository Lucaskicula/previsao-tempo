import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clima_agora/main.dart';
import 'package:clima_agora/services/weather_service.dart';

void main() {
  testWidgets('valida entrada curta sem fazer requisição', (tester) async {
    var calls = 0;
    final service = WeatherService(
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(home: SearchPage(service: service)));
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.text('Buscar cidade'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(
      find.text('Digite pelo menos 3 letras para buscar.'),
      findsOneWidget,
    );
  });
  testWidgets('busca sem resultado mostra orientação', (tester) async {
    final service = WeatherService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(home: SearchPage(service: service)));
    await tester.enterText(find.byType(TextField), 'xxxxzzzz');
    await tester.tap(find.text('Buscar cidade'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhuma cidade encontrada'), findsOneWidget);
  });
}
