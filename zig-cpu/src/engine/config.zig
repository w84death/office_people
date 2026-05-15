// *************************************
// BOROWIK ENGINE
// by Krzysztof Krystian Jankowski
// github.com/w84death/borowik-engine
// *************************************

pub const CONF = struct {
    pub const VERSION = "ZIG-NATIVE";
    pub const THE_NAME = "Office People";
    pub const TAG_LINE = "Turn on all the computers.";
    pub const SCREEN_W = 256;
    pub const SCREEN_H = 144;
    pub const PIXEL_SCALE = 4;
    pub const TARGET_FPS = 60.0;
    pub const FONT_WIDTH = 8;
    pub const FONT_HEIGHT = 8;

    pub const SPRITE_MAX_FILE_BYTES = 16 * 1024 * 1024;
    pub const SPRITE_DEFAULT_TRANSPARENT_INDEX: u8 = 0;
    pub const BMP_FILE_HEADER_SIZE = 14;
    pub const BMP_DIB_HEADER_MIN_SIZE = 40;
    pub const BMP_PALETTE_ENTRY_SIZE = 4;
    pub const BMP_DEFAULT_PALETTE_COLORS = 256;
    pub const BMP_FILE_OFFSET_PIXEL_START = 10;
    pub const BMP_DIB_OFFSET_WIDTH = 18;
    pub const BMP_DIB_OFFSET_HEIGHT = 22;
    pub const BMP_DIB_OFFSET_PLANES = 26;
    pub const BMP_DIB_OFFSET_BITS_PER_PIXEL = 28;
    pub const BMP_DIB_OFFSET_COMPRESSION = 30;
    pub const BMP_DIB_OFFSET_COLORS_USED = 46;

    pub const BMP_SIGNATURE_B = 'B';
    pub const BMP_SIGNATURE_M = 'M';
    pub const BMP_REQUIRED_PLANES = 1;
    pub const BMP_REQUIRED_BPP = 8;
    pub const BMP_COMPRESSION_RGB = 0;
};
