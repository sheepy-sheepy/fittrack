-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles table
CREATE TABLE user_profiles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    height REAL NOT NULL CHECK (height > 0),
    weight REAL NOT NULL CHECK (weight > 0),
    neck_circumference REAL NOT NULL CHECK (neck_circumference > 0),
    waist_circumference REAL NOT NULL CHECK (waist_circumference > 0),
    hip_circumference REAL NOT NULL CHECK (hip_circumference > 0),
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    goal TEXT NOT NULL CHECK (goal IN ('lose', 'maintain', 'gain')),
    activity_level TEXT NOT NULL,
    birth_date DATE NOT NULL,
    deficit INTEGER DEFAULT 300,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Body measurements table
CREATE TABLE body_measurements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    weight REAL NOT NULL CHECK (weight > 0),
    neck REAL NOT NULL CHECK (neck > 0),
    waist REAL NOT NULL CHECK (waist > 0),
    hip REAL NOT NULL CHECK (hip > 0),
    UNIQUE(user_id, date)
);

-- Foods table
CREATE TABLE foods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    calories REAL NOT NULL CHECK (calories >= 0),
    proteins REAL NOT NULL CHECK (proteins >= 0),
    fats REAL NOT NULL CHECK (fats >= 0),
    carbs REAL NOT NULL CHECK (carbs >= 0),
    is_custom BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recipes table
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    total_calories REAL NOT NULL CHECK (total_calories >= 0),
    total_proteins REAL NOT NULL CHECK (total_proteins >= 0),
    total_fats REAL NOT NULL CHECK (total_fats >= 0),
    total_carbs REAL NOT NULL CHECK (total_carbs >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recipe ingredients table
CREATE TABLE recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    food_id UUID REFERENCES foods(id),
    grams REAL NOT NULL CHECK (grams > 0),
    food_name TEXT NOT NULL,
    calories REAL NOT NULL CHECK (calories >= 0),
    proteins REAL NOT NULL CHECK (proteins >= 0),
    fats REAL NOT NULL CHECK (fats >= 0),
    carbs REAL NOT NULL CHECK (carbs >= 0)
);

-- Meals table
CREATE TABLE meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meal entries table
CREATE TABLE meal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_id UUID REFERENCES meals(id) ON DELETE CASCADE,
    food_id UUID REFERENCES foods(id),
    recipe_id UUID REFERENCES recipes(id),
    grams REAL NOT NULL CHECK (grams > 0),
    name TEXT NOT NULL,
    calories REAL NOT NULL CHECK (calories >= 0),
    proteins REAL NOT NULL CHECK (proteins >= 0),
    fats REAL NOT NULL CHECK (fats >= 0),
    carbs REAL NOT NULL CHECK (carbs >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK ((food_id IS NOT NULL AND recipe_id IS NULL) OR (food_id IS NULL AND recipe_id IS NOT NULL))
);

-- Water entries table
CREATE TABLE water_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    amount REAL NOT NULL CHECK (amount >= 0),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Photo entries table
CREATE TABLE photo_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    photo1_path TEXT NOT NULL,
    photo2_path TEXT NOT NULL,
    photo3_path TEXT NOT NULL,
    photo4_path TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_body_measurements_user_date ON body_measurements(user_id, date);
CREATE INDEX idx_foods_name ON foods(name);
CREATE INDEX idx_foods_user ON foods(user_id);
CREATE INDEX idx_recipes_user ON recipes(user_id);
CREATE INDEX idx_meals_user_date ON meals(user_id, date);
CREATE INDEX idx_meal_entries_meal ON meal_entries(meal_id);
CREATE INDEX idx_water_entries_user_date ON water_entries(user_id, date);
CREATE INDEX idx_photo_entries_user_date ON photo_entries(user_id, date);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE photo_entries ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own measurements" ON body_measurements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own measurements" ON body_measurements FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own measurements" ON body_measurements FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view foods" ON foods FOR SELECT USING (is_custom = false OR user_id = auth.uid());
CREATE POLICY "Users can insert own foods" ON foods FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own foods" ON foods FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own foods" ON foods FOR DELETE USING (user_id = auth.uid());

CREATE POLICY "Users can view own recipes" ON recipes FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own recipes" ON recipes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own recipes" ON recipes FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own recipes" ON recipes FOR DELETE USING (user_id = auth.uid());

CREATE POLICY "Users can view own recipe ingredients" ON recipe_ingredients FOR SELECT USING (
    EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_ingredients.recipe_id AND recipes.user_id = auth.uid())
);
CREATE POLICY "Users can insert own recipe ingredients" ON recipe_ingredients FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_ingredients.recipe_id AND recipes.user_id = auth.uid())
);
CREATE POLICY "Users can delete own recipe ingredients" ON recipe_ingredients FOR DELETE USING (
    EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_ingredients.recipe_id AND recipes.user_id = auth.uid())
);

CREATE POLICY "Users can view own meals" ON meals FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own meals" ON meals FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own meals" ON meals FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own meals" ON meals FOR DELETE USING (user_id = auth.uid());

CREATE POLICY "Users can view own meal entries" ON meal_entries FOR SELECT USING (
    EXISTS (SELECT 1 FROM meals WHERE meals.id = meal_entries.meal_id AND meals.user_id = auth.uid())
);
CREATE POLICY "Users can insert own meal entries" ON meal_entries FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM meals WHERE meals.id = meal_entries.meal_id AND meals.user_id = auth.uid())
);
CREATE POLICY "Users can update own meal entries" ON meal_entries FOR UPDATE USING (
    EXISTS (SELECT 1 FROM meals WHERE meals.id = meal_entries.meal_id AND meals.user_id = auth.uid())
);
CREATE POLICY "Users can delete own meal entries" ON meal_entries FOR DELETE USING (
    EXISTS (SELECT 1 FROM meals WHERE meals.id = meal_entries.meal_id AND meals.user_id = auth.uid())
);

CREATE POLICY "Users can view own water entries" ON water_entries FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own water entries" ON water_entries FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own water entries" ON water_entries FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can view own photo entries" ON photo_entries FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own photo entries" ON photo_entries FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own photo entries" ON photo_entries FOR UPDATE USING (user_id = auth.uid());




-- Обновите таблицу users, удалив password_hash
ALTER TABLE users DROP COLUMN IF EXISTS password_hash;

-- Если таблица только создается, используйте:
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);






-- Создаем политики для таблицы users
DROP POLICY IF EXISTS "Users can insert own data" ON users;
CREATE POLICY "Users can insert own data" ON users 
FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view own data" ON users;
CREATE POLICY "Users can view own data" ON users 
FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON users;
CREATE POLICY "Users can update own data" ON users 
FOR UPDATE USING (auth.uid() = id);

-- Для таблицы user_profiles
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile" ON user_profiles 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Убедитесь, что RLS включен
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;