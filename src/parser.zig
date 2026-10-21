// NENE by Alyx Shang.
// Licensed under the FSL v1.

// Importing the namespace
// of the standard library.
const std = @import("std");

// Importing the structure to
// create an array from the 
// standard library.
const ArrayList = std.ArrayList;

// Importing the function to convert
// a string containing an integer
// into an integer type.
const parseInt = std.fmt.parseInt;

// Importing the standard structure
// for allocators from the standard
// library.
const Allocator = std.mem.Allocator;

// Importing the function to convert
// a string containing a float
// into a float type.
const parseFloat = std.fmt.parseFloat;

// Importing the structure for encapsulating
// data about a token captured from Nene source
// code.
const Token = @import("lexer.zig").Token;

// Importing the entity to catch and
// handle errors.
const NeneErr = @import("err.zig").NeneErr;

// Importing the enumeration that
// "lists" all possible types of tokens
// in Nene source code.
const TokenType = @import("lexer.zig").TokenType;

// Importing the structure to record information
// about the positions of a token in a string of
// text.
const Position = @import("position.zig").Position;

// Importing the function to clone a pointer
// to a null-terminated array of characters.
const cloneSlice = @import("utils.zig").cloneSlice;

/// An enumeration that "lists"
/// all possible binary operators
/// in a binary operation.
pub const Operator = enum(u8){
    Plus,
    Minus,
    Times,
    Equal,
    Divide,
    Larger,
    Smaller,
    NotEqual,
};

pub const BinaryExpression = struct {
    operator: Operator,
    left: *Expression,
    right: *Expression,

    pub fn deinit(
        self: *BinaryExpression,
        allocator: Allocator
    ) void {
        self.left.*.deinit(allocator);
        allocator.destroy(self.left);
        self.right.*.deinit(allocator);
        allocator.destroy(self.right);
    }
};

/// A structure to encapsulate
/// information about a set of
/// pattern-expression pairings.
pub const CaseBlock = struct {
    condition: *Expression,
    cases: *ArrayList(CasePair),

    /// A function to drop all
    /// heap-allocated resources
    /// this structure has.
    pub fn deinit(
        self: *CaseBlock,
        allocator: Allocator
    ) void {
        for (self.cases.*.items) |*item| {
            item.deinit(allocator);
        }
        self.cases.deinit(allocator);
        self.condition.*.deinit(allocator);
        allocator.destroy(self.condition);
        allocator.destroy(self.cases);
    }
};

/// A structure to encapsulate
/// data about a pattern-expression
/// pairing.
pub const CasePair = struct {
    left: *Expression,
    right: *Expression,

    /// A function to drop all
    /// heap-allocated resources
    /// this structure has.
    pub fn deinit(
        self: *CasePair,
        allocator: Allocator
    ) void {
        self.left.deinit(allocator);
        allocator.destroy(self.left);
        self.right.deinit(allocator);
        allocator.destroy(self.right);
    }
};

/// A structure to encapsulate
/// data about an argument being
/// defined as a pair consisting
/// of a name and a data type.
pub const ArgumentPair = struct {
    name: [*:0]const u8,
    data_type: [*:0]const u8,

    /// A function to drop all
    /// heap-allocated resources
    /// this structure has.
    pub fn deinit(
        self: *ArgumentPair,
        allocator: Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        allocator.free(std.mem.span(self.data_type));
    }
};

/// A structure to encapsulate
/// information about a function
/// being called.
pub const FunctionCall = struct {
    name: [*:0]const u8,
    arguments: *ArrayList(Expression),

    /// A function to drop all
    /// heap-allocated resources
    /// this union of enumerations
    /// has.
    pub fn deinit(
        self: *FunctionCall,
        allocator: Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        for (self.arguments.items) |*item| {
            item.deinit(allocator);
        }
        self.arguments.*.deinit(allocator);
        allocator.destroy(self.arguments);
    }
};

