/* ---------- ATTRIBUTE TYPE -------------------------------- */
INSERT INTO "AttributeType"(id, name, base_value) VALUES
        (1, 'MaxHealth',   100),
        (2, 'Strength',     10),
        (3, 'Dexterity',    10),
        (4, 'Intelligence', 10),
        (5, 'Constitution', 10),
        (6, 'Charisma',     10),
        (7, 'Luck',         10)
ON CONFLICT DO NOTHING;

/* ---------- CLASS TYPE ------------------------------------ */
INSERT INTO "ClassType"(id, name, base_dmg, armor_bonus, modifier_ap, modifier_inventory) VALUES
        (1, 'Warrior', 15, 2, 1.00, 1.20),
        (2, 'Elf'    ,  9, 0, 1.20, 0.90),
        (3, 'Dwarf'  , 12, 3, 0.80, 1.40),
        (4, 'Paladin',  7, 4, 0.90, 1.30),
        (5, 'Mage'   ,  5, 0, 1.10, 0.80),
        (6, 'Hunter' ,  9, 1, 1.00, 1.40),
        (7, 'Rogue',       10, 1, 1.15, 1.50),
        (8, 'Necromancer',  6, 0, 1.10, 1.00),
        (9, 'Monk',         8, 2, 1.05, 1.10)
ON CONFLICT(id) DO NOTHING;
        
/* ---------- CLASS‑ATTRIBUTE MODIFIERS --------------------- */
INSERT INTO "ClassAttributeModifier"(class_id, attribute_id, value) VALUES
        (1, 2, 3), (1, 5, 2), (1, 1, 10),     -- Warrior: +3 STR, +2 CON, +10 HP
        (2, 3, 3), (2, 6, 2),                 -- Elf: +3 DEX, +2 CHA
        (3, 5, 3), (3, 2, 1), (3, 1, 5),      -- Dwarf: +3 CON, +1 STR, +5 HP
        (5, 4, 3), (5, 6, 1),                 -- Mage: +3 INT, +1 CHA
        (6, 3, 3), (6, 2, 2), (6, 1, 5),      -- Hunter: +3 DEX, +2 STR, +5 HP
        (7, 3, 3), (7, 7, 2),                 -- Rogue: +3 DEX, +2 LCK
        (8, 4, 3), (8, 7, 1), (8, 6, 1),      -- Necromancer: +3 INT, +1 LCK, +1 CHA
        (9, 5, 2), (9, 4, 2), (9, 7, 1), (9, 1, 5) -- Monk: +2 CON, +2 INT, +1 LCK, +5 HP
ON CONFLICT (class_id, attribute_id) DO NOTHING;


/* ---------- SPELL CATEGORIES ------------------------------ */
INSERT INTO "SpellCategory"(id, name) VALUES
        (1, 'Fire'), 
        (2, 'Frost'), 
        (3, 'Healing'), 
        (4, 'Melee'), 
        (5, 'Shadow'),
        (6,  'Arcane'),
        (7,  'Nature'),
        (8,  'Storm'),
        (9,  'Necromancy'),
        (10, 'Void'),
        (11, 'Light'),
        (12, 'Earth')
ON CONFLICT(id) DO NOTHING;

