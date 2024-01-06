const std = @import("std");

pub const ObjectId = @import("ObjectId.zig");
pub const BsonDocument = @import("BsonDocument.zig");

const testing = std.testing;

pub fn main() !void {
    std.debug.print("Salaam world!\n", .{});

    // const op = ObjectId.new();
    // // const op = ObjectId.TS;
    // std.debug.print("Options = {any}\n", .{op});
    // std.time.sleep(2 * std.time.ns_per_s);
    // const op2 = ObjectId.new();
    // std.debug.print("Options = {any}\n", .{op2});
    // std.debug.print("op= {s}\n", .{op.toHex()});
    // std.debug.print("op2={s}\n", .{op2.toHex()});
    const file_name = "../samples/nested-obj.bson";
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const fs = try std.fs.cwd().openFile(file_name, .{});
    defer fs.close();

    const size = (try fs.stat()).size;
    const buffer = try fs.readToEndAlloc(allocator, size);
    defer allocator.free(buffer);
    errdefer allocator.free(buffer);
    // std.debug.print("{any}\n", .{buffer});
    var doc = BsonDocument.init(allocator);
    defer doc.deinit();
    const temp: []const u8 = buffer[0..];
    var buf: std.io.FixedBufferStream([]const u8) = std.io.fixedBufferStream(temp);
    var reader = buf.reader();
    try doc.decode(&reader);
    doc.print(null);
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
