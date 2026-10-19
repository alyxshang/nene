// NENE by Alyx Shang.
// Licensed under the FSL v1.

// Importing the "std" namespace.
const std = @import("std");

// Importing the "ArrayList" structure
// from the standard library.
const ArrayList = std.ArrayList;

// Importing the "Allocator" structure
// from the standard library.
const Allocator = std.mem.Allocator;

// Importing the structure to catch and
// handle errors.
const NeneErr = @import("err.zig").NeneErr;

/// A function to get the 
/// length of a string that
/// is a pointer to a 
/// null-terminated
/// slice.
pub fn strLen(
    sub: [*:0]const u8
) u64 {
    var result: u64 = 0;
    while (sub[result] != 0){
        result = result + 1;
    }
    return result;
}

/// A function to clone
/// a pointer to a null-terminated
/// string slice. If allocation fails
/// an error is returned. If not, the
/// pointer to the slice is returned.
pub fn cloneSlice(
    sub: [*:0]const u8,
    allocator: Allocator
) ![*:0]const u8 {
    var cursor: u64 = 0;
    var chars: ArrayList(u8) = ArrayList(u8)
        .init(allocator);
    errdefer chars.deinit();
    while (sub[cursor] != 0){
        chars.append(sub[cursor])
            catch return NeneErr.WriteErr;
        cursor = cursor + 1;
    }
    const joined: [*:0]const u8 = chars.toOwnedSliceSentinel(0)
        catch return NeneErr.AllocErr;
    errdefer allocator.free(std.mem.span(joined));
    return joined;
}

/// A function to check whether a character
/// is part of the allowed characters for 
/// strings containing user idents.
pub fn isIdentChar(
    character: u8
) bool {
    var cursor: u64 = 0;
    const alphabet: [*:0]const u8 = 
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_";
    while (cursor < 53){
        if (character == alphabet[cursor]) {
            return true;
        }
        cursor = cursor + 1;
    }
    return false;
}

/// A function to check whether a character
/// is part of the allowed characters for 
/// strings containing numbers.
pub fn isNumChar(
    character: u8
) bool {
    var cursor: u64 = 0;
    const alphabet: [*:0]const u8 = 
        "0123456789";
    while (cursor < 10){
        if (character == alphabet[cursor]) {
            return true;
        }
        cursor = cursor + 1;
    }
    return false;
}
