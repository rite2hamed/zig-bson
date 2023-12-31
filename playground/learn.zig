const std = @import("std");

pub fn main() !void {
    const x: u24 = 15;
    const maxValue = std.math.maxInt(u24);
    std.debug.print("{d} - {}\n", .{ x, maxValue });
    std.debug.print("0x{x:0>2}\n", .{x});

    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();

    // const alloc = arena.allocator();
    // var hexTable = std.ArrayList([]const u8).init(alloc);
    // var n: usize = 0;
    var hexan: [256][2]u8 = undefined;
    for (&hexan, 0..) |*hex, i| {
        const buff = hex[0..];
        _ = try std.fmt.bufPrint(buff, "{x:0>2}", .{i});
        std.debug.print("{s}\n", .{buff});
    }
    std.debug.print("255th element {s}\n", .{hexan[255]});
    // while (n < 256) : (n += 1) {
    // const buf = try alloc.alloc(u8, 3);
    // var buffer: [3]u8 = undefined;
    // const buf = buffer[0..];
    // const formatted = try std.fmt.bufPrint(buf, "{x:0>2}", .{n});
    // std.debug.print("{s}\n", .{formatted});
    // try hexTable.append(formatted);
    // w.print("{x:0>2}", n);
    // }

    // std.debug.print("{any}\n", .{hexTable.items});
    // std.debug.print("{d}\n", .{hexTable.items.len});
}
