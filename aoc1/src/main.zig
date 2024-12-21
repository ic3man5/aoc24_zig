const std = @import("std");

pub fn main() !void {
    // Heap allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        if (status != .ok) {
            @panic(("deinit gpa failed!"));
        }
    }
    // Parse the file
    var left = std.ArrayList(i64).init(allocator);
    defer left.deinit();
    var right = std.ArrayList(i64).init(allocator);
    defer right.deinit();
    // Split the file by newlines
    const input = @embedFile("input.txt");
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    // Add the numbers to the lists
    while (lines.next()) |line| {
        // we need to strip the carriage return from the end of the line
        const fixed_line = std.mem.trimRight(u8, line, "\r");
        var number_list = std.mem.tokenizeScalar(u8, fixed_line, ' ');
        if (number_list.peek() == null) {
            continue;
        }
        const left_number = number_list.next().?;
        const right_number = number_list.next().?;
        //std.debug.print("'{s}' '{s}'\n", .{ left_number, right_number });
        try left.append(try std.fmt.parseInt(i64, left_number, 10));
        try right.append(try std.fmt.parseInt(i64, right_number, 10));
    }
    // print the length of both
    std.debug.print(
        "{} {}\n",
        .{ left.items.len, right.items.len },
    );
    // Check to make sure left and right are the same length
    if (left.items.len != right.items.len) {
        @panic("left and right items are not synced!");
    }
    // Sort both left and right
    std.mem.sort(i64, left.items, {}, comptime std.sort.asc(i64));
    std.mem.sort(i64, right.items, {}, comptime std.sort.asc(i64));

    var total_distance: u64 = 0;
    for (left.items, right.items) |left_num, right_num| {
        total_distance += @abs(left_num - right_num);
    }
    std.debug.print("Total Distance: {}", .{total_distance});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "convert string to int" {
    const value = try std.fmt.parseInt(u64, "145752", 10);
    try std.testing.expect(value == 14575);
}
