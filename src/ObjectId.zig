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

const rand = std.crypto.random;
pub const TS = std.time.timestamp();

pub const ObjectIdOptions = struct {
    pub fn Default() ObjectIdOptions {
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

timestamp: i64, //time in seconds since epoch
random1: u24,
random2: u16,
counter: u24,

pub fn toHex(self: *const ObjectId) []const u8 {
    _ = self;
    return "to hex called";
}
