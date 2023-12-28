const std = @import("std");

pub fn main() !void {
    const x: u24 = 1;
    const maxValue = std.math.maxInt(u24);
    std.debug.print("{d} - {}\n", .{ x, maxValue });
}
