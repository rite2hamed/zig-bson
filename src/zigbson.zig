const std = @import("std");

//Allocator alias
const Allocator = std.mem.Allocator;

pub const ObjectId = @import("ObjectId.zig");

//End Of Object
const EOO = 0x00;
const testing = std.testing;

pub fn main() !void {
    std.debug.print("Salaam world!\n", .{});

    const op = ObjectId.new();
    // const op = ObjectId.TS;
    std.debug.print("Options = {any}\n", .{op});
    std.time.sleep(2 * std.time.ns_per_s);
    const op2 = ObjectId.new();
    std.debug.print("Options = {any}\n", .{op2});
    std.debug.print("op= {s}\n", .{op.toHex()});
    std.debug.print("op2={s}\n", .{op2.toHex()});
}

test "instantiate object id" {
    const oid = ObjectId{ .timestamp = 1, .counter = 1, .random1 = 1, .random2 = 2 };
    std.debug.print("{any}\n", .{oid});
    const e: []const u8 = "to hex called";
    try testing.expectEqual(e, oid.toHex());
}

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