/* ---------- SPELLS ---------------------------------------- */
INSERT INTO "Spell"(id, name, category_id, base_cost, base_dmg, description) VALUES
        (1, 'Fireball'   , 1, 5, 10.0, 'A fiery explosion'), 
        (2, 'IceArrow'   , 2, 4,  8.0, 'Freezes target momentarily'), 
        (3, 'Holy Light' , 3, 4, -3.0, 'Heals target small amount'), 
        (4, 'Cleave'     , 4, 3,  7.0, 'Wide swinging melee attack'), 
        (5, 'ThunderCry' , 8, 5,  8.0, 'Ear‑splitting melee shout'),
        (6, 'ShadowBolt' , 10, 4,  9.0, 'Dark bolt of void energy'),
        (7, 'FrostNova'  , 2, 6,  7.0, 'Damages and slows enemies'), 
        (8,  'Divine Blossom', 3, 4, -5.0, 'Strong holy heal'),
        (9,  'ArcaneMissile' , 6, 3,  7.0, 'Quick magical projectile'),
        (10, 'Blizzard'      , 2, 6,  6.0, 'Massive ice storm attack'),
        (11, 'Sanctuary'     , 3, 5, -6.0, 'Protective holy shield'),
        (12, 'Whirlwind'     , 4, 5,  9.0, 'Spinning melee strike'),
        (13, 'RagingRoar'    , 4, 4,  8.0, 'Battle cry that empowers'),
        (14, 'SoulDrain'     , 9, 5, 10.0, 'Siphons life from enemy'),
        (15, 'GlacierSpike'  , 2, 4,  9.0, 'Sharp ice spike attack'),
        (16, 'Sunray'        , 3, 4, -4.0, 'Warm healing light beam'),
        (17, 'MeteorCrash'   , 6, 7, 12.0, 'Meteor impact explosion'),
        (18, 'PhantomGrasp'  ,10, 4,  8.0, 'Ghostly hand attack'),
        (19, 'OverheadSmash' , 4, 5, 11.0, 'Crushing melee blow'),
        (20, 'BloodCurse'    , 9, 6, 10.0, 'Dark curse causing decay'),
        (21, 'SmiteLight',   11, 4,  9.0, 'Blinding light strike'),
        (22, 'Earthquake',   12, 7, 11.0, 'Shakes the ground violently'),
        (23, 'SolarFlare',   11, 6, 10.0, 'Searing column of sunlight'),
        (24, 'StoneSkin',    12, 4, -4.0, 'Fortifies target''s body'),
        (25, 'LightBeam',    11, 3,  7.0, 'Piercing ray of light'),
        (26, 'MudTrap',      12, 5,  8.0, 'Slows and harms enemies'),
        (27, 'Radiance',     11, 5, -6.0, 'Powerful healing aura'),
        (28, 'BoulderThrow', 12, 4,  9.0, 'Hurls a massive rock'),
        (29, 'Sunburst',     11, 6, 10.0, 'Explosive flash of light'),
        (30, 'Sandstorm',    12, 6,  9.0, 'Blinding swirling sand')
ON CONFLICT(id) DO NOTHING;

