const std = @import("std");
const uefi = std.os.uefi;
const EfiError = uefi.Status.EfiError;

const consts = @import("consts.zig");
const game = @import("game.zig");

pub const GraphicsCfg = struct {
    out: *uefi.protocol.SimpleTextOutput,

    columns: usize,
    rows: usize,

    outer_borders: bool,
    inner_borders: bool,
    piece_size: usize,
    charset: Charset,

    pub const Charset = struct {
        clear: u16,
        hover: u16,
        arrow: u16,
        piece: struct {
            normal: u16,
            highlighted: u16,
        },
        outer: struct {
            vertical: u16,
            horizontal: u16,
            top_left: u16,
            top_right: u16,
            bottom_left: u16,
            bottom_right: u16,
        },
        inner: struct {
            vertical: u16,
            horizontal: u16,
            cross: u16,
        },
    };
};

pub fn displayBoard(board: *const game.Board, gcfg: *const GraphicsCfg) EfiError!void {
    const width = (blk: {
        var sum: usize = 0;
        if (gcfg.outer_borders) sum += 2;
        if (gcfg.inner_borders) sum += game.Board.columns - 1;
        sum += gcfg.piece_size * game.Board.columns * 2;
        break :blk sum;
    });
    const cOffset = gcfg.columns / 2 - width / 2;
    const rOffset = gcfg.rows / 2 - (blk: {
        var sum: usize = 1;
        if (gcfg.outer_borders) sum += 2;
        if (gcfg.inner_borders) sum += game.Board.rows - 1;
        sum += gcfg.piece_size * game.Board.rows;
        break :blk sum;
    }) / 2;

    const hover_column: ?usize = 0;

    var current_row = rOffset + 1;

    try gcfg.out.setAttribute(consts.background_black | consts.lightgray).err();
    try gcfg.out.clearScreen().err();

    {
        // first line is border only
        try gcfg.out.setCursorPosition(cOffset, current_row).err();
        try gcfg.out.outputString(&.{gcfg.charset.outer.top_left}).err();
        for (1..width - 1) |_| {
            try gcfg.out.outputString(&.{
                gcfg.charset.outer.horizontal,
            }).err();
        }
        try gcfg.out.outputString(&.{gcfg.charset.outer.top_right}).err();
        current_row += 1;
    }

    for (0..game.Board.rows) |board_row| {
        // inner line
        if (board_row != 0) {
            try gcfg.out.setCursorPosition(cOffset, current_row).err();
            // redundent
            // try gcfg.out.setAttribute(consts.background_black | consts.lightgray).err();

            try gcfg.out.outputString(&.{gcfg.charset.outer.vertical}).err();
            for (0..game.Board.columns) |col| {
                if (col != 0) {
                    try gcfg.out.outputString(&.{gcfg.charset.inner.cross}).err();
                }

                for (0..gcfg.piece_size) |_| {
                    try gcfg.out.outputString(&.{
                        gcfg.charset.inner.horizontal,
                        gcfg.charset.inner.horizontal,
                    }).err();
                }
            }
            try gcfg.out.outputString(&.{gcfg.charset.outer.vertical}).err();

            current_row += 1;
        }

        for (0..gcfg.piece_size) |_| {
            // piece line
            try gcfg.out.setCursorPosition(cOffset, current_row).err();

            // redundent
            // try gcfg.out.setAttribute(consts.background_black | consts.lightgray).err();
            try gcfg.out.outputString(&.{gcfg.charset.outer.vertical}).err();

            for (0..game.Board.columns) |col| {
                if (col != 0) {
                    try gcfg.out.setAttribute(consts.background_black | consts.lightgray).err();
                    try gcfg.out.outputString(&.{gcfg.charset.inner.vertical}).err();
                }

                const attr, const char = switch (board.grid[col + board_row * game.Board.rows]) {
                    .None => switch (col == hover_column) {
                        false => .{ consts.background_black | consts.black, gcfg.charset.clear },
                        true => .{ consts.background_black | consts.lightgray, gcfg.charset.hover },
                    },
                    .Red => .{ consts.background_black | consts.red, gcfg.charset.piece.normal },
                    .Yellow => .{ consts.background_black | consts.yellow, gcfg.charset.piece.normal },
                    .RedHighlight => .{ consts.background_black | consts.red, gcfg.charset.piece.highlighted },
                    .YellowHighlight => .{ consts.background_black | consts.yellow, gcfg.charset.piece.highlighted },
                };
                try gcfg.out.setAttribute(attr).err();
                for (0..gcfg.piece_size) |_| {
                    try gcfg.out.outputString(&.{ char, char }).err();
                }
            }
            try gcfg.out.setAttribute(consts.background_black | consts.lightgray).err();
            try gcfg.out.outputString(&.{gcfg.charset.outer.vertical}).err();
            current_row += 1;
        }
    }

    {
        // last line is border only
        try gcfg.out.setCursorPosition(cOffset, current_row).err();
        // redundent
        // try gcfg.out.setAttribute(consts.background_black | consts.lightgray).err();
        try gcfg.out.outputString(&.{gcfg.charset.outer.bottom_left}).err();
        for (1..width - 1) |_| {
            try gcfg.out.outputString(&.{gcfg.charset.outer.horizontal}).err();
        }
        try gcfg.out.outputString(&.{gcfg.charset.outer.bottom_right}).err();
    }
}

