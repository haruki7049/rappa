const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Module
    const mod = b.addModule("rappa", .{
        .root_source_file = b.path("src/rappa.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Library installation
    const lib = b.addLibrary(.{
        .root_module = mod,
        .linkage = .static,
        .name = "rappa",
    });
    b.installArtifact(lib);

    // Tests
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    // The test step
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
