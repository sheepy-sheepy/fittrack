import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/body_measurement.dart' as app_measurement;
import '../../models/photo_entry.dart' as app_photo;
import '../../models/user_profile.dart' as app_profile;
import '../../models/gender.dart';
import '../../services/local_database/local_database.dart';
import '../../services/calculation_service.dart';

enum AnalyticsType {
  bodyFat,
  weight,
  waist,
  hip,
  neck,
  photos,
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsType _selectedType = AnalyticsType.weight;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<app_measurement.BodyMeasurement> _measurements = [];
  List<app_photo.PhotoEntry> _photos = [];
  app_profile.UserProfile? _profile;
  bool _isLoading = true;

  final LocalDatabase _localDb = LocalDatabase();
  final CalculationService _calculationService = CalculationService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _profile = await _localDb.profileDao.getProfile(session.user.id);
        final measurements = await _localDb.measurementDao.getMeasurements(
          session.user.id,
          startDate: _startDate,
          endDate: _endDate,
        );
        _measurements =
            measurements.cast<app_measurement.BodyMeasurement>().toList();

        final photos = await _localDb.photoDao.getPhotoEntries(
          session.user.id,
          startDate: _startDate,
          endDate: _endDate,
        );
        _photos = photos.cast<app_photo.PhotoEntry>().toList();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadData();
    }
  }

  List<FlSpot> _getSpots() {
    final spots = <FlSpot>[];

    for (int i = 0; i < _measurements.length; i++) {
      final m = _measurements[i];
      double value = 0;

      switch (_selectedType) {
        case AnalyticsType.bodyFat:
          if (_profile != null) {
            value = _calculationService.calculateBodyFatPercentage(
              _profile!.gender == 'male' ? Gender.male : Gender.female,
              _profile!.height,
              m.neck,
              m.waist,
              m.hip,
            );
          }
          break;
        case AnalyticsType.weight:
          value = m.weight;
          break;
        case AnalyticsType.waist:
          value = m.waist;
          break;
        case AnalyticsType.hip:
          value = m.hip;
          break;
        case AnalyticsType.neck:
          value = m.neck;
          break;
        case AnalyticsType.photos:
          return [];
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: AnalyticsType.values.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  label: Text(_getTypeName(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && mounted) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Период:'),
                  Text(
                    '${DateFormat('dd.MM.yyyy').format(_startDate)} - '
                    '${DateFormat('dd.MM.yyyy').format(_endDate)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedType == AnalyticsType.photos
                ? _buildPhotosComparison()
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final spots = _getSpots();

    if (spots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет данных за выбранный период',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _getTypeName(_selectedType),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _measurements.length) {
                          return Text(
                            DateFormat('dd.MM')
                                .format(_measurements[index].date),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosComparison() {
    if (_photos.length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Выберите две даты для сравнения',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final startPhotos = _photos.firstWhere(
      (p) => p.date.isAtSameMomentAs(_startDate),
      orElse: () => _photos.first,
    );

    final endPhotos = _photos.firstWhere(
      (p) => p.date.isAtSameMomentAs(_endDate),
      orElse: () => _photos.last,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Сравнение фото',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd.MM.yyyy').format(startPhotos.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPhotoGrid(startPhotos),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd.MM.yyyy').format(endPhotos.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildPhotoGrid(endPhotos),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(app_photo.PhotoEntry photos) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1,
      children: [
        _buildPhotoWidget(photos.photo1Path),
        _buildPhotoWidget(photos.photo2Path),
        _buildPhotoWidget(photos.photo3Path),
        _buildPhotoWidget(photos.photo4Path),
      ],
    );
  }

  Widget _buildPhotoWidget(String path) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  String _getTypeName(AnalyticsType type) {
    switch (type) {
      case AnalyticsType.bodyFat:
        return '% жира';
      case AnalyticsType.weight:
        return 'Вес (кг)';
      case AnalyticsType.waist:
        return 'Талия (см)';
      case AnalyticsType.hip:
        return 'Бедра (см)';
      case AnalyticsType.neck:
        return 'Шея (см)';
      case AnalyticsType.photos:
        return 'Фото';
    }
  }
}
