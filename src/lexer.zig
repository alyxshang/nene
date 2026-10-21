// NENE by Alyx Shang.
// Licensed under the FSL v1.

// Importing the namespace
// of the standard library.
const std = @import("std");

// Importing the structure to
// create an array from the 
// standard library.
const ArrayList = std.ArrayList;

// Importing the standard structure
// for allocators from the standard
// library.
const Allocator = std.mem.Allocator;

// Importing the entity to catch and
// handle errors.
const NeneErr = @import("err.zig").NeneErr;

// Importing the function to get the length
// of a pointer to a null-terminated character
// array.
const strLen = @import("utils.zig").strLen;

// Importing the function to check if a 
// character is a digit.
const isNumChar = @import("utils.zig").isNumChar;

// Importing the structure to record information
// about the positions of a token in a string of
// text.
const Position = @import("position.zig").Position;

// Importing the function to clone a pointer
// to a null-terminated array of characters.
const cloneSlice = @import("utils.zig").cloneSlice;

// Importing the function to check if a 
// character is an ident character.
const isIdentChar = @import("utils.zig").isIdentChar;

/// An enumeration that "lists"
/// all possible types of tokens
/// that can be used in Nene source
/// code.
pub const TokenType = enum(u8){
    Plus,
    Ident,
    Comma,
    Float,
    Equal,
    Minus,
    Times,
    Divide,
    Number,
    Modulo,
    Larger,
    Comment,
    Smaller,
    NotEqual,
    UserString,
    FinKeyword,
    GlamKeyword,
    VibeKeyword,
    WithKeyword,
    FromKeyword,
    OpenBracket,
    TrueKeyword,
    FalseKeyword,
    CloseBracket,
    InspoKeyword,
    FunkyKeyword,
    CaseOperator,
};

/// A structure to encapsulate
/// information about a token
/// captured from Nene source
/// code.
pub const Token = struct {
    end: *const Position,
    start: *const Position,
    token_type: TokenType,
    value: ?[*:0]const u8,

    /// A function to create a new
    /// instance of the `Token`
    /// structure and return the
    /// created instance.
    pub fn init(
        end: *const Position,
        token_type: TokenType,
        value: ?[*:0]const u8,
        start: *const Position,
    ) Token {
        return Token {
            .end = end,
            .start = start,
            .value = value,
            .token_type = token_type
        };
    }

    /// A function to free
    /// all heap-allocated
    /// resources this structure
    /// holds.
    pub fn deinit(
        self: *const Token,
        allocator: Allocator
    ) void {
        if (self.value) |val| {
            allocator.free(std.mem.span(val));
        }
    }

};

