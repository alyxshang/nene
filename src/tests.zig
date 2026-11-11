// METZTLI by Alyx Shang.
// Licensed under the FSL v1.

// Importing the "std" namespace.
const std = @import("std");

// Importing the module containing
// utility functions to test it.
const utils = @import("utils.zig");

// Testing the module containing utility functions.
test "Testing the module containing utility functions." {
    const test_str: [*:0]const u8 = "hello";
    const len: u64 = utils.strLen(test_str);
    const cloned: [*:0]const u8 = try utils.cloneSlice(
        test_str,
        std.testing.allocator
    );
    defer std.testing.allocator.free(std.mem.span(cloned));
    const cloned_len: u64 = utils.strLen(cloned);
    try std.testing.expect(len == 5);
    try std.testing.expect(cloned_len == 5);
}
