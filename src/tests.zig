// NENE by Alyx Shang.
// Licensed under the FSL v1.

// Importing the namespace for the
// standard library.
const std = @import("std");

// Importing the module containing
// some utility functions.
const utils = @import("utils.zig");

// Importing the module containing
// the structure to tokenize a string
// of Nene source code.
const lexer = @import("lexer.zig");

// Testing the module containing some utility functions.
test "Testing the module containing some utility functions." {
    const test_str: [*:0]const u8 = "Alyx Shang";
    const str_len: u64 = utils.strLen(test_str);
    const is_digit_true = utils.isDigit('2');
    const is_digit_false = utils.isDigit('A');
    const is_ident_char_true = utils.isIdentChar('_');
    const is_ident_char_false = utils.isIdentChar('3');
    try std.testing.expect(str_len == 10);
    try std.testing.expect(is_digit_true == true);
    try std.testing.expect(is_digit_false == false);
    try std.testing.expect(is_ident_char_true == true);
    try std.testing.expect(is_ident_char_false == false);
}

// Testing the module containing Nene's tokenizer.
test "Testing the module containing Nene's tokenizer." {
    const test_str =
        \\% + -> : - , ? / ~~ = * < { my_str "hello" 
        \\} != bag fin ( > vibe load slay naww yass
        \\with from ) funky inspo girlwait rehearsal
        \\45 56.78
    ;
    var ml: lexer.Lexer = lexer.Lexer.init(std.testing.allocator);
    const tokens: std.ArrayList(lexer.Token) = try ml.lex(test_str);
    defer {
        for (tokens.items) |item| {
            item.deinit(std.testing.allocator);
        }
        tokens.deinit();
    } 
    try std.testing.expect(tokens.items.len == 35);
}
