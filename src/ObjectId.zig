const std = @import("std");

const ObjectId = @This();

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
            .timestamp = std.time.Instant.now(),
            .random1 = rand.int(u32),
            .random2 = rand.int(u16),
            .counter = 1,
        };
    }
    timestamp: error{Unsupported}!std.time.Instant,
    random1: u32,
    random2: u16,
    counter: u32,
};

timestamp: u32,
random1: u32,
random2: u16,
counter: u32,

pub fn toHex(self: *const ObjectId) []const u8 {
    _ = self;
    return "to hex called";
}
