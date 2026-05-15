// *************************************
// BOROWIK ENGINE
// by Krzysztof Krystian Jankowski
// github.com/w84death/borowik-engine
// *************************************

pub const Mouse = struct {
    x: i32,
    y: i32,
    left_down: bool,
    right_down: bool,
    just_pressed: bool,
    just_right_pressed: bool,

    pub fn init(x: i32, y: i32, left_down: bool, right_down: bool, just_pressed: bool, just_right_pressed: bool) Mouse {
        return .{ .x = x, .y = y, .left_down = left_down, .right_down = right_down, .just_pressed = just_pressed, .just_right_pressed = just_right_pressed };
    }
};

pub const MouseButtons = struct {
    left_lock: bool = false,
    right_lock: bool = false,

    pub fn init() MouseButtons {
        return .{};
    }

    pub fn update(self: *MouseButtons, x: i32, y: i32, buttons: u32) Mouse {
        const left_down = (buttons & 1) != 0;
        const right_down = (buttons & 2) != 0;
        const left_just_pressed = updateJustPressed(&self.left_lock, left_down);
        const right_just_pressed = updateJustPressed(&self.right_lock, right_down);
        return Mouse.init(x, y, left_down, right_down, left_just_pressed, right_just_pressed);
    }

    fn updateJustPressed(lock: *bool, is_down: bool) bool {
        if (lock.* and !is_down) {
            lock.* = false;
            return false;
        }

        if (!lock.* and is_down) {
            lock.* = true;
            return true;
        }

        return false;
    }
};
