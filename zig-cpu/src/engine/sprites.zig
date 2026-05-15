const std = @import("std");
const CONF = @import("config.zig").CONF;
const Render = @import("render.zig").Render;

pub const SpriteError = error{
    InvalidBmp,
    UnsupportedBmp,
    InvalidTileSize,
    InvalidAnimation,
};

pub const SpriteSheet = struct {
    const Span = struct {
        start: u16,
        end: u16,
    };

    allocator: std.mem.Allocator,
    width: i32,
    height: i32,
    tile_w: i32,
    tile_h: i32,
    columns: i32,
    rows: i32,
    frame_pixels: []u32,
    row_span_offsets: []u32,
    spans: []Span,
    frame_pixels_per_frame: usize,

    pub const LoadSettings = struct {
        name: []const u8,
        source: []const u8,
        tile_w: i32,
        tile_h: i32,
    };

    pub fn load_bmp(
        allocator: std.mem.Allocator,
        path: []const u8,
        tile_w: i32,
        tile_h: i32,
    ) !SpriteSheet {
        if (tile_w <= 0 or tile_h <= 0) return SpriteError.InvalidTileSize;

        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const source = try file.readToEndAlloc(allocator, CONF.SPRITE_MAX_FILE_BYTES);
        defer allocator.free(source);

        return load_bmp_bytes(allocator, source, tile_w, tile_h);
    }

    pub fn load_bmp_bytes(
        allocator: std.mem.Allocator,
        source: []const u8,
        tile_w: i32,
        tile_h: i32,
    ) !SpriteSheet {
        if (tile_w <= 0 or tile_h <= 0) return SpriteError.InvalidTileSize;

        if (source.len < CONF.BMP_FILE_HEADER_SIZE + CONF.BMP_DIB_HEADER_MIN_SIZE) {
            return SpriteError.InvalidBmp;
        }

        if (source[0] != CONF.BMP_SIGNATURE_B or source[1] != CONF.BMP_SIGNATURE_M) {
            return SpriteError.InvalidBmp;
        }

        const pixel_offset = try read_u32_le(source, CONF.BMP_FILE_OFFSET_PIXEL_START);
        const dib_size = try read_u32_le(source, CONF.BMP_FILE_HEADER_SIZE);

        const raw_width = try read_i32_le(source, CONF.BMP_DIB_OFFSET_WIDTH);
        const raw_height = try read_i32_le(source, CONF.BMP_DIB_OFFSET_HEIGHT);
        const planes = try read_u16_le(source, CONF.BMP_DIB_OFFSET_PLANES);
        const bits_per_pixel = try read_u16_le(source, CONF.BMP_DIB_OFFSET_BITS_PER_PIXEL);
        const compression = try read_u32_le(source, CONF.BMP_DIB_OFFSET_COMPRESSION);
        const colors_used = try read_u32_le(source, CONF.BMP_DIB_OFFSET_COLORS_USED);

        if (planes != CONF.BMP_REQUIRED_PLANES) return SpriteError.UnsupportedBmp;
        if (bits_per_pixel != CONF.BMP_REQUIRED_BPP) return SpriteError.UnsupportedBmp;
        if (compression != CONF.BMP_COMPRESSION_RGB) return SpriteError.UnsupportedBmp;
        if (raw_width <= 0 or raw_height == 0) return SpriteError.InvalidBmp;

        const height = if (raw_height < 0) -raw_height else raw_height;
        if (@mod(raw_width, tile_w) != 0 or @mod(height, tile_h) != 0) {
            return SpriteError.InvalidTileSize;
        }

        const width_usize: usize = @intCast(raw_width);
        const height_usize: usize = @intCast(height);
        const row_stride = align_to_4(width_usize);

        const palette_count_u32 = if (colors_used == 0) CONF.BMP_DEFAULT_PALETTE_COLORS else colors_used;
        if (palette_count_u32 > CONF.BMP_DEFAULT_PALETTE_COLORS) return SpriteError.UnsupportedBmp;
        const transparent_index = CONF.SPRITE_DEFAULT_TRANSPARENT_INDEX;

        const palette_count: usize = @intCast(palette_count_u32);
        const dib_size_usize: usize = @intCast(dib_size);
        const palette_start: usize = CONF.BMP_FILE_HEADER_SIZE + dib_size_usize;
        const palette_end = palette_start + palette_count * CONF.BMP_PALETTE_ENTRY_SIZE;
        if (palette_end > source.len) return SpriteError.InvalidBmp;

        const pixel_start: usize = @intCast(pixel_offset);
        const pixel_end = pixel_start + row_stride * height_usize;
        if (pixel_start >= source.len or pixel_end > source.len) return SpriteError.InvalidBmp;

        var palette = [_]u32{0} ** CONF.BMP_DEFAULT_PALETTE_COLORS;
        var i: usize = 0;
        while (i < palette_count) : (i += 1) {
            const p = palette_start + i * CONF.BMP_PALETTE_ENTRY_SIZE;
            const b = source[p];
            const g = source[p + 1];
            const r = source[p + 2];

            palette[i] = (@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b);
        }

        const pixels_len = width_usize * height_usize;
        const indexed_pixels = try allocator.alloc(u8, pixels_len);
        defer allocator.free(indexed_pixels);

        const bottom_up = raw_height > 0;
        var row: usize = 0;
        while (row < height_usize) : (row += 1) {
            const source_row = if (bottom_up) (height_usize - 1 - row) else row;
            const src_off = pixel_start + source_row * row_stride;
            const dst_off = row * width_usize;
            @memcpy(indexed_pixels[dst_off .. dst_off + width_usize], source[src_off .. src_off + width_usize]);
        }

        const cols: usize = @intCast(@divFloor(raw_width, tile_w));
        const rows: usize = @intCast(@divFloor(height, tile_h));
        const decoded_frame_count = cols * rows;
        const tile_w_usize: usize = @intCast(tile_w);
        const tile_h_usize: usize = @intCast(tile_h);
        const frame_pixels_per_frame = tile_w_usize * tile_h_usize;

        const frame_pixels = try allocator.alloc(u32, decoded_frame_count * frame_pixels_per_frame);
        errdefer allocator.free(frame_pixels);

        const row_count = decoded_frame_count * tile_h_usize;
        const row_span_offsets = try allocator.alloc(u32, row_count + 1);
        errdefer allocator.free(row_span_offsets);

        var spans_builder = std.ArrayListUnmanaged(Span){};
        errdefer spans_builder.deinit(allocator);

        row_span_offsets[0] = 0;
        var row_cursor: usize = 0;
        var frame_index: usize = 0;
        while (frame_index < decoded_frame_count) : (frame_index += 1) {
            const frame_x = (frame_index % cols) * tile_w_usize;
            const frame_y = (frame_index / cols) * tile_h_usize;
            const frame_base = frame_index * frame_pixels_per_frame;

            row = 0;
            while (row < tile_h_usize) : (row += 1) {
                const src_row_base = (frame_y + row) * width_usize + frame_x;
                const dst_row_base = frame_base + row * tile_w_usize;

                var col: usize = 0;
                while (col < tile_w_usize) : (col += 1) {
                    const idx = indexed_pixels[src_row_base + col];
                    frame_pixels[dst_row_base + col] = if (idx == transparent_index) 0 else palette[idx];
                }

                col = 0;
                while (col < tile_w_usize) {
                    while (col < tile_w_usize and indexed_pixels[src_row_base + col] == transparent_index) : (col += 1) {}
                    if (col >= tile_w_usize) break;

                    const span_start: usize = col;
                    while (col < tile_w_usize and indexed_pixels[src_row_base + col] != transparent_index) : (col += 1) {}
                    const span_end: usize = col;

                    try spans_builder.append(allocator, .{
                        .start = @intCast(span_start),
                        .end = @intCast(span_end),
                    });
                }

                row_cursor += 1;
                row_span_offsets[row_cursor] = @intCast(spans_builder.items.len);
            }
        }

        const spans = try spans_builder.toOwnedSlice(allocator);

        return .{
            .allocator = allocator,
            .width = raw_width,
            .height = height,
            .tile_w = tile_w,
            .tile_h = tile_h,
            .columns = @divFloor(raw_width, tile_w),
            .rows = @divFloor(height, tile_h),
            .frame_pixels = frame_pixels,
            .row_span_offsets = row_span_offsets,
            .spans = spans,
            .frame_pixels_per_frame = frame_pixels_per_frame,
        };
    }

    pub fn load(allocator: std.mem.Allocator, settings: LoadSettings) !*SpriteSheet {
        var sheet = try load_bmp_bytes(allocator, settings.source, settings.tile_w, settings.tile_h);
        errdefer sheet.deinit();

        const sheet_ptr = try allocator.create(SpriteSheet);
        sheet_ptr.* = sheet;

        const frames = sheet_ptr.frame_count();
        std.debug.print("[spritesheet] loaded {s} size={d}x{d} frames={d}\n", .{ settings.name, sheet_ptr.width, sheet_ptr.height, frames });
        return sheet_ptr;
    }

    pub fn deinit(self: *SpriteSheet) void {
        self.allocator.free(self.frame_pixels);
        self.allocator.free(self.row_span_offsets);
        self.allocator.free(self.spans);
    }

    pub fn frame_count(self: *const SpriteSheet) usize {
        const cols: usize = @intCast(self.columns);
        const rows: usize = @intCast(self.rows);
        return cols * rows;
    }

    pub fn draw_frame(self: *const SpriteSheet, renderer: *Render, frame_index: usize, x: i32, y: i32) void {
        const screen_w = renderer.width;
        const screen_h = renderer.height;
        if (frame_index >= self.frame_count()) return;
        if (x >= screen_w or y >= screen_h) return;
        if (x + self.tile_w <= 0 or y + self.tile_h <= 0) return;

        if (x >= 0 and y >= 0 and x + self.tile_w <= screen_w and y + self.tile_h <= screen_h) {
            self.draw_frame_fast(renderer, frame_index, x, y);
        } else {
            self.draw_frame_clipped(renderer, frame_index, x, y);
        }
    }

    fn draw_frame_fast(self: *const SpriteSheet, renderer: *Render, frame_index: usize, x: i32, y: i32) void {
        const tile_w_usize: usize = @intCast(self.tile_w);
        const tile_h_usize: usize = @intCast(self.tile_h);
        const screen_w_usize: usize = @intCast(renderer.width);
        const x_usize: usize = @intCast(x);
        const y_usize: usize = @intCast(y);

        const buffer = renderer.target_buffer();
        const frame_base = frame_index * self.frame_pixels_per_frame;
        const row_base = frame_index * tile_h_usize;

        var row: usize = 0;
        while (row < tile_h_usize) : (row += 1) {
            const dst_row_base = (y_usize + row) * screen_w_usize + x_usize;
            const src_row_base = frame_base + row * tile_w_usize;

            const spans_start = self.row_span_offsets[row_base + row];
            const spans_end = self.row_span_offsets[row_base + row + 1];
            var si: usize = spans_start;
            while (si < spans_end) : (si += 1) {
                const span = self.spans[si];
                const span_start: usize = span.start;
                const span_end: usize = span.end;

                @memcpy(
                    buffer[dst_row_base + span_start .. dst_row_base + span_end],
                    self.frame_pixels[src_row_base + span_start .. src_row_base + span_end],
                );
            }
        }
    }

    fn draw_frame_clipped(self: *const SpriteSheet, renderer: *Render, frame_index: usize, x: i32, y: i32) void {
        const tile_w_usize: usize = @intCast(self.tile_w);
        const tile_h_usize: usize = @intCast(self.tile_h);
        const screen_w_usize: usize = @intCast(renderer.width);
        const buffer = renderer.target_buffer();
        const frame_base = frame_index * self.frame_pixels_per_frame;
        const row_base = frame_index * tile_h_usize;

        const clip_x0: i32 = @max(0, -x);
        const clip_y0: i32 = @max(0, -y);
        const clip_x1: i32 = @min(self.tile_w, renderer.width - x);
        const clip_y1: i32 = @min(self.tile_h, renderer.height - y);

        if (clip_x0 >= clip_x1 or clip_y0 >= clip_y1) return;

        const clip_x0_usize: usize = @intCast(clip_x0);
        const clip_x1_usize: usize = @intCast(clip_x1);
        const clip_y0_usize: usize = @intCast(clip_y0);
        const clip_y1_usize: usize = @intCast(clip_y1);

        var row: usize = clip_y0_usize;
        while (row < clip_y1_usize) : (row += 1) {
            const dst_y: usize = @intCast(y + @as(i32, @intCast(row)));
            const dst_row_base = dst_y * screen_w_usize;
            const src_row_base = frame_base + row * tile_w_usize;

            const spans_start = self.row_span_offsets[row_base + row];
            const spans_end = self.row_span_offsets[row_base + row + 1];
            var si: usize = spans_start;
            while (si < spans_end) : (si += 1) {
                const span = self.spans[si];
                const span_start: usize = @max(clip_x0_usize, span.start);
                const span_end: usize = @min(clip_x1_usize, span.end);
                if (span_start >= span_end) continue;

                const dst_x: usize = @intCast(x + @as(i32, @intCast(span_start)));

                @memcpy(
                    buffer[dst_row_base + dst_x .. dst_row_base + dst_x + (span_end - span_start)],
                    self.frame_pixels[src_row_base + span_start .. src_row_base + span_end],
                );
            }
        }
    }
};

