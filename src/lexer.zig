// NENE by Alyx Shang.
// Licensed under the FSL v1.

// Importing the namespace for the
// standard library.
const std = @import("std");

// Importing the structure from
// the standard library for list.
const ArrayList = std.ArrayList;

// Importing the "Allocator" structure
// from the standard library.
const Allocator = std.mem.Allocator;

// Importing the structure to capture
// information on the position of a token.
const Position = @import("pos.zig").Position;

/// An enumeration to "list" all
/// possible tokens in a Nene program.
pub const TokenType = enum(u8) {
    Int,
    Mod,
    Plus,
    Case,
    Float,
    Colon, 
    Minus,
    Comma,
    Option,
    Divide, 
    Comment,
    IsEqual, 
    Multiply,
    LessThan, 
    OpenCurly,
    UserIdent,
    UserString, 
    CloseCurly,
    IsNotEqual,
    BagKeyword,
    FinKeyword, 
    OpenBracket,
    GreaterThan,
    VibeKeyword,
    LoadKeyword,
    SlayKeyword,
    NawwKeyword,
    YassKeyword,
    WithKeyword,
    FromKeyword,
    CloseBracket,
    FunkyKeyword,
    InspoKeyword,
    GirlWaitKeyword,
    RehearsalKeyword,
};

/// A structure to encapsulate
/// information on a captured
/// token.
pub const Token = struct {
    end: Position,
    start: Position,
    token_type: TokenType,
    value: ?[*:0]const u8,

    /// A function to deallocate
    /// any heap-allocated resources
    /// this structure may have.
    pub fn deinit(
        self: *Token,
        allocator: Allocator
    ) void {
        if (self.value) |val| {
            allocator.free(val);
        }
    }
};

/// A data structure that holds Nene's
/// lexer. This tokenizer is kept in a
/// structure to also return information
/// on where and how an error occurred.
pub const Lexer = struct {
};
