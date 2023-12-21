const std = @import("std");

const Self = @This();

timestamp: u32,
random1: u32,
random2: u16,
counter: u32,

pub fn toHex(self: *const Self) []const u8 {
    _ = self;
    return "to hex called";
}
