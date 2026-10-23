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

// Importing the function to clone a pointer
// to a null-terminated array of characters.
const cloneSlice = @import("utils.zig").cloneSlice;

// Importing the union of enumerations that "lists"
// all possible types of expressions in Nene source
// code.
const Expression = @import("parser.zig").Expression;

// Importing the union of enumerations that "lists"
// all possible types of block-level statements in 
// Nene source code.
const BlockStatement = @import("parser.zig").BlockStatement;

pub const NeneValue = union(enum){
    Bool: bool,
    Float: f64,
    Integer: i64,
    String: [*:0]const u8,

    pub fn deinit(
        self: *NeneValue,
        allocator: Allocator
    ) void {
        switch (self.*){
            .String => |s| allocator.free(std.mem.span(s)),
            else  => {}
        }
    }
};

pub const ModuleImport = struct {
    entity: [*:0]const u8,
    location: [*:0]const u8,

    pub fn init(
        entity: [*:0]const u8,
        location: [*:0]const u8,
    ) ModuleImport {
        return ModuleImport{
            .entity = entity,
            .location = location
        };
    }

    pub fn deinit(
        self: *ModuleImport,
        allocator: Allocator
    ) void {
        allocator.free(std.mem.span(self.entity));
        allocator.free(std.mem.span(self.location));
    }
};

pub const ScopeVariable = struct {
    name: [*:0]const u8,
    value: NeneValue,

    pub fn deinit(
        self: *ModuleImport,
        allocator: Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        self.value(allocator);
    }
};

pub const ModuleFunction = struct {
    name: [*:0]const u8,
    //scope: ArrayList(ScopeVariable),
    instructions: ArrayList(SimplifiedInstruction),

    pub fn deinit(
        self: *ModuleFunction,
        allocator: Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        for (instructions.items)
    }
};


pub const Module = struct {
    imports: ?ArrayList(ModuleImport),
    functions: ?ArrayList(ModuleFunction),

    pub fn deinit(
        self: *Module,
        allocator: Allocator
    ) void {
        if (self.imports.value) |val|{
            for (val.items) |v| {
                v.deinit(allocator);
            }
            val.deinit();
        }
        if (self.functions.value) |val| {
            for (val.items) |v| {
                v.deinit(allocator);
            }
            val.deinit();
        }
    }
};

/// A union of enumerations that emulates
/// the instruction set for the Wayob virtual
/// machine.
pub const SimplifiedInstruction = union(enum){
    Add: void,
    Divide: void,
    Modulo: void,
    Subtract: void,
    Multiply: void,
    Push: NeneValue,
    CompareEq: void,
    CompareNeq: void,
    Return: NeneValue,
    CompareLarger: void,
    CompareSmaller: void,
};

