const std = @import("std");
const filename = "borowik";

fn configureLinks(exe: *std.Build.Step.Compile, os_tag: std.Target.Os.Tag) void {
    switch (os_tag) {
        .windows => {
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("winmm");
        },
        .linux => {
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("asound");
        },
        else => {},
    }
}

fn addAppExe(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.addIncludePath(b.path("src/libs"));
    exe.addCSourceFile(.{ .file = b.path("src/libs/fenster.c"), .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = b.path("src/libs/fenster_audio.c"), .flags = &[_][]const u8{} });
    configureLinks(exe, target.result.os.tag);
    exe.linkLibC();

    return exe;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = addAppExe(b, filename, target, optimize);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| run_cmd.addArgs(args);

    const release_linux_step = b.step("release-linux", "Build Linux host target (ReleaseFast + UPX)");
    const host_target = target;

    const release_windows_step = b.step("release-windows", "Build Windows 32/64 (ReleaseFast + UPX)");
    const windows_matrix = [_]struct {
        arch: std.Target.Cpu.Arch,
        os: std.Target.Os.Tag,
        suffix: []const u8,
    }{
        .{ .arch = .x86, .os = .windows, .suffix = "windows-x86" },
        .{ .arch = .x86_64, .os = .windows, .suffix = "windows-x86_64" },
    };

    if (host_target.result.os.tag == .linux) {
        const host_suffix = switch (host_target.result.cpu.arch) {
            .x86 => "linux-x86",
            .x86_64 => "linux-x86_64",
            else => "linux",
        };

        const release_name = b.fmt("{s}-{s}", .{ filename, host_suffix });
        const release_exe = addAppExe(b, release_name, host_target, .ReleaseFast);
        const release_install = b.addInstallArtifact(release_exe, .{});

        const release_install_path = b.getInstallPath(.bin, release_name);
        const release_upx = b.addSystemCommand(&[_][]const u8{
            "upx",
            "--best",
            "--lzma",
            "--compress-icons=0",
            release_install_path,
        });

        release_upx.step.dependOn(&release_install.step);
        release_linux_step.dependOn(&release_upx.step);
    }

    inline for (windows_matrix) |entry| {
        const matrix_target = b.resolveTargetQuery(.{
            .cpu_arch = entry.arch,
            .os_tag = entry.os,
        });

        const release_name = b.fmt("{s}-{s}", .{ filename, entry.suffix });
        const release_exe = addAppExe(b, release_name, matrix_target, .ReleaseFast);
        const release_install = b.addInstallArtifact(release_exe, .{});

        const release_binary_name = b.fmt("{s}{s}", .{
            release_name,
            if (entry.os == .windows) ".exe" else "",
        });
        const release_install_path = b.getInstallPath(.bin, release_binary_name);
        const release_upx = b.addSystemCommand(&[_][]const u8{
            "upx",
            "--best",
            "--lzma",
            "--compress-icons=0",
            release_install_path,
        });

        release_upx.step.dependOn(&release_install.step);
        release_windows_step.dependOn(&release_upx.step);
    }
}
