# Clima Agora

Aplicativo Flutter para consultar as condições atuais e a previsão de sete dias de uma cidade. Projeto acadêmico sobre API REST, requisições HTTP, JSON e métodos assíncronos.

Repositório: https://github.com/Lucaskicula/previsao-tempo

## Funcionalidades

- Busca de cidades pelo nome, com estado e país para escolher a localidade correta.
- Temperatura em Celsius, sensação térmica, umidade e velocidade do vento em km/h.
- Previsão de sete dias incluindo hoje, com máximas, mínimas e probabilidade de chuva.
- Atualização manual da previsão e horário dos dados no fuso da cidade.
- Estados de carregamento, entrada inválida, busca sem resultados, falha de conexão e nova tentativa.
- Interface em português e layout adaptável a celular e navegador.

## Executar

Ambiente validado: Flutter 3.47.2 e Dart 3.13.2. Instale o Flutter e execute `flutter doctor` para verificar os requisitos da plataforma.

```sh
flutter pub get
flutter run -d chrome
```

Para Android, conecte um celular com depuração USB ou inicie um emulador e execute:

```sh
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

Para gerar um APK, com Android SDK e Java configurados:

```sh
flutter build apk --release
```

O APK é gerado em `build/app/outputs/flutter-apk/app-release.apk`. A permissão de internet já está no manifesto principal do Android, inclusive para release. O projeto inclui Android e Web; as capturas entregues são da versão web em viewport de celular, e não de um emulador Android.

## API utilizada

**Open-Meteo**: https://open-meteo.com/

Não requer chave de API para este uso acadêmico não comercial. O app usa dois endpoints REST GET:

1. Geocodificação: `https://geocoding-api.open-meteo.com/v1/search`
   - Parâmetros: `name`, `count=10`, `language=pt`, `format=json`.
   - Documentação: https://open-meteo.com/en/docs/geocoding-api
2. Previsão: `https://api.open-meteo.com/v1/forecast`
   - Parâmetros: `latitude`, `longitude`, `current`, `daily`, `timezone=auto`, `forecast_days=7`, `temperature_unit=celsius`, `wind_speed_unit=kmh`.
   - Documentação: https://open-meteo.com/en/docs

Dados meteorológicos: Open-Meteo, CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Localidades: GeoNames, via Open-Meteo (https://www.geonames.org/). O app apresenta essas atribuições no rodapé e na opção Sobre.

As condições atuais são fornecidas pelo modelo meteorológico da API. A chance de chuva diária representa a probabilidade máxima do dia; não representa volume de precipitação. Sem internet, as consultas exibem erro; não há cache offline, cadastro ou localização GPS.

## Organização e conceitos

| Arquivo | Responsabilidade |
| --- | --- |
| `lib/main.dart` | Telas, navegação, estados e widgets da interface |
| `lib/models/weather.dart` | Modelos City, Weather e ForecastDay; conversão do JSON e códigos WMO |
| `lib/services/weather_service.dart` | Montagem das URLs, HTTP GET, timeout e tratamento de erros |
| `test/` | Testes do serviço HTTP e dos estados de busca |

O serviço retorna `Future`, usa `async/await` para aguardar as respostas sem bloquear a interface e transforma o corpo JSON em objetos Dart com `jsonDecode` e fábricas `fromJson`. A busca atualiza a tela com `setState`; a previsão é apresentada com `FutureBuilder`. Cada requisição tem limite de 15 segundos. A interface descarta respostas antigas da busca e verifica `mounted` antes de atualizar um widget após uma operação assíncrona.

## Verificar

```sh
flutter analyze
flutter test
flutter build web --release
```

Os testes usam um cliente HTTP simulado para verificar parâmetros das URLs, leitura de JSON UTF-8, ausência de resultados, valores nulos de chuva, erros HTTP, timeout, falha de conexão e validação de entrada. Os dados exibidos no aplicativo vêm da API externa.

## Entrega

O código-fonte está neste repositório. O [relatório PDF](docs/relatorio-clima-agora.pdf) contém seis capturas reais e a identificação da API. As [capturas originais](docs/capturas/) também estão disponíveis. Consulte o documento para ver o aplicativo funcionando.
