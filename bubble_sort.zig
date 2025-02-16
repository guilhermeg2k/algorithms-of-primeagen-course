const std = @import("std");

const expect = std.testing.expect;

fn bubble_sort(array: []i32) void {
    for (array, 0..) |_, i| {
        var j: usize = 0;
        while (j < array.len - 1 - i) : (j += 1) {
            if (array[j] > array[j + 1]) {
                const tmp = array[j];
                array[j] = array[j + 1];
                array[j + 1] = tmp;
            }
        }
    }
}

test "Bubble Sort" {
    var arr = [_]i32{ 1, 10, 2, 6, 4, 3, 7, 9, 9, 8 };
    const expected = [_]i32{ 1, 2, 3, 4, 6, 7, 8, 9, 9, 10 };
    _ = bubble_sort(&arr);

    for (arr, 0..) |v, i| {
        try expect(v == expected[i]);
    }
}
