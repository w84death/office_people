const std = @import("std");
const Audio = @import("../engine/audio.zig").Audio;
const Render = @import("../engine/render.zig").Render;
const ParticleSystem = @import("../engine/particles.zig").ParticleSystem;
const SpriteSheet = @import("../engine/sprites.zig").SpriteSheet;

const EXPLOSION_TILE_SIZE = 32;
const EXPLOSION_FRAME_COUNT: u8 = 8;
const EXPLOSION_FRAME_DURATION: f32 = 0.133;

pub fn Effects(comptime AudioCfg: type) type {
    return struct {
        allocator: std.mem.Allocator,
        audio: *Audio,
        particles: ParticleSystem,
        explosion_sheet: ?*SpriteSheet,

        pub fn init(allocator: std.mem.Allocator, audio: *Audio, max_particles: usize) @This() {
            var self = @This(){
                .allocator = allocator,
                .audio = audio,
                .particles = ParticleSystem.init(allocator, max_particles),
                .explosion_sheet = null,
            };

            const bmp = @embedFile("../sprites/explosions.bmp");
            if (SpriteSheet.load_bmp_bytes(allocator, bmp, EXPLOSION_TILE_SIZE, EXPLOSION_TILE_SIZE)) |sheet| {
                const frames = sheet.frame_count();
                std.debug.print("[spritesheet] loaded {s} size={d}x{d} frames={d}\n", .{ "explosions.bmp", sheet.width, sheet.height, frames });
                const ptr = allocator.create(SpriteSheet) catch {
                    return self;
                };
                ptr.* = sheet;
                self.explosion_sheet = ptr;
            } else |err| {
                std.log.err("failed to load sprite sheet {s}: {s}", .{ "explosions.bmp", @errorName(err) });
            }

            return self;
        }

        pub fn deinit(self: *@This()) void {
            self.particles.deinit();
            if (self.explosion_sheet) |sheet| {
                sheet.deinit();
                self.allocator.destroy(sheet);
                self.explosion_sheet = null;
            }
        }

        pub fn spawn_explosion(self: *@This(), x: i32, y: i32) void {
            self.playSfx(.explosion);
            self.particles.spawn(.{
                .x = @floatFromInt(x),
                .y = @floatFromInt(y),
                .age = 0.0,
                .frame_duration = EXPLOSION_FRAME_DURATION,
                .frame_count = EXPLOSION_FRAME_COUNT,
            }) catch {};
        }

        pub fn update(self: *@This(), dt: f32) void {
            self.particles.update(dt);
        }

        pub fn draw(self: *@This(), renderer: *Render) void {
            const sheet = self.explosion_sheet orelse return;

            for (self.particles.items()) |p| {
                const frame = p.frame_index();
                const draw_x: i32 = @as(i32, @intFromFloat(p.x)) - @divFloor(EXPLOSION_TILE_SIZE, 2);
                const draw_y: i32 = @as(i32, @intFromFloat(p.y)) - @divFloor(EXPLOSION_TILE_SIZE, 2);
                sheet.draw_frame(renderer, frame, draw_x, draw_y);
            }
        }

        fn playSfx(self: *@This(), effect: AudioCfg.Effect) void {
            const tune = AudioCfg.sfx(effect);
            if (tune.len == 0) return;
            self.audio.play_tune(tune);
        }
    };
}