/// A structure for holding
/// resources to split a 
/// string containing Nene
/// source code into a stream
/// of tokens.
pub const Lexer = struct {
    line: u64,
    length: u64,
    cursor: u64,
    column: u64,
    allocator: Allocator,
    source: [*:0]const u8,
    err_pos: ?*const Position,

    /// A function to
    /// create a new instance
    /// of the `Lexer` structure
    /// and return the created
    /// instance.
    pub fn init(
        allocator: Allocator,
        source: [*:0]const u8
    ) Lexer {
        const length: u64 = strLen(source);
        return Lexer {
            .line = 1,
            .cursor = 0,
            .column = 0,
            .err_pos = null,
            .length = length,
            .source = source,
            .allocator = allocator,
        };
    }

    /// A function to split
    /// Nene source code 
    /// into a stream of 
    /// tokens. The stream 
    /// of tokens is returned 
    /// as an instance of the 
    /// `ArrayList` structure
    /// containing instances 
    /// of the `Token` structure. 
    /// If an unexpected character 
    /// is encountered, an error
    /// is returned.
    pub fn lex(
        self: *Lexer
    ) !ArrayList(Token) {
        var result: ArrayList(Token) = .empty;
        errdefer {
            for (result.items) |item| {
                item.deinit(self.allocator);
            }
            result.deinit(self.allocator);
        }
        while (self.cursor < self.length){
            if (self.source[self.cursor] == ' ' or
                self.source[self.cursor] == '\t'
               )
            {
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '\n' or
                self.source[self.cursor] == '\r'
               )
            {
                self.line = self.line + 1;
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '\r' and
                self.source[self.cursor + 1] == '\n'
               )
            {
                self.line = self.line + 1;
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '+'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Plus,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '-' and
                     self.source[self.cursor + 1] == '>'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 1)
                );
                const token: Token = Token.init(
                    &start,
                    .CaseOperator,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 2;
                self.cursor = self.cursor + 2;
            }
            else if (self.source[self.cursor] == '-'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Minus,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '*'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Times,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '/'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Divide,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '<'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Smaller,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '>'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Larger,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '%'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Modulo,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '('){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .OpenBracket,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == ')'){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .CloseBracket,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == ','){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Comma,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '='){
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Equal,
                    null,
                    &start
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 1;
                self.cursor = self.cursor + 1;
            }
            else if (self.source[self.cursor] == '!' and
                     self.source[self.cursor + 1] == '=')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 1)
                );
                const token: Token = Token.init(
                    &start,
                    .NotEqual,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 2;
                self.cursor = self.cursor + 2;
            }
            else if (self.source[self.cursor] == 'f' and
                     self.source[self.cursor + 1] == 'i' and
                     self.source[self.cursor + 2] == 'n')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 2)
                );
                const token: Token = Token.init(
                    &start,
                    .FunkyKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 3;
                self.cursor = self.cursor + 3;
            }
            else if (self.source[self.cursor] == 'f' and
                     self.source[self.cursor + 1] == 'u' and
                     self.source[self.cursor + 2] == 'n' and
                     self.source[self.cursor + 3] == 'k' and
                     self.source[self.cursor + 4] == 'y')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 4)
                );
                const token: Token = Token.init(
                    &start,
                    .FunkyKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 5;
                self.cursor = self.cursor + 5;
            }
            else if (self.source[self.cursor] == 'i' and
                     self.source[self.cursor + 1] == 'n' and
                     self.source[self.cursor + 2] == 's' and
                     self.source[self.cursor + 3] == 'p' and
                     self.source[self.cursor + 4] == 'o')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 4)
                );
                const token: Token = Token.init(
                    &start,
                    .InspoKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 5;
                self.cursor = self.cursor + 5;
            }
            else if (self.source[self.cursor] == 'f' and
                     self.source[self.cursor + 1] == 'a' and
                     self.source[self.cursor + 2] == 'l' and
                     self.source[self.cursor + 3] == 's' and
                     self.source[self.cursor + 4] == 'e')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 4)
                );
                const token: Token = Token.init(
                    &start,
                    .FalseKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 5;
                self.cursor = self.cursor + 5;
            }
            else if (self.source[self.cursor] == 'w' and
                     self.source[self.cursor + 1] == 'i' and
                     self.source[self.cursor + 2] == 't' and
                     self.source[self.cursor + 3] == 'h')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 3)
                );
                const token: Token = Token.init(
                    &start,
                    .WithKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 4;
                self.cursor = self.cursor + 4;
            }
            else if (self.source[self.cursor] == 'f' and
                     self.source[self.cursor + 1] == 'r' and
                     self.source[self.cursor + 2] == 'o' and
                     self.source[self.cursor + 3] == 'm')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 3)
                );
                const token: Token = Token.init(
                    &start,
                    .FromKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 4;
                self.cursor = self.cursor + 4;
            }
            else if (self.source[self.cursor] == 'g' and
                     self.source[self.cursor + 1] == 'l' and
                     self.source[self.cursor + 2] == 'a' and
                     self.source[self.cursor + 3] == 'm')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 3)
                );
                const token: Token = Token.init(
                    &start,
                    .GlamKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 4;
                self.cursor = self.cursor + 4;
            }
            else if (self.source[self.cursor] == 'v' and
                     self.source[self.cursor + 1] == 'i' and
                     self.source[self.cursor + 2] == 'b' and
                     self.source[self.cursor + 3] == 'e')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 3)
                );
                const token: Token = Token.init(
                    &start,
                    .VibeKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 4;
                self.cursor = self.cursor + 4;
            }
            else if (self.source[self.cursor] == 't' and
                     self.source[self.cursor + 1] == 'r' and
                     self.source[self.cursor + 2] == 'u' and
                     self.source[self.cursor + 3] == 'e')
            {
                const start: Position = Position.init(
                    self.line,
                    self.column
                );
                const end: Position = Position.init(
                    self.line,
                    (self.column + 3)
                );
                const token: Token = Token.init(
                    &start,
                    .TrueKeyword,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
                self.column = self.column + 4;
                self.cursor = self.cursor + 4;
            }
            else if (self.source[self.cursor] == '#'){
                const start_col: u64 = self.column;
                while (self.source[self.cursor] != '\n' and 
                       self.source[self.cursor] != '\r')
                {
                    self.cursor = self.cursor + 1;
                    self.column = self.column + 1;
                }
                const start: Position = Position.init(
                    self.line,
                    start_col
                );
                const end: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Comment,
                    null,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
            }
            else if (self.source[self.cursor] == '"'){
                const start_col: u64 = self.column;
                self.cursor = self.cursor + 1;
                self.column = self.column + 1;
                var char_buf: ArrayList(u8) = .empty;
                errdefer char_buf.deinit(self.allocator);
                while (self.source[self.cursor] != '"'){
                    char_buf.append(self.allocator, self.source[self.cursor]) catch {
                        const err_pos: Position = Position.init(
                            self.line, 
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.WriteErr;
                    };
                    self.cursor = self.cursor + 1;
                    self.column = self.column + 1;
                }
                self.cursor = self.cursor + 1;
                self.column = self.column + 1;
                const joined: [*:0]const u8 = char_buf.toOwnedSliceSentinel(
                    self.allocator, 
                    0
                ) catch {
                    const err_pos: Position = Position.init(
                        self.line, 
                        self.column
                    );
                    self.err_pos = &err_pos;
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(joined));
                const start: Position = Position.init(
                    self.line,
                    start_col
                );
                const end: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .UserString,
                    joined,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
            }
            else if (isIdentChar(self.source[self.cursor])){
                const start_col: u64 = self.column;
                var char_buf: ArrayList(u8) = .empty;
                errdefer char_buf.deinit(self.allocator);
                while (isIdentChar(self.source[self.cursor])){
                    char_buf.append(self.allocator, self.source[self.cursor]) catch {
                        const err_pos: Position = Position.init(
                            self.line, 
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.UnexpectedCharacter;
                    };
                    self.cursor = self.cursor + 1;
                    self.column = self.column + 1;
                }
                self.cursor = self.cursor + 1;
                self.column = self.column + 1;
                const joined: [*:0]const u8 = char_buf.toOwnedSliceSentinel(
                    self.allocator,
                    0
                ) catch {
                    const err_pos: Position = Position.init(
                        self.line, 
                        self.column
                    );
                    self.err_pos = &err_pos;
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(joined));
                const start: Position = Position.init(
                    self.line,
                    start_col
                );
                const end: Position = Position.init(
                    self.line,
                    self.column
                );
                const token: Token = Token.init(
                    &start,
                    .Ident,
                    joined,
                    &end
                );
                result.append(self.allocator, token) catch {
                    self.err_pos = &start;
                    return NeneErr.WriteErr;
                };
            }
            else if (isNumChar(self.source[self.cursor])){
                const start_col: u64 = self.column;
                var char_buf: ArrayList(u8) = .empty;
                defer char_buf.deinit(self.allocator);
                var str_buf: ArrayList([*:0]const u8) = .empty;
                defer {
                    for (str_buf.items) |item| {
                        self.allocator.free(std.mem.span(item));
                    }
                    str_buf.deinit(self.allocator);
                }
                while (isNumChar(self.source[self.cursor]) or 
                       self.source[self.cursor] == '.')
                {
                    if (self.source[self.cursor] == '.'){
                        const joined: [*:0]const u8 = char_buf.toOwnedSliceSentinel(
                            self.allocator,
                            0
                        ) catch {
                            const err_pos: Position = Position.init(
                                self.line, 
                                self.column
                            );
                            self.err_pos = &err_pos;
                            return NeneErr.AllocErr;
                        };
                        errdefer self.allocator.free(std.mem.span(joined));
                        char_buf.clearRetainingCapacity();
                        str_buf.append(self.allocator, joined) catch {
                            const err_pos: Position = Position.init(
                                self.line, 
                                self.column
                            );
                            self.err_pos = &err_pos;
                            return NeneErr.WriteErr;
                        };
                        self.cursor = self.cursor + 1;
                        self.column = self.column + 1;

                    }
                    char_buf.append(self.allocator, self.source[self.cursor]) catch {
                        const err_pos: Position = Position.init(
                            self.line, 
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.UnexpectedCharacter;
                    };
                    self.cursor = self.cursor + 1;
                    self.column = self.column + 1;
                }
                const joined: [*:0]const u8 = char_buf.toOwnedSliceSentinel(
                    self.allocator,
                    0
                ) catch {
                    const err_pos: Position = Position.init(
                        self.line,
                        self.column
                    );
                    self.err_pos = &err_pos;
                    return NeneErr.AllocErr;
                };
                str_buf.append(self.allocator, joined) catch {
                    const err_pos: Position = Position.init(
                        self.line,
                        self.column
                    );
                    self.err_pos = &err_pos;
                    return NeneErr.WriteErr;
                };
                if (str_buf.items.len == 2){
                    const front: [*:0]const u8 = cloneSlice(
                        str_buf.items[0],
                        self.allocator
                    ) catch {
                         const err_pos: Position = Position.init(
                            self.line,
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.AllocErr;
                    };
                    defer self.allocator.free(std.mem.span(front));
                    const back: [*:0]const u8 = cloneSlice(
                        str_buf.items[1],
                        self.allocator
                    ) catch {
                        const err_pos: Position = Position.init(
                            self.line,
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.AllocErr;
                    };
                    defer self.allocator.free(std.mem.span(back));
                    const formatted: [*:0]const u8 = std.fmt.allocPrintSentinel(
                        self.allocator,
                        "{s}.{s}",
                        .{std.mem.span(front), std.mem.span(back)},
                        0
                    ) catch {
                        const err_pos: Position = Position.init(
                            self.line,
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.AllocErr;
                    };
                    errdefer self.allocator.free(std.mem.span(formatted));
                    const start: Position = Position.init(
                        self.line,
                        start_col
                    );
                    const end: Position = Position.init(
                        self.line,
                        self.column
                    );
                    const token: Token = Token.init(
                        &start,
                        .Float,
                        formatted,
                        &end
                    );
                    result.append(self.allocator, token) catch {
                       const err_pos: Position = Position.init(
                            self.line,
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.AllocErr;
                    };
                }
                else if (str_buf.items.len == 1){
                    const num: [*:0]const u8 = cloneSlice(
                        str_buf.items[0],
                        self.allocator
                    ) catch {
                        self.err_pos = &Position.init(
                            self.line, 
                            self.column
                        );
                        return NeneErr.AllocErr;
                    };
                    errdefer self.allocator.free(std.mem.span(num));
                    const start: Position = Position.init(
                        self.line,
                        start_col
                    );
                    const end: Position = Position.init(
                        self.line,
                        self.column
                    );
                    const token: Token = Token.init(
                        &start,
                        .Number,
                        num,
                        &end
                    );
                    result.append(self.allocator, token) catch {
                        const err_pos: Position = Position.init(
                            self.line,
                            self.column
                        );
                        self.err_pos = &err_pos;
                        return NeneErr.WriteErr;
                    };
                }
                else {
                    const err_pos: Position = Position.init(
                        self.line, 
                        self.column
                    );
                    self.err_pos = &err_pos;
                    return NeneErr.UnexpectedNumberFormatErr;
                } 
            }
            else {
                const err_pos: Position = Position.init(
                    self.line, 
                    self.column
                );
                self.err_pos = &err_pos;
                return NeneErr.UnexpectedCharacter;
            }
        }
        return result;
    }

    /// A function to drop
    /// all heap-allocated
    /// resources this structure
    /// holds.
    pub fn deinit(
        self: *Lexer
    ) void {
        self.allocator.free(std.mem.span(self.source));
    }
};
