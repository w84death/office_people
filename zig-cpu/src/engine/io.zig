const std = @import("std");
const CONF = @import("config.zig").CONF;

pub const SETTINGS_FILE = "settings.cfg";

pub const Settings = struct {
    width: i32,
    height: i32,
    fullscreen: bool,
};

pub fn load_or_create_settings() !Settings {
    const cwd = std.fs.cwd();
    var file = cwd.openFile(SETTINGS_FILE, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            const defaults = default_settings();
            try write_settings(defaults);
            return defaults;
        },
        else => return err,
    };
    defer file.close();

    const buf = try file.readToEndAlloc(std.heap.c_allocator, 256);
    defer std.heap.c_allocator.free(buf);

    const parsed = parse_settings(buf) orelse {
        const defaults = default_settings();
        try write_settings(defaults);
        return defaults;
    };
    return parsed;
}

pub fn write_settings(settings: Settings) !void {
    const cwd = std.fs.cwd();
    var file = try cwd.createFile(SETTINGS_FILE, .{ .truncate = true });
    defer file.close();

    var out_buf: [64]u8 = undefined;
    const out = try std.fmt.bufPrint(
        &out_buf,
        "{d}\n{d}\n{d}\n",
        .{ settings.width, settings.height, if (settings.fullscreen) @as(u8, 1) else @as(u8, 0) },
    );
    try file.writeAll(out);
}

fn default_settings() Settings {
    return .{
        .width = CONF.SCREEN_W,
        .height = CONF.SCREEN_H,
        .fullscreen = false,
    };
}

fn parse_settings(buf: []const u8) ?Settings {
    var lines = std.mem.splitScalar(u8, buf, '\n');
    const w_line = std.mem.trim(u8, lines.next() orelse return null, " \t\r");
    const h_line = std.mem.trim(u8, lines.next() orelse return null, " \t\r");
    const f_line = std.mem.trim(u8, lines.next() orelse return null, " \t\r");

    const width = std.fmt.parseInt(i32, w_line, 10) catch return null;
    const height = std.fmt.parseInt(i32, h_line, 10) catch return null;
    const fullscreen_i = std.fmt.parseInt(i32, f_line, 10) catch return null;

    if (width <= 0 or height <= 0) return null;
    if (fullscreen_i != 0 and fullscreen_i != 1) return null;

    return .{
        .width = width,
        .height = height,
        .fullscreen = fullscreen_i == 1,
    };
}
