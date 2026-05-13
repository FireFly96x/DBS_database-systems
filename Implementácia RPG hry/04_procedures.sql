--------------------------------------------------------------------------------
-- 1) Vytvorenie postavy (create_character)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_create_character(TEXT, INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION sp_create_character(
    p_name TEXT,
    p_class_id INT,
    p_is_alliance BOOLEAN
    ) RETURNS VOID AS $$
DECLARE
    v_new_char_id INT;
BEGIN
    -- unikátne meno
    IF EXISTS (SELECT 1 FROM "Character" WHERE name = p_name)
    THEN RAISE EXCEPTION 'Character name % already exists', p_name;
    END IF;

    -- existencia triedy
    IF NOT EXISTS (SELECT 1 FROM "ClassType" WHERE id = p_class_id)
    THEN RAISE EXCEPTION 'ClassType % does not exist', p_class_id;
    END IF;

    -- vloženie novej postavy dočasne na 0
    INSERT INTO "Character"(name, class_id, curr_health, curr_inventory, is_alliance)
    VALUES (p_name, p_class_id, 0, 0, p_is_alliance)
    RETURNING id INTO v_new_char_id;

    -- inicializácia prázdnych atribútov
    INSERT INTO "CharacterAttribute"(character_id, attribute_id, value)
    SELECT v_new_char_id, id, 0 FROM "AttributeType";

    -- reset atribútov podľa base + class modifikátorov + nastav curr_health
    PERFORM sp_reset_attributes(v_new_char_id);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 2) Vstup do boja (enter_combat)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_enter_combat(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_enter_combat(
    p_combat_id INT,
    p_character_id INT
) RETURNS VOID AS $$
DECLARE
    v_round_id INT;
    v_round_number INT;
    v_start_ap NUMERIC;
    v_turn_score INT;
    v_event_number INT;
    v_hp_after INT;
    rec_item RECORD;
BEGIN
    -- kontrola existencie a aktivity combatu
    IF NOT EXISTS (SELECT 1 FROM "Combat" WHERE id = p_combat_id AND is_active)
       THEN RAISE EXCEPTION 'Combat % does not exist or is not active', p_combat_id;
    END IF;

    -- kontrola, že postava už nie je v nejakom combate
    IF f_is_character_in_combat(p_character_id)
       THEN RAISE EXCEPTION 'Character % already in combat', p_character_id;
    END IF;

    -- získanie aktuálneho kola
    SELECT id, round_number
    INTO v_round_id, v_round_number
    FROM "Round"
    WHERE combat_id = p_combat_id AND round_number = (
        SELECT MAX(round_number)
        FROM "Round" WHERE combat_id = p_combat_id
    );

    -- výpočet AP a turn_score (+1000 pre oneskorený vstup)
    v_start_ap := f_get_max_ap(p_character_id);
    v_turn_score := f_get_turn_score(p_character_id) + CASE WHEN v_round_number > 1 THEN 1000 ELSE 0 END;

    -- vloženie stavu do CharacterInCombat
    INSERT INTO "CharacterInCombat"(combat_id, character_id, round_joined, current_ap, turn_score
    ) VALUES (p_combat_id, p_character_id, v_round_number, v_start_ap, v_turn_score );

    -- CombatLog: označiť vstup pomocou 'join'
    INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, action_type, log_message
    ) VALUES (p_combat_id, v_round_id, p_character_id,'join',
              format('%s enters combat (round %s)',
    (SELECT name FROM "Character" WHERE id = p_character_id), v_round_number)
        ) RETURNING event_number INTO v_event_number;

    -- HealthChangeLog: inicializácia HP
    SELECT curr_health INTO v_hp_after FROM "Character" WHERE id = p_character_id;
    INSERT INTO "HealthChangeLog"(event_number, character_id, health_before, health_after
    ) VALUES (v_event_number, p_character_id, NULL, v_hp_after);

    -- ItemChangeLog: zaznam pre každý item v inventári
    FOR rec_item IN
        SELECT item_id, quantity FROM "CharacterInventory"
        WHERE character_id = p_character_id
    LOOP
        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity
        ) VALUES (v_event_number, p_character_id, p_combat_id, rec_item.item_id, 'add', rec_item.quantity);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 3) Zoslanie kúzla (cast_spell)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_spell_cast(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_spell_cast(
    p_caster_id INT,
    p_target_id INT,
    p_spell_id INT
) RETURNS VOID AS $$
DECLARE
    v_combat_id INT;
    v_round_id INT;
    v_cost NUMERIC;
    v_damage NUMERIC;
    v_hit BOOLEAN;
    v_event_number INT;
    v_hp_before NUMERIC;
    v_hp_after NUMERIC;
BEGIN
    -- check: obe postavy musia byť v boji
    IF NOT f_is_character_in_combat(p_caster_id)
       THEN RAISE EXCEPTION 'Caster % is not in combat', p_caster_id;
    END IF;
    IF NOT f_is_character_in_combat(p_target_id)
       THEN RAISE EXCEPTION 'Target % is not in combat', p_target_id;
    END IF;

    -- výpočet cost a damage
    v_cost := f_effective_spell_cost(p_spell_id, p_caster_id);
    v_damage := f_effective_spell_damage(p_spell_id, p_caster_id);

    -- kontrola AP
    IF (SELECT current_ap FROM "CharacterInCombat" WHERE character_id = p_caster_id) < v_cost
        THEN RAISE EXCEPTION 'Not enough AP: need %, have %', v_cost, (SELECT current_ap FROM "CharacterInCombat" WHERE character_id = p_caster_id);
    END IF;

    -- hit/miss pre damaging spells
    v_hit := f_is_spell_hit(p_caster_id, p_target_id, p_spell_id);
    IF NOT v_hit
        THEN v_damage := 0;
    END IF;

    -- odpočítať AP
    UPDATE "CharacterInCombat"
    SET current_ap = current_ap - v_cost
    WHERE character_id = p_caster_id;

    -- log akcie do CombatLog
    SELECT combat_id, (
        SELECT r.id FROM "Round" r
        WHERE r.combat_id = cic.combat_id
        ORDER BY round_number DESC LIMIT 1
    ) INTO v_combat_id, v_round_id
    FROM "CharacterInCombat" cic
    WHERE cic.character_id = p_caster_id;

    INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, target_char_id, action_type, spell_id, damage_dealt, log_message
    ) VALUES (v_combat_id, v_round_id, p_caster_id, p_target_id, 'spell_cast', p_spell_id, v_damage,
              format('%s casts %s on %s',
                (SELECT name FROM "Character" WHERE id = p_caster_id),
                (SELECT name FROM "Spell" WHERE id = p_spell_id),
                (SELECT name FROM "Character" WHERE id = p_target_id))
    ) RETURNING event_number INTO v_event_number;

    -- aplikácia damage/healu
    SELECT curr_health INTO v_hp_before FROM "Character" WHERE id = p_target_id;
    v_hp_after := GREATEST(v_hp_before - v_damage, 0);
    UPDATE "Character" SET curr_health = v_hp_after WHERE id = p_target_id;

    -- HealthChangeLog
    INSERT INTO "HealthChangeLog"(event_number, character_id, health_before, health_after
    ) VALUES (v_event_number, p_target_id, v_hp_before, v_hp_after);

    -- ak cieľ padol, handle death
    IF v_hp_after <= 0
        THEN PERFORM sp_handle_death(p_target_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 4) No-spell útok (auto_attack)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_auto_attack(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_auto_attack(
    p_attacker_id INT,
    p_target_id INT
) RETURNS VOID AS $$
DECLARE
    v_cost INT := 1;
    v_combat_id INT;
    v_round_id INT;
    v_damage NUMERIC;
    v_hit BOOLEAN;
    v_event_number INT;
    v_hp_before NUMERIC;
    v_hp_after NUMERIC;
BEGIN
    -- kontrola v boji pre obe strany
    IF NOT f_is_character_in_combat(p_attacker_id) OR NOT f_is_character_in_combat(p_target_id)
       THEN RAISE EXCEPTION 'Both attacker and target must be in combat';
    END IF;

    -- AP check
    IF (SELECT current_ap FROM "CharacterInCombat" WHERE character_id = p_attacker_id) < v_cost
        THEN RAISE EXCEPTION 'Not enough AP for auto_attack';
    END IF;

    -- hit/miss a damage výpočet
    v_hit := f_is_autoattack_hit(p_attacker_id, p_target_id);
    IF v_hit THEN
        SELECT ct.base_dmg INTO v_damage
        FROM "Character" c
        JOIN "ClassType" ct ON ct.id = c.class_id
        WHERE c.id = p_attacker_id;
    ELSE
        v_damage := 0;
    END IF;

    -- odpočet AP
    UPDATE "CharacterInCombat"
    SET current_ap = current_ap - v_cost
    WHERE character_id = p_attacker_id;

    -- log do CombatLog
    SELECT combat_id, (
        SELECT r.id FROM "Round" r
        WHERE r.combat_id = cic.combat_id
        ORDER BY round_number DESC LIMIT 1
    ) INTO v_combat_id, v_round_id
    FROM "CharacterInCombat" cic
    WHERE cic.character_id = p_attacker_id;

    INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, target_char_id, action_type, damage_dealt, log_message
    ) VALUES (v_combat_id, v_round_id, p_attacker_id, p_target_id, 'auto_attack', v_damage,
        format('%s strikes %s with base attack',
            (SELECT name FROM "Character" WHERE id = p_attacker_id),
            (SELECT name FROM "Character" WHERE id = p_target_id))
    ) RETURNING event_number INTO v_event_number;

    -- aplikovať damage a logovať HealthChangeLog
    SELECT curr_health INTO v_hp_before FROM "Character" WHERE id = p_target_id;
    v_hp_after := GREATEST(v_hp_before - v_damage, 0);
    UPDATE "Character" SET curr_health = v_hp_after WHERE id = p_target_id;
    INSERT INTO "HealthChangeLog"(event_number, character_id, health_before, health_after
    ) VALUES (v_event_number, p_target_id, v_hp_before, v_hp_after);

    -- handle death, ak treba
    IF v_hp_after <= 0
       THEN PERFORM sp_handle_death(p_target_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------
-- 5) Zmena inventára (add_item, remove_item) - attribute recalculation
---------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_change_inventory_mods(INT, INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION sp_change_inventory_mods(
    p_character_id INT,
    p_item_id      INT,
    p_add          BOOLEAN          -- TRUE = add, FALSE = remove
) RETURNS VOID AS $$
DECLARE
    v_qty_before  INT;
    v_is_cons     BOOLEAN;
    rec_mod       RECORD;
BEGIN
    -- je consumable?
    SELECT is_consumable INTO v_is_cons FROM "Item" WHERE id = p_item_id;

    --
    SELECT quantity INTO v_qty_before
    FROM  "CharacterInventory"
    WHERE character_id = p_character_id AND item_id = p_item_id
        FOR UPDATE;

    IF p_add THEN
        IF NOT FOUND THEN
            INSERT INTO "CharacterInventory"(character_id, item_id, quantity)
            VALUES (p_character_id, p_item_id, 1);
        ELSE
            UPDATE "CharacterInventory"
            SET quantity = v_qty_before + 1
            WHERE character_id = p_character_id AND item_id = p_item_id;
        END IF;
    ELSE  --  remove
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Character % does not own item %',
                p_character_id, p_item_id;
        ELSIF v_qty_before = 1 THEN
            DELETE FROM "CharacterInventory"
            WHERE character_id = p_character_id AND item_id = p_item_id;
        ELSE
            UPDATE "CharacterInventory"
            SET quantity = v_qty_before - 1
            WHERE character_id = p_character_id AND item_id = p_item_id;
        END IF;
    END IF;

    /* aktualizuj prenášanú váhu */
    UPDATE "Character"
    SET curr_inventory = f_get_current_inventory_weight(p_character_id)
    WHERE id = p_character_id;

    --
    IF NOT v_is_cons THEN
        FOR rec_mod IN
            SELECT attribute_id, modifier_value
            FROM "ItemAttributeModifier"
            WHERE item_id = p_item_id
            LOOP
                UPDATE "CharacterAttribute"
                SET value =  CASE
                                 WHEN p_add
                                     THEN value * rec_mod.modifier_value
                                 ELSE value / rec_mod.modifier_value
                    END
                WHERE  character_id = p_character_id
                  AND  attribute_id = rec_mod.attribute_id;
            END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 6) Použitie itemu (use_item)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_use_item(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_use_item(
    p_user_id INT,
    p_item_id INT,
    p_target_id INT
) RETURNS VOID AS $$
DECLARE
    v_in_combat BOOLEAN := f_is_character_in_combat(p_user_id);
    v_cost INT := 1;
    v_value NUMERIC;
    v_is_heal BOOLEAN;
    v_combat_id INT;
    v_round_id INT;
    v_event_number INT;
    v_hp_before NUMERIC;
    v_hp_after NUMERIC;
    v_msg TEXT;
BEGIN
    -- kontrola vlastníctva a použiteľnosti itemu
    IF NOT f_item_is_usable(p_user_id, p_item_id)
        THEN RAISE EXCEPTION 'Item % is not usable by %', p_item_id, p_user_id;
    END IF;

    -- načítať value a typ efektu
    SELECT value, is_healing INTO v_value, v_is_heal
    FROM "ItemUseEffect" WHERE item_id = p_item_id;

    IF v_in_combat THEN
        -- kontrola AP v boji
        IF (SELECT current_ap FROM "CharacterInCombat" WHERE character_id = p_user_id) < v_cost
            THEN RAISE EXCEPTION 'Not enough AP to use item';
        END IF;
        -- odpočítať AP
        UPDATE "CharacterInCombat"
        SET current_ap = current_ap - v_cost
        WHERE character_id = p_user_id;

        -- získať kontext combatu a kola
        SELECT combat_id, (
            SELECT r.id FROM "Round" r
            WHERE r.combat_id = cic.combat_id
            ORDER BY round_number DESC LIMIT 1
        ) INTO v_combat_id, v_round_id
        FROM "CharacterInCombat" cic
        WHERE cic.character_id = p_user_id;

        -- pripraviť log_message pre use_item
        IF p_user_id = p_target_id THEN
            v_msg := format('%s drinks %s',
                (SELECT name FROM "Character" WHERE id = p_user_id),
                (SELECT name FROM "Item" WHERE id = p_item_id));
        ELSE
            v_msg := format('%s throws %s at %s',
                (SELECT name FROM "Character" WHERE id = p_user_id),
                (SELECT name FROM "Item" WHERE id = p_item_id),
                (SELECT name FROM "Character" WHERE id = p_target_id));
        END IF;

        -- log CombatLog
        INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, target_char_id, action_type, item_id, damage_dealt, log_message
        ) VALUES (v_combat_id, v_round_id, p_user_id, p_target_id, 'use_item', p_item_id,
                CASE WHEN v_is_heal THEN -v_value ELSE v_value END, v_msg
        ) RETURNING event_number INTO v_event_number;

        -- log ItemChangeLog
        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity
        ) VALUES (v_event_number, p_user_id, v_combat_id, p_item_id, 'remove', 1);

        -- aplikovať heal/damage a log HealthChangeLog
        SELECT curr_health INTO v_hp_before FROM "Character" WHERE id = p_target_id;
        v_hp_after := GREATEST(v_hp_before - CASE WHEN v_is_heal THEN -v_value ELSE v_value END, 0);
        UPDATE "Character" SET curr_health = v_hp_after WHERE id = p_target_id;
        INSERT INTO "HealthChangeLog"(event_number, character_id, health_before, health_after
        ) VALUES (v_event_number, p_target_id, v_hp_before, v_hp_after);

        -- handle death, ak treba
        IF v_hp_after <= 0 THEN
            PERFORM sp_handle_death(p_target_id);
        END IF;
    ELSE
        -- mimo boja
        SELECT curr_health INTO v_hp_before FROM "Character" WHERE id = p_target_id;
        v_hp_after := GREATEST(v_hp_before - CASE WHEN v_is_heal THEN -v_value ELSE v_value END, 0);
        UPDATE "Character" SET curr_health = v_hp_after WHERE id = p_target_id;
    END IF;
    -- aktualizovať zmeny
    PERFORM sp_change_inventory_mods(p_user_id, p_item_id, FALSE);


