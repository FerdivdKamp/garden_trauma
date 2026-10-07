"""Estimate level difficulty with a deterministic, approximate tower defense run.

Run from the project root: python tools/balance_report.py
This is a design diagnostic, not a replacement for playtesting or Godot combat.
"""

import argparse
import json
import math
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STEP = 0.1


def load_json(path):
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def gd_number(source, name):
    match = re.search(r"\b(?:const|var)\s+" + re.escape(name) + r"\s*:?=\s*([\d.]+)", source)
    if not match:
        raise ValueError(f"Could not find {name} in Godot source")
    return float(match.group(1))


@dataclass
class Tower:
    kind: dict
    x: float
    z: float
    yaw: float = 0.0
    clock: float = 0.0


@dataclass
class Enemy:
    kind: dict
    progress: float = 0.0
    health: float = 0.0

    def __post_init__(self):
        self.health = float(self.kind["health"])


def position(route, progress, tile_size):
    index = min(int(progress / tile_size), len(route) - 2)
    part = min(progress / tile_size - index, 1.0)
    a, b = route[index], route[index + 1]
    return ((a[0] + (b[0] - a[0]) * part) * tile_size,
            (a[1] + (b[1] - a[1]) * part) * tile_size)


def distance(tower, point):
    # Towers sit at ground height; enemy visual centers are above it. This
    # horizontal distance is deliberately simpler than Godot's 3D distance.
    return math.hypot(tower.x - point[0], tower.z - point[1])


def damage(tower_kind, unit_kind):
    if not set(tower_kind["targeting"]["targets"]).intersection(unit_kind["tags"]):
        return 0.0
    multiplier = 1.0 - unit_kind.get("armor", {}).get(tower_kind["damage_type"], 0.0)
    for tag in unit_kind["tags"]:
        multiplier *= tower_kind.get("bonus_vs_tags", {}).get(tag, 1.0)
    return max(0.0, tower_kind["attack"]["damage"] * multiplier)


def choose_towers(money, placed, map_data, waves, tower_types, unit_types, tile_size):
    """Buy the strongest route coverage per coin, until nothing is affordable."""
    occupied = {(round(t.x / tile_size), round(t.z / tile_size)) for t in placed}
    route = map_data["route"]
    cells = [(x, z) for z, row in enumerate(map_data["tiles"])
             for x, tile in enumerate(row) if tile == "." and (x, z) not in occupied]
    samples = [position(route, n * tile_size / 2, tile_size)
               for n in range(2 * (len(route) - 1) + 1)]
    while cells:
        best = None
        best_score = 0.0
        for kind in tower_types.values():
            if kind["cost"] > money or kind["cost"] <= 0:
                continue
            radius = min(kind["attack"]["range"], kind["detection_range"])
            for x, z in cells:
                candidate = Tower(kind, x * tile_size, z * tile_size)
                score = 0.0
                for point in samples:
                    if distance(candidate, point) > radius:
                        continue
                    for wave in waves:
                        unit = unit_types[wave["enemy_id"]]
                        score += (wave["count"] * damage(kind, unit) /
                                  kind["attack"]["cooldown"])
                score /= kind["cost"]
                if score > best_score:
                    best, best_score = candidate, score
        if best is None:
            break
        placed.append(best)
        money -= best.kind["cost"]
        cell = (round(best.x / tile_size), round(best.z / tile_size))
        cells.remove(cell)
    return money


def run_wave(wave, placed, route, unit_types, tile_size, health):
    unit = unit_types[wave["enemy_id"]]
    length = (len(route) - 1) * tile_size
    duration = (wave["count"] - 1) * wave["spawn_interval"] + length / unit["speed"] + 2
    enemies = []
    next_spawn = 0
    kills = leaks = 0
    steps = math.ceil(duration / STEP)
    for tick in range(steps):
        now = tick * STEP
        while next_spawn < wave["count"] and now + 1e-9 >= next_spawn * wave["spawn_interval"]:
            enemies.append(Enemy(unit))
            next_spawn += 1
        for enemy in enemies[:]:
            enemy.progress += unit["speed"] * STEP
            if enemy.progress >= length:
                enemies.remove(enemy)
                leaks += 1
                if leaks >= health:
                    return kills, leaks
        for tower in placed:
            tower.clock += STEP
            candidates = []
            for enemy in enemies:
                if damage(tower.kind, enemy.kind) <= 0:
                    continue
                point = position(route, enemy.progress, tile_size)
                d = distance(tower, point)
                if d <= tower.kind["detection_range"]:
                    priority = tower.kind["targeting"]["priority"]
                    key = -enemy.progress if priority == "first" else enemy.progress if priority == "last" else d
                    candidates.append((key, enemy, point, d))
            if not candidates:
                continue
            _, target, point, d = min(candidates, key=lambda item: item[0])
            desired = math.atan2(-(point[0] - tower.x), -(point[1] - tower.z))
            angle = (desired - tower.yaw + math.pi) % (2 * math.pi) - math.pi
            turn = math.radians(tower.kind["turn_speed"]) * STEP
            tower.yaw += max(-turn, min(turn, angle))
            remaining = (desired - tower.yaw + math.pi) % (2 * math.pi) - math.pi
            if (tower.clock >= tower.kind["attack"]["cooldown"] and
                    abs(remaining) < math.radians(5) and d <= tower.kind["attack"]["range"]):
                tower.clock = 0.0
                target.health -= damage(tower.kind, target.kind)
                if target.health <= 0:
                    enemies.remove(target)
                    kills += 1
        if next_spawn == wave["count"] and not enemies:
            break
    if enemies:
        raise RuntimeError("Simulation did not finish; check unit speed and route")
    return kills, leaks


