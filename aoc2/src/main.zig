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
        // get all the values on the line
        var line_items = std.mem.tokenizeScalar(u8, fixed_line, ' ');
        var levels = std.ArrayList(i64).init(allocator);
        defer levels.deinit();
        while (line_items.next()) |item| {
            try levels.append(try std.fmt.parseInt(i64, item, 10));
        }
        const report = Report{ .levels = levels.items };
        std.debug.print("Report: {any} {any}\n", .{ report.levels, report.getLevelType() });
        if (!report.isSafe()) {
            unsafe_reports += 1;
        }
        total_reports += 1;
        //levels.deinit();
    }
    std.debug.print("Total reports: {}\tUnsafe: {}\tSafe: {}\n", .{ total_reports, unsafe_reports, total_reports - unsafe_reports });
}

pub fn contains(comptime T: type, haystack: []T, needle: T) bool {
    for (haystack) |item| {
        if (item == needle) {
            return true;
        }
    }
    // std.debug.print("DEBUG: {} not in {any}\t", .{ needle, haystack });
    return false;
}

const LevelType = union(enum) {
    Safe,
    UnsafeIncrease: u64,
    UnsafeDecrease: u64,
    UnsafeNoChange: u64,
    UnsafeRange: u64,
    UnsafeNotEnoughLevels,
};

const Report = struct {
    levels: []i64,

    const Self = @This();

    pub fn isSafe(self: *const Self) bool {
        return try self.getLevelType() == .Safe;
    }

    pub fn getLevelType(self: *const Self) !LevelType {
        return Self.levelTypeOfSlice(@TypeOf(self.levels[0]), self.levels);
    }

    pub fn levelTypeOfSlice(comptime T: type, levels: []const T) !LevelType {
        var last_value: ?i64 = null;
        var is_increasing: ?bool = null;
        for (levels, 0..) |level, i| {
            // Set the last value to compare if we are the first
            if (last_value == null) {
                last_value = level;
                continue;
            }
            // Get the difference in the levels, negative = increasing level.
            const diff: i64 = last_value.? - level;
            last_value = level;
            if (diff == 0) {
                return LevelType{ .UnsafeNoChange = i };
            }
            if (is_increasing == null) {
                // An increasing level will have a negative value and decreasing will be negative.
                is_increasing = diff < 0;
            }
            // The levels are either all increasing or all decreasing.
            if (diff < 0 and !is_increasing.?) {
                return LevelType{ .UnsafeDecrease = i };
            } else if (diff > 0 and is_increasing.?) {
                return LevelType{ .UnsafeIncrease = i };
            }
            // Any two adjacent levels differ by at least one and at most three.
            if (!contains(u64, @constCast(&[_]u64{ 1, 2, 3 }), @abs(diff))) {
                return LevelType{ .UnsafeRange = i };
            }
        }
        // Something went wrong if we couldn't assign these variables.
        if (is_increasing == null or last_value == null) {
            return LevelType.UnsafeNotEnoughLevels;
        }
        // We made it, winner winner chicken dinner!
        return LevelType.Safe;
    }
};