END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 7) Zodvihnutie itemu (pick_item)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_pick_item(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_pick_item(
    p_character_id INT,
    p_item_id INT
) RETURNS VOID AS $$
DECLARE
    v_in_combat BOOLEAN := f_is_character_in_combat(p_character_id);
    v_cost INT := 1;
    v_combat_id INT;
    v_round_id INT;
    v_event_number INT;
    v_msg TEXT;
BEGIN
    -- kontrola dostupnosti itemu
    IF NOT f_item_is_pickable(p_character_id, p_item_id)
        THEN RAISE EXCEPTION 'Item % not available to pick', p_item_id;
    END IF;

    IF v_in_combat THEN
        -- kontrola AP
        IF (SELECT current_ap FROM "CharacterInCombat" WHERE character_id = p_character_id) < v_cost
            THEN RAISE EXCEPTION 'Not enough AP to pick item';
        END IF;
        UPDATE "CharacterInCombat"
        SET current_ap = current_ap - v_cost WHERE character_id = p_character_id;

        -- kontext combatu a kola
        SELECT combat_id, (
            SELECT r.id FROM "Round" r
            WHERE r.combat_id = cic.combat_id
            ORDER BY round_number DESC LIMIT 1
        ) INTO v_combat_id, v_round_id
        FROM "CharacterInCombat" cic
        WHERE cic.character_id = p_character_id;

        -- log pick_item do CombatLog
        v_msg := format('%s picks up %s from the ground',
            (SELECT name FROM "Character" WHERE id = p_character_id),
            (SELECT name FROM "Item" WHERE id = p_item_id) );

        INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, action_type, item_id, log_message
        ) VALUES (v_combat_id, v_round_id, p_character_id, 'pick_item', p_item_id, v_msg
        ) RETURNING event_number INTO v_event_number;

        -- aktualizovať CombatInventory
        UPDATE "CombatInventory"
        SET quantity = quantity - 1
        WHERE combat_id = v_combat_id AND item_id = p_item_id AND quantity > 1;
        DELETE FROM "CombatInventory"
        WHERE combat_id = v_combat_id AND item_id = p_item_id AND quantity = 1;

        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity)
        VALUES (v_event_number, NULL, v_combat_id, p_item_id, 'remove', 1);

        -- log ItemChangeLog
        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity
        ) VALUES (v_event_number, p_character_id, v_combat_id, p_item_id, 'add', 1);
    END IF;

    -- pridať do CharacterInventory
    PERFORM sp_change_inventory_mods(p_character_id, p_item_id, TRUE);

