# Borowik Engine Manual

This manual covers installation, requirements, architecture, and practical usage examples for the current codebase.

## Requirements

- Zig (recommended: current stable)
- Linux or Windows
- `upx` (optional for release compression steps)

## Installation

Clone and enter project:

```bash
git clone https://github.com/w84death/borowik-engine.git
cd borowik-engine
```

## Build and Run

Default build:

```bash
zig build
```

Run:

```bash
zig build run
```

Release (small + UPX):

```bash
zig build release-linux
zig build release-windows
```

## Architecture

Core modules:

- `src/engine/render.zig` - frame timing and primitive rendering
- `src/engine/fui.zig` - higher-level UI helpers (text, buttons, popups, pivots)
- `src/engine/menu.zig` - reusable menu renderer (`Menu` generic)
- `src/engine/mouse.zig` - click-edge mouse handling
- `src/engine/state.zig` - generic state machine factory
- `src/themes/mil.zig` - theme colors, spacing, and font scales
- `src/main.zig` - app state wiring, scene switching, HUD drawing

Separation of concerns:

- engine modules are reusable and generic
- app logic lives in `main` and scene modules

## Config vs Theme

Use `CONF` (`src/engine/config.zig`) for runtime/system constants:

- screen size
- base font bitmap dimensions
- app metadata (`VERSION`, `THE_NAME`, `TAG_LINE`)

Use `THEME` (`src/themes/mil.zig`) for presentation constants:

- `*_COLOR` values
- menu layout metrics
- UI font scales (`FONT_DEFAULT`, `FONT_MEDIUM`, `FONT_BIG`)

## Main Loop Pattern

Typical frame order:

```zig
sm.update();
renderer.begin_frame();
renderer.clear_background(THEME.BG_COLOR);

const mouse = mouse_buttons.update(f.x, f.y, @intCast(f.mouse));

switch (sm.current) {
    // draw scene
}

// global UI (back button, version, fps, cursor)
renderer.cap_frame(CONF.TARGET_FPS);
```

## UI / Fui API

Common methods:

- `draw_text(text, x, y, scale, color)`
- `draw_text_block(lines, x, y, line_height, scale, color)`
- `text_length(text, scale)`
- `text_center(text, scale)`
- `button(x, y, w, h, label, color, mouse)`
- `info_popup(message, mouse, bg_color)`
- `yes_no_popup(message, mouse)`
- `draw_version()`
- `draw_cursor_lines(.{ x, y })`

Primitive drawing is under `fui.renderer.*`.

## Pivot Helpers

Use pivots for anchored layout:

- `fui.pivotX(.top_left)`, `fui.pivotY(.top_left)`
- `fui.pivotX(.top_right)`, `fui.pivotY(.top_right)`
- `fui.pivotX(.bottom_left)`, `fui.pivotY(.bottom_left)`
- `fui.pivotX(.bottom_right)`, `fui.pivotY(.bottom_right)`
- `fui.pivotX(.center)`, `fui.pivotY(.center)`

## Input and State

Mouse edge handling:

```zig
var mouse_buttons = MouseButtons.init();
const mouse = mouse_buttons.update(f.x, f.y, @intCast(f.mouse));
```

State machine:

```zig
const State = enum { main_menu, example, about, quit };
const StateMachine = @import("engine/state.zig").StateMachine(State);

var sm = StateMachine.init(State.main_menu);
sm.go_to(State.about);
sm.update();
```

## Menu System

Engine menu is generic and reusable:

```zig
const Menu = @import("engine/menu.zig").Menu(State, StateMachine);
```

Use it in scenes or app-level wrappers by providing groups/items and calling:

- `Menu.init(fui, groups)`
- `menu.draw(sm, mouse)` or `menu.draw_at(sm, mouse, cx, y_start)`

## Scene Examples

- `src/scenes/menu.zig` wraps engine menu and draws title/tagline.
- `src/scenes/about.zig` uses `draw_text_block` with static lines.
- `src/scenes/example.zig` combines VFX + reusable menu + popup actions.
