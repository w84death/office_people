const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("fenster.h");
});

const CONF = @import("engine/config.zig").CONF;
const Render = @import("engine/render.zig").Render;
const SpriteSheet = @import("engine/sprites.zig").SpriteSheet;
const Mouse = @import("engine/mouse.zig").Mouse;
const MouseButtons = @import("engine/mouse.zig").MouseButtons;
const UiTheme = @import("themes/default.zig").UiTheme;
const Fui = @import("engine/fui.zig").Fui(UiTheme);
const Levels = @import("game_levels.zig");

const MAX_ENTITIES = 96;
const PLAYER_SPEED: f32 = 30.0;
const SCORE_THROW = 500;
const SCORE_TRIGGER = 100;
const SCORE_USE = 50;
const LEVEL_TIME_LIMIT = 60.0;

const GameState = enum { intro, menu, game, level_clear, game_over, end };
const Direction = enum { up, right, down, left };

const Rect = struct { x: i32, y: i32, w: i32, h: i32 };

const Entity = struct {
    kind: Levels.EntityKind,
    x: f32,
    y: f32,
    vx: f32 = 0,
    vy: f32 = 0,
    dir: Direction = .down,
    frame: usize = 0,
    anim_t: f32 = 0,
    active: bool = true,
    player: bool = false,
    npc: bool = false,
    health: i32 = 0,
    knocked: f32 = 0,
    owner: ?usize = null,
    held: ?usize = null,
    last_owner_player: bool = false,
    lift: bool = false,
    state_on: bool = false,
    timer: i32 = 0,
    ai: Ai = .{},
};

const Ai = struct { up: i32 = 0, right: i32 = 0, down: i32 = 0, left: i32 = 0, idle: i32 = 0, throw_wait: i32 = 0 };

const EntityInfo = struct {
    sheet: SheetId,
    tile_w: i32 = 16,
    tile_h: i32 = 16,
    size_w: i32 = 16,
    size_h: i32 = 16,
    off_x: i32 = 0,
    off_y: i32 = 0,
    friction: f32 = 80,
    can_take: bool = false,
    can_use: bool = false,
    fixed: bool = false,
    weight: f32 = 10,
    power: f32 = 5,
    slow_down: f32 = 5,
    trigger: bool = false,
};

const SheetId = enum { office, employee, npc_employee, desk, chair, plant, water, lack, bookstand, fridge, kitchen, door, elevator, logo, sponsor, hearts, game_over, done, the_end, play0, play1, replay0, replay1, next0, next1, back0, back1, hand };

