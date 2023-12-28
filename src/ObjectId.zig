const std = @import("std");

const ObjectId = @This();

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
        COUNTER = rand.int(u24);
    }
    COUNTER = (COUNTER.? + 1) % 0xFFFFFF;
    return COUNTER.?;
}

const rand = std.crypto.random;

pub const ObjectIdOptions = struct {
    pub fn Default() ObjectIdOptions {
        std.debug.print("MACHINE-ID = {}\n", .{getMachineId()});
        std.debug.print("PID-ID = {}\n", .{getPid()});
        std.debug.print("COUNTER = {}\n", .{getCounter()});

        std.debug.print("MACHINE-ID = {}\n", .{getMachineId()});
        std.debug.print("PID-ID = {}\n", .{getPid()});
        std.debug.print("COUNTER = {}\n", .{getCounter()});

        return .{
            .timestamp = std.time.timestamp(),
            .random1 = rand.int(u32),
            .random2 = rand.int(u16),
            .counter = 1,
        };
    }
    timestamp: i64,
    random1: u32,
    random2: u16,
    counter: u32,
};

timestamp: i64, //time in seconds since UNIX epoch (4 bytes)
random1: u24, // 3 byte random
random2: u16, // 2 byte random
counter: u24, //3 byte counter

pub fn toHex(self: *const ObjectId) []const u8 {
    _ = self;
    return "to hex called";
}
