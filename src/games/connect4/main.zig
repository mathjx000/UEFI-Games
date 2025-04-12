const std = @import("std");
const uefi = std.os.uefi;
const UefiError = uefi.Status.Error;
const STO = uefi.protocol.SimpleTextOutput;

const errors = @import("errors.zig");
const display = @import("display.zig");
const game = @import("game.zig");

pub fn main() uefi.Status {
    wrappedMain() catch |err| {
        inline for (@typeInfo(UefiError).error_set.?) |variant| {
            if (err == @field(UefiError, variant.name)) {
                if (uefi.system_table.boot_services) |bs| {
                    if (uefi.system_table.con_out) |out| {
                        _ = bs.stall(5 * 1000 * 1000);

                        _ = out.setAttribute(STO.background_black | STO.red);
                        _ = out.clearScreen();
                        _ = out.setCursorPosition(0, 0);
                        _ = out.outputString(&comptimeUCS2("ERROR: "));
                        _ = out.outputString(&comptimeUCS2(variant.name));

                        if (@errorReturnTrace()) |stack| {
                            var u8buffer: [@sizeOf(usize) * 2 + 2]u8 = undefined;
                            var u16buffer: [u8buffer.len:0]u16 = undefined;

                            _ = out.outputString(&comptimeUCS2(" (index "));
                            _ = out.outputString(runtimeUCS2(std.fmt.bufPrint(
                                &u8buffer,
                                "{d}",
                                .{stack.index},
                            ) catch unreachable, &u16buffer) catch unreachable);
                            _ = out.outputString(&comptimeUCS2(")\r\nTrace:\r\n"));

                            for (stack.instruction_addresses) |addr| {
                                _ = out.outputString(runtimeUCS2(std.fmt.bufPrint(
                                    &u8buffer,
                                    "{x}  ",
                                    .{addr},
                                ) catch unreachable, &u16buffer) catch unreachable);
                            }
                        } else {
                            _ = out.outputString(&comptimeUCS2("\r\n"));
                        }

                        _ = bs.stall(60 * 1000 * 1000);
                    }
                }

                return errors.toStatus(err);
            }
        }
    };

    return .success;
}

fn wrappedMain() UefiError!void {
    const out = uefi.system_table.con_out orelse return error.Unsupported;
    const bs = uefi.system_table.boot_services orelse return error.Unsupported;

    try out.reset(true).err();

    const gcfg = try display.selectGraphicsCfg(out);

    _ = gcfg.out.enableCursor(false);

    var board: game.Board = undefined;
    @memset(&board.grid, game.Cell.None);
    board.grid[1] = .Red;
    board.grid[2] = .Yellow;
    board.grid[3] = .RedHighlight;
    board.grid[4] = .YellowHighlight;

    try display.displayBoard(&board, &gcfg);

    try bs.stall(10 * 1000 * 1000).err();
}

/// https://fr.wikipedia.org/wiki/ISO/CEI_10646
fn comptimeUCS2(comptime input: []const u8) [input.len:0]u16 {
    return comptime blk: {
        var output: [input.len:0]u16 = undefined;

        for (input, &output) |c, *w| {
            w.* = c;
        }

        break :blk output;
    };
}

/// https://fr.wikipedia.org/wiki/ISO/CEI_10646
fn runtimeUCS2(input: []const u8, output: [:0]u16) UefiError![:0]u16 {
    if (input.len > output.len) return error.OutOfResources;

    for (input, output[0..input.len]) |c, *w| {
        w.* = c;
    }

    if (input.len < output.len) {
        output[input.len] = 0; // sentinel
        return output[0..input.len :0];
    } else {
        return output;
    }
}