const Assets = struct {
    allocator: std.mem.Allocator,
    office: *SpriteSheet,
    employee: *SpriteSheet,
    npc_employee: *SpriteSheet,
    desk: *SpriteSheet,
    chair: *SpriteSheet,
    plant: *SpriteSheet,
    water: *SpriteSheet,
    lack: *SpriteSheet,
    bookstand: *SpriteSheet,
    fridge: *SpriteSheet,
    kitchen: *SpriteSheet,
    door: *SpriteSheet,
    elevator: *SpriteSheet,
    logo: *SpriteSheet,
    sponsor: *SpriteSheet,
    hearts: *SpriteSheet,
    game_over: *SpriteSheet,
    done: *SpriteSheet,
    the_end: *SpriteSheet,
    play0: *SpriteSheet,
    play1: *SpriteSheet,
    replay0: *SpriteSheet,
    replay1: *SpriteSheet,
    next0: *SpriteSheet,
    next1: *SpriteSheet,
    back0: *SpriteSheet,
    back1: *SpriteSheet,
    hand: *SpriteSheet,

    fn init(allocator: std.mem.Allocator) !Assets {
        return .{
            .allocator = allocator,
            .office = try load(allocator, "office", @embedFile("sprites/office_people/office.bmp"), 16, 16),
            .employee = try load(allocator, "employee", @embedFile("sprites/office_people/employee.bmp"), 16, 16),
            .npc_employee = try load(allocator, "npc_employee", @embedFile("sprites/office_people/npc_employee.bmp"), 16, 16),
            .desk = try load(allocator, "desk", @embedFile("sprites/office_people/desk.bmp"), 32, 16),
            .chair = try load(allocator, "chair", @embedFile("sprites/office_people/chair.bmp"), 16, 16),
            .plant = try load(allocator, "plant", @embedFile("sprites/office_people/plant.bmp"), 16, 16),
            .water = try load(allocator, "water", @embedFile("sprites/office_people/water.bmp"), 16, 16),
            .lack = try load(allocator, "lack", @embedFile("sprites/office_people/lack.bmp"), 16, 16),
            .bookstand = try load(allocator, "bookstand", @embedFile("sprites/office_people/bookstand.bmp"), 16, 16),
            .fridge = try load(allocator, "fridge", @embedFile("sprites/office_people/fridge.bmp"), 16, 16),
            .kitchen = try load(allocator, "kitchen", @embedFile("sprites/office_people/kitchen.bmp"), 16, 16),
            .door = try load(allocator, "door", @embedFile("sprites/office_people/door.bmp"), 16, 24),
            .elevator = try load(allocator, "elevator", @embedFile("sprites/office_people/elevator.bmp"), 16, 16),
            .logo = try load(allocator, "logo", @embedFile("sprites/office_people/office_people_logo.bmp"), 75, 36),
            .sponsor = try load(allocator, "sponsor", @embedFile("sprites/office_people/p1x_logo.bmp"), 22, 18),
            .hearts = try load(allocator, "hearts", @embedFile("sprites/office_people/hearth.bmp"), 9, 9),
            .game_over = try load(allocator, "game_over", @embedFile("sprites/office_people/game_over.bmp"), 51, 33),
            .done = try load(allocator, "done", @embedFile("sprites/office_people/done.bmp"), 56, 18),
            .the_end = try load(allocator, "the_end", @embedFile("sprites/office_people/the_end.bmp"), 70, 16),
            .play0 = try load(allocator, "play0", @embedFile("sprites/office_people/button_play_0.bmp"), 60, 16),
            .play1 = try load(allocator, "play1", @embedFile("sprites/office_people/button_play_1.bmp"), 60, 16),
            .replay0 = try load(allocator, "replay0", @embedFile("sprites/office_people/button_reply_0.bmp"), 46, 16),
            .replay1 = try load(allocator, "replay1", @embedFile("sprites/office_people/button_reply_1.bmp"), 46, 16),
            .next0 = try load(allocator, "next0", @embedFile("sprites/office_people/button_next_0.bmp"), 47, 16),
            .next1 = try load(allocator, "next1", @embedFile("sprites/office_people/button_next_1.bmp"), 47, 16),
            .back0 = try load(allocator, "back0", @embedFile("sprites/office_people/button_back_0.bmp"), 16, 16),
            .back1 = try load(allocator, "back1", @embedFile("sprites/office_people/button_back_1.bmp"), 16, 16),
            .hand = try load(allocator, "hand", @embedFile("sprites/hand.bmp"), 18, 28),
        };
    }

    fn load(allocator: std.mem.Allocator, name: []const u8, bytes: []const u8, tile_w: i32, tile_h: i32) !*SpriteSheet {
        return SpriteSheet.load(allocator, .{ .name = name, .source = bytes, .tile_w = tile_w, .tile_h = tile_h });
    }

    fn sheet(self: *const Assets, id: SheetId) *SpriteSheet {
        return switch (id) {
            .office => self.office,
            .employee => self.employee,
            .npc_employee => self.npc_employee,
            .desk => self.desk,
            .chair => self.chair,
            .plant => self.plant,
            .water => self.water,
            .lack => self.lack,
            .bookstand => self.bookstand,
            .fridge => self.fridge,
            .kitchen => self.kitchen,
            .door => self.door,
            .elevator => self.elevator,
            .logo => self.logo,
            .sponsor => self.sponsor,
            .hearts => self.hearts,
            .game_over => self.game_over,
            .done => self.done,
            .the_end => self.the_end,
            .play0 => self.play0,
            .play1 => self.play1,
            .replay0 => self.replay0,
            .replay1 => self.replay1,
            .next0 => self.next0,
            .next1 => self.next1,
            .back0 => self.back0,
            .back1 => self.back1,
            .hand => self.hand,
        };
    }

    fn deinit(self: *Assets) void {
        inline for (std.meta.fields(Assets)) |field| {
            if (field.type == *SpriteSheet) {
                const s = @field(self, field.name);
                s.deinit();
                self.allocator.destroy(s);
            }
        }
    }
};