END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 8) Vyhodenie itemu (drop_item)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_drop_item(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_drop_item(
    p_character_id INT,
    p_item_id INT
) RETURNS VOID AS $$
DECLARE
    v_in_combat BOOLEAN := f_is_character_in_combat(p_character_id);
    v_cost INT := 1;
    v_combat_id INT;
    v_round_id INT;
    v_event_number INT;
    v_msg TEXT;
BEGIN
    -- kontrola vlastníctva itemu
    IF NOT EXISTS (
        SELECT 1 FROM "CharacterInventory"
        WHERE character_id = p_character_id AND item_id = p_item_id
    ) THEN
        RAISE EXCEPTION 'Character % does not own item %', p_character_id, p_item_id;
    END IF;

    IF v_in_combat THEN
        -- kontrola AP
        IF (SELECT current_ap FROM "CharacterInCombat" WHERE character_id = p_character_id) < v_cost
        THEN
            RAISE EXCEPTION 'Not enough AP to drop item';
        END IF;
        UPDATE "CharacterInCombat"
        SET current_ap = current_ap - v_cost
        WHERE character_id = p_character_id;

        -- kontext combatu a kola
        SELECT combat_id, (
            SELECT r.id FROM "Round" r
            WHERE r.combat_id = cic.combat_id
            ORDER BY round_number DESC LIMIT 1
        ) INTO v_combat_id, v_round_id
        FROM "CharacterInCombat" cic
        WHERE cic.character_id = p_character_id;

        -- log drop_item do CombatLog
        v_msg := format('%s drops %s on the ground',
                        (SELECT name FROM "Character" WHERE id = p_character_id),
                        (SELECT name FROM "Item" WHERE id = p_item_id) );

        INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, action_type, item_id, log_message)
        VALUES (v_combat_id, v_round_id, p_character_id, 'drop_item', p_item_id, v_msg)
        RETURNING event_number INTO v_event_number;

        -- pridať do CombatInventory
        INSERT INTO "CombatInventory"(combat_id, item_id, quantity)
        VALUES (v_combat_id, p_item_id, 1)
        ON CONFLICT (combat_id, item_id) DO UPDATE
            SET quantity = "CombatInventory".quantity + 1;

        -- log ItemChangeLog (add to ground, remove from character)
        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity)
        VALUES (v_event_number, NULL, v_combat_id, p_item_id, 'add', 1);

        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity)
        VALUES (v_event_number, p_character_id, v_combat_id, p_item_id, 'remove', 1);
    END IF;

    -- odobrať z CharacterInventory
    PERFORM sp_change_inventory_mods(p_character_id, p_item_id, FALSE);

