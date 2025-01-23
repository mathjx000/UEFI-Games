pub const Board = struct {
    pub const columns: usize = 7;
    pub const rows: usize = 6;

    grid: [columns * rows]Cell,
};

pub const Cell = enum {
    /// Nothing at all
    None,

    Red,
    Yellow,

    /// Used when a row was matched
    RedHighlight,
    /// Used when a row was matched
    YellowHighlight,
};