/// A union of enumerations that 
/// "lists" all possible top-level 
/// statements in Nene source code
/// and the data needed by each 
/// variant.
pub const BlockStatement = union(enum){
    Comment,
    Import: struct {
        entity: [*:0]const u8,
        module: [*:0]const u8
    },
    Function: struct {
        name: [*:0]const u8,
        body: *ArrayList(Expression),
        arguments: *ArrayList(ArgumentPair),
    },

    /// A function to drop all
    /// heap-allocated resources
    /// this union of enumerations
    /// has.
    pub fn deinit(
        self: *BlockStatement,
        allocator: Allocator
    ) void {
        switch (self.*) {
            .Import => |i| {
                allocator.free(std.mem.span(i.entity));
                allocator.free(std.mem.span(i.module));
            },
            .Function => |f| {
                allocator.free(std.mem.span(f.name));
                for (f.body.*.items) |item| {
                    item.deinit(allocator);
                }
                f.body.*.deinit(allocator);
                for (f.arguments.*.items) |*item| {
                    item.deinit(allocator);
                }
                f.arguments.*.deinit(allocator);
                allocator.destroy(f.body);
                allocator.destroy(f.arguments);
            },
            else => {}
        }
    }
};

/// A union of enumerations encapsulating
/// information about legal expressions
/// inside a block-level statement inside
/// the AST.
pub const Expression = union(enum) {
    FloatLiteral: f64,
    BoolLiteral: bool,
    NumberLiteral: i64,
    CaseBlock: CaseBlock,
    VarAccess: [*:0]const u8, 
    FunctionCall: FunctionCall,  
    StringLiteral: [*:0]const u8,
    BinaryOperation: BinaryExpression,

    /// A function to drop all
    /// heap-allocated resources
    /// this union of enumerations
    /// has.
    pub fn deinit(
        self: *const Expression,
        allocator: Allocator
    ) void {
        switch (self.*){
            .CaseBlock => |*cb| @constCast(cb).deinit(allocator),
            .FunctionCall => |*fc| @constCast(fc).deinit(allocator),
            .BinaryOperation => |*bo| @constCast(bo).deinit(allocator), 
            .StringLiteral => |s| allocator.free(std.mem.span(s)),
            else => {}
        }
    }
};