/* ---------- SPELL‑ATTRIBUTE MODIFIERS --------------------- */
INSERT INTO "SpellAttributeModifier"(spell_id, attribute_id, modifier_cost, modifier_dmg) VALUES
        (1, 4, 0.90, 1.20), (1, 7, 0.95, 1.10),    -- Fireball: Intelligence + Luck
        (2, 4, 0.80, 1.10), (2, 7, 0.85, 1.05),    -- IceArrow: Intelligence + Luck
        (3, 5, 0.85, 1.15), (3, 6, 0.90, 1.05),    -- Holy Light: Constitution + Charisma
        (4, 2, 0.95, 1.25), (4, 5, 0.92, 1.10),    -- Cleave: Strength + Constitution
        (5, 2, 0.90, 1.20), (5, 7, 0.93, 1.05),    -- ThunderCry: Strength + Luck
        (6, 3, 0.85, 1.30), (6, 7, 0.90, 1.05),    -- ShadowBolt: Dexterity + Luck
        (7, 3, 0.90, 1.10), (7, 4, 0.92, 1.05),    -- FrostNova: Dexterity + Intelligence
        (8, 4, 0.80, 1.25), (8, 5, 0.85, 1.05),    -- Smite: Intelligence + Constitution
        (9, 4, 0.85, 1.15), (9, 7, 0.88, 1.05),    -- ArcaneMissile: Intelligence + Luck
        (10, 4, 0.90, 1.20), (10, 5, 0.92, 1.05),  -- Blizzard: Intelligence + Constitution
        (11, 5, 0.85, 1.25), (11, 6, 0.90, 1.05),  -- Sanctuary: Constitution + Charisma
        (12, 2, 0.92, 1.22), (12, 3, 0.95, 1.05),  -- Whirlwind: Strength + Dexterity
        (13, 2, 0.90, 1.18), (13, 5, 0.93, 1.05),  -- RagingRoar: Strength + Constitution
        (14, 4, 0.88, 1.30), (14, 7, 0.90, 1.05),  -- SoulDrain: Intelligence + Luck
        (15, 4, 0.87, 1.25), (15, 3, 0.90, 1.05),  -- GlacierSpike: Intelligence + Dexterity
        (16, 5, 0.82, 1.20), (16, 4, 0.85, 1.05),  -- Sunray: Constitution + Intelligence
        (17, 4, 0.80, 1.35), (17, 7, 0.83, 1.10),  -- MeteorCrash: Intelligence + Luck
        (18, 3, 0.90, 1.20), (18, 7, 0.92, 1.05),  -- PhantomGrasp: Dexterity + Luck
        (19, 2, 0.93, 1.28), (19, 5, 0.95, 1.05),  -- OverheadSmash: Strength + Constitution
        (20, 4, 0.86, 1.22), (20, 7, 0.89, 1.05),  -- BloodCurse: Intelligence + Luck
        (21, 5, 0.85, 1.20), (21, 6, 0.88, 1.05),  -- SmiteLight: Constitution + Charisma
        (22, 2, 0.90, 1.25), (22, 5, 0.93, 1.05),  -- Earthquake: Strength + Constitution
        (23, 4, 0.80, 1.30), (23, 7, 0.83, 1.10),  -- SolarFlare: Intelligence + Luck
        (24, 5, 0.85, 1.20), (24, 4, 0.88, 1.05),  -- StoneSkin: Constitution + Intelligence
        (25, 4, 0.90, 1.15), (25, 6, 0.93, 1.05),  -- LightBeam: Intelligence + Charisma
        (26, 3, 0.88, 1.20), (26, 7, 0.90, 1.05),  -- MudTrap: Dexterity + Luck
        (27, 4, 0.85, 1.25), (27, 6, 0.88, 1.05),  -- Radiance: Intelligence + Charisma
        (28, 2, 0.90, 1.20), (28, 5, 0.93, 1.05),  -- BoulderThrow: Strength + Constitution
        (29, 4, 0.80, 1.30), (29, 7, 0.83, 1.10),  -- Sunburst: Intelligence + Luck
        (30, 3, 0.85, 1.10), (30, 7, 0.88, 1.05)   -- Sandstorm: Dexterity + Luck
ON CONFLICT DO NOTHING;


