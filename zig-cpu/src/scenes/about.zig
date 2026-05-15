pub fn AboutScene(comptime Theme: type) type {
    const Fui = @import("../engine/fui.zig").Fui(Theme);
    const Render = @import("../engine/render.zig").Render;

    return struct {
        const Self = @This();
        const lines = [_][:0]const u8{
            "Borowik is an Zig Engine for creating small",
            "applications for Linux and Windows.",
            "",
            "Produced by Krzysztof Krystian Jankowski",
            "",
            "Source code available at:",
            "https://github.com/w84death/borowik-engine",
            "",
            "MIT Licence.",
        };

        fui: *Fui,

        pub fn init(fui: *Fui) Self {
            return Self{ .fui = fui };
        }

        pub fn draw(self: *Self, renderer: *Render) void {
            const px = self.fui.pivotX(.top_left);
            const py = self.fui.pivotY(.top_left);
            self.fui.draw_text_block(renderer, &lines, px, py + 64, Theme.FONT_LINE_HEIGHT, Theme.FONT_DEFAULT, Theme.PRIMARY_COLOR);
        }
    };
}
