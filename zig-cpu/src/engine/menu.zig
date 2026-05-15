// *************************************
// BOROWIK ENGINE
// by Krzysztof Krystian Jankowski
// github.com/w84death/borowik-engine
// *************************************

const Mouse = @import("mouse.zig").Mouse;
const Render = @import("render.zig").Render;

pub fn Menu(comptime State: type, comptime StateMachine: type, comptime Theme: type) type {
    const Fui = @import("fui.zig").Fui(Theme);
    return struct {
        const Self = @This();

        pub const StateMachineType = StateMachine;

        pub const MenuItem = struct {
            text: [:0]const u8,
            normal_color: u32,
            hover_color: u32,
            target_state: State,
        };

        pub const MenuGroup = struct {
            title: [:0]const u8,
            items: []const MenuItem,
        };

        fui: *Fui,
        groups: []const MenuGroup,

        pub fn init(fui: *Fui, groups: []const MenuGroup) Self {
            return Self{
                .fui = fui,
                .groups = groups,
            };
        }

        pub fn height(self: *Self) i32 {
            var h: i32 = 0;
            for (self.groups) |group| {
                h += Theme.MENU_GROUP_TITLE_HEIGHT;
                h += Theme.MENU_FRAME_BASE_HEIGHT;
                h += @as(i32, @intCast(group.items.len)) * Theme.MENU_ITEM_STEP;
                h += Theme.MENU_GROUP_SPACING;
            }
            return h;
        }

        pub fn draw(self: *Self, renderer: *Render, sm: *StateMachine, mouse: Mouse) void {
            const cx: i32 = self.fui.pivotX(.center);
            const y_start = self.fui.pivotY(.center) - @divFloor(self.height(), 2);
            self.draw_at(renderer, sm, mouse, cx, y_start);
        }

        pub fn draw_at(self: *Self, renderer: *Render, sm: *StateMachine, mouse: Mouse, cx: i32, y_start: i32) void {
            var y: i32 = y_start;
            var longest: i32 = 0;
            for (self.groups) |group| {
                const title_x = cx - self.fui.text_center(group.title, Theme.FONT_DEFAULT)[0];
                self.fui.draw_text(renderer, group.title, title_x, y, Theme.FONT_DEFAULT, Theme.PRIMARY_COLOR);
                y += Theme.MENU_GROUP_TITLE_HEIGHT;

                const rect_y_start = y - Theme.MENU_FRAME_BASE_HEIGHT;
                var rect_height: i32 = Theme.MENU_FRAME_BASE_HEIGHT;
                for (group.items) |item| {
                    const width = self.fui.text_length(item.text, Theme.FONT_DEFAULT);
                    if (width > longest) longest = width;
                    if (self.fui.button(renderer, cx - @divFloor(width, 2) - Theme.MENU_BUTTON_X_PADDING, y, width + Theme.MENU_FRAME_X_PADDING, Theme.MENU_ITEM_HEIGHT, item.text, item.normal_color, item.hover_color, mouse)) {
                        sm.go_to(item.target_state);
                    }
                    y += Theme.MENU_ITEM_STEP;
                    rect_height += Theme.MENU_ITEM_STEP;
                }
                renderer.draw_rect_lines(cx - @divFloor(longest, 2) - Theme.MENU_FRAME_X_PADDING, rect_y_start, longest + Theme.MENU_FRAME_X_PADDING * 2, rect_height, Theme.SECONDARY_COLOR);
                longest = 0;
                y += Theme.MENU_GROUP_SPACING;
            }
        }
    };
}