const Game = struct {
    assets: *Assets,
    fui: Fui,
    entities: [MAX_ENTITIES]Entity = undefined,
    count: usize = 0,
    state: GameState = .intro,
    current_level: usize = 0,
    level: *const Levels.Level = &Levels.menu,
    player_idx: ?usize = null,
    camera_x: f32 = 0,
    camera_y: f32 = 0,
    menu_dir: f32 = 1,
    intro_timer: i32 = 35,
    buttons_timer: i32 = 35,
    score: i32 = 0,
    total_score: i32 = 0,
    show_score: i32 = 0,
    level_time_left: f32 = LEVEL_TIME_LIMIT,
    level_clear: bool = false,
    rng: std.Random.DefaultPrng,
    cursor_t: f32 = 0,
    score_buf: [32]u8 = undefined,
    progress_buf: [16]u8 = undefined,

    fn init(assets: *Assets) Game {
        var g = Game{ .assets = assets, .fui = Fui.init(CONF.SCREEN_W, CONF.SCREEN_H), .rng = std.Random.DefaultPrng.init(0x0ff1ce) };
        g.loadLevel(&Levels.menu);
        return g;
    }

    fn loadLevel(self: *Game, level: *const Levels.Level) void {
        self.level = level;
        self.count = 0;
        self.player_idx = null;
        self.level_clear = false;
        for (level.entities) |def| {
            if (self.count >= MAX_ENTITIES) break;
            var e = Entity{ .kind = def.kind, .x = @floatFromInt(def.x), .y = @floatFromInt(def.y), .player = def.player, .npc = def.kind == .npc_employee };
            if (def.kind == .employee) e.health = 3;
            if (def.kind == .desk) e.state_on = false;
            self.entities[self.count] = e;
            if (e.player) self.player_idx = self.count;
            self.count += 1;
        }
    }

    fn startGame(self: *Game) void {
        self.state = .game;
        self.score = 0;
        self.level_time_left = LEVEL_TIME_LIMIT;
        self.buttons_timer = 35;
        self.current_level = @min(self.current_level, Levels.playable.len - 1);
        self.loadLevel(Levels.playable[self.current_level]);
    }

    fn update(self: *Game, mouse: Mouse, dt: f32) void {
        self.cursor_t += dt;
        switch (self.state) {
            .intro => {
                self.intro_timer -= 1;
                if (self.intro_timer <= 0) self.state = .menu;
            },
            .menu => {
                const world_w: f32 = @floatFromInt(self.level.office_w * 16);
                const max_x = @max(0.0, world_w - @as(f32, @floatFromInt(CONF.SCREEN_W)));
                if (self.camera_x > max_x) self.menu_dir = -1;
                if (self.camera_x < 0) self.menu_dir = 1;
                self.camera_x += 0.1 * self.menu_dir;
                self.updateEntities(mouse, dt, false);
            },
            .game => {
                self.level_time_left = @max(0, self.level_time_left - dt);
                self.updateEntities(mouse, dt, true);
                self.updateCamera();
                if (self.player_idx) |pi| {
                    if (self.entities[pi].health <= 0 or self.level_time_left <= 0) self.gameOver(pi);
                }
                if (self.deskDoneCount() == self.deskTotalCount() and self.deskTotalCount() > 0) self.level_clear = true;
            },
            .level_clear, .game_over => {
                if (self.buttons_timer > 0) self.buttons_timer -= 1;
            },
            .end => {},
        }
    }

    fn updateEntities(self: *Game, mouse: Mouse, dt: f32, interactive: bool) void {
        if (interactive and self.player_idx != null) self.updatePlayer(mouse);
        var i: usize = 0;
        while (i < self.count) : (i += 1) {
            if (!self.entities[i].active) continue;
            if (self.entities[i].npc and interactive) self.updateNpc(i);
            self.updateEntityAnimation(i, dt);
            self.integrate(i, dt);
            self.updateHeld(i);
            if (interactive) self.handleInteractions(i);
        }
    }

    fn updatePlayer(self: *Game, mouse: Mouse) void {
        const pi = self.player_idx.?;
        var p = &self.entities[pi];
        if (p.knocked > 0) return;
        const mx = @as(f32, @floatFromInt(mouse.x)) + self.camera_x;
        const my = @as(f32, @floatFromInt(mouse.y)) + self.camera_y;
        const dx = mx - p.x;
        const dy = my - p.y;
        if (mouse.left_down) {
            if (@abs(dx) < 6 and @abs(dy) < 6 and p.held != null) {
                self.throwHeld(pi);
                return;
            }
            const len = @max(1.0, @sqrt(dx * dx + dy * dy));
            const speed = self.actorSpeed(pi);
            p.vx = dx / len * speed;
            p.vy = dy / len * speed;
            p.dir = dominantDir(dx, dy);
        }
    }

    fn updateNpc(self: *Game, idx: usize) void {
        var e = &self.entities[idx];
        if (e.knocked > 0) return;
        if (e.ai.up + e.ai.right + e.ai.down + e.ai.left + e.ai.idle < 1) {
            const r = self.rng.random().intRangeAtMost(i32, 0, 199);
            const t = self.rng.random().intRangeAtMost(i32, 0, 49);
            if (r < 25) e.ai.up = t else if (r < 50) e.ai.right = t else if (r < 75) e.ai.down = t else if (r < 100) e.ai.left = t else e.ai.idle = self.rng.random().intRangeAtMost(i32, 0, 149);
        }
        if (e.held != null and e.ai.throw_wait == 0) e.ai.throw_wait = self.rng.random().intRangeAtMost(i32, 0, 150);
        tick(&e.ai.up);
        tick(&e.ai.right);
        tick(&e.ai.down);
        tick(&e.ai.left);
        tick(&e.ai.idle);
        tick(&e.ai.throw_wait);
        const speed = self.actorSpeed(idx);
        if (e.ai.left > 0) {
            e.vx = -speed;
            e.dir = .left;
        }
        if (e.ai.right > 0) {
            e.vx = speed;
            e.dir = .right;
        }
        if (e.ai.up > 0) {
            e.vy = -speed;
            e.dir = .up;
        }
        if (e.ai.down > 0) {
            e.vy = speed;
            e.dir = .down;
        }
        if (e.held != null and e.ai.throw_wait > 120) self.throwHeld(idx);
    }

    fn integrate(self: *Game, idx: usize, dt: f32) void {
        var e = &self.entities[idx];
        if (e.owner != null) return;
        if (e.knocked > 0) e.knocked -= dt;
        if (@abs(e.vx) > 0.01) {
            const old = e.x;
            e.x += e.vx * dt;
            if (self.mapBlocked(idx)) {
                e.x = old;
                e.vx = 0;
            }
        }
        if (@abs(e.vy) > 0.01) {
            const old = e.y;
            e.y += e.vy * dt;
            if (self.mapBlocked(idx)) {
                e.y = old;
                e.vy = 0;
            }
        }
        const friction = info(e.kind).friction * dt;
        e.vx = approach(e.vx, 0, friction);
        e.vy = approach(e.vy, 0, friction);
    }

    fn updateHeld(self: *Game, owner_idx: usize) void {
        const held_idx = self.entities[owner_idx].held orelse return;
        const owner = self.entities[owner_idx];
        var held = &self.entities[held_idx];
        held.x = owner.x;
        if (owner.lift) {
            held.y = owner.y - 14;
            held.x = owner.x + @as(f32, @floatFromInt(@divFloor(info(owner.kind).size_w, 2) - @divFloor(info(held.kind).size_w, 2)));
        } else {
            held.y = owner.y;
        }
    }

    fn handleInteractions(self: *Game, idx: usize) void {
        if (!self.entities[idx].active) return;
        const is_actor = self.entities[idx].kind == .employee or self.entities[idx].kind == .npc_employee;
        if (!is_actor) return;
        var j: usize = 0;
        while (j < self.count) : (j += 1) {
            if (j == idx or !self.entities[j].active) continue;
            if (!aabb(self.rect(idx), self.rect(j))) continue;
            const ij = info(self.entities[j].kind);
            if (self.entities[j].owner == null and (@abs(self.entities[j].vx) > 15 or @abs(self.entities[j].vy) > 15)) {
                if (!(self.entities[j].last_owner_player and self.entities[idx].player)) self.knock(idx, ij.power, self.entities[j].last_owner_player);
            }
            if (self.entities[idx].held == null and self.entities[j].owner == null and ij.can_take) self.take(idx, j);
            if (self.entities[idx].held == null and self.entities[j].owner == null and ij.can_use) self.useEntity(idx, j);
            if (self.entities[j].kind == .elevator and self.level_clear and self.entities[idx].player) self.finishLevel();
        }
    }

    fn take(self: *Game, owner: usize, item: usize) void {
        self.entities[owner].held = item;
        self.entities[owner].lift = true;
        self.entities[item].owner = owner;
        self.entities[item].last_owner_player = self.entities[owner].player;
    }

    fn dropHeld(self: *Game, owner: usize) void {
        const item = self.entities[owner].held orelse return;
        const oi = info(self.entities[owner].kind);
        var it = &self.entities[item];
        switch (self.entities[owner].dir) {
            .up => it.y = self.entities[owner].y - @as(f32, @floatFromInt(info(it.kind).size_h)),
            .right => {
                it.x = self.entities[owner].x + @as(f32, @floatFromInt(oi.size_w + info(it.kind).size_w));
                it.y += 10;
            },
            .down => it.y = self.entities[owner].y + @as(f32, @floatFromInt(oi.size_h + info(it.kind).size_h)),
            .left => {
                it.x = self.entities[owner].x - @as(f32, @floatFromInt(oi.size_w + info(it.kind).size_w));
                it.y += 10;
            },
        }
        it.owner = null;
        self.entities[owner].held = null;
        self.entities[owner].lift = false;
    }

    fn throwHeld(self: *Game, owner: usize) void {
        const item = self.entities[owner].held orelse return;
        const force = 100 - info(self.entities[item].kind).weight;
        switch (self.entities[owner].dir) {
            .up => self.entities[item].vy = -force,
            .right => self.entities[item].vx = force,
            .down => self.entities[item].vy = force,
            .left => self.entities[item].vx = -force,
        }
        self.dropHeld(owner);
    }

    fn useEntity(self: *Game, actor: usize, target: usize) void {
        _ = actor;
        var e = &self.entities[target];
        switch (e.kind) {
            .desk => if (!e.state_on) {
                e.state_on = true;
                self.score += SCORE_TRIGGER;
            },
            .fridge => if (!e.state_on) {
                e.state_on = true;
                e.timer = 100;
                self.score += SCORE_USE;
            },
            .kitchen_coffee => if (!e.state_on) {
                e.state_on = true;
                e.timer = 400;
                self.score += SCORE_USE * 2;
            },
            .kitchen_sink => if (!e.state_on) {
                e.state_on = true;
                e.timer = 30;
                self.score += SCORE_USE;
            },
            else => {},
        }
    }

    fn knock(self: *Game, idx: usize, power: f32, by_player: bool) void {
        if (self.entities[idx].knocked <= 0 and self.entities[idx].player) self.entities[idx].health -= 1;
        self.entities[idx].knocked = power * 0.1;
        if (self.entities[idx].held != null) self.dropHeld(idx);
        if (by_player and !self.entities[idx].player) self.score += SCORE_THROW;
    }

    fn finishLevel(self: *Game) void {
        self.show_score = self.finalLevelScore();
        self.total_score += self.show_score;
        self.current_level += 1;
        self.buttons_timer = 35;
        self.state = if (self.current_level >= Levels.playable.len) .end else .level_clear;
    }

    fn gameOver(self: *Game, player_idx: usize) void {
        self.dropHeld(player_idx);
        self.entities[player_idx].active = false;
        self.state = .game_over;
        self.show_score = self.finalLevelScore();
        self.total_score = self.show_score;
        self.current_level = 0;
        self.buttons_timer = 35;
    }

    fn draw(self: *Game, renderer: *Render, mouse: Mouse) void {
        renderer.clear_background(0x000000);
        const cx = @divFloor(CONF.SCREEN_W, 2);
        const cy = @divFloor(CONF.SCREEN_H, 2);
        switch (self.state) {
            .intro => self.assets.sponsor.draw_frame(renderer, 0, cx - 11, cy - 9),
            .menu => {
                self.drawWorld(renderer);
                self.assets.logo.draw_frame(renderer, 0, cx - 37, 20);
                const play_x = cx - 30;
                const play_y = CONF.SCREEN_H - 36;
                _ = self.imageButton(renderer, mouse, play_x, play_y, .play0, .play1);
                if (mouse.just_pressed and hit(mouse, .{ .x = play_x, .y = play_y, .w = 60, .h = 16 })) self.startGame();
                self.fui.draw_text(renderer, CONF.VERSION, cx - @divFloor(self.fui.text_length(CONF.VERSION, 1), 2), CONF.SCREEN_H - 10, 1, 0xF8F8F8);
            },
            .game => {
                self.drawWorld(renderer);
                self.drawHud(renderer);
            },
            .game_over => {
                self.assets.game_over.draw_frame(renderer, 0, cx - 25, cy - 34);
                const s = std.fmt.bufPrint(&self.score_buf, "YOU SCORE {d}", .{self.total_score}) catch "YOU SCORE ?";
                self.fui.draw_text(renderer, s, cx - @divFloor(self.fui.text_length(s, 1), 2), cy + 8, 1, 0xF8F8F8);
                if (self.buttons_timer <= 0) self.drawReplayBack(renderer, mouse);
            },
            .level_clear => {
                self.assets.done.draw_frame(renderer, 0, cx - 28, cy - 10);
                const s = std.fmt.bufPrint(&self.score_buf, "YOU SCORE {d}", .{self.show_score}) catch "YOU SCORE ?";
                self.fui.draw_text(renderer, s, cx - @divFloor(self.fui.text_length(s, 1), 2), cy + 8, 1, 0xF8F8F8);
                if (self.buttons_timer <= 0) {
                    if (self.imageButton(renderer, mouse, cx - 32, CONF.SCREEN_H - 20, .back0, .back1)) self.toMenu();
                    if (self.imageButton(renderer, mouse, cx - 14, CONF.SCREEN_H - 20, .next0, .next1)) self.startGame();
                }
            },
            .end => {
                self.assets.the_end.draw_frame(renderer, 0, cx - 35, cy - 10);
                const s = std.fmt.bufPrint(&self.score_buf, "YOU TOTAL SCORE {d}", .{self.total_score}) catch "YOU TOTAL SCORE ?";
                self.fui.draw_text(renderer, s, cx - @divFloor(self.fui.text_length(s, 1), 2), cy + 8, 1, 0xF8F8F8);
                self.fui.draw_text(renderer, "Idea, code, pixel art", cx - @divFloor(self.fui.text_length("Idea, code, pixel art", 1), 2), cy + 18, 1, 0xF8F8F8);
                self.fui.draw_text(renderer, "Krzysztof Jankowski", cx - @divFloor(self.fui.text_length("Krzysztof Jankowski", 1), 2), cy + 28, 1, 0xF8F8F8);
            },
        }
        self.drawCursor(renderer, mouse);
    }

    fn drawCursor(self: *Game, renderer: *Render, mouse: Mouse) void {
        const frame: usize = @intCast(@mod(@as(i32, @intFromFloat(self.cursor_t / 0.133)), 6));
        self.assets.hand.draw_frame(renderer, frame, mouse.x - 2, mouse.y - 2);
    }

    fn drawWorld(self: *Game, renderer: *Render) void {
        var ty: usize = 0;
        while (ty < self.level.office_h) : (ty += 1) {
            var tx: usize = 0;
            while (tx < self.level.office_w) : (tx += 1) {
                const tile = self.level.office[ty * self.level.office_w + tx];
                if (tile > 0) self.assets.office.draw_frame(renderer, tile - 1, @as(i32, @intCast(tx * 16)) - cami(self.camera_x), @as(i32, @intCast(ty * 16)) - cami(self.camera_y));
            }
        }
        var order: [MAX_ENTITIES]usize = undefined;
        var n: usize = 0;
        while (n < self.count) : (n += 1) order[n] = n;
        std.mem.sort(usize, order[0..self.count], self, lessEntityY);
        for (order[0..self.count]) |idx| self.drawEntity(renderer, idx);
    }

    fn drawEntity(self: *Game, renderer: *Render, idx: usize) void {
        const e = self.entities[idx];
        if (!e.active) return;
        const inf = info(e.kind);
        self.assets.sheet(inf.sheet).draw_frame(renderer, self.frameFor(idx), @as(i32, @intFromFloat(e.x)) - inf.off_x - cami(self.camera_x), @as(i32, @intFromFloat(e.y)) - inf.off_y - cami(self.camera_y));
    }

    fn drawHud(self: *Game, renderer: *Render) void {
        const done = self.deskDoneCount();
        const total = self.deskTotalCount();
        const p_health = if (self.player_idx) |pi| self.entities[pi].health else 0;
        var i: i32 = 0;
        while (i < 3) : (i += 1) self.assets.hearts.draw_frame(renderer, if (p_health > i) 0 else 1, CONF.SCREEN_W - 16 - 12 * i, 6);
        const progress = std.fmt.bufPrint(&self.progress_buf, "{d}/{d}", .{ done, total }) catch "?/?";
        self.fui.draw_text(renderer, progress, 8, 8, 1, 0xF8F8F8);
        const timer = std.fmt.bufPrint(&self.score_buf, "{d}", .{@as(i32, @intFromFloat(@ceil(self.level_time_left)))}) catch "?";
        self.fui.draw_text(renderer, timer, @divFloor(CONF.SCREEN_W - self.fui.text_length(timer, 1), 2), 8, 1, 0xF8F8F8);
        if (done == 0) self.fui.draw_text(renderer, "Turn on all the computers.", 8, CONF.SCREEN_H - 12, 1, 0xF8F8F8);
        if (done == total and total > 0) self.fui.draw_text(renderer, "Done! Go to elevator.", 8, CONF.SCREEN_H - 12, 1, 0xF8F8F8);
    }

    fn drawReplayBack(self: *Game, renderer: *Render, mouse: Mouse) void {
        const cx = @divFloor(CONF.SCREEN_W, 2);
        if (self.imageButton(renderer, mouse, cx - 32, CONF.SCREEN_H - 20, .back0, .back1)) self.toMenu();
        if (self.imageButton(renderer, mouse, cx - 14, CONF.SCREEN_H - 20, .replay0, .replay1)) self.startGame();
    }

    fn imageButton(self: *Game, renderer: *Render, mouse: Mouse, x: i32, y: i32, normal: SheetId, active: SheetId) bool {
        const sh = self.assets.sheet(normal);
        const r = Rect{ .x = x, .y = y, .w = sh.tile_w, .h = sh.tile_h };
        const hover = hit(mouse, r);
        self.assets.sheet(if (hover) active else normal).draw_frame(renderer, 0, x, y);
        return hover and mouse.just_pressed;
    }

    fn toMenu(self: *Game) void {
        self.state = .menu;
        self.current_level = 0;
        self.score = 0;
        self.total_score = 0;
        self.camera_x = 0;
        self.camera_y = 0;
        self.loadLevel(&Levels.menu);
    }

    fn updateCamera(self: *Game) void {
        if (self.player_idx) |pi| {
            const p = self.entities[pi];
            self.camera_x = 0.9 * self.camera_x + 0.1 * (p.x - @as(f32, @floatFromInt(CONF.SCREEN_W)) * 0.5);
            self.camera_y = 0.9 * self.camera_y + 0.1 * (p.y - @as(f32, @floatFromInt(CONF.SCREEN_H)) * 0.5);
            const max_x = @max(0, @as(i32, @intCast(self.level.collision_w)) * self.level.collision_tile - CONF.SCREEN_W);
            const max_y = @max(0, @as(i32, @intCast(self.level.collision_h)) * self.level.collision_tile - CONF.SCREEN_H);
            self.camera_x = @min(@max(0, self.camera_x), @as(f32, @floatFromInt(max_x)));
            self.camera_y = @min(@max(0, self.camera_y), @as(f32, @floatFromInt(max_y)));
        }
    }

    fn frameFor(self: *Game, idx: usize) usize {
        const e = self.entities[idx];
        const moving = @abs(e.vx) > 1 or @abs(e.vy) > 1;
        return switch (e.kind) {
            .employee, .npc_employee => actorFrame(e, moving),
            .desk => if (e.state_on) 1 else 0,
            .chair => switch (e.dir) {
                .up => 0,
                .right => 1,
                .down => 2,
                .left => 3,
            },
            .plant => if (moving) 1 else 0,
            .water => if (moving) 2 else @as(usize, @intCast(@mod(@as(i32, @intFromFloat(e.anim_t * 8)), 4))),
            .fridge => if (e.state_on) 1 else 0,
            .kitchen_coffee => if (e.state_on) 4 + @as(usize, @intCast(@mod(@as(i32, @intFromFloat(e.anim_t * 4)), 3))) else @as(usize, @intCast(@mod(@as(i32, @intFromFloat(e.anim_t * 4)), 4))),
            .kitchen_sink => if (e.state_on) 8 + @as(usize, @intCast(@mod(@as(i32, @intFromFloat(e.anim_t * 8)), 4))) else 7,
            .kitchen_cabinet => 12,
            .door => if (aabb(self.rect(idx), self.actorUnionRect())) 1 else 0,
            .door_vertical => if (aabb(self.rect(idx), self.actorUnionRect())) 3 else 2,
            .elevator => if (self.level_clear) 3 else 0,
            else => 0,
        };
    }

    fn updateEntityAnimation(self: *Game, idx: usize, dt: f32) void {
        var e = &self.entities[idx];
        e.anim_t += dt;
        if (e.timer > 0) e.timer -= 1;
        if (e.timer <= 0 and (e.kind == .fridge or e.kind == .kitchen_coffee or e.kind == .kitchen_sink)) e.state_on = false;
    }

    fn rect(self: *Game, idx: usize) Rect {
        const e = self.entities[idx];
        const inf = info(e.kind);
        return .{ .x = @as(i32, @intFromFloat(e.x)), .y = @as(i32, @intFromFloat(e.y)), .w = inf.size_w, .h = inf.size_h };
    }

    fn mapBlocked(self: *Game, idx: usize) bool {
        if (self.entities[idx].kind == .door or self.entities[idx].kind == .door_vertical) return false;
        const r = self.rect(idx);
        return self.solidAt(r.x, r.y) or self.solidAt(r.x + r.w - 1, r.y) or self.solidAt(r.x, r.y + r.h - 1) or self.solidAt(r.x + r.w - 1, r.y + r.h - 1);
    }

    fn solidAt(self: *Game, x: i32, y: i32) bool {
        if (x < 0 or y < 0) return true;
        const tx: usize = @intCast(@divFloor(x, self.level.collision_tile));
        const ty: usize = @intCast(@divFloor(y, self.level.collision_tile));
        if (tx >= self.level.collision_w or ty >= self.level.collision_h) return true;
        return self.level.collision[ty * self.level.collision_w + tx] != 0;
    }

    fn actorUnionRect(self: *Game) Rect {
        if (self.player_idx) |pi| return self.rect(pi);
        return .{ .x = -1000, .y = -1000, .w = 1, .h = 1 };
    }

    fn deskTotalCount(self: *Game) i32 {
        var total: i32 = 0;
        for (self.entities[0..self.count]) |e| {
            if (e.active and e.kind == .desk) total += 1;
        }
        return total;
    }

    fn deskDoneCount(self: *Game) i32 {
        var done: i32 = 0;
        for (self.entities[0..self.count]) |e| {
            if (e.active and e.kind == .desk and e.state_on) done += 1;
        }
        return done;
    }

    fn finalLevelScore(self: *Game) i32 {
        const remaining: i32 = @intFromFloat(@ceil(@max(0, self.level_time_left)));
        return self.score + remaining * 10;
    }

    fn actorSpeed(self: *Game, idx: usize) f32 {
        const held = self.entities[idx].held orelse return PLAYER_SPEED;
        return PLAYER_SPEED - info(self.entities[held].kind).slow_down;
    }
};

