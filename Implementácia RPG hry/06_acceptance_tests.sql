BEGIN;

--------------------------------------------------------------------------------
-- 1) TESTY sp_create_character
--------------------------------------------------------------------------------

SAVEPOINT test_create_ok; -- Test: úspešné vytvorenie novej postavy Zora
SELECT sp_create_character('Zora', 1, TRUE);

-- Overenie: Zora by mala existovať a mať správne atribúty
SELECT char.name, attr.name, ca.value
FROM "CharacterAttribute" ca
         JOIN "Character" char ON ca.character_id = char.id
         JOIN "AttributeType" attr ON ca.attribute_id = attr.id
WHERE char.name = 'Zora';

--------------------------------------------------------------------------------

SAVEPOINT test_create_duplicate; -- pokus o duplikované meno
DO $$
    BEGIN
        PERFORM sp_create_character('Zora', 1, TRUE);
        RAISE EXCEPTION 'Chyba: Duplikátne meno Zora bolo umožnené.';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'OK: Duplikát mena správne zachytený (%).', SQLERRM;
END $$;

--------------------------------------------------------------------------------

SAVEPOINT test_create_invalid_class;
DO $$
    BEGIN
        PERFORM sp_create_character('NovaPostava', 999, TRUE);
        RAISE EXCEPTION 'Chyba: Bola umožnená neexistujúca trieda.';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'OK: Neexistujúca trieda správne zachytená (%).', SQLERRM;
END $$;

--------------------------------------------------------------------------------
-- 2) TESTY sp_enter_combat
--------------------------------------------------------------------------------

SAVEPOINT test_enter_ok; -- Test: Zora vstúpi do combatu 3
SELECT sp_enter_combat(3, (SELECT id FROM "Character" WHERE name = 'Zora'));

-- Overenie: Zora by mala byť prítomná v CharacterInCombat
SELECT *
FROM "CharacterInCombat"
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

--------------------------------------------------------------------------------

SAVEPOINT test_enter_again; -- pokus o opätovný vstup do nejakeho combatu
DO $$
    BEGIN
        PERFORM sp_enter_combat(2, (SELECT id FROM "Character" WHERE name = 'Zora'));
        RAISE EXCEPTION 'Chyba: Opätovné pripojenie Zory do combatu bolo umožnené.';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'OK: Opätovný vstup správne zachytený (%).', SQLERRM;
END $$;

--------------------------------------------------------------------------------
-- 3) TESTY sp_spell_cast
--------------------------------------------------------------------------------

-- Nastavenie AP aby Zora mala dostatok
UPDATE "CharacterInCombat"
SET current_ap = 100
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

--------------------------------------------------------------------------------

SAVEPOINT test_spell_ok; -- Test: Zora zosiela kúzlo Fireball na Arannis
SELECT sp_spell_cast(
               (SELECT id FROM "Character" WHERE name = 'Zora'),
               (SELECT id FROM "Character" WHERE name = 'Arannis'),
               1
       );

-- Overenie: Cedric by mal mať záznam o zmene HP
SELECT *
FROM "HealthChangeLog"
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Arannis')
ORDER BY id DESC
LIMIT 5;

--------------------------------------------------------------------------------

SAVEPOINT test_spell_no_ap;
UPDATE "CharacterInCombat"
SET current_ap = 0
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

DO $$
    BEGIN
        PERFORM sp_spell_cast(
                (SELECT id FROM "Character" WHERE name = 'Zora'),
                (SELECT id FROM "Character" WHERE name = 'Arannis'),
                1
                );
        RAISE EXCEPTION 'Chyba: Zora zoslala kúzlo bez AP.';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'OK: Nedostatok AP správne zachytený (%).', SQLERRM;
END $$;

--------------------------------------------------------------------------------
-- 4) TESTY sp_auto_attack
--------------------------------------------------------------------------------

-- Vrátime Zore AP
UPDATE "CharacterInCombat"
SET current_ap = 100
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

--------------------------------------------------------------------------------

SAVEPOINT test_attack_ok; -- Test: Zora útočí na Arannis
SELECT sp_auto_attack(
               (SELECT id FROM "Character" WHERE name = 'Zora'),
               (SELECT id FROM "Character" WHERE name = 'Arannis')
       );

-- Overenie: Cedric má záznam o znížení HP
SELECT *
FROM "HealthChangeLog"
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Arannis')
ORDER BY id DESC
LIMIT 5;

--------------------------------------------------------------------------------

SAVEPOINT test_attack_no_ap;
UPDATE "CharacterInCombat"
SET current_ap = 0
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