END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 9) Pass (ukončenie ťahu)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_pass(INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_pass(
    p_character_id INT
) RETURNS VOID AS $$
DECLARE
    v_combat_id INT;
    v_round_id INT;
BEGIN
    -- kontrola, že postava je v boji
    IF NOT f_is_character_in_combat(p_character_id)
        THEN RAISE EXCEPTION 'Character % not in combat', p_character_id;
    END IF;

    -- vynulovanie AP a turn_score
    UPDATE "CharacterInCombat"
    SET current_ap = 0, turn_score = 0
    WHERE character_id = p_character_id;

    -- log pass do CombatLog
    SELECT combat_id, (
        SELECT r.id FROM "Round" r
        WHERE r.combat_id = cic.combat_id
        ORDER BY round_number DESC LIMIT 1
    ) INTO v_combat_id, v_round_id
    FROM "CharacterInCombat" cic
    WHERE cic.character_id = p_character_id;

    INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, action_type, log_message
    ) VALUES (v_combat_id, v_round_id, p_character_id, 'pass',
        format('%s skips the turn', (SELECT name FROM "Character" WHERE id = p_character_id)) );
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 10) Round reset (reset AP)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_reset_round(INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_reset_round(
    p_combat_id INT
) RETURNS VOID AS $$
DECLARE
    v_new_round_number INT;
    v_round_id INT;
    rec_mod RECORD;
BEGIN
    -- overenie, že boj stále beží
    IF NOT EXISTS (SELECT 1 FROM "Combat" WHERE id = p_combat_id AND is_active)
       THEN RAISE EXCEPTION 'Combat % is not active', p_combat_id;
    END IF;

    -- pre postavu čo má Death's Trace..
    FOR rec_mod IN
        SELECT attribute_id, modifier_value
        FROM "ItemAttributeModifier"
        WHERE item_id = 1
        LOOP
            -- vráti hodnotu atribútu vydelením modifierom
            UPDATE "CharacterAttribute"
            SET value = value / rec_mod.modifier_value
            WHERE character_id IN (
                SELECT character_id
                FROM "CharacterInCombat"
                WHERE combat_id = p_combat_id
            )
              AND attribute_id = rec_mod.attribute_id;
        END LOOP;

    -- potom odstráň Death's Trace z inventára
    DELETE FROM "CharacterInventory"
    WHERE character_id IN (
        SELECT character_id
        FROM "CharacterInCombat"
        WHERE combat_id = p_combat_id
    ) AND item_id = 1;

    -- vypočítať nové číslo kola
    SELECT COALESCE(MAX(round_number), 0) + 1
    INTO v_new_round_number
    FROM "Round"
    WHERE combat_id = p_combat_id;

-- založiť nové kolo
    INSERT INTO "Round"(combat_id, round_number)
    VALUES (p_combat_id, v_new_round_number)
    RETURNING id INTO v_round_id;

-- obnoviť AP a turn_score pre všetkých v combatu
    UPDATE "CharacterInCombat"
    SET current_ap = f_get_max_ap(character_id),
        turn_score = f_get_turn_score(character_id)
    WHERE combat_id = p_combat_id;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 11) Handle death & respawn
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_handle_death(INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_handle_death(
    p_character_id INT
) RETURNS VOID AS $$
DECLARE
    v_combat_id INT;
    v_round_id INT;
    v_event_number INT;
    rec_item RECORD;
    v_item_id INT := 1; -- debuff item
BEGIN
    -- odstránenie z CharacterInCombat
    SELECT combat_id INTO v_combat_id
    FROM "CharacterInCombat" WHERE character_id = p_character_id;
    DELETE FROM "CharacterInCombat" WHERE character_id = p_character_id;

    -- log died do CombatLog
    SELECT r.id INTO v_round_id
        FROM "Round" r
        WHERE r.combat_id = v_combat_id
        ORDER BY round_number DESC LIMIT 1;
    INSERT INTO "CombatLog"(combat_id, round_id, acting_char_id, action_type, log_message
    ) VALUES (v_combat_id, v_round_id, p_character_id, 'died',
              format('%s has fallen in battle', (SELECT name FROM "Character" WHERE id = p_character_id))
    ) RETURNING event_number INTO v_event_number;

    -- presun itemov do CombatInventory + ItemChangeLog
    FOR rec_item IN
    SELECT item_id, quantity FROM "CharacterInventory"
    WHERE character_id = p_character_id
    LOOP
        INSERT INTO "CombatInventory"(combat_id, item_id, quantity)
        VALUES (v_combat_id, rec_item.item_id, rec_item.quantity)
        ON CONFLICT (combat_id, item_id) DO
        UPDATE SET quantity = "CombatInventory".quantity + rec_item.quantity;

        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity
        ) VALUES (v_event_number, p_character_id, v_combat_id, rec_item.item_id, 'remove', rec_item.quantity);

        INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity
        ) VALUES (v_event_number, NULL, v_combat_id, rec_item.item_id, 'add', rec_item.quantity);
    END LOOP;

    -- vyčistenie inventára postavy
    DELETE FROM "CharacterInventory" WHERE character_id = p_character_id;

    -- respawn: obnoviť HP a pridať debuff item
    PERFORM sp_reset_attributes(p_character_id);
    PERFORM sp_change_inventory_mods(p_character_id, v_item_id, TRUE);
    UPDATE "Character"
    SET curr_health = (
        SELECT value FROM "CharacterAttribute"
        WHERE character_id = p_character_id AND attribute_id = 1
    ) WHERE id = p_character_id;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------------
