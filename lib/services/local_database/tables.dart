import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  IntColumn get status => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class UserProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get height => real()();
  RealColumn get weight => real()();
  RealColumn get neckCircumference => real()();
  RealColumn get waistCircumference => real()();
  RealColumn get hipCircumference => real()();
  TextColumn get gender => text()();
  TextColumn get goal => text()();
  TextColumn get activityLevel => text()();
  DateTimeColumn get birthDate => dateTime()();
  IntColumn get deficit => integer().withDefault(const Constant(300))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

class BodyMeasurements extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weight => real()();
  RealColumn get neck => real()();
  RealColumn get waist => real()();
  RealColumn get hip => real()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('user_date_idx', 'userId, date'),
      ];
}

class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get calories => real()();
  RealColumn get proteins => real()();
  RealColumn get fats => real()();
  RealColumn get carbs => real()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('name_idx', 'name'),
        Index('user_idx', 'userId'),
      ];
}

class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get totalCalories => real()();
  RealColumn get totalProteins => real()();
  RealColumn get totalFats => real()();
  RealColumn get totalCarbs => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('user_idx', 'userId'),
      ];
}

class RecipeIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId => text()();
  TextColumn get foodId => text()();
  RealColumn get grams => real()();
  TextColumn get foodName => text()();
  RealColumn get calories => real()();
  RealColumn get proteins => real()();
  RealColumn get fats => real()();
  RealColumn get carbs => real()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('recipe_idx', 'recipeId'),
      ];
}

class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('user_date_idx', 'userId, date'),
      ];
}

class MealEntries extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text()();
  TextColumn get foodId => text().nullable()();
  TextColumn get recipeId => text().nullable()();
  RealColumn get grams => real()();
  TextColumn get name => text()();
  RealColumn get calories => real()();
  RealColumn get proteins => real()();
  RealColumn get fats => real()();
  RealColumn get carbs => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('meal_idx', 'mealId'),
      ];
}

class WaterEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('user_date_idx', 'userId, date'),
      ];
}

class PhotoEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get photo1Path => text()();
  TextColumn get photo2Path => text()();
  TextColumn get photo3Path => text()();
  TextColumn get photo4Path => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('user_date_idx', 'userId, date'),
      ];
}