fn info(kind: Levels.EntityKind) EntityInfo {
    return switch (kind) {
        .employee => .{ .sheet = .employee, .size_w = 5, .size_h = 3, .off_x = 5, .off_y = 13 },
        .npc_employee => .{ .sheet = .npc_employee, .size_w = 5, .size_h = 3, .off_x = 5, .off_y = 13 },
        .desk => .{ .sheet = .desk, .tile_w = 32, .size_w = 19, .size_h = 4, .off_x = 7, .off_y = 9, .fixed = true, .can_use = true, .trigger = true, .friction = 200 },
        .chair => .{ .sheet = .chair, .size_w = 5, .size_h = 4, .off_x = 5, .off_y = 11, .can_take = true, .weight = 20, .slow_down = 2, .friction = 15 },
        .plant => .{ .sheet = .plant, .size_w = 7, .size_h = 8, .off_x = 5, .off_y = 8, .can_take = true, .weight = 20, .power = 10, .slow_down = 7, .friction = 100 },
        .water => .{ .sheet = .water, .size_w = 6, .size_h = 4, .off_x = 5, .off_y = 12, .can_take = true, .weight = 40, .power = 15, .slow_down = 10, .friction = 100 },
        .lack => .{ .sheet = .lack, .size_w = 10, .size_h = 7, .off_x = 3, .off_y = 9, .can_take = true, .weight = 10, .power = 8, .slow_down = 6, .friction = 200 },
        .bookstand => .{ .sheet = .bookstand, .size_w = 16, .size_h = 3, .off_y = 14, .friction = 400 },
        .fridge => .{ .sheet = .fridge, .size_w = 8, .size_h = 5, .off_x = 1, .off_y = 11, .can_use = true, .friction = 200 },
        .kitchen_cabinet => .{ .sheet = .kitchen, .size_w = 16, .size_h = 3, .off_y = 13, .fixed = true },
        .kitchen_coffee => .{ .sheet = .kitchen, .size_w = 16, .size_h = 3, .off_y = 13, .fixed = true, .can_use = true },
        .kitchen_sink => .{ .sheet = .kitchen, .size_w = 16, .size_h = 3, .off_y = 13, .fixed = true, .can_use = true },
        .door => .{ .sheet = .door, .tile_h = 19, .size_w = 16, .size_h = 16 },
        .door_vertical => .{ .sheet = .door, .tile_h = 24, .size_w = 8, .size_h = 24, .off_x = 8 },
        .elevator => .{ .sheet = .elevator, .size_w = 16, .size_h = 16, .fixed = true },
    };
}

