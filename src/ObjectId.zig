const std = @import("std");

const ObjectId = @This();

const BSONError = @import("Globals.zig").BSONError;

const ByteReader = std.io.FixedBufferStream([]const u8).Reader;

const ByteWriter = std.io.FixedBufferStream([]const u8).Writer;

//references:
// https://www.npmjs.com/package/bson-objectid?activeTab=code
// https://www.mongodb.com/docs/manual/reference/method/ObjectId/
// https://github.com/mongodb/mongo-java-driver/blob/master/bson/src/main/org/bson/types/ObjectId.java#L442

// var prng = std.rand.DefaultPrng.init(500);
var prng = std.rand.DefaultPrng.init(blk: {
    var seed: u64 = undefined;
    std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    break :blk seed;
});

var MACHINE_ID: ?u24 = null;

fn getMachineId() u24 {
    if (MACHINE_ID == null) {
        std.log.info("Instantiating MACHINE ID\n", .{});
        MACHINE_ID = rand.int(u24);
    }
    return MACHINE_ID.?;
}

var PID: ?u16 = null;
/// Gets process id
fn getPid() u16 {
    if (PID == null) {
        std.log.info("Instantiating PID\n", .{});
        PID = rand.int(u16);
    }
    return PID.?;
}

var COUNTER: ?u24 = null;

fn getCounter() u24 {
    if (COUNTER == null) {
        std.log.info("Intantiating counter", .{});
        // COUNTER = rand.int(u24);

        COUNTER = rand.intRangeLessThan(u24, 0, 0xffffff);
    }
    COUNTER = (COUNTER.? + 1) % 0xFFFFFF;
    return COUNTER.?;
}

const rand = std.crypto.random;
// const rand = prng.random();

/// new up an instance of Object Id.
pub fn new() ObjectId {
    return .{
        .timestamp = std.time.timestamp(),
        .machineId = getMachineId(),
        .pid = getPid(),
        .counter = getCounter(),
    };
}

timestamp: i64, //time in seconds since UNIX epoch (4 bytes) in BE
machineId: u24, // 3 byte random
pid: u16, // 2 byte random
counter: u24, //3 byte counter in BE

/// toHex - 24 characters hexadecimal representation of the objectid
pub fn toHex(self: *const ObjectId) []const u8 {
    var buffer: [24]u8 = undefined;
    const buf = buffer[0..];
    const formatted = std.fmt.bufPrint(buf, "{x}{x:0>6}{x:0>4}{x:0>6}", .{ self.timestamp, self.machineId, self.pid, self.counter }) catch unreachable;
    return formatted;
}

pub fn encode(self: *const ObjectId, writer: ByteWriter) BSONError!void {
    try writer.writeByte(int3(self.timestamp));
    try writer.writeByte(int2(self.timestamp));
    try writer.writeByte(int1(self.timestamp));
    try writer.writeByte(int0(self.timestamp));

    try writer.writeByte(int2(self.machineId));
    try writer.writeByte(int1(self.machineId));
    try writer.writeByte(int0(self.machineId));

    try writer.writeByte(short1(self.pid));
    try writer.writeByte(short0(self.pid));

    try writer.writeByte(int2(self.counter));
    try writer.writeByte(int1(self.counter));
    try writer.writeByte(int0(self.counter));
}

pub fn decode(reader: ByteReader) BSONError!ObjectId {
    const ts = makeInt(try reader.readByte(), try reader.readByte(), try reader.readByte(), try reader.readByte());
    const machineId: u24 = @intCast(makeInt(0, try reader.readByte(), try reader.readByte(), try reader.readByte()));
    const pid = makeShort(try reader.readByte(), try reader.readByte());
    const counter: u24 = @intCast(makeInt(0, try reader.readByte(), try reader.readByte(), try reader.readByte()));
    return .{ .timestamp = ts, .machineId = machineId, .pid = pid, .counter = counter };
}

// private methods
pub fn len(_: *const ObjectId) i32 {
    //one for tag and 12 bytes for backing fields
    return 13;
}
fn makeInt(b3: u32, b2: u24, b1: u16, b0: u8) u32 {
    return (((b3) << 24) |
        ((b2 & 0xff) << 16) |
        ((b1 & 0xff) << 8) |
        ((b0 & 0xff)));
}

fn makeShort(b1: u16, b0: u8) u16 {
    return (((b1 & 0xff) << 8) | ((b0 & 0xff)));
}

fn int3(x: u32) u8 {
    return @truncate(x >> 24);
}

fn int2(x: u32) u8 {
    return @truncate(x >> 16);
}

fn int1(x: u32) u8 {
    return @truncate(x >> 8);
}

fn int0(x: u32) u8 {
    return @truncate(x);
}

fn short1(x: u16) u8 {
    return @truncate(x >> 8);
}

fn short0(x: u16) u8 {
    return @truncate(x);
}
