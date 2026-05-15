const CONF = @import("../engine/config.zig").CONF;
const Mouse = @import("../engine/mouse.zig").Mouse;
const Render = @import("../engine/render.zig").Render;

pub fn MenuScene(comptime Menu: type, comptime Theme: type) type {
    const Fui = @import("../engine/fui.zig").Fui(Theme);
    return struct {
        const Self = @This();

        pub const MenuItem = Menu.MenuItem;
        pub const MenuGroup = Menu.MenuGroup;

        fui: *Fui,
        sm: *Menu.StateMachineType,
        menu: Menu,

        pub fn init(fui: *Fui, sm: *Menu.StateMachineType, menu: Menu) Self {
            return .{
                .fui = fui,
                .sm = sm,
                .menu = menu,
            };
        }

        pub fn draw(self: *Self, renderer: *Render, mouse: Mouse) void {
            const cx: i32 = self.fui.pivotX(.center);
            const menu_h = self.menu.height();
            const menu_y = self.fui.pivotY(.center) - @divFloor(menu_h, 2);
            const cy: i32 = menu_y - 128;
            const tx: i32 = cx - self.fui.text_center(CONF.THE_NAME, Theme.FONT_BIG)[0];
            self.fui.draw_text(renderer, CONF.THE_NAME, tx + 4, cy + 4, Theme.FONT_BIG, Theme.SECONDARY_COLOR);
            self.fui.draw_text(renderer, CONF.THE_NAME, tx, cy, Theme.FONT_BIG, Theme.PRIMARY_COLOR);
            self.fui.draw_text(renderer, CONF.TAG_LINE, cx - self.fui.text_center(CONF.TAG_LINE, Theme.FONT_DEFAULT)[0], cy + 64, Theme.FONT_DEFAULT, Theme.PRIMARY_COLOR);

            self.menu.draw_at(renderer, self.sm, mouse, cx, menu_y);
        }
    };
}
