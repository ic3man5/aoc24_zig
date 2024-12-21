const std = @import("std");

pub fn countOccurrences(comptime T: type, value: T, items: []T) i64 {
    var count: i64 = 0;
    for (items) |item| {
        if (value == item) {
            count += 1;
        }
    }
    return count;
}

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
    // Sort both left and right
    std.mem.sort(i64, left.items, {}, comptime std.sort.asc(i64));
    std.mem.sort(i64, right.items, {}, comptime std.sort.asc(i64));

    var total_similarity: i64 = 0;
    for (left.items) |item| {
        total_similarity += item * countOccurrences(i64, item, right.items);
    }
    std.debug.print("Total Similarity: {}", .{total_similarity});
}
