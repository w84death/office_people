# Office People Zig CPU Port

Native Zig/software-rendered port of **Office People** using the small `fenster` window backend and the Borowik engine modules in `src/engine/`.

The game is mouse-driven: move through the office, pick up objects, throw them at hostile coworkers, turn on every computer, then escape through the elevator.

## Features

- Software rendering through `fenster`.
- Embedded BMP sprite sheets.
- Mouse edge detection and custom animated cursor.
- Runtime game states: intro, menu, game, level clear, game over, end, editor.
- Built-in playable levels with runtime level overrides.
- Built-in one-window level editor.
- Debug shortcuts for level jumping and godmode.
- Plain-text level save files under `levels/`.

## Run

```bash
zig build run
```

## Build

```bash
zig build
```

Release builds:

```bash
zig build release-linux
zig build release-windows
```

## Gameplay

- Hold left mouse button away from the player to move toward the cursor.
- Hold left mouse near the player while holding an item to throw it.
- Walk into pickup items to take them if your hands are empty.
- Walk into usable objects to activate them if your hands are empty.
- Turn on all computers to open the elevator.
- Enter the elevator after all computers are on to finish the level.

Scoring:

- Throw hit: `500`
- Computer trigger: `100`
- Usable object: `50`
- Coffee machine: `100`
- Remaining level time adds bonus score.

## Debug Shortcuts

- `Esc`: return to menu, or quit from menu.
- `Ctrl+G`: toggle godmode.
- `Ctrl+1` through `Ctrl+9`: jump to playable level slot if available.
- `Ctrl+E`: toggle the built-in level editor.

Godmode prevents player health loss and restores health when enabled. The HUD shows `GOD` while it is active.

## Level Editor

Open the editor with `Ctrl+E`. The editor uses a single window with two panels.

- Left panel: level grid/map viewport.
- Right panel: tools, palettes, save/load slots, and play button.

Editor buttons:

- `TILES`: paint background office tiles.
- `COL`: paint collision cells.
- `ENTS`: place entities.
- `PLAY`: test the currently edited level.
- `NEW S`: create a small level.
- `M`: create a medium level.
- `B`: create a big level.
- `<`, `>`, `^`, `v`: scroll the map viewport.
- `S 1..9`: save to slot `1..9`.
- `L 1..9`: load from slot `1..9`.

Editor mouse controls:

- Left click on the map: place selected tile, collision, or entity.
- Right click on the map: erase tile, collision, or entity.
- Left click in the palette: select tile/entity or activate a button.
- Tile/entity palette `<` and `>` buttons page through available entries.

Level sizes:

- Small: `12x6` background tiles, `24x12` collision cells.
- Medium: `14x14` background tiles, `28x28` collision cells.
- Big: `24x8` background tiles, `48x16` collision cells.

Saved editor files:

```text
levels/level1.txt
levels/level2.txt
...
levels/level9.txt
```

Saved slots override playable levels at runtime. Built-in levels are used when no saved override exists.

## Level File Format

Levels are saved as plain text for easy inspection and manual edits.

```text
office 12 6
1 2 3 ...
collision 24 12 8
1 1 1 ...
entities 3
elevator 160 0 0
employee 161 41 1
desk 27 17 0
```

Entity line format:

```text
kind x y player_flag
```

Use `player_flag` `1` for the player employee and `0` for normal entities.

## Project Layout

- `src/main.zig`: game loop, game logic, rendering, debug shortcuts, level editor.
- `src/game_levels.zig`: built-in fallback levels.
- `src/engine/render.zig`: software renderer and frame timing.
- `src/engine/sprites.zig`: indexed BMP sprite-sheet loader/drawer.
- `src/engine/mouse.zig`: mouse button edge detection.
- `src/engine/fui.zig`: immediate-mode text/UI helpers.
- `src/themes/default.zig`: UI theme values.

## Notes

- The editor is intentionally compact because the game runs at `256x144` logical resolution.
- Small levels are centered in the viewport instead of pinned to the top-left.
- Larger levels scroll normally with camera/view controls.

## Credits

- https://github.com/zserge/fenster
- https://jared.geek.nz/2014/01/custom-fonts-for-microcontrollers/
