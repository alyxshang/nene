// NENE by Alyx Shang.
// Licensed under the FSL v1.

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Token = @import("lexer.zig").Token;
const NeneErr = @import("err.zig").NeneErr;
const Position = @import("pos.zig").Position;
const TokenType = @import("lexer.zig").TokenType;

pub const FieldPair = struct {
    name: [*:0]const u8,
    data_type: [*:0]const u8,

    pub fn deinit(
        self: *FieldPair,
        allocator: Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        allocator.free(std.mem.span(self.data_type));
    }
};

pub const BlockStatement = union(enum) {
    Comment,
    ImportStatement: struct {
        entity: [*:0]const u8,
        location: [*:0]const u8,
    },
    FunctionDefinition: struct {
        is_async: bool,
        is_public: bool,
        name: [*:0]const u8,
        arguments: ArrayList(FieldPair),
        expressions: ArrayList(Expression)
    },
    TestingDefinition: struct {
        description: [*:0]const u8,
        expressions: ArrayList(Expression)
    },
    StructureDefinition: struct {
        is_public: bool,
        name: [*:0]const u8,
        fields: ArrayList(FieldPair)
    },

    pub fn deinit(
        self: *BlockStatement,
        allocator: Allocator
    ) void {
        switch (self.*){
            .Comment => {},
            .ImportStatement => |i| {
                allocator.free(std.mem.span(i.entity));
                allocator.free(std.mem.span(i.location));
            },
            .FunctionDefinition => |fd| {
                allocator.free(std.mem.span(fd.name));
                for (fd.arguments.items) |item| {
                    item.deinit(allocator);
                }
                fd.arguments.deinit();
                for (fd.expressions.items) |item| {
                    item.deinit(allocator);
                }
                fd.expressions.deinit();
            },
            .TestingDefinition => |td| {
                allocator.free(std.mem.span(td.description)); 
                for (td.expressions.items) |item| {
                    item.deinit(allocator);
                }
                td.expressions.deinit();
            },
            .StructureDefinition => |sd| {
                allocator.free(std.mem.span(sd.name));
                for (sd.fields.items) |item| {
                    item.deinit(allocator);
                }
                sd.fields.deinit();
            },
        }
    }
};

pub const InlineBlock = union(enum) {
    CaseBlock: struct {
        condition: *const Expression,
        cases: ArrayList(CaseMapping)
    },
    ExternCall: struct {
        entity: [*:0]const u8,
        location: [*:0]const u8,
        arguments: *const ArrayList(Expression)
    },
    FunctionCall: struct {
        name: [*:0]const u8,
        arguments: *const ArrayList(Expression)
    },
    StructInitalization: struct {
        name: [*:0]const u8,
        arguments: *const ArrayList(Expression)
    },
};

