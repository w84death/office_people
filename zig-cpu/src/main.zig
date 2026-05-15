// *************************************
// BOROWIK ENGINE
// by Krzysztof Krystian Jankowski
// github.com/w84death/borowik-engine
// *************************************

const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("fenster.h");
    @cInclude("fenster_audio.h");
});
const CONF = @import("engine/config.zig").CONF;
const IO = @import("engine/io.zig");
const Render = @import("engine/render.zig").Render;
const Audio = @import("engine/audio.zig").Audio;
const ProcAudio = @import("engine/proc_audio.zig").ProcAudio;
const Sprite = @import("engine/sprites.zig").Sprite;
const SpriteSheet = @import("engine/sprites.zig").SpriteSheet;
const UiTheme = @import("themes/default.zig").UiTheme;
//const UiTheme = @import("themes/smol.zig").UiTheme;
//const UiTheme = @import("themes/shroom.zig").UiTheme;
//const UiTheme = @import("themes/gray.zig").UiTheme;
//const AudioTheme = @import("themes/default_audio.zig").AudioTheme;
const AudioTheme = @import("themes/vibrant_audio.zig").AudioTheme;
const Fui = @import("engine/fui.zig").Fui(UiTheme);
const MouseButtons = @import("engine/mouse.zig").MouseButtons;
const State = enum {
    main_menu,
    example,
    about,
    quit,
};
const StateMachine = @import("engine/state.zig").StateMachine(State);
const Menu = @import("engine/menu.zig").Menu(State, StateMachine, UiTheme);

// Scenes
const MenuScene = @import("scenes/menu.zig").MenuScene(Menu, UiTheme);
const AboutScene = @import("scenes/about.zig").AboutScene(UiTheme);
const ExampleScene = @import("scenes/example.zig").ExampleScene(UiTheme, AudioTheme);

fn playSfx(audio: *Audio, effect: AudioTheme.Effect) void {
    const tune = AudioTheme.sfx(effect);
    if (tune.len == 0) return;
    audio.play_tune(tune);
}

fn hideSystemCursor(f: *c.fenster) void {
    switch (builtin.os.tag) {
        .windows => {
            _ = c.ShowCursor(0);
        },
        else => {
            var data = [_]u8{0};
            const bitmap = c.XCreateBitmapFromData(f.dpy, f.w, @as([*c]const u8, @ptrCast(&data[0])), 1, 1);
            if (bitmap == 0) return;
            defer _ = c.XFreePixmap(f.dpy, bitmap);

            var color: c.XColor = std.mem.zeroes(c.XColor);
            const cursor = c.XCreatePixmapCursor(f.dpy, bitmap, bitmap, &color, &color, 0, 0);
            if (cursor == 0) return;
            defer _ = c.XFreeCursor(f.dpy, cursor);

            _ = c.XDefineCursor(f.dpy, f.w, cursor);
            _ = c.XFlush(f.dpy);
        },
    }
}

