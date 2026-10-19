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

// Importing the enumeration that
// "lists" all possible types of tokens
// in Nene source code.
const TokenType = @import("lexer.zig").TokenType;

// Importing the structure for encapsulating
// data about a token captured from Nene source
// code.
const Token = @import("lexer.zig").Token;

// Importing the entity to catch and
// handle errors.
const NeneErr = @import("err.zig").NeneErr;

// Importing the structure to record information
// about the positions of a token in a string of
// text.
const Position = @import("position.zig").Position;

// Importing the function to clone a pointer
// to a null-terminated array of characters.
const cloneSlice = @import("utils.zig").cloneSlice;

/// A structure to encapsulate
/// information about a set of
/// pattern-expression pairings.
pub const CaseBlock = struct {
    condition: *const Expression,
    cases: ArrayList(CasePair),

    /// A function to drop all
    /// heap-allocated resources
    /// this structure has.
    pub fn deinit(
        self: *CaseBlock,
        allocator: Allocator
    ) void {
        for (self.cases.items) |item| {
            item.deinit(allocator);
        }
        self.cases.deinit();
    }
};

/// A structure to encapsulate
/// data about a pattern-expression
/// pairing.
pub const CasePair = struct {
    left: *const Expression,
    right: *const Expression,

    /// A function to drop all
    /// heap-allocated resources
    /// this structure has.
    pub fn deinit(
        self: *CasePair,
        allocator: Allocator
    ) void {
        self.left.deinit(allocator);
        self.right.deinit(allocator);
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
    arguments: ArrayList(Expression),

    /// A function to drop all
    /// heap-allocated resources
    /// this union of enumerations
    /// has.
    pub fn deinit(
        self: *FunctionCall,
        allocator: Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        for (self.arguments.items) |item| {
            item.deinit(allocator);
        }
        self.arguments.deinit();
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
        body: ArrayList(Expression),
        arguments: ArrayList(ArgumentPair),
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
                for (f.body.items) |item| {
                    item.deinit(allocator);
                }
                f.body.deinit();
                for (f.arguments.items) |item| {
                    item.deinit(allocator);
                }
                f.arguments.deinit();
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
    BinaryOperation: CasePair,
    FunctionCall: FunctionCall,  
    StringLiteral: [*:0]const u8,

    /// A function to drop all
    /// heap-allocated resources
    /// this union of enumerations
    /// has.
    pub fn deinit(
        self: *Expression,
        allocator: Allocator
    ) void {
        switch (self.*){
            .CaseBlock => |cb| cb.deinit(allocator),
            .FunctionCall => |fc| fc.deinit(allocator),
            .BinaryOperation => |bo| bo.deinit(allocator), 
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

    pub fn isDone(
        self: *Parser
    ) bool {
        return self.token_stream.items.len == self.cursor;
    }

    pub fn peekN(
        self: *Parser,
        n: u64
    ) !Token {
        const new_cursor = self.cursor + n;
        if (new_cursor < self.token_stream.items.len){
            return self.token_stream.items[self.cursor];
        }
        else {
            return NeneErr.UnexpectedEndOfStream;
        }
    }

    pub fn advance(
        self: *Parser
    ) void {
        self.cursor = self.cursor + 1;
    }

    pub fn expect(
        self: *Parser,
        expected: *const TokenType
    ) !Token {
        if (self < self.token_stream.items.len){
            const current: Token = self.token_stream.items[self.cursor];
            if (current.token_type == expected){
                self.advance();
                return current;
            }
            self.err_pos = &current.start;
            return NeneErr.UnexpectedToken;
        }
        else {
            return NeneErr.UnexpectedEndOfStream;
        }
    }

    pub fn parse(
        self: *Parser
    ) !ArrayList(BlockStatement) {
        var blocks: ArrayList(BlockStatement) = ArrayList(BlockStatement)
            .init(self.allocator);
        errdefer {
            for (blocks.items) |item| {
                item.deinit(self.allocator);
            }
            blocks.deinit();
        }
        while (!self.isDone()){
            blocks.append(try self.parseBlockStatement) catch {
                self.err_pos = &self.token_stream[self.cursor].start;
                return NeneErr.WriteErr;
            };
        }
        return blocks;
    }

    pub fn parseBlockStatement(
        self: *Parser
    ) !BlockStatement {
        const peeked: Token = try self.peekN(0);
        return switch (peeked.token_type){
            .Comment => try self.parseComment(),
            .InspoKeyword => try self.parseImport(),
            .FunkyKeyword => try self.parseFunctionDef(),
            else => {
                self.err_pos = &self.token_stream[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            }
        };
    }

    pub fn parseComment(
        self: *Parser
    ) !BlockStatement {
        _ = try self.expect(&.Comment);
        return .Comment;
    }

    pub fn parseImport(
        self: *Parser
    ) !BlockStatement {
        _ = try self.expect(&.InpsoKeyword);
        const entity_token: Token = try self.expect(&.UserString);
        _ = try self.expect(&.FromKeyword);
        const location_token: Token = try self.expect(&.UserString);
        if (entity_token.value) |e| {
            if (location_token.value) |l| {
                const entity_cloned: [*:0]const u8 = cloneSlice(
                    e,
                    self.allocator
                ) catch {
                    self.err_pos = &entity_token.start;
                    return NeneErr.AllocErr;
                };
                errdefer self.allocator.free(std.mem.span(entity_cloned));
                const location_cloned: [*:0]const u8 = cloneSlice(
                    l,
                    self.allocator
                ) catch {
                    self.err_pos = &location_token.start;
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
                self.err_pos = &location_token.start;
                return NeneErr.NoValueErr;
            }
        }
        else {
            self.err_pos = &entity_token.start;
            return NeneErr.NoValueErr;
        }
    }

    pub fn parseExpression(
        self: *Parser
    ) !Expression {
        const peeked: Token = try self.peekN(0);
        return switch (peeked.token_type){
            .Float => try self.parseFloatLiteral(), 
            .Number => try self.parseIntegerLiteral(),
            .VibeKeyword => try self.parseCaseBlock(),
            .TrueKeyword => try self.parseBoolLiteral(),
            .FalseKeyword => try self.parseBoolLiteral(), 
            .UserString => try self.parseStringLiteral(),
            .UserIdent => try self.parseIdentExpression(),
            .OpenBracket => try self.parseBinaryExpression(),
        };
    }

    pub fn parseFloatLiteral(
        self: *Parser
    ) !Expression {
        const float_token: Token = try self.expect(.Float);
        if (float_token.val) |val| {
            const parsed: f64 = parseFloat(f64, val) catch {
                self.err_pos = &self.token_stream[self.cursor].start;
                return NeneErr.ParseFloatErr;
            };
            return Expression{ .FloatLiteral = parsed };
        }
        else {
            self.err_pos = &self.token_stream[self.cursor].start;
            return NeneErr.NoValueErr;
        }
    }

    pub fn parseIntegerLiteral(
        self: *Parser
    ) !Expression {
        const int_token: Token = try self.expect(.Number);
        if (int_token.val) |val| {
            const parsed: f64 = parseInt(i64, val, 10) catch {
                self.err_pos = &self.token_stream[self.cursor].start;
                return NeneErr.ParseIntErr;
            };
            return Expression{ .IntegerLiteral = parsed };
        }
        else {
            self.err_pos = &self.token_stream[self.cursor].start;
            return NeneErr.NoValueErr;
        }
    }

    pub fn parseBoolLiteral(
        self: *Parser
    ) !Expression {
        const peeked: Token = try self.peekN(0);
        if (peeked.token_type == .TrueKeyword){
            return Expression{ .BoolLiteral = true };
        }
        else if (peeked.token_type == .FalseKeyword){
            return Expression{ .BoolLiteral = false };
        }
        else {
            self.err_pos = self.token_stream[self.cursor].start;
            return NeneErr.UnexpectedTokenErr;
        }
    }

    pub fn parseStringLiteral(
        self: *Parser
    ) !Expression {
        const string_token: Token = try self.expect(.UserString);
        if (string_token.val) |val| {
            const literal: [*:0]const u8 = cloneSlice(
                val,
                self.allocator
            ) catch {
                self.err_pos = &string_token.start;
                return NeneErr.AllocErr;
            };
            errdefer self.allocator.free(std.mem.span(literal));
            return Expression{ .StringLiteral = literal };
        }
        else {
            self.err_pos = &self.token_stream[self.cursor].start;
            return NeneErr.NoValueErr;
        }
    }

    pub fn parseIdentExpression(
        self: *Parser
    ) !Expression {
        const peeked: Token = try self.peekN(0);
        const next: Token = try self.peekN(1);
        if (peeked.token_type == .UserIdent and
            next.token_type == .OpenBracket)
        {
            return (try self.parseFunctionCall());
        }
        else if (peeked.token_type == .UserIdent and
            next.token_type != .OpenBracket)
        {
            return (try self.parseVarAccess());
        }
        else {
            self.err_pos = peeked.start;
            return NeneErr.UnexpectedTokenErr;
        }
    }

    pub fn parseVarAccess(
        self: *Parser
    ) !Expression {
        const ident: Token = try self.expect(.UserIdent);
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

    pub fn parseFunctionCall(
        self: *Parser
    ) !Expression {
        const fn_name: Token = try self.expect(.UserIdent);
        _ = try self.expect(.OpenBracket);
        var expressions: ArrayList(Expression) = ArrayList(Expression)
            .init(self.allocator);
        errdefer {

        }
    }

    pub fn parseBinaryExpression(
        self: *Parser
    ) !Expression {
        _ = try self.expect(.OpenBracket);
        const left = self.allocator.create(Expression);
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
                self.err_pos = &self.token_stream[self.cursor].start;
                return NeneErr.UnexpectedTokenErr;
            }
        };
        const right = self.allocator.create(Expression);
        right.* = try self.parseExpression();
        errdefer self.allocator.destroy(right);
        _ = try self.expect(.CloseBracket);
        const bin_expr: BinaryExpression = BinaryExpression{
            .left = left,
            .right = right,
            .operator = operator
        };
        return Expression{ .BinaryExpression = bin_expr };
    }

    pub fn parseCaseBlock(
        self: *Parser
    ) !Expression {
        _ = try self.expect(.VibeKeyword);
        const expr: Expression = try self.parseExpression();
        var cases: ArrayList(CasePair) = ArrayList(CasePair)
            .init(self.allocator);
        errdefer {
            for (cases.items) |item| {
                item.deinit(self.allocator);
            }
            cases.deinit();
        }
        while ((try self.peekN(0)).token_type != .FinKeyWord){
            const literal: Expression = try self.parseLiteral();
            _ = try self.expect(.CaseOperator);
            const result: Expression = try self.parseExpression();
            // create pair.
        }
        _ = try self.expect(.FinKeyword);
        const case_block: CaseBlock = CaseBlock {
        };
        return Expression{ .CaseBlock = case_block };
    }
};
