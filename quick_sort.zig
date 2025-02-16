const std = @import("std");
const expect = std.testing.expect;

fn partition(arr: []i32, lo: usize, hi: usize) usize {
    const pivot = arr[hi];
    var curr_id = lo;

    for (lo..hi + 1) |i| {
        if (arr[i] < pivot) {
            const tmp = arr[i];
            arr[i] = arr[curr_id];
            arr[curr_id] = tmp;
            curr_id += 1;
        }
    }

    arr[hi] = arr[curr_id];
    arr[curr_id] = pivot;
    const pivotId: usize = @intCast(curr_id);
    return pivotId;
}

fn qs(arr: []i32, lo: usize, hi: usize) void {
    if (lo >= hi) {
        return;
    }

    const pivot_id = partition(arr, lo, hi);

    qs(arr, lo, pivot_id - 1);
    qs(arr, pivot_id + 1, hi);
}

fn quickSort(arr: []i32) void {
    qs(arr, 0, arr.len - 1);
}

test "merge sort" {
    var arr = [_]i32{ 9, 3, 7, 4, 42, 69, 30, 500, 420, 42 };
    const sorted_arr = [_]i32{ 3, 4, 7, 9, 30, 42, 42, 69, 420, 500 };

    quickSort(&arr);

    for (0..sorted_arr.len) |i| {
        try expect(arr[i] == sorted_arr[i]);
    }
}