/* ---------- ITEMS ----------------------------------------- */
INSERT INTO "Item"(id, name, weight, description, is_consumable) VALUES
        (1, 'Death''s Trace', 0.0, 'Weightless yet crushing. Carry your ghost, until blood lays it to rest.', false),
        (2, 'Minor Healing Potion', 0.4, 'Minor heal power', true), 
        (3, 'Great Healing Potion', 0.5, 'Great heal power', true), 
        (4, 'Minor Poison', 0.4, 'Harmful potion', true), 
        (5, 'Poison Vial', 0.5, 'Deadly poison', true), 

        (6, 'Mighty Axe', 5.0, 'Large two‑handed axe', false), 
        (7, 'Sword of Strength', 3.5, 'Sturdy longsword with engraved hilt', false), 
        (8, 'Knight Armor', 8.0, 'Heavy plate armor worn by elite knights', false), 
        (9, 'Staff of Maraia', 4.0, 'Ancient staff once owned by arch‑mage', false), 
        (10,'Bow of Silence', 4.0, 'Silent longbow', false),
        (11,'Leather Quiver', 1.0, 'Light quiver for hunters', false),

        (12, 'Elven Bread', 0.2, 'Light bread that soothes hunger', true),
        (13, 'Honeyed Nectar', 0.1, 'Sweet drink that restores minor health', true),
        (14, 'Spicy Jerky', 0.3, 'Cured meat that grants a small stamina boost', true),
        (15, 'Mushroom Cap', 0.1, 'Tiny mushroom that heals 2 HP', true),
        (16, 'Nightshade Spores', 0.05, 'Powdery toxin for hunting small game', true),
        (17, 'Ginseng Tea', 0.2, 'Soothing tea that restores focus over time', true),
        (18, 'Silver Wine', 0.5, 'Fine wine that slightly fortifies the drinker''s spirit', true),
        (19, 'Dragonfruit Slice', 0.2, 'Exotic fruit slice that cures minor poisoning', true),
        (20, 'Tasty Cookie', 0.1, 'Sweet cookie that restores your taste to live', true),
        (21, 'Roasted Boar', 1.0, 'Hearty feast that heals moderate HP', true),
        (22, 'Rotten Meat', 0.2, 'Spoiled meat that causes nausea', true),
        (23, 'Ghost Pepper', 0.05, 'Fiery pepper that deals burning damage when eaten', true),

        (24, 'Iron Shield', 6.0, 'Sturdy shield forged from heavy iron', false),
        (25, 'Boots of Swiftness', 1.5, 'Light boots that increase wearer''s movement speed', false),
        (26, 'Cloak of Shadows', 1.0, 'Dark cloak that muffles footsteps and blends into darkness', false),
        (27, 'Ring of Fortitude', 0.1, 'Simple ring that grants a minor health boost while worn', false),
        (28, 'Amulet of Cinders', 0.1, 'Charred amulet that augments fire-based magic', false),
        (29, 'Wand of Sparks', 1.0, 'Basic wand that fires small electric sparks', false),
        (30, 'Traveler''s Ration', 0.4, 'Compact ration that restores a little health and stamina', true),
        (31, 'Crystal Dagger',   2.0, 'Razor-sharp crystal blade', false),
        (32, 'Phoenix Feather',  0.05,'Rare feather with healing power', true),
        (33, 'Luck Charm',       0.1, 'Amulet that bends fate',   false),
        (34, 'Earth Totem',      1.5, 'Totem empowering earth spells', false),
        (35, 'Sun Elixir',       0.3, 'Bright potion of vitality', true),
        (36, 'Shadow Cloak',     1.2, 'Enhances shadow magic',    false),
        (37, 'Rejuvenation Scroll',0.1,'One-use healing scroll',  true),
        (38, 'Pebble of Power',  0.2, 'Tiny stone, great stamina', false),
        (39, 'Silent Boots',     1.3, 'Footsteps of a whisper',   false),
        (40, 'Lucky Coin',       0.05,'Coin that chooses your side', false)
ON CONFLICT(id) DO NOTHING;

