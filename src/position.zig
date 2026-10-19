// NENE by Alyx Shang.
// Licensed under the FSL v1.

/// A structure to encapsulate
/// information about the position
/// of characters in a string of
/// text.
pub const Position = struct {
    line: u64,
    column: u64,

    /// A function that creates
    /// a new instance of the
    /// `Position` structure
    /// and returns it.
    pub fn init(
        line: u64,
        column: u64
    ) Position {
        return Position {
            .line = line,
            .column = column
        };
    }
};
