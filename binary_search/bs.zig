const std = @import("std");
const math = std.math;

const expect = std.testing.expect;
const warn = std.log.warn;

fn bs_search(arr: []const i32, value: i32) isize {
    var left: usize = 0;
    var right: usize = arr.len;

    while (left != right) {
        const mid = (left + right) / 2;
        const midV = arr[mid];

        if (midV == value) return @intCast(mid);

        if (midV > value) {
            right = mid;
            continue;
        }

        left = mid + 1;
    }

    return -1;
}

test "Binary Search" {
    const arr = [_]i32{ 1, 4, 6, 7, 8, 9, 11, 34, 54, 100 };

    for (arr, 0..) |_, i| {
        const result = bs_search(&arr, arr[i]);
        try expect(result == i);
    }

    for (arr, 0..) |_, i| {
        const result = bs_search(&arr, arr[i] * 10000);
        try expect(result == -1);
    }
}