-- 12) Reset atribútov postavy (ked nemá žiadne itemy)
---------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS sp_reset_attributes(INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_reset_attributes(
    p_character_id INT
) RETURNS VOID AS $$
DECLARE
    rec_attr RECORD;
    v_class_id INT;
    v_mod_value NUMERIC;
BEGIN
    -- zisti class_id postavy
    SELECT class_id INTO v_class_id
    FROM "Character" WHERE id = p_character_id;

    -- resetni každému atribútu base_value + class modifier
    FOR rec_attr IN
        SELECT id AS attribute_id, att.base_value
        FROM "AttributeType" as att
        LOOP
            -- nájdi class modifier (ak je)
            SELECT value INTO v_mod_value
            FROM "ClassAttributeModifier"
            WHERE class_id = v_class_id AND attribute_id = rec_attr.attribute_id
            LIMIT 1;

            -- ak nie je, nastav modifier na 0
            v_mod_value := COALESCE(v_mod_value, 0);

            -- aktualizuj hodnotu
            UPDATE "CharacterAttribute"
            SET value = rec_attr.base_value + v_mod_value
            WHERE character_id = p_character_id AND attribute_id = rec_attr.attribute_id;
        END LOOP;



    -- aktualizuj curr_health v Character podľa aktuálnej hodnoty atribútu Health (id = 5)
    UPDATE "Character"
    SET curr_health = (
        SELECT value FROM "CharacterAttribute"
        WHERE character_id = p_character_id AND attribute_id = 1
    ) WHERE id = p_character_id;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------------------------
-- 13) Začiatok boja (sp_start_combat)
------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS sp_start_combat(INT[]) CASCADE;
CREATE OR REPLACE FUNCTION sp_start_combat(
    p_character_ids INT[] ) RETURNS INT AS $$
