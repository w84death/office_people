// *************************************
// BOROWIK ENGINE
// by Krzysztof Krystian Jankowski
// github.com/w84death/borowik-engine
// *************************************

const std = @import("std");
const c = @cImport({
    @cInclude("fenster.h");
});
const CONF = @import("config.zig").CONF;

pub const Framebuffer = enum {
    frame,
    terrain,
};

pub const Render = struct {
    const PERF_ALPHA: f32 = 0.1;

    const PerfStats = struct {
        sim_start_ns: i128 = 0,
        draw_start_ns: i128 = 0,
        present_start_ns: i128 = 0,
        smoothed_fps: f32 = CONF.TARGET_FPS,
        smoothed_sim_ms: f32 = 0.0,
        smoothed_draw_ms: f32 = 0.0,
        smoothed_present_ms: f32 = 0.0,
        fps_text_buf: [32]u8 = undefined,
        sim_text_buf: [32]u8 = undefined,
        draw_text_buf: [32]u8 = undefined,
        present_text_buf: [32]u8 = undefined,
    };

    const ClippedRect = struct {
        x: i32,
        y: i32,
        w: i32,
        h: i32,
    };

    window_buf: []u32,
    width: i32,
    height: i32,
    pixels_count: usize,
    frame_buf: []u32,
    terrain_buf: []u32,
    allocator: std.mem.Allocator,
    target: Framebuffer = .frame,
    dt: f32 = 0.0,
    now: i64,
    perf: PerfStats = .{},

    pub fn init(buf: []u32, width: i32, height: i32) Render {
        const allocator = std.heap.c_allocator;
        const w: i32 = if (width > 0) width else CONF.SCREEN_W;
        const h: i32 = if (height > 0) height else CONF.SCREEN_H;
        const count: usize = @intCast(@as(i64, w) * @as(i64, h));

        const frame_buf = allocator.alloc(u32, count) catch @panic("failed to allocate frame buffer");
        const terrain_buf = allocator.alloc(u32, count) catch @panic("failed to allocate terrain buffer");

        @memset(frame_buf, 0);
        @memset(terrain_buf, 0);

        std.debug.print("[init] renderer initilized\n", .{});

        return .{
            .window_buf = buf,
            .width = w,
            .height = h,
            .pixels_count = count,
            .frame_buf = frame_buf,
            .terrain_buf = terrain_buf,
            .allocator = allocator,
            .target = .frame,
            .now = c.fenster_time(),
        };
    }

    pub fn deinit(self: *Render) void {
        self.allocator.free(self.frame_buf);
        self.allocator.free(self.terrain_buf);
    }

    pub fn begin_frame(self: *Render) void {
        const d: f32 = @floatFromInt(c.fenster_time() - self.now);
        self.dt = @as(f32, d / 1000.0);
        self.now = c.fenster_time();
    }

    pub fn cap_frame(self: *Render, target_fps: f64) void {
        const frame_time_target: f64 = 1000.0 / target_fps;
        const processing_time: f64 = @floatFromInt(c.fenster_time() - self.now);
        const sleep_ms: i64 = @intFromFloat(@max(0.0, frame_time_target - processing_time));
        if (sleep_ms > 0) {
            c.fenster_sleep(sleep_ms);
        }
    }

    pub fn present(self: *Render) void {
        @memcpy(self.window_buf, self.frame_buf);
    }

    pub fn perf_begin_sim(self: *Render) void {
        self.perf.sim_start_ns = std.time.nanoTimestamp();
    }

    pub fn perf_begin_draw(self: *Render) void {
        const now_ns = std.time.nanoTimestamp();
        const sim_ms = ns_to_ms(now_ns - self.perf.sim_start_ns);
        self.perf.smoothed_sim_ms = smooth(self.perf.smoothed_sim_ms, sim_ms);
        self.perf.draw_start_ns = now_ns;
    }

    pub fn perf_begin_present(self: *Render) void {
        const now_ns = std.time.nanoTimestamp();
        const draw_ms = ns_to_ms(now_ns - self.perf.draw_start_ns);
        self.perf.smoothed_draw_ms = smooth(self.perf.smoothed_draw_ms, draw_ms);
        self.perf.present_start_ns = now_ns;
    }

    pub fn perf_end_present(self: *Render) void {
        const now_ns = std.time.nanoTimestamp();
        const present_ms = ns_to_ms(now_ns - self.perf.present_start_ns);
        self.perf.smoothed_present_ms = smooth(self.perf.smoothed_present_ms, present_ms);

        if (self.dt > 0.0) {
            const instant_fps: f32 = 1.0 / self.dt;
            self.perf.smoothed_fps = smooth(self.perf.smoothed_fps, instant_fps);
        }
    }

    pub fn draw_perf_overlay(self: *Render, fui: anytype, comptime Theme: type) void {
        const fps: i32 = @intFromFloat(@round(self.perf.smoothed_fps));
        const fps_text = std.fmt.bufPrint(&self.perf.fps_text_buf, "FPS: {d}", .{fps}) catch "FPS: ?";
        fui.draw_text(self, fps_text, fui.pivotX(.bottom_left), fui.pivotY(.bottom_left), Theme.FONT_PERF, Theme.SECONDARY_COLOR);

        const sim_ms_text = std.fmt.bufPrint(&self.perf.sim_text_buf, "SIM: {d:.2}ms", .{self.perf.smoothed_sim_ms}) catch "SIM: ?";
        fui.draw_text(self, sim_ms_text, fui.pivotX(.bottom_left), fui.pivotY(.bottom_left) - Theme.FONT_PERFLINE_HEIGHT, Theme.FONT_PERF, Theme.SECONDARY_COLOR);

        const draw_ms_text = std.fmt.bufPrint(&self.perf.draw_text_buf, "DRAW: {d:.2}ms", .{self.perf.smoothed_draw_ms}) catch "DRAW: ?";
        fui.draw_text(self, draw_ms_text, fui.pivotX(.bottom_left), fui.pivotY(.bottom_left) - Theme.FONT_PERFLINE_HEIGHT * 2, Theme.FONT_PERF, Theme.SECONDARY_COLOR);

        const present_ms_text = std.fmt.bufPrint(&self.perf.present_text_buf, "PRESENT: {d:.2}ms", .{self.perf.smoothed_present_ms}) catch "PRESENT: ?";
        fui.draw_text(self, present_ms_text, fui.pivotX(.bottom_left), fui.pivotY(.bottom_left) - Theme.FONT_PERFLINE_HEIGHT * 3, Theme.FONT_PERF, Theme.SECONDARY_COLOR);
    }

    pub fn set_target(self: *Render, target: Framebuffer) void {
        self.target = target;
    }

    pub fn clear_buffer(self: *Render, target: Framebuffer, color: u32) void {
        const buf = self.buffer_ptr(target);
        for (buf) |*px| {
            px.* = color;
        }
    }

    pub fn copy_buffer(self: *Render, src: Framebuffer, dst: Framebuffer) void {
        const src_buf = self.buffer_ptr(src);
        const dst_buf = self.buffer_ptr(dst);
        @memcpy(dst_buf, src_buf);
    }

    pub fn target_buffer(self: *Render) []u32 {
        return self.active_buffer_ptr();
    }

    pub fn put_pixel(self: *Render, x: i32, y: i32, color: u32) void {
        const buf = self.active_buffer_ptr();
        const index: usize = @intCast(y * self.width + x);
        buf[index] = color;
    }

    pub fn get_pixel(self: *Render, x: i32, y: i32) u32 {
        const buf = self.active_buffer_ptr();
        const index: usize = @intCast(y * self.width + x);
        return buf[index];
    }

    pub fn clear_background(self: *Render, color: u32) void {
        self.clear_buffer(self.target, color);
    }

    pub fn draw_line(self: *Render, x0: i32, y0: i32, x1: i32, y1: i32, color: u32) void {
        var x = x0;
        var y = y0;
        const dx: i32 = @intCast(@abs(x1 - x0));
        const dy: i32 = @intCast(@abs(y1 - y0));
        const sx: i32 = if (x0 < x1) 1 else -1;
        const sy: i32 = if (y0 < y1) 1 else -1;
        var err: i32 = if (dx > dy) dx else -dy;
        err = @divFloor(err, 2);
        while (true) {
            if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
                self.put_pixel(x, y, color);
            }
            if (x == x1 and y == y1) break;
            const e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x += sx;
            }
            if (e2 < dy) {
                err += dx;
                y += sy;
            }
        }
    }

    pub fn draw_rect(self: *Render, x: i32, y: i32, w: i32, h: i32, color: u32) void {
        const clipped = self.clip_rect(x, y, w, h) orelse return;

        const ix: u32 = @intCast(clipped.x);
        const iy: u32 = @intCast(clipped.y);
        const iw: u32 = @intCast(clipped.w);
        const ih: u32 = @intCast(clipped.h);

        for (iy..(iy + ih)) |row| {
            for (ix..(ix + iw)) |col| {
                self.put_pixel(@intCast(col), @intCast(row), color);
            }
        }
    }

    pub fn splat_sprite(
        self: *Render,
        target: Framebuffer,
        sheet: anytype,
        sprite_size: i32,
        anim_start: usize,
        anim_len: usize,
        x: i32,
        y: i32,
        rand: *const std.Random,
    ) void {
        if (anim_len == 0) return;

        const frame_offset = rand.intRangeAtMost(usize, 0, anim_len - 1);
        const frame = anim_start + frame_offset;
        const draw_x = x - @divFloor(sprite_size, 2);
        const draw_y = y - @divFloor(sprite_size, 2);

        const prev_target = self.target;
        self.set_target(target);
        defer self.set_target(prev_target);

        sheet.draw_frame(self, frame, draw_x, draw_y);
    }

    pub fn draw_rect_trans(self: *Render, x: i32, y: i32, w: i32, h: i32, color: u32) void {
        const clipped = self.clip_rect(x, y, w, h) orelse return;

        const ix: u32 = @intCast(clipped.x);
        const iy: u32 = @intCast(clipped.y);
        const iw: u32 = @intCast(clipped.w);
        const ih: u32 = @intCast(clipped.h);

        for (iy..(iy + ih)) |row| {
            for (ix..(ix + iw)) |col| {
                const local_row = row - iy;
                if (local_row % 4 != 1) {
                    self.put_pixel(@intCast(col), @intCast(row), color);
                }
            }
        }
    }

    pub fn draw_rect_lines(self: *Render, x: i32, y: i32, w: i32, h: i32, color: u32) void {
        if (w <= 0 or h <= 0) return;
        self.draw_line(x, y, x + w - 1, y, color);
        self.draw_line(x, y + h - 1, x + w - 1, y + h - 1, color);
        self.draw_line(x, y, x, y + h - 1, color);
        self.draw_line(x + w - 1, y, x + w - 1, y + h - 1, color);
    }

    pub fn draw_hline(self: *Render, x: i32, y: i32, w: i32, color: u32) void {
        if (w <= 0) return;
        self.draw_line(x, y, x + w - 1, y, color);
    }

    pub fn draw_circle(self: *Render, x: i32, y: i32, r: u32, color: u32) void {
        const rr = @as(i64, r) * r;
        const ir: i32 = @intCast(r);
        var dy: i32 = -ir;
        while (dy <= ir) : (dy += 1) {
            var dx: i32 = -ir;
            while (dx <= ir) : (dx += 1) {
                const px = x + dx;
                const py = y + dy;
                if (px >= 0 and px < self.width and py >= 0 and py < self.height) {
                    const dist = @as(i64, dx) * dx + @as(i64, dy) * dy;
                    if (dist <= rr) {
                        const index = (@as(usize, @intCast(py)) * @as(usize, @intCast(self.width))) + @as(usize, @intCast(px));
                        self.active_buffer_ptr()[index] = color;
                    }
                }
            }
        }
    }

    pub fn fill(self: *Render, x: i32, y: i32, old_color: u32, new_color: u32) void {
        if (old_color == new_color) {
            return;
        }
        if (x < 0 or y < 0 or x >= self.width or y >= self.height) {
            return;
        }
        if (self.get_pixel(x, y) == old_color) {
            self.put_pixel(x, y, new_color);
            self.fill(x - 1, y, old_color, new_color);
            self.fill(x + 1, y, old_color, new_color);
            self.fill(x, y - 1, old_color, new_color);
            self.fill(x, y + 1, old_color, new_color);
        }
    }

    fn clip_rect(self: *Render, x: i32, y: i32, w: i32, h: i32) ?ClippedRect {
        if (w <= 0 or h <= 0) return null;

        var rx = x;
        var ry = y;
        var rw = w;
        var rh = h;

        if (rx < 0) {
            rw += rx;
            rx = 0;
        }
        if (ry < 0) {
            rh += ry;
            ry = 0;
        }
        if (rx + rw > self.width) {
            rw = self.width - rx;
        }
        if (ry + rh > self.height) {
            rh = self.height - ry;
        }

        if (rw <= 0 or rh <= 0) return null;

        return ClippedRect{ .x = rx, .y = ry, .w = rw, .h = rh };
    }

    fn active_buffer_ptr(self: *Render) []u32 {
        return self.buffer_ptr(self.target);
    }

    fn buffer_ptr(self: *Render, target: Framebuffer) []u32 {
        return switch (target) {
            .frame => self.frame_buf,
            .terrain => self.terrain_buf,
        };
    }

    fn sub_sat(a: u8, b: u8) u8 {
        if (a <= b) return 0;
        return a - b;
    }

    fn smooth(current: f32, next: f32) f32 {
        return current + (next - current) * PERF_ALPHA;
    }

    fn ns_to_ms(value_ns: i128) f32 {
        return @as(f32, @floatFromInt(value_ns)) / 1_000_000.0;
    }
};