/// A structure that parses
/// a stream of tokens obtained
/// from Nene source code into
/// an AST.
pub const Parser = struct {
    cursor: u64,
    allocator: Allocator,
    err_pos: ?*const Position,
    token_stream: *const ArrayList(Token),

    /// A function to create a new
    /// instance of the `Parser`
    /// structure and return it.
    pub fn init(
        allocator: Allocator,
        token_stream: *const ArrayList(Token)
    ) Parser {
        return Parser {
            .cursor = 0,
            .err_pos = null,
            .allocator = allocator,
            .token_stream = token_stream
        };
    }

    /// A function to check if the
    /// end of the internal token
    /// stream has been reached and
    /// return a boolean based on this.
    pub fn isDone(
        self: *Parser
    ) bool {
        return self.token_stream.items.len == self.cursor;
    }

    /// A function to check which 
    /// token is at position `n`
    /// in the token stream. If
    /// the position is within
    /// the internal token stream,
    /// the token at that position
    /// is returned. If it is not,
    /// an error is returned.
    pub fn peekN(
        self: *Parser,
        n: u64
    ) NeneErr!Token {
        const new_cursor = self.cursor + n;
        if (new_cursor < self.token_stream.items.len){
            return self.token_stream.items[self.cursor];
        }
        else {
            return NeneErr.UnexpectedEndOfStream;
        }
    }

    /// A function to advance
    /// the internal cursor keeping
    /// track of the cursor's position
    /// in the internal token stream by
    /// one.
    pub fn advance(
        self: *Parser
    ) void {
        self.cursor = self.cursor + 1;
    }

    /// A function to expect a token
    /// of the supplied token type in
    /// the internal token stream at
    /// the cursor's current position.
    /// If the cursor is smaller than
    /// the end of the stream and the 
    /// token types match, the token
    /// is returned. If either of these
    /// conditions are not met, an error
    /// is returned.
    pub fn expect(
        self: *Parser,
        expected: TokenType
    ) NeneErr!Token {
        if (self.cursor < self.token_stream.items.len){
            const current: Token = self.token_stream.items[self.cursor];
            if (current.token_type == expected){
                self.advance();
                return current;
            }
            self.err_pos = current.start;
            return NeneErr.UnexpectedTokenErr;
        }
        else {
            return NeneErr.UnexpectedEndOfStream;
        }
    }

    /// A function to parse the internal stream
    /// of tokens into a list of block-level
    /// statements. If the operation is successful,
    /// an instance of the `ArrayList` structure
    /// is returned, containing instances of the
    /// `BlockStatement` union of enumerations.
    pub fn parse(
        self: *Parser
    ) NeneErr!ArrayList(BlockStatement) {
        var blocks: ArrayList(BlockStatement) = .empty;
        errdefer {
            for (blocks.items) |*item| {
                item.deinit(self.allocator);
            }
            blocks.deinit(self.allocator);
        }
        while (!self.isDone()){
            blocks.append(
                self.allocator,
                (try self.parseBlockStatement())
            ) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.WriteErr;
            };
        }
        return blocks;
    }

    /// A function to parse a block-level statement.
    /// If the operation is successful, a variant
    /// of the `BlockStatement` union of enumerations 
    /// is returned. If the operation
    /// fails, an error is returned.
    pub fn parseBlockStatement(
        self: *Parser
    ) NeneErr!BlockStatement {
        const peeked: Token = try self.peekN(0);
        return switch (peeked.token_type){
            .Comment => try self.parseComment(),
            .InspoKeyword => try self.parseImport(),
            .FunkyKeyword => try self.parseFunctionDef(),
            else => {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            }
        };
    }

    /// A function to parse a block-level comment.
    /// If the operation is successful, the `Comment`
    /// variant of the `BlockStatement` union of 
    /// enumerations is returned. If the operation
    /// fails, an error is returned.
    pub fn parseComment(
        self: *Parser
    ) NeneErr!BlockStatement {
        _ = try self.expect(.Comment);
        return .Comment;
    }

    /// A function to parse an import block-level
    /// statement. If the operation is successful,
    /// the `Import` variant of the `BlockStatement` 
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseImport(
        self: *Parser
    ) NeneErr!BlockStatement {
        _ = try self.expect(.InspoKeyword);
        const entity_token: Token = try self.expect(.UserString);
        _ = try self.expect(.FromKeyword);
        const location_token: Token = try self.expect(.UserString);
        if (entity_token.value) |e| {
            if (location_token.value) |l| {
                const entity_cloned: [*:0]const u8 = cloneSlice(
                    e,
                    self.allocator
                ) catch {
                    self.err_pos = entity_token.start;
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(entity_cloned));
                const location_cloned: [*:0]const u8 = cloneSlice(
                    l,
                    self.allocator
                ) catch {
                    self.err_pos = location_token.start;
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(location_cloned));
                return .{
                    .Import = .{
                        .entity = entity_cloned,
                        .module = location_cloned
                    }
                };
            }
            else {
                self.err_pos = location_token.start;
                return NeneErr.NoValueErr;
            }
        }
        else {
            self.err_pos = entity_token.start;
            return NeneErr.NoValueErr;
        }
    }

    /// A function to parse a pair
    /// of a data type and an identifier,
    /// both constituting a parameter for
    /// a function. If the operation is
    /// successful, an instance of the
    /// `ArgumentPair` structure is returned.
    /// If the operation fails, an error is
    /// returned.
    pub fn parseArgumentPair(
        self: *Parser
    ) NeneErr!ArgumentPair {
        const type_name_token: Token = try self.expect(.Ident);
        const var_name_token: Token = try self.expect(.Ident);
        if (type_name_token.value) |t| {
            if (var_name_token.value) |v| {
                const type_name: [*:0]const u8 = cloneSlice(
                    t,
                    self.allocator
                ) catch {
                    self.err_pos = type_name_token.start;
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(type_name));
                const var_name: [*:0]const u8 = cloneSlice(
                    v,
                    self.allocator
                ) catch {
                    self.err_pos = var_name_token.start;
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(var_name));
                return ArgumentPair{
                    .name = var_name,
                    .data_type = type_name
                };
            }
            else {
                self.err_pos = var_name_token.start;
                return NeneErr.NoValueErr;
            }
        }
        else {
            self.err_pos = type_name_token.start;
            return NeneErr.NoValueErr;
        }


    }

    /// A function to parse a function definition as a
    /// block-level statement. If the operation is 
    /// successful, the `FunctionDef` variant of the 
    /// `BlockStatement` union of enumerations is 
    /// returned. If the operation fails, an error 
    /// is returned.
    pub fn parseFunctionDef(
        self: *Parser
    ) NeneErr!BlockStatement {
        _ = try self.expect(.FunkyKeyword);
        const ident_token: Token = try self.expect(.Ident);
        _ = try self.expect(.OpenBracket);
        var pairs: ArrayList(ArgumentPair) = .empty;
        errdefer {
            for (pairs.items) |*item| {
                item.deinit(self.allocator);
            }
            pairs.deinit(self.allocator);
        }
        while ((try self.peekN(0)).token_type != .CloseBracket){
            const peeked: Token = try self.peekN(1);
            if (peeked.token_type != .CloseBracket){
                _ = try self.expect(.Comma);
            }
            pairs.append(
                self.allocator,
                (try self.parseArgumentPair())
            ) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            };
        }
        _ = try self.expect(.CloseBracket);
        _ = try self.expect(.Equal);
        var expressions: ArrayList(Expression) = .empty;
        errdefer {
            for (expressions.items) |*item| {
                item.deinit(self.allocator);
            }
            expressions.deinit(self.allocator);
        }
        while ((try self.peekN(0)).token_type != .FinKeyword){
            expressions.append(
                self.allocator,
                (try self.parseExpression())
            ) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.WriteErr;
            };
        }
        const arg_ptr = self.allocator.create(ArrayList(ArgumentPair)) catch {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.AllocErr;
        };
        errdefer self.allocator.destroy(arg_ptr);
        arg_ptr.* = pairs;
        const body_ptr = self.allocator.create(ArrayList(Expression)) catch {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.AllocErr;
        };
        errdefer self.allocator.destroy(body_ptr);
        body_ptr.* = expressions;
        if (ident_token.value) |val| {
            const fn_name: [*:0]const u8 = cloneSlice(
                val,
                self.allocator
            ) catch {
                self.err_pos = ident_token.start;
                return NeneErr.AllocErr;
            };
            errdefer self.allocator.free(std.mem.span(fn_name));
            return BlockStatement{ 
                .Function = .{
                    .name = fn_name,
                    .body = body_ptr,
                    .arguments = arg_ptr
                }
            };
        }
        else {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.NoValueErr;
        } 
    }

    /// A function to parse an expression.
    /// If the operation is successful, a
    /// variant of the `Expression` union of 
    /// enumerations is returned. If the operation
    /// fails, an error is returned.
    pub fn parseExpression(
        self: *Parser
    ) NeneErr!Expression {
        const peeked: Token = try self.peekN(0);
        return switch (peeked.token_type){
            .Ident => try self.parseIdentExpression(),
            .Float => try self.parseFloatLiteral(), 
            .Number => try self.parseIntegerLiteral(),
            .VibeKeyword => try self.parseCaseBlock(),
            .TrueKeyword => try self.parseBoolLiteral(),
            .FalseKeyword => try self.parseBoolLiteral(), 
            .UserString => try self.parseStringLiteral(), 
            .OpenBracket => try self.parseBinaryExpression(),
            else => {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            }
        };
    }

    /// A function to parse a literal expression
    /// for a float. If the operation is successful,
    /// the `FloatLiteral` variant of the `Expression` 
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseFloatLiteral(
        self: *Parser
    ) NeneErr!Expression {
        const float_token: Token = try self.expect(.Float);
        if (float_token.value) |val| {
            const parsed: f64 = parseFloat(f64, std.mem.span(val)) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.ParseFloatErr;
            };
            return Expression{ .FloatLiteral = parsed };
        }
        else {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.NoValueErr;
        }
    }

    /// A function to parse a literal expression
    /// for an integer. If the operation is successful,
    /// the `IntegerLiteral` variant of the `Expression` 
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseIntegerLiteral(
        self: *Parser
    ) NeneErr!Expression {
        const int_token: Token = try self.expect(.Number);
        if (int_token.value) |val| {
            const parsed: i64 = parseInt(i64, std.mem.span(val), 10) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.ParseIntErr;
            };
            return Expression{ .NumberLiteral = parsed };
        }
        else {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.NoValueErr;
        }
    }

    /// A function to parse a literal expression
    /// for a boolean. If the operation is successful,
    /// the `BoolLiteral` variant of the `Expression` 
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseBoolLiteral(
        self: *Parser
    ) NeneErr!Expression {
        const peeked: Token = try self.peekN(0);
        if (peeked.token_type == .TrueKeyword){
            return Expression{ .BoolLiteral = true };
        }
        else if (peeked.token_type == .FalseKeyword){
            return Expression{ .BoolLiteral = false };
        }
        else {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.UnexpectedTokenErr;
        }
    }

    /// A function to parse a literal expression
    /// for a string. If the operation is successful,
    /// the `StringLiteral` variant of the `Expression` 
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseStringLiteral(
        self: *Parser
    ) NeneErr!Expression {
        const string_token: Token = try self.expect(.UserString);
        if (string_token.value) |val| {
            const literal: [*:0]const u8 = cloneSlice(
                val,
                self.allocator
            ) catch {
                self.err_pos = string_token.start;
                return NeneErr.AllocErr;
            };
            errdefer self.allocator.free(std.mem.span(literal));
            return Expression{ .StringLiteral = literal };
        }
        else {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.NoValueErr;
        }
    }

    /// A function to parse an expression for an
    /// identifier. If the operation is successful,
    /// the either of the variants using identifiers
    /// of the `Expression`  union of enumerations 
    /// are returned. If the operation fails, an 
    /// error is returned.
    pub fn parseIdentExpression(
        self: *Parser
    ) NeneErr!Expression {
        const peeked: Token = try self.peekN(0);
        const next: Token = try self.peekN(1);
        if (peeked.token_type == .Ident and
            next.token_type == .OpenBracket)
        {
            return (try self.parseFunctionCall());
        }
        else if (peeked.token_type == .Ident and
            next.token_type != .OpenBracket)
        {
            return (try self.parseVarAccess());
        }
        else {
            self.err_pos = peeked.start;
            return NeneErr.UnexpectedTokenErr;
        }
    }

    /// A function to parse an expression for an
    /// identifier. If the operation is successful,
    /// the `VarAccess` variant of the `Expression`  
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseVarAccess(
        self: *Parser
    ) NeneErr!Expression {
        const ident: Token = try self.expect(.Ident);
        if (ident.value) |val| {
            const var_access: [*:0]const u8 = cloneSlice(
                val,
                self.allocator
            ) catch {
                self.err_pos = ident.start;
                return NeneErr.AllocErr;
            };
            errdefer self.allocator.free(std.mem.span(var_access));
            return Expression{ .VarAccess = var_access };
        }
        else {
            self.err_pos = ident.start;
            return NeneErr.NoValueErr;
        }
    }

    /// A function to parse an expression for a
    /// function call. If the operation is successful,
    /// the `FunctionCall` variant of the `Expression`  
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseFunctionCall(
        self: *Parser
    ) NeneErr!Expression {
        const fn_name: Token = try self.expect(.Ident);
        _ = try self.expect(.OpenBracket);
        var expressions: ArrayList(Expression) = .empty;
        errdefer {
            for (expressions.items) |*item| {
                item.deinit(self.allocator);
            }
            expressions.deinit(self.allocator);
        }
        while ((try self.peekN(0)).token_type != .CloseBracket){
            const peeked: Token = try self.peekN(1);
            if (peeked.token_type != .CloseBracket){
                _ = try self.expect(.Comma);
            }
            expressions.append(
                self.allocator,
                (try self.parseExpression())
            ) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            };
        }
        if (fn_name.value) |val| {
            const name: [*:0]const u8 = cloneSlice(
                val,
                self.allocator
            ) catch {
                self.err_pos = fn_name.start;
                return NeneErr.AllocErr;
            };
            errdefer self.allocator.free(std.mem.span(name));
            const args_ptr = self.allocator.create(ArrayList(Expression)) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.AllocErr;
            };
            errdefer self.allocator.destroy(args_ptr);
            args_ptr.* = expressions;
            const fn_call: FunctionCall = FunctionCall{
                .name = name,
                .arguments = args_ptr
            };
            return Expression{ .FunctionCall = fn_call };
        }
        else {
            self.err_pos = fn_name.start;
            return NeneErr.NoValueErr;
        }
    }

    /// A function to parse an expression for a
    /// binary expression. If the operation is successful,
    /// the `BinaryOperation` variant of the `Expression`  
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseBinaryExpression(
        self: *Parser
    ) NeneErr!Expression {
        _ = try self.expect(.OpenBracket);
        const left = self.allocator.create(Expression) catch {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.AllocErr;
        };
        left.* = try self.parseExpression();
        errdefer self.allocator.destroy(left);
        const peeked: Token = try self.peekN(0);
        const operator: Operator = switch (peeked.token_type){
            .Equal => .Equal,
            .Plus => .Plus,
            .Minus => .Minus,
            .Times => .Times,
            .Divide => .Divide,
            .Larger => .Larger,
            .Smaller => .Smaller,
            .NotEqual => .NotEqual,
            else => {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            }
        };
        const right = self.allocator.create(Expression) catch {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.AllocErr;
        };
        right.* = try self.parseExpression();
        errdefer self.allocator.destroy(right);
        _ = try self.expect(.CloseBracket);
        const bin_expr: BinaryExpression = BinaryExpression{
            .left = left,
            .right = right,
            .operator = operator
        };
        return Expression{ .BinaryOperation = bin_expr };
    }

    /// A function to parse an expression for a
    /// literal expression. If the operation is successful,
    /// a variant containing a literal of the `Expression`  
    /// union of enumerations is returned. If the 
    /// operation fails, an error is returned.
    pub fn parseLiteral(
        self: *Parser
    ) NeneErr!Expression {
        const peeked: Token = try self.peekN(0);
        switch (peeked.token_type) {
            .Float => return (try self.parseFloatLiteral()),
            .Number => return (try self.parseIntegerLiteral()),
            .TrueKeyword => return (try self.parseBoolLiteral()),
            .FalseKeyword => return (try self.parseBoolLiteral()),
            .UserString => return (try self.parseStringLiteral()),
            else => {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            }

        }
    }

    /// A function to parse an expression containing a
    /// pattern-matching block. If the operation is 
    /// successful, the `CaseBlock` variant of 
    /// the `Expression`  union of enumerations 
    /// is returned. If the operation fails, an 
    /// error is returned.
    pub fn parseCaseBlock(
        self: *Parser
    ) NeneErr!Expression {
        _ = try self.expect(.VibeKeyword);
        const expr: Expression = try self.parseExpression();
        var cases: ArrayList(CasePair) = .empty;
        errdefer {
            for (cases.items) |*item| {
                item.deinit(self.allocator);
            }
            cases.deinit(self.allocator);
        }
        while ((try self.peekN(0)).token_type != .FinKeyword){
            const literal: Expression = try self.parseLiteral();
            const ptrn_ptr = self.allocator.create(Expression) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.AllocErr;
            };
            errdefer self.allocator.destroy(ptrn_ptr);
            _ = try self.expect(.CaseOperator);
            const result: Expression = try self.parseExpression();
            const result_ptr = self.allocator.create(Expression) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.AllocErr;
            };
            result_ptr.* = result;
            ptrn_ptr.* = literal;
            const case: CasePair = CasePair {
                .left = ptrn_ptr,
                .right = result_ptr
            };
            cases.append(
                self.allocator,
                case
            ) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.WriteErr;
            };
        }
        _ = try self.expect(.FinKeyword);
        const cond_ptr = self.allocator.create(Expression) catch {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.AllocErr;
        };
        errdefer self.allocator.destroy(cond_ptr);
        cond_ptr.* = expr;
        const cases_ptr = self.allocator.create(ArrayList(CasePair)) catch {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.AllocErr;
        };
        errdefer self.allocator.destroy(cases_ptr);
        cases_ptr.* = cases;
        const case_block: CaseBlock = CaseBlock {
            .condition = cond_ptr,
            .cases = cases_ptr
        };
        return Expression{ .CaseBlock = case_block };
    }
};
