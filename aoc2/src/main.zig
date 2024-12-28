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
    Safe: bool,
    UnsafeIncrease: u64,
    UnsafeDecrease: u64,
    UnsafeNoChange: u64,
    UnsafeRange: u64,
    UnsafeChange,
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

    pub fn isLevelSafe(comptime T: type, first: T, second: T, index: u64) LevelType {
        var is_increasing: bool = false;
        if (first < second) {
            is_increasing = true;
        } else if (first > second) {
            is_increasing = false;
        } else {
            return LevelType{ .UnsafeNoChange = index };
        }
        const diff = @abs(first - second);
        // Any two adjacent levels differ by at least one and at most three.
        if (!contains(u64, @constCast(&[_]u64{ 1, 2, 3 }), diff)) {
            return LevelType{ .UnsafeRange = index };
        }
        return LevelType{ .Safe = is_increasing };
    }

    pub fn levelTypeOfSlice(comptime T: type, levels: []const T) !LevelType {
        var skipped_one = false;
        var level_type: ?LevelType = null;
        var is_increasing: ?bool = null;
        // We have to use a while loop because a for loop makes i const and we can't skip
        var i: usize = 0;
        while (i < levels.len) : (i += 1) {
            if (i + 1 >= levels.len) {
                break;
            }
            level_type = Self.isLevelSafe(T, levels[i], levels[i + 1], @intCast(i));
            if (level_type.? == .Safe) {
                // We need to make sure the Increase/Decrease isn't changing
                if (is_increasing == null) {
                    is_increasing = level_type.?.Safe;
                } else if (is_increasing.? != level_type.?.Safe) {
                    level_type = LevelType.UnsafeChange;
                }
            }
            // the reactor safety systems tolerate a single bad level
            if (level_type.? != .Safe) {
                if (skipped_one) {
                    return level_type.?;
                } else {
                    skipped_one = true;
                    i += 1;
                    continue;
                }
            }
        }
        if (level_type == null) {
            return LevelType.UnsafeNotEnoughLevels;
        }
        return level_type.?;
    }
};
