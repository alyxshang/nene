// NENE by Alyx Shang.
// Licensed under the FSL v1.

// Importing the namespace
// of the standard library.
const std = @import("std");

// Importing the structure to
// create an array from the 
// standard library.
const ArrayList = std.ArrayList;

// Importing the module containing
// some utility functions to test 
// those functions.
const utils = @import("utils.zig");

// Importing the structure encapsulating
// data about a captured token.
const Token = @import("lexer.zig").Token;

// Importing the structure containing
// the function to tokenize Nene source
// code.
const Lexer = @import("lexer.zig").Lexer;

// Importing the structure containing Nene's
// parser to test it.
const Parser = @import("parser.zig").Parser;

// A test block for testing the module 
// containing some utility functions.
test "Testing the module containing some utility functions." {
    const cloned: [*:0]const u8 = try utils.cloneSlice(
        "hello",
        std.testing.allocator
    );
    defer std.testing.allocator.free(std.mem.span(cloned));
    const len: u64 = utils.strLen(cloned);
    const is_ident_char_true: bool = utils.isIdentChar('g');
    const is_ident_char_false: bool = utils.isIdentChar('4');
    const is_num_char_false: bool = utils.isNumChar('g');
    const is_num_char_true: bool = utils.isNumChar('4');
    try std.testing.expect(is_ident_char_true == true);
    try std.testing.expect(is_ident_char_false == false);
    try std.testing.expect(is_num_char_true == true);
    try std.testing.expect(is_num_char_false == false);
    try std.testing.expect(len == 5);
}

// A test block for testing the module 
// containing the tokenizer.
test "Testing the module containing the tokenizer." {
    const sample: [*:0]const u8 = 
        \\ + hello , 34.15 = - * / 45 % > #hello
        \\ < != "alyx" fin glam vibe with from (
        \\ true false ) inspo funky ->
    ;
    var lexer: Lexer = Lexer.init(
        std.testing.allocator,
        sample
    );
    var lexed: ArrayList(Token) = try lexer.lex();
    defer {
        for (lexed.items) |item| {
            item.deinit(std.testing.allocator);
        }
        lexed.deinit(std.testing.allocator);
    }
    try std.testing.expect(lexed.items.len == 27);
}

// A test block for testing the module
// containing Nene's parser.
test "Testing the structure containing Nene's parser." {
}