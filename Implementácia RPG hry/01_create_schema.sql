-- ENUM pre typ akcie v CombatLog
DROP TYPE IF EXISTS action_type_enum CASCADE;
CREATE TYPE action_type_enum AS ENUM (
     'spell_cast',
     'pick_item',
     'drop_item',
     'use_item',
     'auto_attack',
     'start',
     'join',
     'pass',
     'died'
);

------------------------------------------------------------
-- Základné tabuľky (bez FK)
------------------------------------------------------------
DROP TABLE IF EXISTS "AttributeType" CASCADE;
CREATE TABLE "AttributeType" (
     id SERIAL PRIMARY KEY,
     name VARCHAR(50) NOT NULL UNIQUE,
     base_value NUMERIC(5,2) NOT NULL
);

DROP TABLE IF EXISTS "ClassType" CASCADE;
CREATE TABLE "ClassType" (
     id SERIAL PRIMARY KEY,
     name VARCHAR(50) NOT NULL UNIQUE,
     base_dmg NUMERIC(5,2) NOT NULL,
     armor_bonus INTEGER NOT NULL,
     modifier_ap NUMERIC(4,2) NOT NULL CHECK (modifier_ap > 0),
     modifier_inventory NUMERIC(4,2) NOT NULL CHECK (modifier_inventory > 0)
);

DROP TABLE IF EXISTS "Item" CASCADE;
CREATE TABLE "Item" (
     id SERIAL PRIMARY KEY,
     name VARCHAR(80) NOT NULL UNIQUE,
     weight NUMERIC(4,2) NOT NULL CHECK (weight >= 0),
     description TEXT,
     is_consumable BOOLEAN NOT NULL DEFAULT FALSE
);

DROP TABLE IF EXISTS "SpellCategory" CASCADE;
CREATE TABLE "SpellCategory" (
     id SERIAL PRIMARY KEY,
     name VARCHAR(50) NOT NULL UNIQUE
);

DROP TABLE IF EXISTS "Combat" CASCADE;
CREATE TABLE "Combat" (
     id SERIAL PRIMARY KEY,
     is_active BOOLEAN NOT NULL DEFAULT TRUE
);

------------------------------------------------------------
-- Závislé tabuľky (s FK na základné)
------------------------------------------------------------
DROP TABLE IF EXISTS "Spell" CASCADE;
CREATE TABLE "Spell" (
     id SERIAL PRIMARY KEY,
     name VARCHAR(80) NOT NULL UNIQUE,
     category_id INTEGER NOT NULL REFERENCES "SpellCategory"(id) ON DELETE RESTRICT,
     base_cost INTEGER NOT NULL CHECK (base_cost > 0),
     base_dmg NUMERIC(5,2) NOT NULL,
     description TEXT
);

DROP TABLE IF EXISTS "Character" CASCADE;
CREATE TABLE "Character" (
     id SERIAL PRIMARY KEY,
     name VARCHAR(40) NOT NULL UNIQUE,
     class_id INTEGER NOT NULL REFERENCES "ClassType"(id) ON DELETE RESTRICT,
     curr_health INTEGER NOT NULL CHECK (curr_health >= 0),
     curr_inventory NUMERIC(5,2) NOT NULL DEFAULT 0,
     is_alliance BOOLEAN NOT NULL
);

DROP TABLE IF EXISTS "ItemUseEffect" CASCADE;
CREATE TABLE "ItemUseEffect" (
     item_id INTEGER PRIMARY KEY REFERENCES "Item"(id) ON DELETE CASCADE,
     is_healing BOOLEAN NOT NULL,
     value NUMERIC(5,2) NOT NULL
);

DROP TABLE IF EXISTS "Round" CASCADE;
CREATE TABLE "Round" (
     id SERIAL PRIMARY KEY,
     combat_id INTEGER NOT NULL REFERENCES "Combat"(id) ON DELETE CASCADE,
     round_number INTEGER NOT NULL
);

------------------------------------------------------------
-- Many-to-many tabuľky
------------------------------------------------------------
DROP TABLE IF EXISTS "CharacterAttribute" CASCADE;
CREATE TABLE "CharacterAttribute" (
     character_id INTEGER REFERENCES "Character"(id) ON DELETE CASCADE,
     attribute_id INTEGER REFERENCES "AttributeType"(id) ON DELETE CASCADE,
     value NUMERIC(5,2) NOT NULL,
     PRIMARY KEY (character_id, attribute_id)
);

DROP TABLE IF EXISTS "ClassAttributeModifier" CASCADE;
CREATE TABLE "ClassAttributeModifier" (
     class_id INTEGER REFERENCES "ClassType"(id) ON DELETE CASCADE,
     attribute_id INTEGER REFERENCES "AttributeType"(id) ON DELETE CASCADE,
     value INTEGER NOT NULL,
     PRIMARY KEY (class_id, attribute_id)
);

DROP TABLE IF EXISTS "ItemAttributeModifier" CASCADE;
CREATE TABLE "ItemAttributeModifier" (
     item_id INTEGER REFERENCES "Item"(id) ON DELETE CASCADE,
     attribute_id INTEGER REFERENCES "AttributeType"(id) ON DELETE CASCADE,
     modifier_value NUMERIC(4,2) NOT NULL,
     PRIMARY KEY (item_id, attribute_id)
);

