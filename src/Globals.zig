const std = @import("std");

const BSONDocument = @import("BsonDocument.zig");
const BSONBinary = @import("BsonBinary.zig");
const ObjectId = @import("ObjectId.zig");
const BSONRegex = @import("BsonRegex.zig");

const ByteReader = std.io.FixedBufferStream([]const u8).Reader;
const ByteWriter = std.io.FixedBufferStream([]const u8).Writer;

//Allocator alias
const Allocator = std.mem.Allocator;

//End Of Object
pub const EOO: u8 = 0x00;
//boolean false
pub const FALSE: u8 = 0x00;
//boolean true
pub const TRUE: u8 = 0x01;

// error set
pub const BSONError = error{ EndOfStream, OutOfMemory, StreamTooLong, NoSpaceLeft };

pub const BSONElement = enum(u8) {
    double = 0x01,
    string = 0x02,
    embeded_doc = 0x03,
    array = 0x04,
    binary = 0x05,
    undefined = 0x06, //deprecated
    oid = 0x07,
    boolean = 0x08,
    datetime_utc = 0x09,
    null = 0x0A,
    regex = 0x0B,
    db_pointer = 0x0C,
    js_code = 0x0D,
    symbol = 0x0E,
    js_code_ws = 0x0F,
    int32 = 0x10,
    uint64 = 0x11,
    int64 = 0x12,
    decimal128 = 0x13,
    min_key = 0xff,
    max_key = 0x7F,
};

