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

// Importing the function to create
// sentinel-terminated formatted strings.
const allocPrintZ = std.fmt.allocPrintZ;

// Importing the function to get the
// length of a string that is a pointer
// to a null-terminated array of characters.
const strLen = @import("utils.zig").strLen;

// Importing the entity for catching
// and handling errors.
const NeneErr = @import("err.zig").NeneErr;

// Importing the structure to capture
// information on the position of a token.
const Position = @import("pos.zig").Position;

// Importing the fun ction to check whether
// a character is a digit or not.
const isDigit = @import("utils.zig").isDigit;

// Importing the function to check whether a
// character is part of the allowed characters
// for a user ident.
const isIdentChar = @import("utils.zig").isIdentChar;

/// An enumeration to "list" all
/// possible tokens in a Nene program.
pub const TokenType = enum(u8) {
    Int,
    Mod, // done.
    Plus, // done.
    Case, // done.
    Float,
    Colon, // done. 
    Minus, // done.
    Comma, // done.
    Option, // done.
    Divide, // done. 
    Comment, // done.
    IsEqual, // done. 
    Multiply, // done.
    LessThan, // done. 
    OpenCurly, // done.
    UserIdent, // done.
    UserString, // done.
    CloseCurly, // done.
    IsNotEqual, // done.
    BagKeyword, // done.
    FinKeyword, // done.
    OpenBracket, // done.
    GreaterThan, // done.
    VibeKeyword, // done.
    LoadKeyword, // done.
    SlayKeyword, // done.
    NawwKeyword, // done.
    YassKeyword, // done.
    WithKeyword, // done.
    FromKeyword, // done.
    CloseBracket, // done.
    FunkyKeyword, // done.
    InspoKeyword, // done.
    GirlwaitKeyword, // done.
    RehearsalKeyword, // done.
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
        self: *const Token,
        allocator: Allocator
    ) void {
        if (self.value) |val| {
            allocator.free(std.mem.span(val));
        }
    }
};