pub fn main() void {
    std.debug.print("*************************************\n", .{});
    std.debug.print(" BOROWIK ENGINE\n", .{});
    std.debug.print(" by Krzysztof Krystian Jankowski\n", .{});
    std.debug.print(" github.com/w84death/borowik-engine\n", .{});
    std.debug.print("*************************************\n", .{});
    std.debug.print("[init] Main start\n", .{});

    const settings = IO.load_or_create_settings() catch IO.Settings{
        .width = CONF.SCREEN_W,
        .height = CONF.SCREEN_H,
        .fullscreen = false,
    };

    std.debug.print("[config] window size: {d}x{d}\n", .{ settings.width, settings.height });
    std.debug.print("[config] to change window size edit settings.cfg\n", .{});

    const total_pixels: usize = @intCast(@as(i64, settings.width) * @as(i64, settings.height));

    const allocator = std.heap.c_allocator;
    const raw_buf = allocator.alloc(u32, total_pixels) catch @panic("failed to allocate window buffer");
    defer allocator.free(raw_buf);
    @memset(raw_buf, 0);
    const fullscreen_flag: i32 = if (settings.fullscreen) 1 else 0;

    var f = std.mem.zeroInit(c.fenster, .{
        .width = settings.width,
        .height = settings.height,
        .title = CONF.THE_NAME,
        .buf = raw_buf.ptr,
        .fullscreen = fullscreen_flag,
    });
    _ = c.fenster_open(&f);
    hideSystemCursor(&f);
    defer c.fenster_close(&f);
    var mouse_buttons = MouseButtons.init();
    var renderer = Render.init(raw_buf, settings.width, settings.height);
    defer renderer.deinit();
    var audio = Audio.init();
    defer audio.deinit();
    var proc_audio = ProcAudio.init(std.heap.c_allocator);
    defer proc_audio.deinit();
    var logo_sheet: ?*SpriteSheet = null;
    var logo_sprite: ?Sprite = null;

    std.debug.print("[init] Main sprites loading:\n", .{});
    if (SpriteSheet.load(allocator, .{
        .name = "logo.bmp",
        .source = @embedFile("sprites/logo.bmp"),
        .tile_w = 100,
        .tile_h = 26,
    })) |sheet_ptr| {
        logo_sheet = sheet_ptr;

        var sprite = Sprite.init(sheet_ptr, 0.14);
        const frame_count = @min(@as(usize, 3), sheet_ptr.frame_count());
        if (frame_count > 0) {
            sprite.set_animation(0, frame_count, 0.14, true) catch {};
            logo_sprite = sprite;
        }
    } else |err| {
        std.log.err("failed to load sprite sheet {s}: {s}", .{ "logo.bmp", @errorName(err) });
    }

    defer if (logo_sheet) |sheet| {
        sheet.deinit();
        allocator.destroy(sheet);
    };

    var fui = Fui.init(settings.width, settings.height);
    var sm = StateMachine.init(State.main_menu);
    var esc_lock = false;

    const menu_groups = [_]Menu.MenuGroup{
        .{
            .title = "Main Menu",
            .items = &[_]Menu.MenuItem{
                .{ .text = "Example", .normal_color = UiTheme.MENU_NORMAL_COLOR, .hover_color = UiTheme.MENU_HIGHLIGHT_COLOR, .target_state = State.example },
            },
        },
        .{
            .title = "System",
            .items = &[_]Menu.MenuItem{
                .{ .text = "About", .normal_color = UiTheme.MENU_SECONDARY_COLOR, .hover_color = UiTheme.MENU_HIGHLIGHT_COLOR, .target_state = State.about },
                .{ .text = "Quit", .normal_color = UiTheme.MENU_SECONDARY_COLOR, .hover_color = UiTheme.MENU_DANGER_COLOR, .target_state = State.quit },
            },
        },
    };

    const core_menu = Menu.init(&fui, &menu_groups);
    var menu = MenuScene.init(&fui, &sm, core_menu);
    var about = AboutScene.init(&fui);
    var example = ExampleScene.init(std.heap.c_allocator, &fui, &renderer, &audio, &proc_audio);
    defer example.deinit();

    std.debug.print("[init] Main initialized\n", .{});

    var prev_state = sm.current;

    while (c.fenster_loop(&f) == 0) {
        renderer.perf_begin_sim();
        sm.update();
        if (prev_state == .main_menu and sm.current != .main_menu) {
            playSfx(&audio, .menu_main);
        }
        prev_state = sm.current;
        renderer.begin_frame();
        if (!sm.is(.example)) renderer.clear_background(UiTheme.BG_COLOR);

        const mouse = mouse_buttons.update(f.x, f.y, @intCast(f.mouse));

        // ESC handler
        if (esc_lock and f.keys[27] == 0) {
            esc_lock = false;
        } else if (!esc_lock and f.keys[27] != 0) {
            esc_lock = true;
            if (!sm.is(State.main_menu)) sm.go_to(State.main_menu) else break;
        }

        // Update audio
        audio.update_audio(renderer.dt);

        // State update
        switch (sm.current) {
            State.example => {
                example.update(mouse, renderer.dt, &renderer);
            },
            State.main_menu => {},
            else => {},
        }
        if (logo_sprite) |*s| s.update(renderer.dt);

        // State draw
        switch (sm.current) {
            State.main_menu => {
                menu.draw(&renderer, mouse);
            },
            State.example => {
                example.draw(mouse, renderer.dt, &renderer);
            },
            State.about => {
                about.draw(&renderer);
            },
            State.quit => {
                break;
            },
        }

        renderer.perf_begin_draw();

        // Top global navigation
        if (!sm.is(State.main_menu) and fui.button(&renderer, fui.pivotX(.top_left), fui.pivotY(.top_left), 120, 32, "< Menu", UiTheme.MENU_SECONDARY_COLOR, UiTheme.MENU_HIGHLIGHT_COLOR, mouse)) {
            playSfx(&audio, .menu_back);
            sm.go_to(State.main_menu);
        }

        // Bottom global info
        if (logo_sprite) |*s| {
            const logo_x = fui.pivotX(.bottom_right) - 96;
            const logo_y = fui.pivotY(.bottom_right) - 32;
            s.draw(&renderer, logo_x, logo_y);
        }
        fui.draw_version(&renderer);
        renderer.draw_perf_overlay(&fui, UiTheme);

        if (!sm.is(State.example)) {
            fui.draw_cursor_lines(&renderer, .{ f.x, f.y });
        }

        renderer.perf_begin_present();
        renderer.present();
        renderer.perf_end_present();

        renderer.cap_frame(CONF.TARGET_FPS);
    }
}