/// A structure to compile
/// an AST obtained from
/// Nene source code into
/// a set of functions each 
/// containing a set of 
/// simplified bytecode
/// instructions.
pub const Compiler = struct {
    cursor: u64,
    allocator: Allocator,
    tree_nodes: *ArrayList(BlockStatement),

    /// A function to create a new 
    /// instance of the `Compiler` 
    /// structure and return the
    /// created instance.
    pub fn init(
        allocator: Allocator,
        tree_nodes: *ArrayList(BlockStatement)
    ) Compiler {
        return Compiler {
            .cursor = 0,
            .allocator = allocator,
            .tree_nodes = tree_nodes
        };
    }

    /// A function to check if 
    /// the end of the internal
    /// stream of block statements
    /// has been reached or not.
    pub fn isDone(
        self: *Compiler
    ) bool {
        return self.cursor == self.tree_nodes.items.len;
    }

    /// A function to advance
    /// the internal cursor keeping
    /// track of the current block-level
    /// statement by one.
    pub fn advance(
        self: *Compiler
    ) void {
        self.cursor = self.cursor + 1;
    }


    pub fn compile(
        self: *Compiler
    ) !Module {
        var imports: ArrayList(ModuleImport) = ArrayList(ModuleImport)
            .init(self.allocator);
        var functions: ArrayList(ModuleFunction) = ArrayList(ModuleFunction)
            .init(self.allocator);
        errdefer {
            for (imports.items) |i|{
                i.deinit(self.allocator);
            }
            imports.deinit();
            for (functions.items) |f|{
                f.deinit(self.allocator);
            }
            functions.deinit();
        }
        while (!self.isDone()) {
            const current: BlockStatement = self.tree_nodes.items[self.cursor];
            switch (current){
                .Comment => {},
                .Import => |i| {
                    const import: ModuleImport = try self.compileImport(&i);
                    imports.append(import) catch {
                        return NeneErr.WriteErr;
                    };
                },
                .Function => |f| {
                    const function: ModuleFunction = try self.compileFunction(&f);
                    functions.append(function) catch {
                        return NeneErr.WriteErr;
                    };
                }
            }
            self.advance();
        }
        const mod = Module{
            .imports = imports,
            .functions = functions
        };
        return mod;
    }

    pub fn compileImport(
        self: *Compiler,
        import: *BlockStatement
    ) !ModuleImport {
        if (import == .Import){
            const entity_cloned: [*:0]const u8 = cloneSlice(
                import.entity,
                self.allocator
            ) catch return NeneErr.AllocErr;
            errdefer self.allocator.free(std.mem.span(entity_cloned));
            const location_cloned: [*:0]const u8 = cloneSlice(
                import.module,
                self.allocator
            ) catch return NeneErr.AllocErr;
            errdefer self.allocator.free(std.mem.span(location_cloned));
            const mod_import: ModuleImport = ModuleImport{
                .entity = entity_cloned,
                .location = location_cloned
            };
            return mod_import;
        }
        else {
            return NeneErr.WrongNodeErr;
        }
    }

    pub fn compileFunction(
        self: *Compiler,
        function: *BlockStatement
    ) !ModuleFunction {
        if (function == .Function){
            const fn_name: [*:0]const u8 = cloneSlice(
                function.name,
                self.allocator
            ) catch return NeneErr.AllocErr;
            errdefer self.allocator.free(std.mem.span(fn_name));
            var instructions: ArrayList(SimplifiedInstruction) = .empty;
            errdefer {
                for (instructions.items) |item| {
                    item.deinit(self.allocator);
                }
                instructions.deinit(self.allocator);
            }
            for (function.body.items) |item| {
                instructions.append(
                    self.allocator,
                    (try self.compileExpression(&item))
                ) catch return NeneErr.WriteErr;
            }
        }
        else {
            return NeneErr.WrongNodeErr;
        }
    }

    pub fn compileExpression(
        self: *Compiler,
        expr: *Expression
    ) !SimplifiedInstruction {
        switch (expr.*){
            .CaseBlock => return try self.compileCaseBlock(expr),
            .FunctionCall => return try self.compileFunctionCall(expr),
            .BinaryOperation => return try self.compileBinaryOperation(expr),
            else => return SimplifiedInstruction{
                .Push = try self.literalToValue(expr)
            }, 
        }
    }

    pub fn literalToValue(
        self: *Compiler,
        literal: *Expression
    ) !NeneValue {
        switch (literal.*) {
            .BoolLiteral => return try self.compileBoolLiteral(literal),
            .NumberLiteral => return try self.compileFloatLiteral(literal),
            .StringLiteral => return try self.compileStringLiteral(literal), 
            .FloatLiteral => return try self.compileIntegerLiteral(literal), 
            else => return NeneErr.WrongNodeErr
        }
    }

    pub fn compileStringLiteral(
        self: *Compiler,
        literal: *Expression
    ) !NeneValue {
        if (literal == .StringLiteral){
            const cloned: [*:0]const u8 = cloneSlice(
                literal.StringLiteral,
                self.allocator
            ) catch return NeneErr.AllocErr;
            errdefer self.allocator.free(std.mem.span(cloned));
            return NeneValue{ .StringLiteral = cloned };
        }
        else {
            return NeneErr.WrongNodeErr;
        }
    }

    pub fn compileBoolLiteral(
        self: *Compiler,
        literal: *Expression
    ) !NeneValue {
        if (literal == .BoolLitera){
            return NeneValue{ .Bool = literal.BoolLiteral };
        }
        else {
            return NeneErr.WrongNodeErr;
        }
    }

    pub fn compileIntegerLiteral(
        self: *Compiler,
        literal: *Expression
    ) !NeneValue {
        if (literal == .NumberLiteral){
            return NeneValue{ .Integer = literal.NumberLiteral };
        }
        else {
            return NeneErr.WrongNodeErr;
        }
    }

    pub fn compileFloatLiteral(
        self: *Compiler,
        literal: *Expression
    ) !NeneValue {
        if (literal == .FloatLiteral){
            return NeneValue{ .Float = literal.FloatLiteral };
        }
        else {
            return NeneErr.WrongNodeErr;
        }
    }

    pub fn compileBinaryOperation(
        self: *Compiler,
        expr: *Expression
    ) !SimplifiedInstruction {
        const left: SimplifiedInstruction = try self.compileExpression(expr.left);
        const right: SimplifiedInstruction = try self.compileExpression(expr.right);

    }
};