/// A data structure that holds Nene's
/// lexer. This tokenizer is kept in a
/// structure to also return information
/// on where and how an error occurred.
pub const Lexer = struct { 
    err_pos: ?Position,
    allocator: Allocator,

    /// A function to create
    /// a new instance of this
    /// data structure with the 
    /// given parameters and return
    /// the created instance.
    pub fn init(
        allocator: Allocator,
    ) Lexer {
        return Lexer {
            .err_pos = null,
            .allocator = allocator
        };
    }

    /// A function to take a string
    /// of Nene source code and tokenize
    /// this string into an instance of
    /// the `std.ArrayList` structure containing
    /// instances of the `Token` structure. If
    /// the operation fails due to sub-buffers or
    /// the token stream not being writable or
    /// an unexpected character is encountered,
    /// an error is returned.
    pub fn lex(
        self: *Lexer,
        source: [*:0]const u8
    ) !ArrayList(Token) {
        var stream: ArrayList(Token) = ArrayList(Token)
           .init(self.allocator);
        errdefer {
            for (stream.items) |item| {
                item.deinit(self.allocator);
            }
            stream.deinit();
        }
        var cursor: u64 = 0;
        var line_count: u64 = 0;
        var column_count: u64 = 0;
        const str_len: u64 = strLen(source);
        while (cursor < str_len){
            if (source[cursor] == '%'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Mod,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '-' and
                source[cursor + 1] == '>')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = (column_count + 1)
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Case,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 2;
                column_count = column_count + 2;
            }
            else if (source[cursor] == '~' and
                source[cursor + 1] == '~')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = (column_count + 1)
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Comment,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 2;
                column_count = column_count + 2;
            }
            else if (source[cursor] == '\r' and
                source[cursor + 1] == '\n')
            { 
                column_count = 0;
                cursor = cursor + 2;
                line_count = line_count + 1;
            }
            else if (source[cursor] == '\r' or
                source[cursor] == '\n')
            { 
                column_count = 0;
                cursor = cursor + 1;
                line_count = line_count + 1;
            }
            else if (source[cursor] == ' '){
                cursor = cursor + 1;
                column_count = column_count + 1; 
            }
            else if (source[cursor] == '!' and
                source[cursor + 1] == '=')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = (column_count + 1)
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .IsNotEqual,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 2;
                column_count = column_count + 2;
            }
            else if (source[cursor] == '='){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .IsEqual,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '<'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .LessThan,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '>'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .GreaterThan,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '-'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Minus,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '+'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Plus,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '/'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Divide,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '*'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Multiply,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '{'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .OpenCurly,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '}'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .CloseCurly,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '('){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .OpenBracket,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == ')'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .CloseBracket,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == ':'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Colon,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == ','){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Comma,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == '?'){
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .Option,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
            }
            else if (source[cursor] == 'f' and
                source[cursor + 1] == 'i' and
                source[cursor + 2] == 'n')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .FinKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 3;
                column_count = column_count + 3;
            }
            else if (source[cursor] == 'b' and
                source[cursor + 1] == 'a' and
                source[cursor + 2] == 'g')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .BagKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 3;
                column_count = column_count + 3;
            }
            else if (source[cursor] == 's' and
                source[cursor + 1] == 'l' and
                source[cursor + 2] == 'a' and
                source[cursor + 3] == 'y')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .SlayKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 4;
                column_count = column_count + 4;
            }
            else if (source[cursor] == 'v' and
                source[cursor + 1] == 'i' and
                source[cursor + 2] == 'b' and
                source[cursor + 3] == 'e')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .VibeKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 4;
                column_count = column_count + 4;
            }
            else if (source[cursor] == 'l' and
                source[cursor + 1] == 'o' and
                source[cursor + 2] == 'a' and
                source[cursor + 3] == 'd')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .LoadKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 4;
                column_count = column_count + 4;
            }
            else if (source[cursor] == 'w' and
                source[cursor + 1] == 'i' and
                source[cursor + 2] == 't' and
                source[cursor + 3] == 'h')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .WithKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 4;
                column_count = column_count + 4;
            }
            else if (source[cursor] == 'f' and
                source[cursor + 1] == 'r' and
                source[cursor + 2] == 'o' and
                source[cursor + 3] == 'm')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .FromKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 4;
                column_count = column_count + 4;
            }
            else if (source[cursor] == 'y' and
                source[cursor + 1] == 'a' and
                source[cursor + 2] == 's' and
                source[cursor + 3] == 's')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .YassKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 4;
                column_count = column_count + 4;
            }
            else if (source[cursor] == 'n' and
                source[cursor + 1] == 'a' and
                source[cursor + 2] == 'w' and
                source[cursor + 3] == 'w')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .NawwKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 4;
                column_count = column_count + 4;
            }
            else if (source[cursor] == 'i' and
                source[cursor + 1] == 'n' and
                source[cursor + 2] == 's' and
                source[cursor + 3] == 'p' and
                source[cursor + 4] == 'o')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .InspoKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 5;
                column_count = column_count + 5;
            }
            else if (source[cursor] == 'f' and
                source[cursor + 1] == 'u' and
                source[cursor + 2] == 'n' and
                source[cursor + 3] == 'k' and
                source[cursor + 4] == 'y')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .FunkyKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 5;
                column_count = column_count + 5;
            }
            else if (source[cursor] == 'g' and
                source[cursor + 1] == 'i' and
                source[cursor + 2] == 'r' and
                source[cursor + 3] == 'l' and
                source[cursor + 4] == 'w' and
                source[cursor + 5] == 'a' and
                source[cursor + 6] == 'i' and
                source[cursor + 7] == 't')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .GirlwaitKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 8;
                column_count = column_count + 8;
            }
            else if (source[cursor] == 'r' and
                source[cursor + 1] == 'e' and
                source[cursor + 2] == 'h' and
                source[cursor + 3] == 'e' and
                source[cursor + 4] == 'a' and
                source[cursor + 5] == 'r' and
                source[cursor + 6] == 's' and
                source[cursor + 7] == 'a' and
                source[cursor + 8] == 'l')
            {
                stream.append(
                    Token{
                        .end = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .start = Position{
                            .line = line_count,
                            .column = column_count
                        },
                        .token_type = .RehearsalKeyword,
                        .value = null
                    }
                ) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 9;
                column_count = column_count + 9;
            }
            else if (source[cursor] == '"'){ 
                const column_start: u64 = column_count;
                cursor = cursor + 1;
                column_count = column_count + 1;
                var char_buf: ArrayList(u8) = ArrayList(u8)
                    .init(self.allocator);
                errdefer char_buf.deinit();   
                while (source[cursor] != '"'){
                    char_buf.append(source[cursor]) catch {
                        self.err_pos = Position{
                            .line = line_count,
                            .column = column_count
                        };
                        return NeneErr.AllocErr;
                    };
                    cursor = cursor + 1;
                    column_count = column_count + 1;
                }
                cursor = cursor + 1;
                column_count = column_count + 1;
                const joined: [*:0]const u8 = char_buf.toOwnedSliceSentinel(0) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(joined));
                const end_pos: Position = Position {
                    .column = column_count,
                    .line = line_count
                };
                const start_pos: Position = Position {
                    .column = column_start,
                    .line = line_count
                };
                const token: Token = Token{
                    .end = end_pos,
                    .start = start_pos,
                    .value = joined,
                    .token_type = .UserString
                };
                stream.append(token) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
            }
            else if (isIdentChar(source[cursor])){
                const column_start: u64 = column_count;
                var char_buf: ArrayList(u8) = ArrayList(u8)
                    .init(self.allocator);
                errdefer char_buf.deinit();
                char_buf.append(source[cursor]) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                cursor = cursor + 1;
                column_count = column_count + 1;
                while (isIdentChar(source[cursor])){
                    char_buf.append(source[cursor]) catch {
                        self.err_pos = Position{
                            .line = line_count,
                            .column = column_count
                        };
                        return NeneErr.AllocErr;
                    };
                    cursor = cursor + 1;
                    column_count = column_count + 1;
                }
                const joined: [*:0]const u8 = char_buf.toOwnedSliceSentinel(0) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(joined));
                const end_pos: Position = Position {
                    .column = column_count,
                    .line = line_count
                };
                const start_pos: Position = Position {
                    .column = column_start,
                    .line = line_count
                };
                const token: Token = Token{
                    .end = end_pos,
                    .start = start_pos,
                    .value = joined,
                    .token_type = .UserIdent
                };
                stream.append(token) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
            }
            else if (isDigit(source[cursor])){
                const column_start: u64 = column_count;
                var str_buf: ArrayList([]const u8) = ArrayList([]const u8)
                    .init(self.allocator);
                defer {
                    for (str_buf.items) |item| {
                        self.allocator.free(item);
                    }
                    str_buf.deinit();
                }
                var char_buf: ArrayList(u8) = ArrayList(u8)
                    .init(self.allocator);
                defer char_buf.deinit();
                while (isDigit(source[cursor]) or source[cursor] == '.'){
                    if (isDigit(source[cursor])){
                        char_buf.append(source[cursor]) catch {
                            self.err_pos = Position{
                                .line = line_count,
                                .column = column_count
                            };
                            return NeneErr.AllocErr;
                        };
                    }
                    else if (source[cursor] == '.'){
                        const joined: []const u8 = char_buf.toOwnedSlice() catch {
                            self.err_pos = Position{
                                .line = line_count,
                                .column = column_count
                            };
                            return NeneErr.AllocErr;
                        };
                        str_buf.append(joined) catch {
                            self.err_pos = Position{
                                .line = line_count,
                                .column = column_count
                            };
                            return NeneErr.AllocErr;
                        };
                    }
                    else {
                        self.err_pos = Position{
                            .line = line_count,
                            .column = column_count
                        };
                        return NeneErr.UnexpectedChar;
                    }
                    cursor = cursor + 1;
                    column_count = column_count + 1;
                }
                const joined: []const u8 = char_buf.toOwnedSlice() catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                str_buf.append(joined) catch {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.AllocErr;
                };
                if (str_buf.items.len == 2){
                    const fmtd: [*:0]const u8 = allocPrintZ(
                        self.allocator,
                        "{s}.{s}",
                        .{str_buf.items[0],
                          str_buf.items[1]
                        }
                    ) catch {
                        self.err_pos = Position{
                            .line = line_count,
                            .column = column_count
                        };
                        return NeneErr.AllocErr;
                    };
                    errdefer self.allocator.free(std.mem.span(fmtd));
                    const end_pos: Position = Position {
                        .column = column_count,
                        .line = line_count
                    };
                    const start_pos: Position = Position {
                        .column = column_start,
                        .line = line_count
                    };
                    const token: Token = Token{
                        .end = end_pos,
                        .start = start_pos,
                        .value = fmtd,
                        .token_type = .Float
                    };
                    stream.append(token) catch {
                        self.err_pos = Position{
                            .line = line_count,
                            .column = column_count
                        };
                        return NeneErr.AllocErr;
                    };
                }
                else if (str_buf.items.len == 1){
                    const fmtd: [*:0]const u8 = allocPrintZ(
                        self.allocator,
                        "{s}",
                        .{str_buf.items[0]}
                    ) catch {
                        self.err_pos = Position{
                            .line = line_count,
                            .column = column_count
                        };
                        return NeneErr.AllocErr;
                    };
                    errdefer self.allocator.free(std.mem.span(fmtd));
                    const end_pos: Position = Position {
                        .column = column_count,
                        .line = line_count
                    };
                    const start_pos: Position = Position {
                        .column = column_start,
                        .line = line_count
                    };
                    const token: Token = Token{
                        .end = end_pos,
                        .start = start_pos,
                        .value = fmtd,
                        .token_type = .Int
                    };
                    stream.append(token) catch {
                        self.err_pos = Position{
                            .line = line_count,
                            .column = column_count
                        };
                        return NeneErr.AllocErr;
                    };
                }
                else {
                    self.err_pos = Position{
                        .line = line_count,
                        .column = column_count
                    };
                    return NeneErr.UnknownNumberPattern;
                }
            }
            else {
                self.err_pos = Position {
                    .line = line_count,
                    .column = column_count
                };
                return NeneErr.UnexpectedChar;
            } 
        }
        return stream;
    }
};