DECLARE
    v_combat_id    INT;
    v_round_id     INT;
    v_event_number INT;
    v_true_count   INT;
    v_false_count  INT;
    rec_id         INT;
    v_curr_health  INT;
    v_start_ap     NUMERIC;
    v_turn_score   INT;
    rec_item       RECORD;
    v_item_count   INT;
    v_qty          INT;
BEGIN
    -- overenie duplicít
    IF (SELECT COUNT(DISTINCT x) FROM unnest(p_character_ids) AS x)
        <> array_length(p_character_ids, 1)
    THEN
        RAISE EXCEPTION 'Duplicate character IDs are not allowed';
    END IF;

    -- Overenie, že medzi postavami sú obe aliancie
    SELECT
                COUNT(*) FILTER (WHERE is_alliance) ,
                COUNT(*) FILTER (WHERE NOT is_alliance)
    INTO v_true_count, v_false_count
    FROM "Character"
    WHERE id = ANY(p_character_ids);

    IF v_true_count = 0 OR v_false_count = 0 THEN
        RAISE EXCEPTION 'Combat requires at least one Alliance (TRUE) and one Horde (FALSE) character';
    END IF;

    -- Vytvorenie nového combatu
    INSERT INTO "Combat"(is_active)
    VALUES (TRUE)
    RETURNING id INTO v_combat_id;

    -- Prvé kolo
    INSERT INTO "Round"(combat_id, round_number)
    VALUES (v_combat_id, 1)
    RETURNING id INTO v_round_id;

    -- Pridanie postáv do CharacterInCombat
    FOREACH rec_id IN ARRAY p_character_ids LOOP
            SELECT curr_health
            INTO   v_curr_health
            FROM   "Character"
            WHERE  id = rec_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Character % does not exist', rec_id;
            ELSIF v_curr_health <= 0 THEN
                RAISE EXCEPTION 'Character % is dead (curr_health = %)', rec_id, v_curr_health;
            ELSIF f_is_character_in_combat(rec_id) THEN
                RAISE EXCEPTION 'Character % already in another combat', rec_id;
            END IF;

            v_start_ap   := f_get_max_ap(rec_id);
            v_turn_score := f_get_turn_score(rec_id);

            INSERT INTO "CharacterInCombat"(combat_id, character_id, round_joined, current_ap, turn_score
            ) VALUES (v_combat_id, rec_id, 1, v_start_ap, v_turn_score);
        END LOOP;

    -- Záznam 'start' eventu
    INSERT INTO "CombatLog"(combat_id, round_id, action_type, log_message)
    VALUES (v_combat_id, v_round_id, 'start', format('Combat %s started with %s participants', v_combat_id, array_length(p_character_ids,1)))
    RETURNING event_number INTO v_event_number;

    -- Inicializácia HealthChangeLog
    FOREACH rec_id IN ARRAY p_character_ids
        LOOP
            SELECT curr_health INTO v_curr_health
            FROM "Character" WHERE id = rec_id;

            INSERT INTO "HealthChangeLog"(event_number, character_id, health_before, health_after
            ) VALUES (v_event_number, rec_id, NULL, v_curr_health);
        END LOOP;

    -- Generovanie 3–5 náhodných itemov
    v_item_count := 3 + floor(random() * 3)::INT;
    FOR rec_item IN
        SELECT id AS item_id FROM "Item" ORDER BY random() LIMIT v_item_count
        LOOP
            v_qty := 1 + floor(random() * 3)::INT;
            INSERT INTO "CombatInventory"(combat_id, item_id, quantity)
            VALUES (v_combat_id, rec_item.item_id, v_qty)
            ON CONFLICT(combat_id, item_id) DO UPDATE
                SET quantity = "CombatInventory".quantity + EXCLUDED.quantity;

            INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity
            ) VALUES (v_event_number, NULL, v_combat_id, rec_item.item_id, 'add', v_qty);
        END LOOP;

    -- Presun existujúcich itemov postáv do CombatInventory
    FOR rec_item IN
        SELECT character_id, item_id, quantity
        FROM "CharacterInventory"
        WHERE character_id = ANY(p_character_ids)
        LOOP
            INSERT INTO "ItemChangeLog"(event_number, character_id, combat_id, item_id, change, quantity)
            VALUES (v_event_number, rec_item.character_id, v_combat_id, rec_item.item_id, 'add', rec_item.quantity);
        END LOOP;

    RETURN v_combat_id;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- 14) Centrálna combat procedúra
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS sp_take_turn(TEXT, INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_take_turn(
    p_action TEXT,         -- 'cast_spell','auto_attack','use_item','pick_item','drop_item','pass'
    p_actor_id INT,
    p_target_id INT DEFAULT NULL,
    p_spell_or_item_id INT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_combat_id INT;
BEGIN
    -- zisti combat_id, v ktorom je actor
    SELECT combat_id
    INTO   v_combat_id
    FROM   "CharacterInCombat"
    WHERE  character_id = p_actor_id;

    IF NOT FOUND
    THEN RAISE EXCEPTION 'Character % is not in combat', p_actor_id;
    END IF;

    -- ak ma 0 turnscore, tak sa nestane nič
    IF (SELECT turn_score FROM "CharacterInCombat" WHERE character_id = p_actor_id) <= 0
        THEN RETURN;
    END IF;

    -- dispatch akcie
    CASE p_action
        WHEN 'spell_cast'
            THEN PERFORM sp_spell_cast(p_actor_id, p_target_id, p_spell_or_item_id);
        WHEN 'auto_attack'
            THEN PERFORM sp_auto_attack(p_actor_id, p_target_id);
        WHEN 'use_item'
            THEN PERFORM sp_use_item(p_actor_id, p_spell_or_item_id, p_target_id);
        WHEN 'pick_item'
            THEN PERFORM sp_pick_item(p_actor_id, p_spell_or_item_id);
        WHEN 'drop_item'
            THEN PERFORM sp_drop_item(p_actor_id, p_spell_or_item_id);
        WHEN 'pass'
            THEN PERFORM sp_pass(p_actor_id);
        ELSE
            RAISE EXCEPTION 'Unknown action %', p_action;
        END CASE;

    -- na záver vždy skontroluj stav boja
    PERFORM f_check_combat_state(v_combat_id);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNKCIA - musí tu byť lebo má v sebe procedúru ktorá sa inicializuje pred ňou
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS f_check_combat_state(INT) CASCADE;
CREATE OR REPLACE FUNCTION f_check_combat_state(
    p_combat_id INT
) RETURNS VOID AS $$
DECLARE
    v_alliance_alive BOOLEAN;
    v_horde_alive BOOLEAN;
BEGIN
    -- kontrola, či sú ešte živí hráči na oboch stranách
    SELECT  BOOL_OR(is_alliance) FILTER (WHERE c.curr_health > 0),
            BOOL_OR(NOT is_alliance) FILTER (WHERE c.curr_health > 0)
    INTO v_alliance_alive, v_horde_alive
    FROM "Character" c JOIN "CharacterInCombat" cic ON c.id = cic.character_id
    WHERE cic.combat_id = p_combat_id;

    -- ak už jedna strana nemá nikoho nažive, boj končí
    IF NOT v_alliance_alive OR NOT v_horde_alive
    THEN UPDATE "Combat" SET is_active = FALSE WHERE id = p_combat_id;
    DELETE FROM "CharacterInCombat"
    WHERE combat_id = p_combat_id;

    RETURN;
    END IF;

    -- ak všetci odohrali (turn_score = 0), resetnúť kolo
    IF NOT EXISTS (
        SELECT 1
        FROM "CharacterInCombat"
        WHERE combat_id = p_combat_id AND turn_score > 0
    ) THEN
        PERFORM sp_reset_round(p_combat_id);
    END IF;
END;
$$ LANGUAGE plpgsql;