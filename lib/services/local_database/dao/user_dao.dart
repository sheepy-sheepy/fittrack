import 'package:drift/drift.dart';
import '../local_database.dart';
import '../../../models/user.dart' as app_models;
import '../../../models/registration_status.dart';

class UserDao {
  final LocalDatabase db;

  UserDao(this.db);

  Future<void> insertUser(app_models.User user) async {
    await db.into(db.users).insert(
          UsersCompanion(
            id: Value(user.id),
            email: Value(user.email),
            status: Value(user.status.toInt()),
            createdAt: Value(user.createdAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<app_models.User?> getUser(String userId) async {
    final query = await (db.select(db.users)..where((t) => t.id.equals(userId)))
        .getSingleOrNull();

    if (query != null) {
      return app_models.User(
        id: query.id,
        email: query.email,
        status: RegistrationStatus.fromInt(query.status),
        createdAt: query.createdAt,
      );
    }
    return null;
  }

  Future<app_models.User?> getUserByEmail(String email) async {
    final query = await (db.select(db.users)
          ..where((t) => t.email.equals(email)))
        .getSingleOrNull();

    if (query != null) {
      return app_models.User(
        id: query.id,
        email: query.email,
        status: RegistrationStatus.fromInt(query.status),
        createdAt: query.createdAt,
      );
    }
    return null;
  }

  Future<void> updateUserStatus(
      String userId, RegistrationStatus status) async {
    await (db.update(db.users)..where((t) => t.id.equals(userId)))
        .write(UsersCompanion(status: Value(status.toInt())));
  }

  Future<void> deleteUser(String userId) async {
    await (db.delete(db.users)..where((t) => t.id.equals(userId))).go();
  }
}