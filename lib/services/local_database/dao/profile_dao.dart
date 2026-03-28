import 'package:drift/drift.dart';

import '../local_database.dart';
import '../../../models/user_profile.dart' as app_models;

class ProfileDao {
  final LocalDatabase db;
  
  ProfileDao(this.db);
  
  Future<void> insertProfile(app_models.UserProfile profile) async {
    await db.into(db.userProfiles).insert(
      UserProfilesCompanion(
        userId: Value(profile.userId),
        name: Value(profile.name),
        height: Value(profile.height),
        weight: Value(profile.weight),
        neckCircumference: Value(profile.neckCircumference),
        waistCircumference: Value(profile.waistCircumference),
        hipCircumference: Value(profile.hipCircumference),
        gender: Value(profile.gender),
        goal: Value(profile.goal),
        activityLevel: Value(profile.activityLevel),
        birthDate: Value(profile.birthDate),
        deficit: Value(profile.deficit),
        updatedAt: Value(profile.updatedAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
  
  Future<app_models.UserProfile?> getProfile(String userId) async {
    final query = await (db.select(db.userProfiles)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    
    if (query != null) {
      return app_models.UserProfile(
        userId: query.userId,
        name: query.name,
        height: query.height,
        weight: query.weight,
        neckCircumference: query.neckCircumference,
        waistCircumference: query.waistCircumference,
        hipCircumference: query.hipCircumference,
        gender: query.gender,
        goal: query.goal,
        activityLevel: query.activityLevel,
        birthDate: query.birthDate,
        deficit: query.deficit,
        updatedAt: query.updatedAt,
      );
    }
    return null;
  }
  
  Future<void> updateProfile(app_models.UserProfile profile) async {
    await (db.update(db.userProfiles)
          ..where((t) => t.userId.equals(profile.userId)))
        .write(
          UserProfilesCompanion(
            name: Value(profile.name),
            height: Value(profile.height),
            weight: Value(profile.weight),
            neckCircumference: Value(profile.neckCircumference),
            waistCircumference: Value(profile.waistCircumference),
            hipCircumference: Value(profile.hipCircumference),
            gender: Value(profile.gender),
            goal: Value(profile.goal),
            activityLevel: Value(profile.activityLevel),
            birthDate: Value(profile.birthDate),
            deficit: Value(profile.deficit),
            updatedAt: Value(profile.updatedAt),
          ),
        );
  }
  
  Future<void> deleteProfile(String userId) async {
    await (db.delete(db.userProfiles)..where((t) => t.userId.equals(userId))).go();
  }
}