fn actorFrame(e: Entity, moving: bool) usize {
    const lift: usize = if (e.lift) 4 else 0;
    const row: usize = switch (e.dir) {
        .up => 0,
        .right => 8,
        .down => 16,
        .left => 24,
    };
    if (e.knocked > 0) return if (e.dir == .right) 51 else 48;
    if (!moving) return row + lift;
    const step: usize = @intCast(@mod(@as(i32, @intFromFloat(e.anim_t * 6)), 3));
    return row + lift + 1 + step;
}

fn dominantDir(dx: f32, dy: f32) Direction {
    if (@abs(dx) >= @abs(dy)) return if (dx >= 0) .right else .left;
    return if (dy >= 0) .down else .up;
}

fn approach(v: f32, target: f32, step_size: f32) f32 {
    if (v < target) return @min(target, v + step_size);
    if (v > target) return @max(target, v - step_size);
    return target;
}

fn tick(v: *i32) void {
    if (v.* > 0) v.* -= 1;
}

fn aabb(a: Rect, b: Rect) bool {
    return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y;
}

fn hit(mouse: Mouse, r: Rect) bool {
    return mouse.x >= r.x and mouse.x < r.x + r.w and mouse.y >= r.y and mouse.y < r.y + r.h;
}

fn cami(v: f32) i32 {
    return @intFromFloat(@round(v));
}

