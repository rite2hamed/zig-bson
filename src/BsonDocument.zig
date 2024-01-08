const std = @import("std");

const BsonVariant = @import("Globals.zig").BSONVariant;

const BSONError = @import("Globals.zig").BSONError;

const EOO = @import("Globals.zig").EOO;

const ByteReader = std.io.FixedBufferStream([]const u8).Reader;

const ByteWriter = std.io.FixedBufferStream([]const u8).Writer;

const BsonDocument = @This();

map: std.StringArrayHashMap(BsonVariant),
length: i32 = 0,

pub fn init(alloc: std.mem.Allocator) BsonDocument {
    return .{
        .map = std.StringArrayHashMap(BsonVariant).init(alloc),
    };
}

pub fn deinit(self: *BsonDocument) void {
    //loop over all they keys and free them before deiniting map itself
    var it = self.map.iterator();
    while (it.next()) |e| {
        switch (e.value_ptr.*) {
            .array, .embeded_doc => |*doc| doc.deinit(),
            else => {},
        }
    }
    self.map.deinit();
    self.* = undefined;
}

pub fn len(self: *const BsonDocument) i32 {
    var totalLen: i32 = 4; //need 4 bytes to store the size of this document
    var it = self.map.iterator();
    //loop over all the fields
    while (it.next()) |e| {
        //add up field name length
        totalLen += @intCast(e.key_ptr.*.len);
        //add 1 for null sentinel
        totalLen += 1;
        const activeField = std.meta.activeTag(e.value_ptr.*);
        totalLen += e.value_ptr.*.len();
        if (activeField == .array or activeField == .embeded_doc)
            totalLen += 1;
    }
    //for EOO
    totalLen += 1;
    return totalLen;
}

pub fn encode(self: *const BsonDocument, writer: ByteWriter) BSONError!void {
    //write document length
    try writer.writeIntLittle(i32, self.length());
    var it = self.map.iterator();
    while (it.next()) |e| {
        //write tag
        const tag: u8 = @intFromEnum(e.value_ptr.*);
        try writer.writeIntLittle(u8, tag);
        //write field name
        _ = try writer.write(e.key_ptr.*);
        //write field sentinel
        try writer.writeByte(EOO);
        //encode field value
        try e.value_ptr.*.encode(writer);
    }
    //write EOO
    try writer.writeByte(EOO);
}

pub fn decode(self: *BsonDocument, reader: *ByteReader) BSONError!void {
    //read document length
    self.length += try reader.readIntLittle(i32);
    while (reader.context.pos < self.length - 1) {
        //read tag
        const tag = try reader.readByte();
        //read field name
        const start = reader.context.pos;
        try reader.skipUntilDelimiterOrEof(EOO);
        const end = reader.context.pos - 1;
        const field = @constCast(reader.context.buffer[start..end]);
        //read variant
        const variant = try BsonVariant.decode(self.map.allocator, tag, reader);
        try self.map.put(field, variant);
    }
    const eoo = try reader.readByte(); //read EOO
    if (eoo != EOO) {
        @panic("last read byte isn't EOO");
    }
}

pub fn print(self: *const BsonDocument, indent: ?usize) void {
    std.debug.print("{s}\n", .{"{"});
    var iv = if (indent) |v| v + 2 else 2;
    for (self.map.keys(), 0..) |key, index| {
        var i: usize = 0;
        while (i < iv) : (i += 1) {
            std.debug.print(" ", .{});
        }
        const value = self.map.get(key).?;
        const tag = @tagName(value);
        const tagValue = @intFromEnum(value);
        std.debug.print("[0x{x:0>2}] ({s}) \"{s}\": ", .{ tagValue, tag, key });
        value.print(iv);
        if (index < self.map.count() - 1) {
            std.debug.print(",\n", .{});
        }
    }
    iv -= 2;
    std.debug.print("\n", .{});
    var i: usize = 0;
    while (i < iv) : (i += 1) {
        std.debug.print(" ", .{});
    }
    std.debug.print("{s} 0x{x:0>2} //EOO [{d}]\n", .{ "}", EOO, self.len() });
}

pub fn contains(self: *BsonDocument, key: []const u8) bool {
    return self.map.contains(key);
}

pub fn get(self: *BsonDocument, key: []const u8) ?BsonVariant {
    if (self.map.get(key)) |value| {
        return value;
    }
    @panic("Invalid key");
}