def evaluate(level_path, wave_path, tower_types, unit_types, currency, health, tile_size):
    map_data = load_json(level_path)
    waves = load_json(wave_path)["waves"]
    route = map_data["route"]
    if len(route) < 2 or any(abs(a[0] - b[0]) + abs(a[1] - b[1]) != 1
                             for a, b in zip(route, route[1:])):
        raise ValueError(f"Invalid route in {level_path}")
    placed = []
    outcomes = []
    for wave in waves:
        if wave["enemy_id"] not in unit_types:
            raise ValueError(f"Unknown unit {wave['enemy_id']} in {wave_path}")
        currency = choose_towers(currency, placed, map_data, [wave], tower_types, unit_types, tile_size)
        kills, leaks = run_wave(wave, placed, route, unit_types, tile_size, health)
        currency += kills * unit_types[wave["enemy_id"]]["reward"]
        health = max(0, health - leaks)
        placements = [f"{tower.kind['id']}@({round(tower.x / tile_size)},{round(tower.z / tile_size)})"
                      for tower in placed]
        outcomes.append((kills, leaks, currency, health, placements))
        if health <= 0:
            break
    return len(route) - 1, outcomes, health


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--level", help="Level ID; default is all matching map/wave pairs")
    args = parser.parse_args()
    placement = (ROOT / "scripts/tower_placement.gd").read_text(encoding="utf-8")
    grid = (ROOT / "scripts/level_grid.gd").read_text(encoding="utf-8")
    currency = int(gd_number(placement, "starting_currency"))
    health = int(gd_number(placement, "starting_objective_health"))
    tile_size = gd_number(grid, "TILE_SIZE")
    ids_match = re.search(r"const TOWER_IDS\s*:=\s*\[([^]]+)\]", placement)
    if not ids_match:
        raise ValueError("Could not find available tower IDs")
    available = re.findall(r'"([a-z0-9_]+)"', ids_match.group(1))
    towers = {item["id"]: item for path in (ROOT / "data/towers").glob("*.json")
              for item in [load_json(path)] if item["id"] in available}
    units = {item["id"]: item for path in (ROOT / "data/units").glob("*.json")
             for item in [load_json(path)]}
    if set(available) != set(towers):
        raise ValueError(f"Missing tower definitions: {set(available) - set(towers)}")
    levels = sorted((ROOT / "levels/data").glob("*.json"))
    if args.level:
        levels = [path for path in levels if path.stem == args.level]
        if not levels:
            parser.error(f"Unknown level: {args.level}")
    print("Estimate: greedy route coverage, automatic targeting, instant hits, 0.1 s steps")
    print(f"Starting resources: {currency} coins, {health} garden health\n")
    for path in levels:
        wave_path = ROOT / "levels/waves" / path.name
        if not wave_path.exists():
            print(f"{path.stem}: no matching wave file; skipped")
            continue
        cells, outcomes, remaining = evaluate(path, wave_path, towers, units, currency, health, tile_size)
        print(f"{path.stem}: route {cells} tiles / {cells * tile_size:.0f} world units")
        for index, (kills, leaks, coins, hp, placements) in enumerate(outcomes, 1):
            print(f"  wave {index}: {kills} defeated, {leaks} leaked; {len(placements)} towers; {coins} coins; {hp} health")
            if index == 1 or placements != outcomes[index - 2][4]:
                print("    placed: " + (", ".join(placements) if placements else "none"))
        print("  policy outcome: " + ("defeat" if remaining <= 0 else
              "high pressure" if remaining <= health / 2 else
              "moderate pressure" if remaining < health else "low pressure"))
        print()


if __name__ == "__main__":
    main()
