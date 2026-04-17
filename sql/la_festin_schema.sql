-- ============================================================
--  La Festin — Database Schema
--  Run this file once to set up all 6 tables.
--  Order matters: parent tables before child tables.
-- ============================================================

CREATE DATABASE IF NOT EXISTS la_festin
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE la_festin;

-- ============================================================
--  1. user
--  Parent table — referenced by recipe, pantry, meal_entry
-- ============================================================
CREATE TABLE IF NOT EXISTS user (
    user_id       INT             NOT NULL AUTO_INCREMENT,
    username      VARCHAR(50)     NOT NULL,
    password_hash VARCHAR(255)    NOT NULL,

    CONSTRAINT pk_user        PRIMARY KEY (user_id),
    CONSTRAINT uq_username    UNIQUE      (username)
);

-- ============================================================
--  2. ingredient
--  Parent table — referenced by recipe_ingredient, pantry
-- ============================================================
CREATE TABLE IF NOT EXISTS ingredient (
    ingredient_id INT             NOT NULL AUTO_INCREMENT,
    name          VARCHAR(100)    NOT NULL,

    CONSTRAINT pk_ingredient  PRIMARY KEY (ingredient_id),
    CONSTRAINT uq_ingredient  UNIQUE      (name)
);

-- ============================================================
--  3. recipe
--  Depends on: user
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe (
    recipe_id     INT             NOT NULL AUTO_INCREMENT,
    user_id       INT             NOT NULL,
    title         VARCHAR(150)    NOT NULL,
    category      ENUM(
                    'Breakfast',
                    'Lunch',
                    'Dinner',
                    'Snack',
                    'Dessert'
                  )               NOT NULL,
    prep_time     INT             NOT NULL,  -- in minutes
    `procedure`   TEXT            NOT NULL,

    CONSTRAINT pk_recipe      PRIMARY KEY (recipe_id),
    CONSTRAINT fk_recipe_user FOREIGN KEY (user_id)
        REFERENCES user (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_prep_time  CHECK (prep_time > 0)
);

-- ============================================================
--  4. recipe_ingredient  (junction table)
--  Depends on: recipe, ingredient
-- ============================================================
CREATE TABLE IF NOT EXISTS recipe_ingredient (
    recipe_id     INT             NOT NULL,
    ingredient_id INT             NOT NULL,
    quantity      DECIMAL(10, 2)  NOT NULL,
    unit          VARCHAR(50)     NOT NULL,

    CONSTRAINT pk_recipe_ingredient
        PRIMARY KEY (recipe_id, ingredient_id),
    CONSTRAINT fk_ri_recipe
        FOREIGN KEY (recipe_id)
        REFERENCES recipe (recipe_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_ri_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient (ingredient_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_ri_quantity CHECK (quantity > 0)
);

-- ============================================================
--  5. pantry  (virtual pantry per user)
--  Depends on: ingredient, user
-- ============================================================
CREATE TABLE IF NOT EXISTS pantry (
    ingredient_id INT             NOT NULL,
    user_id       INT             NOT NULL,
    quantity      DECIMAL(10, 2)  NOT NULL,
    unit          VARCHAR(50)     NOT NULL,

    CONSTRAINT pk_pantry
        PRIMARY KEY (ingredient_id, user_id),
    CONSTRAINT fk_pantry_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient (ingredient_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_pantry_user
        FOREIGN KEY (user_id)
        REFERENCES user (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_pantry_quantity CHECK (quantity >= 0)
);

-- ============================================================
--  6. meal_entry
--  Depends on: recipe, user
-- ============================================================
CREATE TABLE IF NOT EXISTS meal_entry (
    recipe_id      INT     NOT NULL,
    user_id        INT     NOT NULL,
    meal_type      ENUM(
                     'Breakfast',
                     'Lunch',
                     'Dinner'
                   )        NOT NULL,
    scheduled_date DATE    NOT NULL,

    CONSTRAINT pk_meal_entry
        PRIMARY KEY (user_id, scheduled_date, meal_type),
    CONSTRAINT fk_me_recipe
        FOREIGN KEY (recipe_id)
        REFERENCES recipe (recipe_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_me_user
        FOREIGN KEY (user_id)
        REFERENCES user (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================================
--  Indexes — speeds up the most common DAO queries
-- ============================================================

-- recipes by user (RecipeDAO.getAllRecipes)
CREATE INDEX idx_recipe_user
    ON recipe (user_id);

-- ingredients by recipe (RecipeIngredientDAO.getByRecipeId)
CREATE INDEX idx_ri_recipe
    ON recipe_ingredient (recipe_id);

-- pantry by user (PantryDAO.getPantryByUser)
CREATE INDEX idx_pantry_user
    ON pantry (user_id);

-- meal entries by user + date (MealEntryDAO.getByDate / getByWeek)
CREATE INDEX idx_me_user_date
    ON meal_entry (user_id, scheduled_date);