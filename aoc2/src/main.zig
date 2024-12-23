const std = @import("std");

pub fn main() !void {
    // Create the heap allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        if (status != .ok) {
            @panic("Failed to deinitialize allocator!");
        }
    }
    // Parse the file
    var reports = std.ArrayList(std.ArrayList(i64)).init(allocator);
    defer reports.deinit();
    const input = @embedFile("input.txt");
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var total_reports: u64 = 0;
    var unsafe_reports: u64 = 0;
    while (lines.next()) |line| {
        // strip return carriage if it exists
        const fixed_line = std.mem.trimRight(u8, line, "\r");
        var levels_iter = std.mem.tokenizeScalar(u8, fixed_line, ' ');
        var report = std.ArrayList(i64).init(allocator);
        defer report.deinit();
        while (levels_iter.next()) |level| {
            try report.append(try std.fmt.parseInt(i64, level, 10));
        }
        total_reports += 1;
        try reports.append(report);
        const is_safe = checkIfSafe(std.ArrayList(i64), report);
        if (!is_safe) {
            unsafe_reports += 1;
        }
        std.debug.print("{any} {} {}\n", .{ report.items, report.items.len, is_safe });
    }
    std.debug.print("Total reports: {}\tUnsafe: {}\tSafe: {}\n", .{ total_reports, unsafe_reports, total_reports - unsafe_reports });
}

pub fn checkIfSafe(comptime T: type, items: T) bool {
    var last_value = items.items[0];
    const increasing = (last_value - items.items[1]) < 0;
    for (items.items[2..]) |item| {
        const value = last_value - item;
        // The levels are either all increasing or all decreasing.
        if (increasing and value > 0) {
            return false;
        } else if (!increasing and value < 0) {
            return false;
        }
        // Any two adjacent levels differ by at least one and at most three.
        if (@abs(value) < 1 and @abs(value) > 3) {
            return false;
        }
        last_value = item;
    }
    return true;
}
