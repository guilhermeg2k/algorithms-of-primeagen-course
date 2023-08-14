const std = @import("std");
const expect = std.testing.expect;
const math = std.math;
const warn = std.log.warn;

fn two_crystal_balls(breaks: []const bool) isize {
    if (breaks.len == 1) return switch (breaks[0]) {
        true => 0,
        else => -1,
    };

    const jmp_amnt: u32 = math.sqrt(breaks.len);
    var i: usize = 0;

    while (i < breaks.len) {
        if (breaks[i]) break;
        i += jmp_amnt;
    }

    i -= jmp_amnt;

    while (i < breaks.len) : (i += jmp_amnt) {
        if (breaks[i]) return @intCast(i);
    }

    return -1;
}

test "Two Crystal Balls" {
    const breaks = [_]bool{ false, false, false, false, false, false, true, true, true, true };

    try expect(two_crystal_balls(&breaks) == 6);
    const breaks2 = [_]bool{ false, true };
    try expect(two_crystal_balls(&breaks2) == 1);

    const breaks3 = [_]bool{true};
    try expect(two_crystal_balls(&breaks3) == 0);

    const breaks4 = [_]bool{false};
    try expect(two_crystal_balls(&breaks4) == -1);
}
