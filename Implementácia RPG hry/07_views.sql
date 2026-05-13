-- aktuálne kolo + všetci aktívni účastníci + ich AP
CREATE OR REPLACE VIEW v_combat_state AS
SELECT
    c.id AS combat_id,
    r.round_number AS current_round,
    cic.character_id,
    ch.name AS character_name,
    cic.current_ap,
    cic.turn_score
FROM "Combat" c
     JOIN "Round" r ON r.combat_id = c.id
              AND r.round_number = (
                  SELECT MAX(r2.round_number)
                  FROM "Round" r2
                  WHERE r2.combat_id = c.id
              )
     JOIN "CharacterInCombat" cic ON cic.combat_id = c.id
     JOIN "Character" ch ON ch.id = cic.character_id
WHERE c.is_active;

-- 2) Celkový dmg podľa postáv (od najväčšieho po najmenšie)
CREATE OR REPLACE VIEW v_most_damage AS
SELECT
    cl.acting_char_id AS character_id,
    ch.name AS character_name,
    SUM(cl.damage_dealt) AS total_damage
FROM "CombatLog" cl
    JOIN "Character" ch ON ch.id = cl.acting_char_id
WHERE cl.damage_dealt > 0
GROUP BY cl.acting_char_id, ch.name
ORDER BY total_damage DESC;

-- 3) Najsilnejší hráči: podľa damage dealt a zostávajúceho HP
CREATE OR REPLACE VIEW v_strongest_characters AS
SELECT
    c.id AS character_id,
    c.name AS character_name,
    COALESCE(d.total_damage,0) AS total_damage,
    c.curr_health AS current_health
FROM "Character" c
    LEFT JOIN (
        SELECT acting_char_id, SUM(damage_dealt) AS total_damage
        FROM "CombatLog"
        WHERE damage_dealt > 0
        GROUP BY acting_char_id
    ) d ON d.acting_char_id = c.id
ORDER BY COALESCE(d.total_damage,0) DESC, c.curr_health DESC;

-- 4) Celkové poškodenie v každom boji
CREATE OR REPLACE VIEW v_combat_damage AS
SELECT combat_id, SUM(damage_dealt) AS total_damage
FROM "CombatLog"
WHERE damage_dealt > 0
GROUP BY combat_id
ORDER BY combat_id;

-- 5) Štatistiky kúziel: počet použití + dmg summary
CREATE OR REPLACE VIEW v_spell_statistics AS
SELECT
    cl.spell_id,
    s.name AS spell_name,
    COUNT(*) AS usage_count,
    SUM(cl.damage_dealt) AS total_damage
FROM "CombatLog" cl
    JOIN "Spell" s ON s.id = cl.spell_id
WHERE cl.action_type = 'spell_cast'
GROUP BY cl.spell_id, s.name
ORDER BY usage_count DESC;

---------------------------------------------------------
-- CUSTOM VIEWS pre lepší zážitok z boja
---------------------------------------------------------


-- Atribúty postáv
CREATE OR REPLACE VIEW v_character_attributes AS
SELECT  ch.id AS character_id,
        ch.name AS character_name,
        ct.name AS class_name,
        at.name AS attribute_name,
        ca.value AS attribute_value
FROM "Character" ch
    JOIN "ClassType" ct ON ct.id = ch.class_id
    JOIN "CharacterAttribute" ca ON ca.character_id = ch.id
    JOIN "AttributeType" at ON at.id = ca.attribute_id
ORDER BY ch.name, at.name;


-- Inventár postáv
CREATE OR REPLACE VIEW v_character_inventory AS
SELECT  ch.id AS character_id,
        ch.name AS character_name,
        i.name AS item_name,
        ci.quantity,
        i.description AS item_description
FROM "CharacterInventory" ci
    JOIN "Character" ch ON ch.id = ci.character_id
    JOIN "Item" i ON i.id = ci.item_id
ORDER BY ch.name, i.name;


-- Log zmeny HP (HealthChangeLog + CombatLog)
CREATE OR REPLACE VIEW v_health_changelog AS
SELECT  hc.event_number,
        CONCAT(cl.combat_id, '_', cl.round_id) AS combat_round,
        cl.log_message,
        act.name AS actor_name,
        cl.action_type,
        tgt.name AS target_name,
        cl.damage_dealt,
        chg.name AS character_name,
        hc.health_before,
        hc.health_after,
        (hc.health_after - COALESCE(hc.health_before, 0)) AS change

FROM "HealthChangeLog" hc
    JOIN "CombatLog" cl ON cl.event_number = hc.event_number
    JOIN "Character" chg ON chg.id = hc.character_id
    LEFT JOIN "Item" it ON it.id = cl.item_id
    LEFT JOIN "Character" act ON act.id = cl.acting_char_id
    LEFT JOIN "Character" tgt ON tgt.id = cl.target_char_id
ORDER BY hc.event_number;


-- Log zmien v inventári (ItemChangeLog + CombatLog)
CREATE OR REPLACE VIEW v_item_changelog AS
SELECT  icl.event_number,
        CONCAT(cl.combat_id, '_', cl.round_id) AS combat_round,
        cl.log_message,
        act.name AS actor_name,
        cl.action_type,
        tgt.name AS target_name,
        icl.quantity,
        it.name AS item_name,
        icl.change,
        ch.name AS character_name

FROM "ItemChangeLog" icl
    JOIN "CombatLog" cl ON cl.event_number = icl.event_number
    LEFT JOIN "Character" ch ON ch.id = icl.character_id
    LEFT JOIN "Item" it ON it.id = icl.item_id
    LEFT JOIN "Character" act ON act.id = cl.acting_char_id
    LEFT JOIN "Character" tgt ON tgt.id = cl.target_char_id
ORDER BY icl.event_number;