DROP TABLE IF EXISTS "SpellAttributeModifier" CASCADE;
CREATE TABLE "SpellAttributeModifier" (
     spell_id INTEGER REFERENCES "Spell"(id) ON DELETE CASCADE,
     attribute_id INTEGER REFERENCES "AttributeType"(id) ON DELETE CASCADE,
     modifier_cost NUMERIC(4,2) NOT NULL,
     modifier_dmg NUMERIC(4,2) NOT NULL,
     PRIMARY KEY (spell_id, attribute_id)
);

DROP TABLE IF EXISTS "CharacterInventory" CASCADE;
CREATE TABLE "CharacterInventory" (
     character_id INTEGER REFERENCES "Character"(id) ON DELETE CASCADE,
     item_id INTEGER REFERENCES "Item"(id) ON DELETE CASCADE,
     quantity INTEGER NOT NULL CHECK (quantity > 0),
     PRIMARY KEY (character_id, item_id)
);

DROP TABLE IF EXISTS "CombatInventory" CASCADE;
CREATE TABLE "CombatInventory" (
     combat_id INTEGER REFERENCES "Combat"(id) ON DELETE CASCADE,
     item_id INTEGER REFERENCES "Item"(id) ON DELETE CASCADE,
     quantity INTEGER NOT NULL CHECK (quantity > 0),
     PRIMARY KEY (combat_id, item_id)
);

DROP TABLE IF EXISTS "CharacterInCombat" CASCADE;
CREATE TABLE "CharacterInCombat" (
     combat_id INTEGER REFERENCES "Combat"(id) ON DELETE CASCADE,
     character_id INTEGER REFERENCES "Character"(id) ON DELETE CASCADE,
     round_joined INTEGER NOT NULL,
     current_ap INTEGER NOT NULL,
     turn_score INTEGER NOT NULL,
     PRIMARY KEY (combat_id, character_id)
);

------------------------------------------------------------
-- Logovacie tabuľky
------------------------------------------------------------
DROP TABLE IF EXISTS "CombatLog" CASCADE;
CREATE TABLE "CombatLog" (
     event_number SERIAL PRIMARY KEY,
     combat_id INTEGER NOT NULL REFERENCES "Combat"(id) ON DELETE CASCADE,
     round_id INTEGER NOT NULL REFERENCES "Round"(id) ON DELETE CASCADE,
     acting_char_id INTEGER REFERENCES "Character"(id) ON DELETE RESTRICT,
     target_char_id INTEGER REFERENCES "Character"(id) ON DELETE SET NULL,
     action_type action_type_enum NOT NULL,
     item_id INTEGER REFERENCES "Item"(id) ON DELETE SET NULL,
     spell_id INTEGER REFERENCES "Spell"(id) ON DELETE SET NULL,
     damage_dealt NUMERIC(5,2),
     log_message TEXT
);

DROP TABLE IF EXISTS "ItemChangeLog" CASCADE;
CREATE TABLE "ItemChangeLog" (
     id SERIAL PRIMARY KEY,
     event_number INTEGER NOT NULL REFERENCES "CombatLog"(event_number) ON DELETE CASCADE,
     character_id INTEGER REFERENCES "Character"(id) ON DELETE SET NULL,
     combat_id INTEGER REFERENCES "Combat"(id) ON DELETE SET NULL,
     item_id INTEGER NOT NULL REFERENCES "Item"(id) ON DELETE RESTRICT,
     change VARCHAR(6) NOT NULL CHECK (change IN ('add','remove')),
     quantity INTEGER NOT NULL CHECK (quantity > 0)
);

DROP TABLE IF EXISTS "HealthChangeLog" CASCADE;
CREATE TABLE "HealthChangeLog" (
     id SERIAL PRIMARY KEY,
     event_number INTEGER NOT NULL REFERENCES "CombatLog"(event_number) ON DELETE CASCADE,
     character_id INTEGER NOT NULL REFERENCES "Character"(id) ON DELETE CASCADE,
     health_before INTEGER,
     health_after INTEGER NOT NULL
);

------------------------------------------------------------
-- Indexovanie pre rýchle vyhľadávanie
------------------------------------------------------------
-- CombatLog
CREATE INDEX ON "CombatLog"(combat_id);
CREATE INDEX ON "CombatLog"(acting_char_id);
CREATE INDEX ON "CombatLog"(action_type);

-- CharacterInCombat
CREATE INDEX ON "CharacterInCombat"(character_id);
CREATE INDEX ON "CharacterInCombat"(combat_id);

-- Inventár
CREATE INDEX ON "CharacterInventory"(character_id);
CREATE INDEX ON "CharacterInventory"(item_id);
CREATE INDEX ON "CombatInventory"(combat_id);
CREATE INDEX ON "CombatInventory"(item_id);

-- Atributy - trieda
CREATE INDEX ON "Character"(class_id);
CREATE INDEX ON "CharacterAttribute"(character_id);