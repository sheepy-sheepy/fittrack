import 'package:drift/drift.dart';
import '../local_database.dart';
import '../../../models/body_measurement.dart' as app_models;

class MeasurementDao {
  final LocalDatabase db;

  MeasurementDao(this.db);

  Future<void> insertMeasurement(app_models.BodyMeasurement measurement) async {
    await db.into(db.bodyMeasurements).insert(
          BodyMeasurementsCompanion(
            id: Value(measurement.id),
            userId: Value(measurement.userId),
            date: Value(measurement.date),
            weight: Value(measurement.weight),
            neck: Value(measurement.neck),
            waist: Value(measurement.waist),
            hip: Value(measurement.hip),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<app_models.BodyMeasurement?> getMeasurementByDate(
      String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await (db.select(db.bodyMeasurements)
          ..where((t) =>
              t.userId.equals(userId) &
              t.date.isBetweenValues(startOfDay, endOfDay)))
        .getSingleOrNull();

    if (query != null) {
      return app_models.BodyMeasurement(
        id: query.id,
        userId: query.userId,
        date: query.date,
        weight: query.weight,
        neck: query.neck,
        waist: query.waist,
        hip: query.hip,
      );
    }
    return null;
  }

  Future<List<app_models.BodyMeasurement>> getMeasurements(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query =
        (db.select(db.bodyMeasurements)..where((t) => t.userId.equals(userId)));

    if (startDate != null && endDate != null) {
      query = query..where((t) => t.date.isBetweenValues(startDate, endDate));
    } else if (startDate != null) {
      // Используем isBiggerOrEqualValue вместо isAfter
      query = query..where((t) => t.date.isBiggerOrEqualValue(startDate));
    } else if (endDate != null) {
      // Используем isSmallerOrEqualValue вместо isBefore
      query = query..where((t) => t.date.isSmallerOrEqualValue(endDate));
    }

    final results = await query.get();

    return results
        .map((m) => app_models.BodyMeasurement(
              id: m.id,
              userId: m.userId,
              date: m.date,
              weight: m.weight,
              neck: m.neck,
              waist: m.waist,
              hip: m.hip,
            ))
        .toList();
  }

  Future<List<app_models.BodyMeasurement>> getAllMeasurements(
      String userId) async {
    final results = await (db.select(db.bodyMeasurements)
          ..where((t) => t.userId.equals(userId)))
        .get();

    return results
        .map((m) => app_models.BodyMeasurement(
              id: m.id,
              userId: m.userId,
              date: m.date,
              weight: m.weight,
              neck: m.neck,
              waist: m.waist,
              hip: m.hip,
            ))
        .toList();
  }

  Future<void> deleteMeasurement(String id) async {
    await (db.delete(db.bodyMeasurements)..where((t) => t.id.equals(id))).go();
  }
}
