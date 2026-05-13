-----------------------------------------------------------------------------
-- 1) Základné funkcie
--------------------------------------------------------------------------------

-- Vráti hodnotu atribútu pre postavu (ak nie je definované, vráti 0)
DROP FUNCTION IF EXISTS f_get_character_attribute(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_character_attribute(
    p_character_id INT,
    p_attribute_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_value NUMERIC;
BEGIN
    SELECT value
    INTO v_value
    FROM "CharacterAttribute"
    WHERE character_id = p_character_id AND attribute_id = p_attribute_id;
    -- ak hodnota neexistuje, vraciame 0
    RETURN COALESCE(v_value, 0);
END;
$$ LANGUAGE plpgsql;

-- Vráti AP modifier pre triedu postavy
DROP FUNCTION IF EXISTS f_get_class_modifier_ap(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_class_modifier_ap(
    p_character_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_mod_ap NUMERIC;
BEGIN
    SELECT ct.modifier_ap
    INTO v_mod_ap
    FROM "Character" c JOIN "ClassType" ct ON ct.id = c.class_id
    WHERE c.id = p_character_id;
    -- získanie koeficientu AP z ClassType
    RETURN COALESCE(v_mod_ap, 1);
END;
$$ LANGUAGE plpgsql;

-- Vráti inventory modifier pre triedu postavy
DROP FUNCTION IF EXISTS f_get_class_modifier_inventory(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_class_modifier_inventory(
    p_character_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_mod_inv NUMERIC;
BEGIN
    SELECT ct.modifier_inventory
    INTO v_mod_inv
    FROM "Character" c JOIN "ClassType" ct ON ct.id = c.class_id
    WHERE c.id = p_character_id;
    -- získanie koeficientu inventára z ClassType
    RETURN COALESCE(v_mod_inv, 1);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 2) Štatistické výpočty
--------------------------------------------------------------------------------

-- Max AP = (Dexterity + Intelligence) × modifier_ap
DROP FUNCTION IF EXISTS f_get_max_ap(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_max_ap(
    p_character_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_dex NUMERIC := f_get_character_attribute(p_character_id, 3); -- dexterity
    v_int NUMERIC := f_get_character_attribute(p_character_id, 4); -- intelligence
    v_mod_ap NUMERIC := f_get_class_modifier_ap(p_character_id);
BEGIN
    -- vypočítame maximálne AP podľa vzorca
    RETURN (v_dex + v_int) * v_mod_ap;
END;
$$ LANGUAGE plpgsql;

-- Max Inventory = (Strength + Constitution) × modifier_inventory
DROP FUNCTION IF EXISTS f_get_max_inventory(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_max_inventory(
    p_character_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_str NUMERIC := f_get_character_attribute(p_character_id, 2); -- strength
    v_con NUMERIC := f_get_character_attribute(p_character_id, 5); -- constitution
    v_mod_inv NUMERIC := f_get_class_modifier_inventory(p_character_id);
BEGIN
    -- vypočítame maximálnu nosnosť inventára
    RETURN (v_str + v_con) * v_mod_inv;
END;
$$ LANGUAGE plpgsql;

-- Turn Score = 2 × Dexterity + Intelligence
DROP FUNCTION IF EXISTS f_get_turn_score(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_turn_score(
    p_character_id INT
) RETURNS INTEGER AS $$
BEGIN
    -- iniciatívne skóre pre poradie ťahov
    RETURN 2 * f_get_character_attribute(p_character_id, 3)  -- DEX je stále najdôležitejší
        +     f_get_character_attribute(p_character_id, 4)  -- INT = rozvaha, rýchla reakcia
        +     f_get_character_attribute(p_character_id, 7);  -- LUCK = šťastie pri pohotovej reakcii
END
$$ LANGUAGE plpgsql;

-- Armor Class = 10 + (Dexterity / 2) + armor_bonus
DROP FUNCTION IF EXISTS f_get_armor_class(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_armor_class(
    p_character_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_dex NUMERIC := f_get_character_attribute(p_character_id, 3); -- dexterity
    v_bonus NUMERIC;
BEGIN
    SELECT ct.armor_bonus
    INTO v_bonus
    FROM "Character" c JOIN "ClassType" ct ON ct.id = c.class_id
    WHERE c.id = p_character_id;
    -- základná AC + Dexterity + bonus z triedy
    RETURN 10 + (v_dex / 2) + v_bonus;
END;
$$ LANGUAGE plpgsql;

-- Vracia náhodné číslo od 1 do 20
DROP FUNCTION IF EXISTS f_roll_d20() CASCADE;
CREATE OR REPLACE FUNCTION f_roll_d20() RETURNS INT AS $$
BEGIN
    -- simulácia hody d20
    RETURN FLOOR(RANDOM() * 20) + 1;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 3) Spell cost & damage
--------------------------------------------------------------------------------

-- Effektívna cena kúzla = base_cost × modifier_ap × PRODUCT(modifier_cost)
DROP FUNCTION IF EXISTS f_effective_spell_cost(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_effective_spell_cost(
    p_spell_id INT,
    p_caster_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_cost NUMERIC;
    v_mod RECORD;
BEGIN
    -- základná cena × AP modifier
    SELECT base_cost * f_get_class_modifier_ap(p_caster_id)
    INTO v_cost
    FROM "Spell"
    WHERE id = p_spell_id;

    -- aplikovať každý modifier_cost
    FOR v_mod IN
    SELECT modifier_cost
    FROM "SpellAttributeModifier"
    WHERE spell_id = p_spell_id
        LOOP
            v_cost := v_cost * v_mod.modifier_cost;
        END LOOP;

    RETURN v_cost;
END;
$$ LANGUAGE plpgsql;

-- Effektívne poškodenie kúzla = base_dmg × PRODUCT(modifier_dmg)
DROP FUNCTION IF EXISTS f_effective_spell_damage(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_effective_spell_damage(
    p_spell_id INT,
    p_caster_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_base_dmg NUMERIC;
    v_attr_value NUMERIC;
    v_final_dmg NUMERIC;
    v_mod RECORD;
BEGIN
    -- základné poškodenie kúzla
    SELECT base_dmg
    INTO v_base_dmg
    FROM "Spell"
    WHERE id = p_spell_id;
    v_final_dmg := v_base_dmg;

    -- aplikovať každý modifier_dmg
    FOR v_mod IN
    SELECT attribute_id, modifier_dmg
    FROM "SpellAttributeModifier"
    WHERE spell_id = p_spell_id
    LOOP
        SELECT value
        INTO v_attr_value
        FROM "CharacterAttribute"
        WHERE character_id = p_caster_id AND attribute_id = v_mod.attribute_id;

        -- vplyv atribútu na damage
        v_final_dmg := v_final_dmg * v_mod.modifier_dmg * (v_attr_value / 10);
    END LOOP;
    RETURN v_final_dmg;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 4) Validácie stavu postavy
--------------------------------------------------------------------------------

-- Je postava nažive?
DROP FUNCTION IF EXISTS f_is_character_alive(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_is_character_alive(
    p_character_id INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_hp NUMERIC;
BEGIN
    SELECT curr_health
    INTO v_hp
    FROM "Character"
    WHERE id = p_character_id;
    -- true, ak má viac než 0 HP
    RETURN v_hp > 0;
END;
$$ LANGUAGE plpgsql;

-- Postava je v aktuálnom boji?
DROP FUNCTION IF EXISTS f_is_character_in_combat(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_is_character_in_combat(
    p_character_id INT
) RETURNS BOOLEAN AS $$
BEGIN
    -- kontrola existencie záznamu v CharacterInCombat
    RETURN EXISTS (
        SELECT 1
        FROM "CharacterInCombat"
        WHERE character_id = p_character_id
    );
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 5) Inventár a itemy
--------------------------------------------------------------------------------

-- Súčet váhy inventára postavy
DROP FUNCTION IF EXISTS f_get_current_inventory_weight(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_get_current_inventory_weight(
    p_character_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(ci.quantity * i.weight), 0)
    INTO v_total
    FROM "CharacterInventory" ci JOIN "Item" i ON i.id = ci.item_id
    WHERE ci.character_id = p_character_id;
    -- vráti celkovú váhu všetkých itemov
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Vie postava zdvihnúť item bez prekročenia limitu?
DROP FUNCTION IF EXISTS f_can_lift(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_can_lift(
    p_character_id INT,
    p_item_id INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_current NUMERIC := f_get_current_inventory_weight(p_character_id);
    v_weight NUMERIC;
    v_max_inv NUMERIC := f_get_max_inventory(p_character_id);
BEGIN
    SELECT weight
    INTO v_weight
    FROM "Item"
    WHERE id = p_item_id;
    -- skontrolovať, či pridaná váha nepresiahne maximálnu nosnosť
    RETURN (v_current + v_weight) <= v_max_inv;
END;
$$ LANGUAGE plpgsql;

-- Je item dostupný na zdvihnutie?
DROP FUNCTION IF EXISTS f_item_is_pickable(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_item_is_pickable(
    p_character_id INT,
    p_item_id INT
) RETURNS BOOLEAN AS $$
BEGIN
    -- item s id 1 sa nedá zdvihnúť (Death's Trace)
    IF p_item_id = 1 THEN
        RETURN FALSE;
    END IF;

    IF NOT f_is_character_in_combat(p_character_id) THEN
        -- mimo boja môže vziať čokoľvek
        RETURN TRUE;
    END IF;
    -- v boji: item musí byť v CombatInventory súboja
    RETURN EXISTS (
        SELECT 1
        FROM "CharacterInCombat" cc JOIN "CombatInventory" ci ON ci.combat_id = cc.combat_id
        WHERE cc.character_id = p_character_id AND ci.item_id = p_item_id
    );
END;
$$ LANGUAGE plpgsql;

-- Môže postava použiť daný item?
DROP FUNCTION IF EXISTS f_item_is_usable(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_item_is_usable(
    p_character_id INT,
    p_item_id INT
) RETURNS BOOLEAN AS $$
BEGIN
    -- item musí byť in inventory, consumable a mať definovaný efekt
    RETURN EXISTS (
        SELECT 1
        FROM "CharacterInventory" ci
            JOIN "Item" i ON i.id = ci.item_id
            JOIN "ItemUseEffect" ue ON ue.item_id = ci.item_id
        WHERE ci.character_id = p_character_id AND ci.item_id = p_item_id AND i.is_consumable
    );
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 6) Kontrola zásahu (hit/miss)
--------------------------------------------------------------------------------

-- Hit check pre autoattack (Strength)
DROP FUNCTION IF EXISTS f_is_autoattack_hit(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_is_autoattack_hit(
    p_attacker_id INT,
    p_target_id INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_roll INT := f_roll_d20();
    v_str NUMERIC := f_get_character_attribute(p_attacker_id, 1);
    v_ac NUMERIC := f_get_armor_class(p_target_id);
BEGIN
    -- návrat true ak roll + bonus > AC cieľa
    RETURN (v_roll + (v_str / 2)) > v_ac;
END;
$$ LANGUAGE plpgsql;

-- Hit check pre spell (iba damaging spells)
DROP FUNCTION IF EXISTS f_is_spell_hit(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION f_is_spell_hit(
    p_caster_id INT,
    p_target_id INT,
    p_spell_id INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_base_dmg NUMERIC;
    v_roll INT;
    v_attr_sum NUMERIC;
    v_mod_count INT;
    v_hit_bonus NUMERIC;
    v_ac NUMERIC;
BEGIN
    SELECT base_dmg
    INTO v_base_dmg
    FROM "Spell"
    WHERE id = p_spell_id;

    IF v_base_dmg <= 0 THEN
        -- healing alebo 0 dmg: vždy success
        RETURN TRUE;
    END IF;

    -- hádzeme d20
    v_roll := f_roll_d20();

    -- spočítame hodnoty relevantných atribútov
    SELECT
        COUNT(*) ,
        COALESCE(SUM(f_get_character_attribute(p_caster_id, attribute_id)), 0)
    INTO
        v_mod_count,
        v_attr_sum
    FROM "SpellAttributeModifier"
    WHERE spell_id = p_spell_id;

    -- priemerný bonus z atribútov + menší násobiteľ
    IF v_mod_count > 0 THEN
        v_hit_bonus := (v_attr_sum / v_mod_count) / 2;
    ELSE
        v_hit_bonus := 0;
    END IF;
    v_ac := f_get_armor_class(p_target_id);
    -- hit, ak roll + bonus > AC
    RETURN (v_roll + v_hit_bonus) > v_ac;
END;
$$ LANGUAGE plpgsql;