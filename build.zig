const std = @import("std");
const allocPrint = std.fmt.allocPrint;

const GameInfo = struct {
    display_name: []const u8,
    source_name: []const u8,
    version: std.SemanticVersion,
};

const games = [_]GameInfo{
    .{
        .display_name = "Connect Four",
        .source_name = "connect4",
        .version = .{ .major = 0, .minor = 0, .patch = 0 },
    },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{ .default_target = .{
        .os_tag = .uefi,
        .cpu_arch = .x86_64,
        .abi = .msvc,
    } });
    const optimize = b.standardOptimizeOption(.{});

    for (games) |game_info| {
        const exe = b.addExecutable(.{
            .name = game_info.display_name,
            .root_source_file = b.path(try allocPrint(
                b.allocator,
                "src/games/{s}/main.zig",
                .{game_info.source_name},
            )),
            .target = target,
            .optimize = optimize,
        });

        const install = b.addInstallArtifact(exe, .{
            .dest_sub_path = try allocPrint(
                b.allocator,
                // TODO dodument myself on this
                "{s}/efi/boot/bootx64.efi",
                .{game_info.source_name},
            ),
        });

        const step = b.step(
            try allocPrint(b.allocator, "install-{s}", .{game_info.source_name}),
            try allocPrint(b.allocator, "Install {s} artifacts", .{game_info.display_name}),
        );

        step.dependOn(&install.step);
        b.getInstallStep().dependOn(step);
    }
}
