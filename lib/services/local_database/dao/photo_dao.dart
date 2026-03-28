import 'package:drift/drift.dart';
import '../local_database.dart';
import '../../../models/photo_entry.dart' as app_models;

class PhotoDao {
  final LocalDatabase db;
  
  PhotoDao(this.db);
  
  Future<void> insertPhotoEntry(app_models.PhotoEntry entry) async {
    await db.into(db.photoEntries).insert(
      PhotoEntriesCompanion(
        id: Value(entry.id),
        userId: Value(entry.userId),
        date: Value(entry.date),
        photo1Path: Value(entry.photo1Path),
        photo2Path: Value(entry.photo2Path),
        photo3Path: Value(entry.photo3Path),
        photo4Path: Value(entry.photo4Path),
        createdAt: Value(entry.createdAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
  
  Future<app_models.PhotoEntry?> getPhotoEntryByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await (db.select(db.photoEntries)
          ..where((t) => t.userId.equals(userId) &
                t.date.isBetweenValues(startOfDay, endOfDay)))
        .getSingleOrNull();
    
    if (result != null) {
      return app_models.PhotoEntry(
        id: result.id,
        userId: result.userId,
        date: result.date,
        photo1Path: result.photo1Path,
        photo2Path: result.photo2Path,
        photo3Path: result.photo3Path,
        photo4Path: result.photo4Path,
        createdAt: result.createdAt,
      );
    }
    return null;
  }
  
  Future<List<app_models.PhotoEntry>> getPhotoEntries(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = (db.select(db.photoEntries)
          ..where((t) => t.userId.equals(userId)));
    
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
    
    return results.map((p) => app_models.PhotoEntry(
      id: p.id,
      userId: p.userId,
      date: p.date,
      photo1Path: p.photo1Path,
      photo2Path: p.photo2Path,
      photo3Path: p.photo3Path,
      photo4Path: p.photo4Path,
      createdAt: p.createdAt,
    )).toList();
  }
  
  Future<List<app_models.PhotoEntry>> getAllPhotoEntries(String userId) async {
    final results = await (db.select(db.photoEntries)
          ..where((t) => t.userId.equals(userId)))
        .get();
    
    return results.map((p) => app_models.PhotoEntry(
      id: p.id,
      userId: p.userId,
      date: p.date,
      photo1Path: p.photo1Path,
      photo2Path: p.photo2Path,
      photo3Path: p.photo3Path,
      photo4Path: p.photo4Path,
      createdAt: p.createdAt,
    )).toList();
  }
  
  Future<void> deletePhotoEntry(String id) async {
    await (db.delete(db.photoEntries)..where((t) => t.id.equals(id))).go();
  }
}