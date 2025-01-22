const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{ .default_target = .{
        .os_tag = .uefi,
        .cpu_arch = .x86_64,
        .abi = .msvc,
    } });
    const optimize = b.standardOptimizeOption(.{});

    // TODO
    _ = target;
    _ = optimize;
}