pub const BSONVariant = union(BSONElement) {
    double: f64,
    string: []const u8,
    embeded_doc: BSONDocument,
    array: BSONDocument,
    binary: BSONBinary,
    undefined, //deprecated
    oid: ObjectId,
    boolean: bool,
    datetime_utc: i64,
    null: void,
    regex: BSONRegex,
    db_pointer, //deprecated
    js_code: []const u8,
    symbol, //deprecated
    js_code_ws,
    int32: i32,
    uint64: u64,
    int64: i64,
    decimal128: f128,
    min_key,
    max_key,

    /// returns the length of the BSON variant
    pub fn len(self: *const BSONVariant) i32 {
        return switch (self.*) {
            .string => |value| {
                const l: i32 = @intCast(value.len);
                //tag(1) + length(4) + null sentinel(1)
                return l + 6;
            },
            .int32 => 1 + @sizeOf(i32),
            .int64, .datetime_utc, .uint64 => 1 + @sizeOf(i64),
            .double => 1 + @sizeOf(f64),
            .decimal128 => 1 + @sizeOf(f128),
            .boolean => 1 + @sizeOf(bool),
            .oid => |value| {
                return value.len();
            },
            .null => 1,
            .array, .embeded_doc => |value| {
                return value.len();
            },
            else => 0,
        };
    }

    ///decodes BsonVariant from tag and reader
    pub fn decode(alloc: Allocator, tag: u8, reader: *ByteReader) BSONError!BSONVariant {
        const e: BSONElement = @enumFromInt(tag);
        const variant = switch (e) {
            .string => try readString(reader),
            .int32 => try readInt32(reader),
            .int64 => try readInt64(reader),
            .datetime_utc => try readDateTimeUTC(reader),
            .uint64 => try readUInt64(reader),
            .double => try readDouble(reader),
            .decimal128 => try readDecimal(reader),
            .boolean => try readBoolean(reader),
            .null => BSONVariant{ .null = {} },
            .oid => try readObjectId(reader),
            .embeded_doc => try readDocument(alloc, reader),
            .array => try readArray(alloc, reader),
            else => BSONVariant{ .undefined = undefined },
        };
        return variant;
    }

    /// encodes BsonVariant
    pub fn encode(self: *BSONVariant, writer: ByteWriter) void {
        switch (self.*) {
            .string => |str| {
                const l: i32 = @intCast(str.len);
                //write len+1(for null sentinel)
                try writer.writeIntLittle(i32, l + 1);
                //write actual string bytes
                _ = try writer.write(str);
                //write sentinel terminal
                try writer.writeByte(EOO);
            },
            .int32 => |i| {
                try writer.writeIntLittle(i32, i);
            },
            .int64 => |i| {
                try writer.writeIntLittle(i64, i);
            },
            .datetime_utc => |utc| {
                try writer.writeIntLittle(i64, utc);
            },
            .uint64 => |ui| {
                try writer.writeIntLittle(u64, ui);
            },
            .double => |d| {
                const v: u64 = @bitCast(d);
                try writer.writeIntLittle(u64, v);
            },
            .decimal128 => |d| {
                const v: u128 = @bitCast(d);
                try writer.writeIntLittle(u128, v);
            },
            .boolean => |b| {
                const v = if (b) TRUE else FALSE;
                try writer.writeByte(v);
            },
            .null => {},
            .oid => |oid| {
                try oid.encode(writer);
            },
            .embeded_doc, .array => |doc| {
                try doc.encode(writer);
            },
            else => {},
        }
    }

    pub fn print(self: *const BSONVariant, indent: ?usize) void {
        switch (self.*) {
            .string => |str| std.debug.print("\"{s}\"", .{str}),
            .embeded_doc, .array => |doc| doc.print(indent),
            .int32, .int64, .datetime_utc => |i| std.debug.print("{d}", .{i}),
            .uint64 => |i| std.debug.print("{d}", .{i}),
            .oid => |oid| std.debug.print("\"{s}\"", .{oid.toHex()}),
            .boolean => |b| std.debug.print("{s}", .{if (b) "TRUE" else "FALSE"}),
            .null => |_| std.debug.print("NULL", .{}),
            .double => |d| std.debug.print("{d}", .{d}),
            else => std.debug.print("yet to be implemented", .{}),
        }
        std.debug.print(" // [{d}]", .{self.len()});
    }

    pub fn fromDouble(d: f64) BSONVariant {
        return .{ .double = d };
    }

    pub fn fromString(str: []const u8) BSONVariant {
        return .{ .string = str };
    }

    pub fn fromBsonDocument(doc: BSONDocument) BSONVariant {
        return .{ .embeded_doc = doc };
    }

    pub fn fromObjectId(oid: ObjectId) BSONVariant {
        return .{ .oid = oid };
    }

    pub fn fromBoolean(b: bool) BSONVariant {
        return .{ .boolean = b };
    }

    pub fn fromNull() BSONVariant {
        return .{ .null = {} };
    }

    pub fn fromInt32(i: i32) BSONVariant {
        return .{ .int32 = i };
    }

    pub fn fromInt64(i: i64) BSONVariant {
        return .{ .int64 = i };
    }

    pub fn fromUInt64(i: u64) BSONVariant {
        return .{ .uint64 = i };
    }

    pub fn fromDecimal128(f: f128) BSONVariant {
        return .{ .decimal128 = f };
    }

    //private methods
    fn readString(reader: *ByteReader) BSONError!BSONVariant {
        const length = try reader.readIntLittle(i32);
        var num_bytes: u64 = @intCast(length);
        const start = reader.context.pos;
        try reader.skipBytes(num_bytes, .{});
        const end = reader.context.pos - 1; //skip EOS
        const bytes = @constCast(reader.context.buffer[start..end]);
        return BSONVariant{ .string = bytes };
    }

    fn readInt32(reader: *ByteReader) BSONError!BSONVariant {
        const i = try reader.readIntLittle(i32);
        return BSONVariant{ .int32 = i };
    }

    fn readInt64(reader: *ByteReader) BSONError!BSONVariant {
        const i = try reader.readIntLittle(i64);
        return BSONVariant{ .int64 = i };
    }

    fn readDateTimeUTC(reader: *ByteReader) BSONError!BSONVariant {
        const i = try reader.readIntLittle(i64);
        return BSONVariant{ .datetime_utc = i };
    }

    fn readUInt64(reader: *ByteReader) BSONError!BSONVariant {
        const u = try reader.readIntLittle(u64);
        return BSONVariant{ .uint64 = u };
    }

    fn readDouble(reader: *ByteReader) BSONError!BSONVariant {
        const raw = try reader.readIntLittle(u64);
        const d: f64 = @bitCast(raw);
        return BSONVariant{ .double = d };
    }

    fn readDecimal(reader: *ByteReader) BSONError!BSONVariant {
        const raw = try reader.readIntLittle(u128);
        const dd: f128 = @bitCast(raw);
        return BSONVariant{ .decimal128 = dd };
    }

    fn readObjectId(reader: *ByteReader) BSONError!BSONVariant {
        const oid = try ObjectId.decode(reader);
        return BSONVariant{ .oid = oid };
    }

    fn readBoolean(reader: *ByteReader) BSONError!BSONVariant {
        const b = try reader.readByte();
        return BSONVariant{ .boolean = (b == TRUE) };
    }

    fn readDocument(alloc: Allocator, reader: *ByteReader) BSONError!BSONVariant {
        var doc = BSONDocument.init(alloc);
        doc.length += @intCast(reader.context.pos);
        try doc.decode(reader);
        return BSONVariant{ .embeded_doc = doc };
    }

    fn readArray(alloc: Allocator, reader: *ByteReader) BSONError!BSONVariant {
        var doc = BSONDocument.init(alloc);
        doc.length += @intCast(reader.context.pos);
        try doc.decode(reader);
        return BSONVariant{ .array = doc };
    }
};
