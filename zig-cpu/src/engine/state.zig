// *************************************
// BOROWIK ENGINE
// by Krzysztof Krystian Jankowski
// github.com/w84death/borowik-engine
// *************************************

pub fn StateMachine(comptime State: type) type {
    return struct {
        const Self = @This();

        current: State,
        next: ?State,

        pub fn init(current: State) Self {
            return Self{ .current = current, .next = null };
        }

        pub fn go_to(self: *Self, next: State) void {
            self.next = next;
        }

        pub fn update(self: *Self) void {
            if (self.next) |next| {
                self.current = next;
                self.next = null;
            }
        }

        pub fn is(self: Self, target: State) bool {
            return self.current == target;
        }
    };
}
