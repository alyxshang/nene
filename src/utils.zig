// NENE by Alyx Shang.
// Licensed under the FSL v1.

/// A function to get the length
/// of a string expressed as a ponter
/// to a null-terminated character array.
pub fn strLen(
    str: [*:0]const u8
) u64 {
    var len: u64 = 0;
    while (str[len] != 0){
        len = len + 1;
    }
    return len;
}

/// Checks whether the supplied
/// character is part of the pool
/// of allowed characters for an
/// identifier. A boolean is returned
/// to reflect this.
pub fn isIdentChar(
    sub: u8
) bool {
    var cursor: u64 = 0;
    const alphabet: []const u8 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_";
    while (cursor < alphabet.len){
        if (sub == alphabet[cursor]){
            return true;
        }
        cursor = cursor + 1;
    }
    return false;
}

/// Checks whether the supplied
/// character is a digit or not.
/// A boolean is returned
/// to reflect this.
pub fn isDigit(
    sub: u8
) bool {
    var cursor: u64 = 0;
    const alphabet: []const u8 = "0123456789";
    while (cursor < alphabet.len){
        if (sub == alphabet[cursor]){
            return true;
        }
        cursor = cursor + 1;
    }
    return false;
}
