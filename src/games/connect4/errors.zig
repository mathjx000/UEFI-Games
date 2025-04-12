const std = @import("std");
const uefi = std.os.uefi;
const Status = uefi.Status;
const UefiError = Status.Error;

pub fn toStatus(zig: UefiError) Status {
    const fields = @typeInfo(Status).@"enum".fields;

    @setEvalBranchQuota(fields.len * fields.len);

    return switch (zig) {
        inline else => |zig_variant| comptime blk: {
            for (fields) |status_field| {
                const uefi_variant: Status = @field(Status, status_field.name);

                uefi_variant.err() catch |err| if (zig_variant == err) break :blk uefi_variant;
            } else unreachable;
        },
    };
}

test {
    for (@typeInfo(Status).@"enum".fields) |status_field| {
        const uefi_variant: Status = @field(Status, status_field.name);
        uefi_variant.err() catch |err| std.debug.assert(toStatus(err) == uefi_variant);
    }
}
