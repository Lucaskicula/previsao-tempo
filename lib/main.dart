import 'package:flutter/material.dart';

import 'models/weather.dart';
import 'services/weather_service.dart';

void main() => runApp(const WeatherApp());
const ink = Color(0xFF17334A);
const blue = Color(0xFF126EBA);

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Clima Agora',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: const Color(0xFFF3F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF3F7FA),
        foregroundColor: ink,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    home: const SearchPage(),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.service});
  final WeatherService? service;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final WeatherService service = widget.service ?? WeatherService();
  final controller = TextEditingController();
  List<City>? cities;
  bool loading = false;
  String? error;
  String searched = '';
  int requestId = 0;
  @override
  void dispose() {
    controller.dispose();
    if (widget.service == null) service.close();
    super.dispose();
  }

  Future<void> search([String? suggestion]) async {
    if (suggestion != null) controller.text = suggestion;
    final query = controller.text.trim();
    final id = ++requestId;
    FocusScope.of(context).unfocus();
    if (query.length < 3) {
      setState(() {
        error = 'Digite pelo menos 3 letras para buscar.';
        loading = false;
        cities = null;
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
      cities = null;
      searched = query;
    });
    try {
      final result = await service.searchCities(query);
      if (!mounted || id != requestId) return;
      setState(() => cities = result);
    } on WeatherException catch (e) {
      if (!mounted || id != requestId) return;
      setState(() => error = e.message);
    } finally {
      if (mounted && id == requestId) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Clima Agora'),
      actions: [
        IconButton(
          tooltip: 'Sobre o aplicativo',
          onPressed: () => showAboutDialog(
            context: context,
            applicationName: 'Clima Agora',
            applicationVersion: '1.0.0',
            children: const [
              Text(
                'Projeto Flutter com API REST, JSON e métodos assíncronos.\n\n'
                'Dados meteorológicos: Open-Meteo (CC BY 4.0).\nhttps://open-meteo.com/\n\n'
                'Localidades: GeoNames via Open-Meteo.\nhttps://www.geonames.org/',
              ),
            ],
          ),
          icon: const Icon(Icons.info_outline),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFE0EFFB),
                child: Icon(Icons.wb_sunny_outlined, color: blue, size: 34),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Seu próximo dia\ncomeça aqui.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Busque uma cidade e descubra o que o tempo reserva.',
              style: TextStyle(
                color: Color(0xFF5B7183),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => search(),
              decoration: const InputDecoration(
                labelText: 'Nome da cidade',
                hintText: 'Ex.: Curitiba',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : () => search(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.travel_explore),
              label: const Text('Buscar cidade'),
            ),
            const SizedBox(height: 26),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Buscando cidades…'),
                  ],
                ),
              )
            else if (error != null)
              Notice(
                icon: Icons.wifi_off_rounded,
                text: error!,
                action: searched.isNotEmpty ? () => search() : null,
              )
            else if (cities != null && cities!.isEmpty)
              Notice(
                icon: Icons.location_off_outlined,
                text:
                    'Nenhuma cidade encontrada para “$searched”. Confira o nome e tente novamente.',
              )
            else if (cities != null) ...[
              Text(
                'Escolha a cidade',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text('Confira o estado e o país antes de continuar.'),
              const SizedBox(height: 14),
              ...cities!.map(
                (city) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: blue,
                      ),
                      title: Text(
                        city.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(city.subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ForecastPage(city: city, service: service),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'EXPLORE UMA CIDADE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B7183),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['São Paulo', 'Curitiba', 'Rio de Janeiro']
                    .map(
                      (city) => ActionChip(
                        label: Text(city),
                        onPressed: () => search(city),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
              const Notice(
                icon: Icons.calendar_month_outlined,
                text: 'Planeje a semana com as condições atuais e a previsão dos próximos 7 dias.',
              ),
            ],
            const SizedBox(height: 28),
            const Attribution(),
          ],
        ),
      ),
    ),
  );
}

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key, required this.city, required this.service});
  final City city;
  final WeatherService service;
  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  late Future<Weather> forecast = widget.service.forecast(widget.city);
  void refresh() =>
      setState(() => forecast = widget.service.forecast(widget.city));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Previsão do tempo'),
      actions: [
        IconButton(
          onPressed: refresh,
          tooltip: 'Atualizar previsão',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Weather>(
      future: forecast,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Consultando a previsão…'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Notice(
                icon: Icons.cloud_off_outlined,
                text: snapshot.error.toString(),
                action: refresh,
              ),
            ),
          );
        }
        final weather = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              children: [
                Text(
                  widget.city.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  widget.city.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5B7183),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: weather.isDay
                          ? const [Color(0xFF087DC1), Color(0xFF144B8A)]
                          : const [Color(0xFF334873), Color(0xFF182744)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AGORA',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${weather.temperature.round()}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 76,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          Icon(
                            weatherIcon(weather.code, isDay: weather.isDay),
                            color: const Color(0xFFFFDB78),
                            size: 72,
                          ),
                        ],
                      ),
                      Text(
                        weatherDescription(weather.code, isDay: weather.isDay),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Máx. ${weather.days.first.maximum.round()}°  •  Mín. ${weather.days.first.minimum.round()}°',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Metric(
                          width: width,
                          icon: Icons.thermostat_outlined,
                          label: 'Sensação',
                          value: '${weather.feelsLike.round()} °C',
                        ),
                        Metric(
                          width: width,
                          icon: Icons.water_drop_outlined,
                          label: 'Umidade',
                          value: '${weather.humidity}%',
                        ),
                        Metric(
                          width: width,
                          icon: Icons.air,
                          label: 'Vento',
                          value: '${weather.wind.toStringAsFixed(1)} km/h',
                        ),
                        Metric(
                          width: width,
                          icon: Icons.umbrella_outlined,
                          label: 'Chuva hoje',
                          value: weather.days.first.rain == null
                              ? 'Indisponível'
                              : '${weather.days.first.rain}%',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  'Próximos 7 dias',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Máximas, mínimas e chance de chuva.',
                  style: TextStyle(color: Color(0xFF5B7183)),
                ),
                const SizedBox(height: 14),
                ...weather.days.indexed.map(
                  (entry) => DayTile(day: entry.$2, today: entry.$1 == 0),
                ),
                const SizedBox(height: 20),
                Text(
                  'Dados de ${dateLabel(weather.time)} às ${timeLabel(weather.time)}\nFuso da cidade: ${weather.timezone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5B7183),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                const Attribution(),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric({
    super.key,
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });
  final double width;
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: blue, size: 22),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Color(0xFF5B7183))),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class DayTile extends StatelessWidget {
  const DayTile({super.key, required this.day, required this.today});
  final ForecastDay day;
  final bool today;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(weatherIcon(day.code), color: blue, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                today
                    ? 'Hoje'
                    : '${weekday(day.date)} · ${dateLabel(day.date)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
              ),
              Text(
                weatherDescription(day.code),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5B7183)),
              ),
              Text(
                day.rain == null
                    ? 'Chuva: indisponível'
                    : 'Chuva: ${day.rain}%',
                style: const TextStyle(fontSize: 12, color: blue),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${day.maximum.round()}° / ${day.minimum.round()}°',
          style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
        ),
      ],
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });
  final IconData icon;
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EFF7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon, color: blue, size: 32),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ink, height: 1.5),
        ),
        if (action != null)
          TextButton(onPressed: action, child: const Text('Tentar novamente')),
      ],
    ),
  );
}

class Attribution extends StatelessWidget {
  const Attribution({super.key});
  @override
  Widget build(BuildContext context) => const Text(
    'Dados: Open-Meteo · Localidades: GeoNames\nopen-meteo.com · CC BY 4.0',
    textAlign: TextAlign.center,
    style: TextStyle(color: Color(0xFF5B7183), fontSize: 11, height: 1.6),
  );
}

IconData weatherIcon(int code, {bool isDay = true}) => switch (code) {
  0 || 1 => isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
  2 => Icons.cloud_queue,
  3 => Icons.cloud,
  45 || 48 => Icons.foggy,
  >= 71 && <= 77 || 85 || 86 => Icons.ac_unit,
  >= 95 => Icons.thunderstorm_outlined,
  >= 51 && <= 82 => Icons.grain,
  _ => Icons.cloud_outlined,
};
String weekday(DateTime date) =>
    ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][date.weekday - 1];
String dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
String timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