fn lessEntityY(game: *Game, a: usize, b: usize) bool {
    return game.entities[a].y < game.entities[b].y;
}

fn hideSystemCursor(f: *c.fenster) void {
    switch (builtin.os.tag) {
        .windows => _ = c.ShowCursor(0),
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

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const window_w = CONF.SCREEN_W * CONF.PIXEL_SCALE;
    const window_h = CONF.SCREEN_H * CONF.PIXEL_SCALE;
    const total_pixels: usize = @intCast(window_w * window_h);
    const raw_buf = try allocator.alloc(u32, total_pixels);
    defer allocator.free(raw_buf);
    @memset(raw_buf, 0);

    var f = std.mem.zeroInit(c.fenster, .{ .width = window_w, .height = window_h, .title = CONF.THE_NAME, .buf = raw_buf.ptr, .fullscreen = 0 });
    _ = c.fenster_open(&f);
    defer c.fenster_close(&f);
    hideSystemCursor(&f);

    var renderer = Render.init_scaled(raw_buf, CONF.SCREEN_W, CONF.SCREEN_H, CONF.PIXEL_SCALE);
    defer renderer.deinit();
    var mouse_buttons = MouseButtons.init();
    var assets = try Assets.init(allocator);
    defer assets.deinit();
    var game = Game.init(&assets);

    var esc_lock = false;
    while (c.fenster_loop(&f) == 0) {
        renderer.begin_frame();
        const mouse = mouse_buttons.update(@divFloor(f.x, CONF.PIXEL_SCALE), @divFloor(f.y, CONF.PIXEL_SCALE), @intCast(f.mouse));
        if (esc_lock and f.keys[27] == 0) esc_lock = false else if (!esc_lock and f.keys[27] != 0) {
            esc_lock = true;
            if (game.state == .menu) break else game.toMenu();
        }
        game.update(mouse, renderer.dt);
        game.draw(&renderer, mouse);
        renderer.present();
        renderer.cap_frame(CONF.TARGET_FPS);
    }
}