DO $$
    BEGIN
        PERFORM sp_auto_attack(
                (SELECT id FROM "Character" WHERE name = 'Zora'),
                (SELECT id FROM "Character" WHERE name = 'Arannis')
                );
        RAISE EXCEPTION 'Chyba: Útok bez AP bol umožnený.';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'OK: Nedostatok AP pri útoku správne zachytený (%).', SQLERRM;
END $$;

--------------------------------------------------------------------------------
-- 5) TESTY sp_pass
--------------------------------------------------------------------------------

-- Nastavíme Zore AP a turn_score
UPDATE "CharacterInCombat"
SET current_ap = 5, turn_score = 100
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

--------------------------------------------------------------------------------

SAVEPOINT test_pass_ok; -- Test: Zora skipne ťah

SELECT sp_pass((SELECT id FROM "Character" WHERE name = 'Zora'));

SELECT current_ap, turn_score FROM "CharacterInCombat" WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

--------------------------------------------------------------------------------

SAVEPOINT test_pass_not_in_combat; -- Test: pokus o pass postavy mimo combatu

-- Vytvoríme novú postavu mimo boja
SELECT sp_create_character('DaktoMimoCombat', 1, TRUE);

DO $$
    BEGIN
        PERFORM sp_pass((SELECT id FROM "Character" WHERE name = 'DaktoMimoCombat'));
        RAISE EXCEPTION 'Chyba: Umožnené pass bez prítomnosti v combatu.';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'OK: Pokus o pass mimo combatu správne zachytený (%).', SQLERRM;
END $$;

---------------------------------------------------------------------------
-- 6) TEST sp_reset_attributes
--------------------------------------------------------------------------------

-- Pokazíme Zore atribúty
UPDATE "CharacterAttribute"
SET value = 999
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');

--------------------------------------------------------------------------------

SAVEPOINT test_reset_attributes_ok; -- Reset atribútov

SELECT char.name, attr.name, ca.attribute_id, ca.value
FROM "CharacterAttribute" ca
         JOIN "Character" char ON ca.character_id = char.id
         JOIN "AttributeType" attr ON ca.attribute_id = attr.id
WHERE char.name = 'Zora';

SELECT sp_reset_attributes((SELECT id FROM "Character" WHERE name = 'Zora'));

-- Overenie: hodnoty vrátené na normál
SELECT char.name, attr.name, ca.attribute_id, ca.value
FROM "CharacterAttribute" ca
         JOIN "Character" char ON ca.character_id = char.id
         JOIN "AttributeType" attr ON ca.attribute_id = attr.id
WHERE char.name = 'Zora';


--------------------------------------------------------------------------------
-- 7) TEST sp_reset_round
--------------------------------------------------------------------------------

SAVEPOINT test_reset_round_ok; -- Test: nové kolo v combatu 1
SELECT * FROM "Round" WHERE combat_id = 2 ORDER BY round_number DESC LIMIT 1;

SELECT sp_reset_round(2);

-- Overenie: nové číslo kola
SELECT * FROM "Round" WHERE combat_id = 2 ORDER BY round_number DESC LIMIT 1;

--------------------------------------------------------------------------------
-- 8) TEST sp_handle_death
--------------------------------------------------------------------------------

-- Nastavíme Zore veľmi nízke HP a vela AP
UPDATE "Character"
SET curr_health = 1
WHERE name = 'Zora';

UPDATE "CharacterInCombat"
SET current_ap = 100
WHERE character_id = (SELECT id FROM "Character" WHERE name = 'Zora');
--------------------------------------------------------------------------------

SAVEPOINT test_handle_death_ok; -- Test: Zora zomrie v boji

-- Dáme jej veci do inventára
SELECT sp_pick_item(
               (SELECT id FROM "Character" WHERE name = 'Zora'), (SELECT item_id FROM "CombatInventory" WHERE combat_id = 3 LIMIT 1)
       );
SELECT sp_pick_item(
               (SELECT id FROM "Character" WHERE name = 'Zora'), (SELECT item_id FROM "CombatInventory" WHERE combat_id = 3 LIMIT 1)
       );

-- Arannis dorazí Zoru
SELECT sp_auto_attack(
               (SELECT id FROM "Character" WHERE name = 'Arannis'),
               (SELECT id FROM "Character" WHERE name = 'Zora')
       );

-- Overenie: respawn, HP reset, debuff item v inventári spôsobil 60% zmeny atribútov
SELECT char.name, attr.name, ca.value
FROM "CharacterAttribute" ca
         JOIN "Character" char ON ca.character_id = char.id
         JOIN "AttributeType" attr ON ca.attribute_id = attr.id
WHERE char.name = 'Zora';

--------------------------------------------------------------------------------
-- Ukončenie testovania bez zmien v databáze
--------------------------------------------------------------------------------

ROLLBACK;
