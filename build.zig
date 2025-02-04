const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .cpu_arch = .x86_64 } });
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "zig-gmod-bhop",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const zigwin32_dep = b.dependency("zigwin32", .{});
    lib.root_module.addImport("zigwin32", zigwin32_dep.module("zigwin32"));

    const vmthook_dep = b.dependency("vmthook", .{});
    lib.root_module.addImport("vmthook", vmthook_dep.module("hooking"));

    const zlm_dep = b.dependency("zlm", .{});
    lib.root_module.addImport("zlm", zlm_dep.module("zlm"));
}