const supported_charsets = [_]GraphicsCfg.Charset{
    .{
        .clear = ' ',
        .hover = consts.blockelement_light_shade,
        .arrow = consts.arrow_down,
        .piece = .{
            .normal = consts.blockelement_full_block,
            .highlighted = consts.blockelement_light_shade,
        },
        .outer = .{
            .vertical = consts.boxdraw_double_vertical,
            .horizontal = consts.boxdraw_double_horizontal,
            .top_left = consts.boxdraw_double_down_right,
            .top_right = consts.boxdraw_double_down_left,
            .bottom_left = consts.boxdraw_double_up_right,
            .bottom_right = consts.boxdraw_double_up_left,
        },
        .inner = .{
            .vertical = consts.boxdraw_vertical,
            .horizontal = consts.boxdraw_horizontal,
            .cross = consts.boxdraw_vertical_horizontal,
        },
    },
    .{
        .clear = ' ',
        .hover = ':',
        .arrow = 'V',
        .piece = .{
            .normal = consts.blockelement_full_block,
            .highlighted = '%',
        },
        .outer = .{
            .vertical = consts.boxdraw_double_vertical,
            .horizontal = consts.boxdraw_double_horizontal,
            .top_left = consts.boxdraw_double_down_right,
            .top_right = consts.boxdraw_double_down_left,
            .bottom_left = consts.boxdraw_double_up_right,
            .bottom_right = consts.boxdraw_double_up_left,
        },
        .inner = .{
            .vertical = consts.boxdraw_vertical,
            .horizontal = consts.boxdraw_horizontal,
            .cross = consts.boxdraw_vertical_horizontal,
        },
    },
    .{
        .clear = ' ',
        .hover = '.',
        .arrow = 'V',
        .piece = .{
            .normal = 'O',
            .highlighted = 'o',
        },
        .outer = .{
            .vertical = '#',
            .horizontal = '#',
            .top_left = '#',
            .top_right = '#',
            .bottom_left = '#',
            .bottom_right = '#',
        },
        .inner = .{
            .vertical = '|',
            .horizontal = '-',
            .cross = '+',
        },
    },
};

pub fn selectGraphicsCfg(out: *uefi.protocol.SimpleTextOutput) EfiError!GraphicsCfg {
    const minimum_columns = game.Board.columns * 2;
    const minimum_rows = game.Board.rows + 1; // plus drop column

    var best_mode: ?struct { mode: usize, cfg: GraphicsCfg } = null;
    for (0..out.mode.max_mode + 1) |mode| {
        var columns: usize = undefined;
        var rows: usize = undefined;
        out.queryMode(mode, &columns, &rows).err() catch |err| switch (err) {
            // specific mode may be unsupported by the firmware
            error.Unsupported => continue,
            else => |other| return other,
        };

        if (columns < minimum_columns or rows < minimum_rows) {
            // too small
            continue;
        }

        var cBudget = columns;
        var rBudget = rows;

        const outer_borders = cBudget > (game.Board.columns * 2 * 2) and
            (rBudget - 1) > (game.Board.rows * 2);
        if (outer_borders) {
            cBudget -= 2;
            rBudget -= 2;
        }

        const pre_piece_size = @min(
            (cBudget -| (game.Board.columns - 1)) / (game.Board.columns * 2),
            (rBudget - 1 -| (game.Board.rows - 1)) / game.Board.rows,
        );
        const inner_borders = pre_piece_size > 2;
        if (inner_borders) {
            cBudget -= game.Board.columns - 1;
            rBudget -= game.Board.rows - 1;
        }

        const piece_size = @min(cBudget / (game.Board.columns * 2), (rBudget -
            1) / game.Board.rows);

        if (best_mode) |current| {
            if (current.cfg.piece_size >= piece_size and
                (!current.cfg.outer_borders or !outer_borders) and
                (!current.cfg.inner_borders or !inner_borders)) continue;
        }

        best_mode = .{
            .mode = mode,
            .cfg = GraphicsCfg{
                .out = undefined,
                .columns = columns,
                .rows = rows,
                .outer_borders = outer_borders,
                .inner_borders = inner_borders,
                .piece_size = piece_size,
                .charset = undefined,
            },
        };
    }

    if (best_mode) |*best| {
        if (out.mode.mode != best.mode) {
            // change mode, is expected to work since firmware listed it
            try out.setMode(best.mode).err();
        }

        // now check for the character palette to use depending on what firmware
        // supports
        best.cfg.charset = blk: {
            for (supported_charsets) |set| {
                out.testString(&.{
                    set.clear,
                    set.hover,
                    set.arrow,
                    set.piece.normal,
                    set.piece.highlighted,
                    set.outer.vertical,
                    set.outer.horizontal,
                    set.outer.top_left,
                    set.outer.top_right,
                    set.outer.bottom_left,
                    set.outer.bottom_right,
                    set.inner.vertical,
                    set.inner.horizontal,
                    set.inner.cross,
                }).err() catch |err| switch (err) {
                    error.Unsupported => continue,
                    else => |other| return other,
                };

                break :blk set;
            } else return error.Unsupported;
        };

        best.cfg.out = out;
        return best.cfg;
    }

    return error.Unsupported;
}
