TRUNCATE TABLE
    "Character",
    "CharacterAttribute",
    "CharacterInventory",
    "CharacterInCombat",
    "Combat",
    "CombatInventory",
    "CombatLog",
    "ItemChangeLog",
    "HealthChangeLog",
    "Round"
RESTART IDENTITY CASCADE;

DO
$$
    DECLARE
        /* ID postáv ------------------------------------------------- */
        margotka INT; thorin  INT; elowen INT; althaea INT;  liana   INT;
        cedric   INT; rowan   INT; sylvara INT; kaelen  INT;  vanya   INT;
        oren     INT; nymeria INT; farin   INT; arannis INT;  isolde  INT;

        /* ID bojov -------------------------------------------------- */
        combat_a INT;
        combat_b INT;
        combat_c INT;
    BEGIN
        ----------------------------------------------------------------
        -- 1. Vytvorenie 15 postáv
        ----------------------------------------------------------------
        PERFORM sp_create_character('Margotka', 5, TRUE);
        PERFORM sp_create_character('Thorin',   1, TRUE);
        PERFORM sp_create_character('Elowen',   2, TRUE);
        PERFORM sp_create_character('Althaea',  4, TRUE);
        PERFORM sp_create_character('Liana',    6, TRUE);
        PERFORM sp_create_character('Cedric',   3, FALSE);
        PERFORM sp_create_character('Rowan',    6, FALSE);
        PERFORM sp_create_character('Sylvara',  5, FALSE);
        PERFORM sp_create_character('Kaelen',   4, FALSE);
        PERFORM sp_create_character('Vanya',    2, FALSE);
        PERFORM sp_create_character('Oren',     1, TRUE);
        PERFORM sp_create_character('Nymeria',  6, TRUE);
        PERFORM sp_create_character('Farin',    3, TRUE);
        PERFORM sp_create_character('Arannis',  5, FALSE);
        PERFORM sp_create_character('Isolde',   2, TRUE);


        /* priradenie ID premenným ---------------------------------- */
        SELECT id INTO margotka FROM "Character" WHERE name='Margotka';
        SELECT id INTO thorin   FROM "Character" WHERE name='Thorin';
        SELECT id INTO elowen   FROM "Character" WHERE name='Elowen';
        SELECT id INTO althaea  FROM "Character" WHERE name='Althaea';
        SELECT id INTO liana    FROM "Character" WHERE name='Liana';
        SELECT id INTO cedric   FROM "Character" WHERE name='Cedric';
        SELECT id INTO rowan    FROM "Character" WHERE name='Rowan';
        SELECT id INTO sylvara  FROM "Character" WHERE name='Sylvara';
        SELECT id INTO kaelen   FROM "Character" WHERE name='Kaelen';
        SELECT id INTO vanya    FROM "Character" WHERE name='Vanya';
        SELECT id INTO oren     FROM "Character" WHERE name='Oren';
        SELECT id INTO nymeria  FROM "Character" WHERE name='Nymeria';
        SELECT id INTO farin    FROM "Character" WHERE name='Farin';
        SELECT id INTO arannis  FROM "Character" WHERE name='Arannis';
        SELECT id INTO isolde   FROM "Character" WHERE name='Isolde';

        ----------------------------------------------------------------
        -- 2. Predbojové pick/use mimo combatu
        ----------------------------------------------------------------
    -- Sylvara
        BEGIN PERFORM sp_pick_item(sylvara , 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(sylvara ,10);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Oren
        BEGIN PERFORM sp_pick_item(kaelen  ,11);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Rowan
        BEGIN PERFORM sp_pick_item(rowan   , 4);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(rowan   , 6);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Vanya, Oren, Arannis
        BEGIN PERFORM sp_pick_item(vanya   , 3);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(oren    , 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(arannis , 9);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Margotka
        BEGIN PERFORM sp_pick_item(margotka, 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(margotka, 5);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(margotka, 5);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Thorin
        BEGIN PERFORM sp_pick_item(thorin  , 6);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(thorin  , 6);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(thorin  , 7);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Elowen
        BEGIN PERFORM sp_pick_item(elowen  , 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(elowen  , 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(elowen  , 3);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Althaea
        BEGIN PERFORM sp_pick_item(althaea , 1);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(althaea , 3);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(althaea , 4);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Liana
        BEGIN PERFORM sp_pick_item(liana   , 9);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(liana   , 9);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(liana   , 10); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Cedric
        BEGIN PERFORM sp_pick_item(cedric  , 7);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(cedric  , 8);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(cedric  , 5);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Nymeria
        BEGIN PERFORM sp_pick_item(nymeria , 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(nymeria , 3);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(nymeria , 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Farin
        BEGIN PERFORM sp_pick_item(farin   , 6);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(farin   , 7);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(farin   , 6);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Arannis (rozšírené)
        BEGIN PERFORM sp_pick_item(arannis , 9);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(arannis , 10); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(arannis , 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

    -- Isolde
        BEGIN PERFORM sp_pick_item(isolde  , 11); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(isolde  , 4);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(isolde  , 5);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;


        ----------------------------------------------------------------
        -- 3. Combat A – Margotka + Oren vs Rowan
        ----------------------------------------------------------------
        SELECT sp_start_combat(ARRAY[margotka, oren, rowan]) INTO combat_a;

        -- kolo 1
        BEGIN PERFORM sp_take_turn('spell_cast',  margotka, rowan , 4);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('spell_cast',  margotka, rowan , 5);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        margotka, NULL  , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('auto_attack', oren  , rowan, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', oren  , rowan, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        oren  , NULL, NULL);     EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('use_item',    rowan   , margotka, 4); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('spell_cast',  rowan   , margotka, 6); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        rowan   , NULL, NULL);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        -- kolo 2
        BEGIN PERFORM sp_take_turn('spell_cast',  margotka, rowan , 1);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        margotka, NULL  , NULL);EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('auto_attack', rowan, margotka, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        rowan, NULL, NULL);     EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  oren, rowan , 5);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('spell_cast',  oren, rowan , 5);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        oren, NULL  , NULL);EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        RAISE NOTICE 'Rowan data: %', (SELECT row_to_json(c) FROM "Character" c WHERE id = rowan);

        -- kolo 3 – Thorin prichádza
        BEGIN PERFORM sp_enter_combat(combat_a, thorin);                        EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  thorin  , rowan, 4);          EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', thorin  , rowan, NULL);       EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', thorin  , rowan, NULL);       EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  margotka, rowan , 13);        EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        margotka, NULL , NULL);       EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        RAISE NOTICE 'Rowan data: %', (SELECT row_to_json(c) FROM "Character" c WHERE id = rowan); -- mal by byt mrtvy ak bol dostatocny dmg
        RAISE NOTICE 'Combat is_active: %', (SELECT is_active FROM "Combat" WHERE id = 1);

        -- post-combat A
        BEGIN PERFORM sp_pick_item(margotka, 2);                EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_use_item(margotka, 2, margotka);       EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        ----------------------------------------------------------------
        -- 4. Combat B - Nymeria + Farin vs Kaelen + Vanya
        ----------------------------------------------------------------
        SELECT sp_start_combat(ARRAY[nymeria, farin, kaelen, vanya]) INTO combat_b;

        ----------------------------------------------------------------
        -- 5. Combat C – Althaea vs Arannis
        ----------------------------------------------------------------
        SELECT sp_start_combat(ARRAY[althaea, arannis]) INTO combat_c;

        --------------------------------------------------------------- -
        -- Prehľadnosť: B-kolo1  →  C-kolo1  →  B-kolo2  →  C-kolo2 …
        ----------------------------------------------------------------

        -- --------- B kolo 1
        BEGIN PERFORM sp_take_turn('spell_cast',  nymeria, vanya , 2); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', nymeria, vanya , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        nymeria, NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('auto_attack', farin  , vanya , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', farin  , vanya , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        farin  , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  kaelen , kaelen, 8); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', kaelen , nymeria, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        kaelen , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  vanya  , nymeria, 2); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        vanya  , NULL, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        -- --------- C kolo 1
        BEGIN PERFORM sp_take_turn('spell_cast',  althaea, arannis, 5); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', althaea, arannis, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        althaea, NULL, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  arannis, althaea, 1); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('spell_cast',  arannis, althaea, 6); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        arannis, NULL, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        -- --------- B kolo 2
        BEGIN PERFORM sp_take_turn('auto_attack', nymeria, vanya , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', nymeria, vanya , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        nymeria, NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('auto_attack', farin  , vanya , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', farin  , vanya , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        farin  , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  kaelen , farin , 5); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', kaelen , farin , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        kaelen , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        -- --------- C kolo 2
        BEGIN PERFORM sp_take_turn('auto_attack', althaea, arannis, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', althaea, arannis, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        althaea, NULL, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  arannis, althaea, 1); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        arannis, NULL, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        -- --------- B kolo 3 (Elowen vstup)
        BEGIN PERFORM sp_enter_combat(combat_b, elowen); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  elowen , farin , 3); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('spell_cast',  elowen , kaelen, 2); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        elowen , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  nymeria, kaelen, 2); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', nymeria, kaelen, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        nymeria, NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('auto_attack', farin  , kaelen, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', farin  , kaelen, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        farin  , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('spell_cast',  kaelen , kaelen, 8); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('auto_attack', kaelen , nymeria, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        kaelen , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        -- --------- B kolo 4
        BEGIN PERFORM sp_take_turn('spell_cast',  elowen , kaelen, 2); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        elowen , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('auto_attack', nymeria, kaelen, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        nymeria, NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_take_turn('auto_attack', farin  , kaelen, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_take_turn('pass',        farin  , NULL , NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        ----------------------------------------------------------------
        -- 6. Post-combat B
        ----------------------------------------------------------------
        BEGIN PERFORM sp_pick_item(nymeria, 3);           EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_use_item(nymeria, 3, nymeria);   EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        ----------------------------------------------------------------
        -- 7. Mimo bojov
        ----------------------------------------------------------------
        BEGIN PERFORM sp_drop_item(sylvara, 2);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_pick_item(oren   , 7);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_pick_item(isolde , 6);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
        BEGIN PERFORM sp_drop_item(isolde , 6);  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;

        BEGIN PERFORM sp_use_item(arannis , 9, arannis); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;
    END
$$;