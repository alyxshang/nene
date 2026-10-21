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

const Expression = @import("parser.zig").Expression;

const BlockStatement = @import("parser.zig").BlockStatement;

pub const Instruction = union(enum) {
    ADD: void, // done.
    SUB: void, // done.
    DIV: void, // done.
    MUL: void, // done.
    CALL: u64,
    MODULO: void, // done.
    RETURN: void, // done.
    JUMP_FRWD: u64, 
    LOAD_CONST: u64,
    EXTERN_CALL: u64,
    COMPARE_EQ: void, // done.
    COMPARE_GT: void, // done.
    COMPARE_LT: void, // done.
    COMPARE_NEQ: void, // done.
    STORE_CONST: void,
    MODIFY_CONST: u64,
    CREATE_STRUCT: u64, 
    JUMP_BACK_IF_TRUE: u64,
    JUMP_FRWD_IF_TRUE: u64,
};

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
    scope: ArrayList(ScopeVariable),
    instructions: ArrayList(SimplifiedInstruction),
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

pub const SimplifiedInstruction = union(enum){
    Add: struct {
        left: NeneValue,
        right: NeneValue,
    },
    Subtract: struct {
        left: NeneValue,
        right: NeneValue,
    },
    Divide: struct {
        left: NeneValue,
        right: NeneValue,
    },
    Multiply: struct {
        left: NeneValue,
        right: NeneValue,
    },
    Modulo: struct {
        left: NeneValue,
        right: NeneValue,
    },
    CompareEq: struct {
        left: NeneValue,
        right: NeneValue,
    },
    CompareNeq: struct {
        left: NeneValue,
        right: NeneValue,
    }, 
    CompareLarger: struct {
        left: NeneValue,
        right: NeneValue,
    },
    CompareSmaller: struct {
        left: NeneValue,
        right: NeneValue,
    },
    Return: NeneValue,
};

pub const Compiler = struct {
    cursor: u64,
    allocator: Allocator,
    tree_nodes: ArrayList(BlockStatement),

    pub fn init(
        allocator: Allocator,
        tree_nodes: *const ArrayList(BlockStatement)
    ) Compiler {
        return Compiler {
            .cursor = 0,
            .allocator = allocator,
            .tree_nodes = tree_nodes
        };
    }

    pub fn isDone(
        self: *Compiler
    ) bool {
        return self.cursor == self.tree_nodes.items.len;
    }

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
        }
        else {
            return NeneErr.WrongNodeErr;
        }

    }

};