pub const Sprite = struct {
    sheet: *const SpriteSheet,
    anim_start: usize,
    anim_len: usize,
    frame_duration: f32,
    timer: f32 = 0.0,
    current_offset: usize = 0,
    looping: bool = true,

    pub fn init(sheet: *const SpriteSheet, frame_duration: f32) Sprite {
        return .{
            .sheet = sheet,
            .anim_start = 0,
            .anim_len = sheet.frame_count(),
            .frame_duration = frame_duration,
            .looping = true,
        };
    }

    pub fn init_range(sheet: *const SpriteSheet, start_frame: usize, frame_count: usize, frame_duration: f32, looping: bool) SpriteError!Sprite {
        var sprite = Sprite.init(sheet, frame_duration);
        try sprite.set_animation(start_frame, frame_count, frame_duration, looping);
        return sprite;
    }

    pub fn set_animation(self: *Sprite, start_frame: usize, frame_count: usize, frame_duration: f32, looping: bool) SpriteError!void {
        if (frame_count == 0) return SpriteError.InvalidAnimation;
        if (start_frame >= self.sheet.frame_count()) return SpriteError.InvalidAnimation;
        if (start_frame + frame_count > self.sheet.frame_count()) return SpriteError.InvalidAnimation;

        self.anim_start = start_frame;
        self.anim_len = frame_count;
        self.frame_duration = frame_duration;
        self.looping = looping;
        self.reset();
    }

    pub fn update(self: *Sprite, dt: f32) void {
        if (self.anim_len <= 1 or self.frame_duration <= 0.0) return;

        self.timer += dt;
        while (self.timer >= self.frame_duration) {
            self.timer -= self.frame_duration;
            if (self.current_offset + 1 < self.anim_len) {
                self.current_offset += 1;
            } else if (self.looping) {
                self.current_offset = 0;
            } else {
                break;
            }
        }
    }

    pub fn draw(self: *const Sprite, renderer: *Render, x: i32, y: i32) void {
        self.sheet.draw_frame(renderer, self.current_frame(), x, y);
    }

    pub fn reset(self: *Sprite) void {
        self.timer = 0.0;
        self.current_offset = 0;
    }

    pub fn current_frame(self: *const Sprite) usize {
        return self.anim_start + self.current_offset;
    }
};

fn align_to_4(value: usize) usize {
    return (value + 3) & ~@as(usize, 3);
}

fn read_u16_le(data: []const u8, offset: usize) SpriteError!u16 {
    if (offset + 2 > data.len) return SpriteError.InvalidBmp;
    return @as(u16, data[offset]) | (@as(u16, data[offset + 1]) << 8);
}

fn read_u32_le(data: []const u8, offset: usize) SpriteError!u32 {
    if (offset + 4 > data.len) return SpriteError.InvalidBmp;
    return @as(u32, data[offset]) |
        (@as(u32, data[offset + 1]) << 8) |
        (@as(u32, data[offset + 2]) << 16) |
        (@as(u32, data[offset + 3]) << 24);
}

fn read_i32_le(data: []const u8, offset: usize) SpriteError!i32 {
    const value = try read_u32_le(data, offset);
    return @bitCast(value);
}
