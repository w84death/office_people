// *************************************
// BOROWIK ENGINE
// by Krzysztof Krystian Jankowski
// github.com/w84death/borowik-engine
// *************************************

const Mouse = @import("mouse.zig").Mouse;
const Render = @import("render.zig").Render;
const CONF = @import("config.zig").CONF;
const Font = @import("font.zig").Font8x16;
const Vec2 = @Vector(2, i32);
const Rect = struct {
    w: i32,
    h: i32,
    x: i32,
    y: i32,
    pub fn init(w: i32, h: i32, x: i32, y: i32) Rect {
        return .{ .w = w, .h = h, .x = x, .y = y };
    }
};

inline fn vec2(x: i32, y: i32) Vec2 {
    return .{ x, y };
}
pub const Pivot = enum {
    center,
    top_left,
    top_right,
    bottom_left,
    bottom_right,
};
pub fn Fui(comptime Theme: type) type {
    return struct {
        const Self = @This();

        screen_w: i32,
        screen_h: i32,

        pub fn init(screen_w: i32, screen_h: i32) Self {
            return Self{ .screen_w = screen_w, .screen_h = screen_h };
        }
        pub inline fn pivot(self: *const Self, p: Pivot) Vec2 {
            return switch (p) {
                .center => vec2(@divFloor(self.screen_w, 2), @divFloor(self.screen_h, 2)),
                .top_left => vec2(Theme.PIVOT_PADDING, Theme.PIVOT_PADDING),
                .top_right => vec2(self.screen_w - Theme.PIVOT_PADDING, Theme.PIVOT_PADDING),
                .bottom_left => vec2(Theme.PIVOT_PADDING, self.screen_h - Theme.PIVOT_PADDING),
                .bottom_right => vec2(self.screen_w - Theme.PIVOT_PADDING, self.screen_h - Theme.PIVOT_PADDING),
            };
        }
        pub inline fn pivotX(self: *const Self, p: Pivot) i32 {
            return self.pivot(p)[0];
        }
        pub inline fn pivotY(self: *const Self, p: Pivot) i32 {
            return self.pivot(p)[1];
        }

        pub fn draw_text(self: *Self, renderer: *Render, s: []const u8, x: i32, y: i32, scale: i32, color: u32) void {
            _ = self;
            var px = x;
            for (s) |chr| {
                if (chr >= 32 and chr < 95 + 32) {
                    const bmh = Font[chr - 32];
                    var dy: i32 = 0;
                    while (dy < CONF.FONT_HEIGHT) : (dy += 1) {
                        var dx: i32 = 0;
                        while (dx < CONF.FONT_WIDTH) : (dx += 1) {
                            const bit: u6 = @intCast(dy * CONF.FONT_WIDTH + dx);
                            if ((bmh >> bit) & 1 != 0) {
                                const rx: i32 = @intCast(dx * scale);
                                const ry: i32 = @intCast(dy * scale);
                                renderer.draw_rect(px + rx + 2, y + ry + 2, scale, scale, Theme.SHADOW_COLOR);
                                renderer.draw_rect(px + rx, y + ry, scale, scale, color);
                            }
                        }
                    }
                }
                px += @as(i32, CONF.FONT_WIDTH) * scale + 1;
            }
        }
        pub fn draw_text_block(self: *Self, renderer: *Render, lines: []const [:0]const u8, x: i32, y: i32, line_height: i32, scale: i32, color: u32) void {
            var ay = y;
            for (lines) |line| {
                self.draw_text(renderer, line, x, ay, scale, color);
                ay += line_height;
            }
        }
        pub fn text_length(self: *Self, s: []const u8, scale: i32) i32 {
            _ = self;
            const len: i32 = @intCast(s.len);
            if (len <= 0) return 0;
            return len * scale * CONF.FONT_WIDTH + (len - 1);
        }
        pub fn text_center(self: *Self, s: []const u8, scale: i32) Vec2 {
            return vec2(@divFloor(self.text_length(s, scale), 2), @divFloor(scale * CONF.FONT_HEIGHT, 2));
        }
        pub fn draw_cursor_lines(self: *Self, renderer: *Render, mouse: Vec2) void {
            renderer.draw_line(mouse[0], 0, mouse[0], self.screen_h, Theme.CROSSHAIR_COLOR);
            renderer.draw_line(0, mouse[1], self.screen_w, mouse[1], Theme.CROSSHAIR_COLOR);
        }
        pub fn button(self: *Self, renderer: *Render, x: i32, y: i32, w: i32, h: i32, label: [:0]const u8, normal_color: u32, hover_color: u32, mouse: Mouse) bool {
            const hover: bool = self.check_hover(mouse, Rect.init(w, h, x, y));
            const text_cener = self.text_center(label, Theme.FONT_DEFAULT);
            const text_x: i32 = x + @divFloor(w, 2) - text_cener[0];
            const text_y: i32 = y + @divFloor(h, 2) - text_cener[1];

            renderer.draw_rect(x, y, w, h, if (hover) hover_color else normal_color);
            renderer.draw_rect_lines(x, y, w, h, if (hover) Theme.MENU_FRAME_HOVER_COLOR else Theme.MENU_FRAME_COLOR);
            self.draw_text(renderer, label, text_x, text_y, Theme.FONT_DEFAULT, if (hover) Theme.BUTTON_TEXT_HOVER_COLOR else Theme.BUTTON_TEXT_COLOR);

            return mouse.just_pressed and hover;
        }
        pub fn check_hover(self: *Self, mouse: Mouse, target: Rect) bool {
            _ = self;
            return mouse.x >= target.x and mouse.x < target.x + target.w and
                mouse.y >= target.y and mouse.y < target.y + target.h;
        }
        pub fn draw_version(self: *Self, renderer: *Render) void {
            const len = self.text_length(CONF.VERSION, Theme.FONT_DEFAULT);
            const ver_x: i32 = self.pivotX(.bottom_right) - len;
            const ver_y: i32 = self.pivotY(.bottom_right);
            self.draw_text(renderer, CONF.VERSION, ver_x, ver_y, Theme.FONT_DEFAULT, Theme.SECONDARY_COLOR);
        }
        fn draw_base_popup(self: *Self, renderer: *Render, message: [:0]const u8, bg_color: u32) Rect {
            const text_width: i32 = self.text_length(message, Theme.FONT_DEFAULT);
            const popup_size = vec2(if (text_width < 256) 256 else text_width + 128, 128);
            const center = vec2(self.pivotX(.center), self.pivotY(.center));
            const popup_corner = vec2(center[0] - @divFloor(popup_size[0], 2), center[1] - @divFloor(popup_size[1], 2));

            const text_x: i32 = popup_corner[0] + @divFloor(popup_size[0] - text_width, 2);
            const text_y: i32 = popup_corner[1] + 24;

            const x: i32 = popup_corner[0];
            const y: i32 = popup_corner[1];
            const w: i32 = popup_size[0];
            const h: i32 = popup_size[1];

            renderer.draw_rect(x + 8, y + 8, w, h, Theme.SHADOW_COLOR);
            renderer.draw_rect(x, y, w, h, bg_color);
            renderer.draw_rect_lines(x, y, w, h, Theme.LIGHT_COLOR);
            self.draw_text(renderer, message, text_x, text_y, Theme.FONT_DEFAULT, Theme.POPUP_MSG_COLOR);
            return Rect.init(popup_size[0], popup_size[1], popup_corner[0], popup_corner[1]);
        }
        pub fn info_popup(self: *Self, renderer: *Render, message: [:0]const u8, mouse: Mouse, bg_color: u32) ?bool {
            // Popup
            const popupv4: Rect = self.draw_base_popup(renderer, message, bg_color);
            const popup_corner = vec2(popupv4.x, popupv4.y);
            const popup_height = popupv4.h;

            // Button
            const button_height = 32;
            const button_width = 80;
            const button_x = self.pivotX(.center) - @divFloor(button_width, 2);
            const button_y = popup_corner[1] + popup_height - 50;
            const ok_clicked = self.button(renderer, button_x, button_y, button_width, button_height, "OK", Theme.OK_COLOR, Theme.MENU_OK_COLOR, mouse);
            if (ok_clicked) return true;
            return null;
        }
        pub fn yes_no_popup(self: *Self, renderer: *Render, message: [:0]const u8, mouse: Mouse) ?bool {
            // Popup
            const popupv4: Rect = self.draw_base_popup(renderer, message, Theme.POPUP_COLOR);
            const popup_corner = vec2(popupv4.x, popupv4.y);
            const popup_size = vec2(popupv4.w, popupv4.h);

            // buttons
            const button_y = popup_corner[1] + popup_size[1] - 50;
            const button_height = 32;
            const button_width = 80;
            const no_x = popup_corner[0] + 24;
            const yes_x = popup_corner[0] + popup_size[0] - 80 - 24;

            const yes_clicked = self.button(renderer, yes_x, button_y, button_width, button_height, "Yes", Theme.YES_COLOR, Theme.MENU_YES_COLOR, mouse);
            if (yes_clicked) return true;

            const no_clicked = self.button(renderer, no_x, button_y, button_width, button_height, "No", Theme.NO_COLOR, Theme.MENU_NO_COLOR, mouse);
            if (no_clicked) return false;

            return null;
        }
    };
}
