import 'package:flutter/material.dart';
import '../../services/language.dart';
import '../../services/firebase_service.dart';
import '../../widgets/GlassContainer.dart';

class AreasStatisticsPage extends StatefulWidget {
  final LocaleController ctrl;
  const AreasStatisticsPage({super.key, required this.ctrl});

  @override
  State<AreasStatisticsPage> createState() => _AreasStatisticsPageState();
}

class _AreasStatisticsPageState extends State<AreasStatisticsPage> {
  final FirebaseService _firebaseService = FirebaseService.instance;
  Map<String, Map<String, int>> _cityAreaCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreaStatistics();
  }

  Future<void> _loadAreaStatistics() async {
    try {
      setState(() => _isLoading = true);

      // Get all users
      final users = await _firebaseService.getAllUsers();

      // Count areas by city
      Map<String, Map<String, int>> cityAreaCounts = {};

      for (var user in users) {
        final city = user['city'] as String? ?? 'Unknown';
        final area = user['area'] as String? ?? 'Unknown';

        if (!cityAreaCounts.containsKey(city)) {
          cityAreaCounts[city] = {};
        }

        cityAreaCounts[city]![area] = (cityAreaCounts[city]![area] ?? 0) + 1;
      }

      setState(() {
        _cityAreaCounts = cityAreaCounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading area statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, child) {
        final ar = widget.ctrl.isArabic;
        final theme = Theme.of(context);

        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.textTheme.bodyMedium?.color ?? Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                ar ? 'إحصائيات المناطق' : 'Areas Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAreaStatistics,
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cityAreaCounts.isEmpty
                ? Center(
                    child: Text(
                      ar ? 'لا توجد بيانات' : 'No data available',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(theme, ar),
                      const SizedBox(height: 16),
                      ..._cityAreaCounts.entries.map(
                        (cityEntry) => _buildCityCard(
                          cityEntry.key,
                          cityEntry.value,
                          theme,
                          ar,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool ar) {
    int totalPlayers = 0;
    int totalCities = _cityAreaCounts.length;
    int totalAreas = 0;

    _cityAreaCounts.forEach((city, areas) {
      totalAreas += areas.length;
      areas.forEach((area, count) {
        totalPlayers += count;
      });
    });

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              ar ? 'ملخص عام' : 'Overall Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  totalPlayers.toString(),
                  ar ? 'لاعبين' : 'Players',
                  Icons.people,
                  theme,
                ),
                _buildStat(
                  totalCities.toString(),
                  ar ? 'مدن' : 'Cities',
                  Icons.location_city,
                  theme,
                ),
                _buildStat(
                  totalAreas.toString(),
                  ar ? 'مناطق' : 'Areas',
                  Icons.map,
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    String value,
    String label,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildCityCard(
    String city,
    Map<String, int> areas,
    ThemeData theme,
    bool ar,
  ) {
    int totalInCity = areas.values.fold(0, (sum, count) => sum + count);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          city,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          ar ? '$totalInCity لاعب' : '$totalInCity players',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: areas.entries.map((areaEntry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            areaEntry.key,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${areaEntry.value}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