pub const Parser = struct {
    cursor: u64,
    err_pos: ?Position,
    allocator: Allocator,
    token_stream: *const ArrayList(Token),

    pub fn init(
        allocator: Allocator,
        token_stream: *const ArrayList(Token)
    ) Parser {
        return Parser {
            .cursor = 0,
            .err_post = null,
            .allocator = allocator,
            .token_stream = token_stream
        };
    }

    pub fn isDone(
        self: *Parser
    ) bool {
        return self.cursor == self.token_stream.len;
    }

    pub fn advance(
        self: *Parser
    ) void {
        self.cursor = self.cursor + 1;
    }

    pub fn peekN(
        self: *Parser,
        n: u64 
    ) !Token {
        const new_pos = self.cursor + n;
        if (new_pos <= self.token_stream.len){
            return self.token_stream.items[self.cursor];
        }
        else {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.UnexepectedTokenStreamEnd;
        }
    }

    pub fn expect(
        self: *Parser,
        expected: TokenType
    ) !Token {
        if (self.cursor <= self.token_stream.len){
            const fetched = self.token_stream.items[self.cursor];
            if (fetched.token_type == expected){
                self.advance();
                return fetched;
            }
            else {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexepectedToken;
            }
        }
        else {
            self.err_pos = self.token_stream.items[self.cursor].start;
            return NeneErr.UnexepectedTokenStreamEnd;
        }
    }

    pub fn parse(
        self: *Parser
    ) !ArrayList(BlockStatement) {
        var result: ArrayList(BlockStatement) = ArrayList(BlockStatement)
            .init(self.allocator);
        errdefer {
            for (result.items) |item| {
                item.deinit(self.allocator);
            }
            result.deinit();
        }
        while (!self.isDone()){
            result.append(try self.parseBlockStatement()) catch {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.AllocErr;
            };
        }
        return result;
    }
    pub fn parseBlockStatement(
        self: *Parser
    ) !BlockStatement {
        const peeked: Token = try self.peekN(0);
        switch (peeked.token_type){
            .Comment => return .Comment, 
            .BagKeyword => return (try self.parseBag()),
            .InpsoKeyword => return (try self.parseInspo()),
            .FunkyKeyword => return (try self.parseFunction()), 
            .SlayKeyword => return (try self.parsePublicEntity()),
            .RehearsalKeyword => return (try self.parseRehearsal()),
            .GirlwaitKeyword => return (try self.parseAsyncFunction()),
            _ => {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedToken;
            }
        }
    }

    pub fn parseInspo(
        self: *Parser
    ) !BlockStatement {
        _ = try self.expect(.InspoKeyword);
        const entity = try self.expect(.UserString);
        _ = try self.expect(.FromKeyword);
        const location = try self.expect(.UserString);
        if (entity.value) |e_val| {
            if (location.value) |l_val| {
                const cloned_e_val: [*:0]const u8 = self.allocator.dupeZ(
                    u8,
                    std.mem.span(e_val)
                ) catch {
                    self.err_pos = entity.start;
                    return NeneErr.NoValueErr;
                };
                errdefer self.allocator.free(std.mem.span(cloned_e_val));
                const cloned_l_val: [*:0]const u8 = self.allocator.dupeZ(
                    u8,
                    std.mem.span(l_val)
                ) catch {
                    self.err_pos = location.start;
                    return NeneErr.NoValueErr;
                };
                errdefer self.allocator.free(std.mem.span(cloned_l_val));
                return BlockStatement{
                    .ImportStatement = .{
                        .entity = cloned_e_val,
                        .location = cloned_l_val
                    }
                };
            }
            else {
                self.err_pos = location.start;
                return NeneErr.NoValueErr;
            }
        }
        else {
            self.err_pos = entity.start;
            return NeneErr.NoValueErr;
        }
    }

    pub fn parseBag(
        self: *Parser,
        is_public: bool
    ) !BlockStatement {
        _ = try self.expect(.BagKeyword);
        const name: Token = try self.expect(.UserIdent);
        var fields: ArrayList(FieldPair) = ArrayList(FieldPair)
            .init(self.allocator);
        errdefer {
            for (fields.items) |item| {
                item.deinit(self.allocator);
            }
            fields.deinit();
        }
        while ((try self.peekN(0)).token_type != .FinKeyword){
            const field_name_token: Token = try self.expect(.UserIdent);
            const field_data_type_token: Token = try self.expect(.UserIdent);
            if (field_name_token.value) |fn_val| {
                if (field_data_type_token.value) |fdt_val| {
                    const cloned_fn_val: [*:0]const u8 = self.allocator.dupeZ(
                        u8,
                        std.mem.span(fn_val)
                    ) catch {
                        self.err_pos = field_name_token.start;
                        return NeneErr.NoValueErr;
                    };
                    errdefer self.allocator.free(std.mem.span(cloned_fn_val));
                    const cloned_fdt_val: [*:0]const u8 = self.allocator.dupeZ(
                        u8,
                        std.mem.span(fdt_val)
                    ) catch {
                        self.err_pos = field_data_type_token.start;
                        return NeneErr.NoValueErr;
                    };
                    errdefer self.allocator.free(std.mem.span(cloned_fdt_val));
                    const pair = FieldPair {
                        .name = cloned_fn_val,
                        .data_type = cloned_fdt_val
                    };
                    fields.append(pair) catch {
                        self.err_pos = field_data_type_token.end;
                        return NeneErr.NoValueErr;
                    };
                }
                else {
                    self.err_pos = field_data_type_token.start;
                    return NeneErr.NoValueErr;
                }
            }
            else {
                self.err_pos = field_name_token.start;
                return NeneErr.NoValueErr;
            }
        }
        _ = try self.expect(.FinKeyword);
        const cloned_name_val: [*:0]const u8 = self.allocator.dupeZ(
            u8,
            std.mem.span(name)
        ) catch {
            self.err_pos = name.start;
            return NeneErr.NoValueErr;
        };
        errdefer self.allocator.free(std.mem.span(cloned_name_val));
        return BlockStatement{
            .StructureDefinition{
                .is_public = is_public,
                .name = cloned_name_val
            }
        };
    }

    pub fn parseSlay(
        self: *Parser
    ) !BlockStatement {
        _ = try self.expect(.SlayKeyword);
        const peeked = try self.peekN(0);
        switch (peeked.token_type){
            .Bag => return (try self.parseBag(true)),
            .Funky => return (try self.parseFunky(true, false)),
            _ => {
                self.err_pos = self.token_stream.items[self.cursor].start;
                return NeneErr.UnexpectedToken;
            }
        }
    }

    pub fn parseFunky(
        self: *Parser,
        is_public: bool,
        is_async: bool
    ) !BlockStatement {
        _ = try self.expect(.FunkyKeyword);
        const name: Token = try self.expect(.UserIdent);
        _ = try self.expect(.OpenBracket);
        var fields: ArrayList(FieldPair) = ArrayList(FieldPair)
            .init(self.allocator);
        errdefer {
            for (fields.items) |item| {
                item.deinit(self.allocator);
            }
            fields.deinit();
        }
        while ((try self.peekN(0)).token_type != .CloseBracket){
            if ((try self.peekN(0)).token_type != .CloseBracket){
                _ = try self.expect(.Comma);
            }
            const field_name_token: Token = try self.expect(.UserIdent);
            const field_data_type_token: Token = try self.expect(.UserIdent);
            if (field_name_token.value) |fn_val| {
                if (field_data_type_token.value) |fdt_val| {
                    const cloned_fn_val: [*:0]const u8 = self.allocator.dupeZ(
                        u8,
                        std.mem.span(fn_val)
                    ) catch {
                        self.err_pos = field_name_token.start;
                        return NeneErr.NoValueErr;
                    };
                    errdefer self.allocator.free(std.mem.span(cloned_fn_val));
                    const cloned_fdt_val: [*:0]const u8 = self.allocator.dupeZ(
                        u8,
                        std.mem.span(fdt_val)
                    ) catch {
                        self.err_pos = field_data_type_token.start;
                        return NeneErr.NoValueErr;
                    };
                    errdefer self.allocator.free(std.mem.span(cloned_fdt_val));
                    const pair = FieldPair {
                        .name = cloned_fn_val,
                        .data_type = cloned_fdt_val
                    };
                    fields.append(pair) catch {
                        self.err_pos = field_data_type_token.end;
                        return NeneErr.NoValueErr;
                    };
                }
                else {
                    self.err_pos = field_data_type_token.start;
                    return NeneErr.NoValueErr;
                }
            }
        }
        _ = try self.expect(.OpenBracket);
        while ((try self.peekN(0)).token_type != .FinKeyword){
            const expr: Expression = try self.parseExpression();

        }
        _ = try self.expect(.FinKeyword);
    }
};
