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
    const target_efi = b.resolveTargetQuery(.{
        .os_tag = .uefi,
        .cpu_arch = .x86_64,
        .abi = .msvc,
    });
    const optimize = b.standardOptimizeOption(.{});

    for (games) |game_info| {
        const mod = b.createModule(.{
            .root_source_file = b.path(try allocPrint(
                b.allocator,
                "src/games/{s}/main.zig",
                .{game_info.source_name},
            )),
            .target = target_efi,
            .optimize = optimize,
        });

        const exe = b.addExecutable(.{
            .name = game_info.display_name,
            .root_module = mod,
        });

        const install = b.addInstallArtifact(exe, .{
            .dest_sub_path = try allocPrint(
                b.allocator,
                // TODO dodument myself on this
                "{s}/efi/boot/bootx64.efi",
                .{game_info.source_name},
            ),
        });

        b.getInstallStep().dependOn(&install.step);
    }
}
