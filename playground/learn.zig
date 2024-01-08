const std = @import("std");

const Person = struct {
    firstname: []const u8,
    lastname: []const u8,
    fullname: [100]u8 = undefined,

    pub fn init(firstname: []const u8, lastname: []const u8) Person {
        return .{ .firstname = firstname, .lastname = lastname };
    }

    pub fn fullName(self: *Person) []const u8 {
        const buf = self.fullname[0..]; //stack allocated slice
        std.debug.print("\n{any}|{d}\n", .{ buf, buf.len });
        const formatted = std.fmt.bufPrint(buf, "{s} {s}", .{ self.firstname, self.lastname }) catch "";
        return self.fullname[0..formatted.len];
    }
};

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
    var buffer: [32]u8 = undefined;
    const val: i64 = 1;
    const buffered = try std.fmt.bufPrint(&buffer, "{x:0>20}", .{val});
    std.debug.print("{s}\n", .{buffered});

    var hamed = Person.init("Hamed", "Mohammed");
    std.debug.print("{any}\n", .{hamed});
    std.debug.print("{s}\n", .{hamed.fullName()});
    std.debug.print("{any}\n", .{hamed});
}
