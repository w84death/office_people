const std = @import("std");

pub const Particle = struct {
    x: f32,
    y: f32,
    age: f32,
    frame_duration: f32,
    frame_count: u8,

    pub fn lifetime(self: Particle) f32 {
        return @as(f32, @floatFromInt(self.frame_count)) * self.frame_duration;
    }

    pub fn is_alive(self: Particle) bool {
        return self.age < self.lifetime();
    }

    pub fn frame_index(self: Particle) usize {
        if (self.frame_count == 0) return 0;
        const idx: usize = @intFromFloat(self.age / self.frame_duration);
        const max_idx = @as(usize, self.frame_count - 1);
        return @min(idx, max_idx);
    }
};

pub const ParticleSystem = struct {
    allocator: std.mem.Allocator,
    particles: std.ArrayListUnmanaged(Particle),
    max_particles: usize,

    pub fn init(allocator: std.mem.Allocator, max_particles: usize) ParticleSystem {
        return .{
            .allocator = allocator,
            .particles = .{},
            .max_particles = max_particles,
        };
    }

    pub fn deinit(self: *ParticleSystem) void {
        self.particles.deinit(self.allocator);
    }

    pub fn spawn(self: *ParticleSystem, particle: Particle) !void {
        if (self.max_particles == 0) return;

        if (self.particles.items.len >= self.max_particles) {
            _ = self.particles.orderedRemove(0);
        }

        try self.particles.append(self.allocator, particle);
    }

    pub fn update(self: *ParticleSystem, dt: f32) void {
        var i: usize = 0;
        while (i < self.particles.items.len) {
            self.particles.items[i].age += dt;
            if (!self.particles.items[i].is_alive()) {
                _ = self.particles.swapRemove(i);
                continue;
            }
            i += 1;
        }
    }

    pub fn items(self: *const ParticleSystem) []const Particle {
        return self.particles.items;
    }
};
