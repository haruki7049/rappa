const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies
    const lightmix = b.dependency("lightmix", .{});

    // Module
    const mod = b.addModule("rappa", .{
        .root_source_file = b.path("src/rappa.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "lightmix", .module = lightmix.module("lightmix") },
        },
    });

    // Library installation
    const lib = b.addLibrary(.{
        .root_module = mod,
        .linkage = .static,
        .name = "rappa",
    });
    b.installArtifact(lib);

    // Examples
    try build_example_dir(
        b,
        target,
        optimize,
        lightmix,
        mod,
    );

    // Tests
    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    // The test step
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

fn build_example_dir(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    lightmix: *std.Build.Dependency,
    rappa_mod: *std.Build.Module,
) !void {
    var example_dir = try b.build_root.handle.openDir("./examples", .{ .iterate = true });
    defer example_dir.close();

    var walker = try example_dir.walk(b.allocator);
    defer walker.deinit();

    const example_step = b.step("examples", "Build all executables in ./examples");
    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const filepath = try std.fmt.allocPrint(b.allocator, "examples/{s}", .{entry.path});
            const example_exe_name = entry.basename;
            const lazypath = b.path(filepath);

            const example_mod = b.createModule(.{
                .root_source_file = lazypath,
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "lightmix", .module = lightmix.module("lightmix") },
                    .{ .name = "rappa", .module = rappa_mod },
                },
            });

            // Library linking on Linux
            if (target.result.os.tag == .linux) {
                example_mod.linkSystemLibrary("alsa", .{});
                example_mod.linkSystemLibrary("libpulse", .{});
                example_mod.linkSystemLibrary("libpipewire-0.3", .{});
            }

            const example_exe = b.addExecutable(.{
                .name = example_exe_name,
                .root_module = example_mod,
            });
            const install = b.addInstallArtifact(example_exe, .{});
            example_step.dependOn(&install.step);
        }
    }
}
