const std = @import("std");
const audio_mod = @import("audio.zig");

pub const Profile = enum {
    energetic,
    subtle,
    lose_negative,
};

const DIR_NEUTRAL: u8 = 0;
const DIR_UP: u8 = 1;
const DIR_DOWN: u8 = 2;

const NOTE_DUR: f32 = 0.16;
const REST_DUR: f32 = 0.12;

const ProfileDef = struct {
    min_note: usize,
    max_note: usize,
    rest_chance: u8,
    max_slot: usize,
    dir_bias: u8,
    phrase_min: usize,
    phrase_max: usize,
    scale_mask12: u16,
};

const NEXT_DELTA_BY_PC = [12][8]i8{
    .{ 2, 0, -2, 4, -5, 7, -7, 12 },
    .{ 1, -1, 2, -2, 3, -3, 7, -5 },
    .{ -2, 2, 0, 3, -4, 5, -7, 12 },
    .{ 1, -1, 2, -2, 4, -4, 7, -5 },
    .{ -1, 2, -2, 0, 3, -5, 7, -12 },
    .{ 2, -2, 0, 3, -4, 5, -7, 12 },
    .{ 1, -1, 2, -2, 3, -3, 7, -5 },
    .{ 2, -2, 0, 4, -5, 7, -7, 12 },
    .{ 1, -1, 2, -2, 3, -4, 7, -5 },
    .{ -2, 2, 0, 3, -5, 7, -7, 12 },
    .{ 1, -1, 2, -2, 4, -3, 7, -5 },
    .{ 1, -2, 2, 0, -1, 5, -7, 12 },
};

fn profile_def(profile: Profile) ProfileDef {
    return switch (profile) {
        .energetic => .{
            .min_note = audio_mod.NOTE_C4,
            .max_note = audio_mod.NOTE_B6,
            .rest_chance = 12,
            .max_slot = 6,
            .dir_bias = DIR_UP,
            .phrase_min = 8,
            .phrase_max = 16,
            .scale_mask12 = 0x0AB5,
        },
        .subtle => .{
            .min_note = audio_mod.NOTE_A3,
            .max_note = audio_mod.NOTE_E5,
            .rest_chance = 40,
            .max_slot = 3,
            .dir_bias = DIR_NEUTRAL,
            .phrase_min = 8,
            .phrase_max = 12,
            .scale_mask12 = 0x0AB5,
        },
        .lose_negative => .{
            .min_note = audio_mod.NOTE_C3,
            .max_note = audio_mod.NOTE_B4,
            .rest_chance = 64,
            .max_slot = 4,
            .dir_bias = DIR_DOWN,
            .phrase_min = 6,
            .phrase_max = 10,
            .scale_mask12 = 0x05AD,
        },
    };
}

pub const ProcAudio = struct {
    allocator: std.mem.Allocator,
    notes: std.ArrayListUnmanaged(audio_mod.Note) = .{},

    pub fn init(allocator: std.mem.Allocator) ProcAudio {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *ProcAudio) void {
        self.notes.deinit(self.allocator);
    }

    pub fn play(self: *ProcAudio, audio: *audio_mod.Audio, profile: Profile, seed: u32, phrase_count: usize) !void {
        const def = profile_def(profile);
        var rng_state: u32 = if (seed == 0) 1 else seed;
        self.notes.clearRetainingCapacity();

        var current = pick_start_note(def, &rng_state);

        var p: usize = 0;
        while (p < phrase_count) : (p += 1) {
            const phrase_len = rand_in_range(&rng_state, def.phrase_min, def.phrase_max);
            var i: usize = 0;
            while (i < phrase_len) : (i += 1) {
                try self.notes.append(self.allocator, .{
                    .id = current,
                    .dur = if (current == audio_mod.NOTE_REST) REST_DUR else NOTE_DUR,
                });
                current = next_note(current, def, &rng_state);
            }
        }

        audio.play_tune(self.notes.items);
    }
};

fn rand8(state: *u32) u8 {
    state.* = state.* *% 1664525 +% 1013904223;
    return @intCast((state.* >> 24) & 0xFF);
}

fn rand_in_range(state: *u32, min_inc: usize, max_inc: usize) usize {
    const span = max_inc - min_inc + 1;
    return min_inc + (@as(usize, rand8(state)) % span);
}

fn note_to_pc(note_id: usize) usize {
    return (note_id - 1) % 12;
}

fn in_scale(note_id: usize, mask12: u16) bool {
    const pc = note_to_pc(note_id);
    return ((mask12 >> @intCast(pc)) & 1) != 0;
}

fn pick_start_note(def: ProfileDef, rng: *u32) usize {
    var i: usize = 0;
    while (i < 64) : (i += 1) {
        const n = rand_in_range(rng, def.min_note, def.max_note);
        if (in_scale(n, def.scale_mask12)) return n;
    }
    return def.min_note;
}

fn next_note(current: usize, def: ProfileDef, rng: *u32) usize {
    if (rand8(rng) < def.rest_chance) return audio_mod.NOTE_REST;
    if (current == audio_mod.NOTE_REST) return pick_start_note(def, rng);

    const a = rand8(rng) & 7;
    const b = rand8(rng) & 7;
    var slot: usize = @min(a, b);
    if (slot > def.max_slot) slot = def.max_slot;

    const row = NEXT_DELTA_BY_PC[note_to_pc(current)];

    while (true) {
        const delta = row[slot];
        if (def.dir_bias == DIR_UP and delta < 0) {
            if (slot == 0) return current;
            slot -= 1;
            continue;
        }
        if (def.dir_bias == DIR_DOWN and delta > 0) {
            if (slot == 0) return current;
            slot -= 1;
            continue;
        }

        const cand_signed = @as(i32, @intCast(current)) + delta;
        if (cand_signed < @as(i32, @intCast(def.min_note)) or cand_signed > @as(i32, @intCast(def.max_note))) {
            if (slot == 0) return current;
            slot -= 1;
            continue;
        }

        const cand: usize = @intCast(cand_signed);
        if (!in_scale(cand, def.scale_mask12)) {
            if (slot == 0) return current;
            slot -= 1;
            continue;
        }
        return cand;
    }
}