/* ---------- ITEM‑ATTRIBUTE MODIFIERS ---------------------- */
INSERT INTO "ItemAttributeModifier"(item_id, attribute_id, modifier_value) VALUES
        (1, 1, 0.60), (1, 2, 0.60), (1, 3, 0.60), (1, 4, 0.60), (1, 5, 0.60), (1, 6, 0.60), (1, 7, 0.60), -- Death's Trace: -40% all attributes
        (6 , 2, 1.20), (6 , 5, 1.10),  -- Mighty Axe: +20% STR, +10% HP
        (7 , 2, 1.30), (7 , 5, 1.10),  -- Sword of Strength: +30% STR, +10% HP
        (8 , 5, 1.30), (8 , 1, 1.20),  -- Knight Armor: +30% CON, +20% HP
        (9 , 4, 1.30), (9 , 6, 1.10),  -- Staff of Maraia: +30% INT, +10% CHA
        (10, 3, 1.20), (10, 7, 1.10),  -- Bow of Silence: +20% DEX, +10% LCK
        (11, 3, 1.10), (11, 5, 1.20),  -- Leather Quiver: +10% DEX, +20% HP
        (24, 5, 1.25), (24, 1, 1.20),  -- Iron Shield: +25% CON, +20% HP
        (25, 3, 1.15),                 -- Boots of Swiftness: +15% DEX
        (26, 3, 1.10),                 -- Cloak of Shadows: +10% DEX
        (27, 5, 1.10),                 -- Ring of Fortitude: +10% HP
        (28, 4, 1.20), (28, 7, 1.10),  -- Amulet of Cinders: +20% INT, +10% LCK
        (29, 4, 1.10),                 -- Wand of Sparks: +10% INT
        (30, 5, 1.10),                 -- Traveler's Ration: +10% HP
        (31, 3, 1.20), (31, 7, 1.10),  -- Crystal Dagger: +20% DEX, +10% LCK
        (32, 5, 1.15),                 -- Phoenix Feather: +15% HP
        (33, 7, 1.10),                 -- Luck Charm: +10% LCK
        (34, 4, 1.20),                 -- Earth Totem: +20% INT
        (35, 5, 1.15),                 -- Sun Elixir: +15% HP
        (36, 3, 1.20), (36, 7, 1.10),  -- Shadow Cloak: +20% DEX, +10% LCK
        (37, 5, 1.30), (37, 1, 1.10),  -- Rejuvenation Scroll: +30% HP, +10% CON
        (38, 5, 1.10),                 -- Pebble of Power: +10% CON
        (39, 3, 1.15),                 -- Silent Boots: +15% DEX
        (40, 7, 0.90)                  -- Lucky Coin: -10% LCK
ON CONFLICT DO NOTHING;


/* ---------- ITEM USE EFFECTS ------------------------------ */
INSERT INTO "ItemUseEffect"(item_id, is_healing, value) VALUES
        (2 , true , 15.0),   -- Minor Healing Potion   → +15 HP
        (3 , false, 14.0),   -- Great Healing Potion   → +14 HP
        (4 , false,  -7.0),  -- Minor Poison           → -7 HP
        (5 , false, -20.0),  -- Poison Vial            → -20 HP
        (12, true ,  8.0),   -- Elven Bread            → +8 HP
        (13, true ,  5.0),   -- Honeyed Nectar         → +5 HP
        (14, true , 12.0),   -- Spicy Jerky            → +12 HP
        (15, true ,  -2.0),  -- Mushroom Cap           → -2 HP
        (16, false,  -3.0),  -- Nightshade Spores      → -3 HP
        (17, true ,  5.0),   -- Ginseng Tea            → +5 HP
        (18, true ,  6.0),   -- Silver Wine            → +6 HP
        (19, true , 10.0),   -- Dragonfruit Slice      → +10 HP
        (20, true ,  3.0),   -- Tasty Cookie           → +3 HP
        (21, true , 15.0),   -- Roasted Boar           → +15 HP
        (22, true ,  -5.0),  -- Rotten Meat            → -5 HP
        (23, false,  -5.0),  -- Ghost Pepper           → -5 HP
        (30, true , 10.0),    -- Traveler's Ration     → +10 HP
        (32, true , 12.0),   -- Phoenix Feather        → +12 HP
        (35, true , 18.0),   -- Sun Elixir             → +18 HP
        (37, true , 14.0)    -- Rejuvenation Scroll    → +14 HP
ON CONFLICT DO NOTHING;

-- Aktualizácia sekvencií pre statické tabuľky
SELECT setval(pg_get_serial_sequence('"AttributeType"', 'id'), (SELECT MAX(id) FROM "AttributeType"));
SELECT setval(pg_get_serial_sequence('"ClassType"', 'id'), (SELECT MAX(id) FROM "ClassType"));
SELECT setval(pg_get_serial_sequence('"SpellCategory"', 'id'), (SELECT MAX(id) FROM "SpellCategory"));
SELECT setval(pg_get_serial_sequence('"Spell"', 'id'), (SELECT MAX(id) FROM "Spell"));
SELECT setval(pg_get_serial_sequence('"Item"', 'id'), (SELECT MAX(id) FROM "Item"));
