import random

# statické rozsahy
class_count = 6
spell_count = 8
item_min, item_max = 2, 11

# súbor na zapisovanie
output_file = "game_log.sql"

# funkcie na generovanie zápisov
def create_character(name):
    cls = random.randint(1, class_count)
    is_active = random.choice(["TRUE", "FALSE"])
    return f"PERFORM sp_create_character('{name}', {cls}, {is_active});\n"

def pick_item(name):
    item_id = random.randint(item_min, item_max)
    return f"BEGIN PERFORM sp_pick_item({name}, {item_id}); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def drop_item(name):
    item_id = random.randint(item_min, item_max)
    return f"BEGIN PERFORM sp_drop_item({name}, {item_id}); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def use_item(name):
    item_id = random.randint(item_min, item_max)
    return f"BEGIN PERFORM sp_use_item({name}, {item_id}, {name}); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def pick_combat_item(name):
    item_id = random.randint(item_min, item_max)
    return f"BEGIN PERFORM sp_take_turn('pick_item', {name}, NULL, {item_id}); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def drop_combat_item(name):
    item_id = random.randint(item_min, item_max)
    return f"BEGIN PERFORM sp_take_turn('drop_item', {name}, NULL, {item_id}); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def use_combat_item(name):
    item_id = random.randint(item_min, item_max)
    return f"BEGIN PERFORM sp_take_turn('use_item', {name}, {name}, {item_id}); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def cast_spell(caster, target):
    spell_id = random.randint(1, spell_count)
    return f"BEGIN PERFORM sp_take_turn('spell_cast', {caster}, {target}, {spell_id}); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def auto_attack(attacker, target):
    return f"BEGIN PERFORM sp_take_turn('auto_attack', {attacker}, {target}, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

def pass_turn(name):
    return f"BEGIN PERFORM sp_take_turn('pass', {name}, NULL, NULL); EXCEPTION WHEN OTHERS THEN RAISE NOTICE '%', SQLERRM; END;\n"

# vypíše všetky možnosti príkazov
def print_commands():
    print("\nDostupné príkazy:")
    print("  create <meno> [<meno> <meno> ...]    - vytvorí postavy")
    print("  pick_item <meno>                     - postava si vezme náhodný item (mimo combatu)")
    print("  drop_item <meno>                     - postava zahodí náhodný item (mimo combatu)")
    print("  use_item <meno>                      - postava použije náhodný item (mimo combatu)")
    print("  pick_combat_item <meno>              - postava si vezme item v combatu")
    print("  drop_combat_item <meno>              - postava zahodí item v combatu")
    print("  use_combat_item <meno>               - postava použije item v combatu")
    print("  cast_spell <kto> <na_koho>            - kúzlenie na cieľ")
    print("  auto_attack <kto> <na_koho>           - auto útok na cieľ")
    print("  pass <meno> [<meno> <meno> ...]       - viacerí passujú kolo")
    print("  exit                                 - ukončí zadávanie\n")

# hlavný loop na zadávanie príkazov
def main():
    print_commands()

    with open(output_file, "w") as file:
        while True:
            command = input("Zadaj príkaz: ").strip()
            if command == "exit":
                break

            parts = command.split()

            if parts[0] == "create" and len(parts) >= 2:
                for name in parts[1:]:
                    line = create_character(name)
                    file.write(line)
                    print(f"Pridané:\n{line}")

            elif parts[0] == "pass" and len(parts) >= 2:
                for name in parts[1:]:
                    line = pass_turn(name)
                    file.write(line)
                    print(f"Pridané:\n{line}")

            elif parts[0] == "pick_item" and len(parts) == 2:
                line = pick_item(parts[1])
                file.write(line)
                print(f"Pridané:\n{line}")

            elif parts[0] == "drop_item" and len(parts) == 2:
                line = drop_item(parts[1])
                file.write(line)
                print(f"Pridané:\n{line}")

            elif parts[0] == "use_item" and len(parts) == 2:
                line = use_item(parts[1])
                file.write(line)
                print(f"Pridané:\n{line}")

            elif parts[0] == "pick_combat_item" and len(parts) == 2:
                line = pick_combat_item(parts[1])
                file.write(line)
                print(f"Pridané:\n{line}")

            elif parts[0] == "drop_combat_item" and len(parts) == 2:
                line = drop_combat_item(parts[1])
                file.write(line)
                print(f"Pridané:\n{line}")

            elif parts[0] == "use_combat_item" and len(parts) == 2:
                line = use_combat_item(parts[1])
                file.write(line)
                print(f"Pridané:\n{line}")

            elif parts[0] == "cast_spell" and len(parts) == 3:
                line = cast_spell(parts[1], parts[2])
                file.write(line)
                print(f"Pridané:\n{line}")

            elif parts[0] == "auto_attack" and len(parts) == 3:
                line = auto_attack(parts[1], parts[2])
                file.write(line)
                print(f"Pridané:\n{line}")

            else:
                print("Neznámy alebo chybný príkaz. Skontroluj syntax.\n")

if __name__ == "__main__":
    main()
