const std = @import("std");
const expect = std.testing.expect;

const I32BTree = BTree(i32);
const I32Array = std.ArrayList(i32);

fn BTree(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        left: ?*Self = null,
        right: ?*Self = null,

        fn preWalk(self: *Self, res_array: *I32Array) !void {
            try res_array.append(self.value);
            if (self.left) |l| try l.preWalk(res_array);
            if (self.right) |r| try r.preWalk(res_array);
        }

        fn inWalk(self: *Self, res_array: *I32Array) !void {
            if (self.left) |l| try l.inWalk(res_array);
            try res_array.append(self.value);
            if (self.right) |r| try r.inWalk(res_array);
        }

        fn posWalk(self: *Self, res_array: *I32Array) !void {
            if (self.left) |l| try l.posWalk(res_array);
            if (self.right) |r| try r.posWalk(res_array);
            try res_array.append(self.value);
        }
    };
}

test "DF transverse" {
    var node1: I32BTree = .{ .value = 8 };
    var node2: I32BTree = .{ .value = 9 };
    var node3: I32BTree = .{ .value = 6, .left = &node1, .right = &node2 };
    var node4: I32BTree = .{ .value = 7 };
    var node5: I32BTree = .{ .value = 5, .left = &node4 };
    var root: I32BTree = .{ .value = 4, .left = &node5, .right = &node3 };

    var res = I32Array.init(std.testing.allocator);
    defer res.deinit();
    const pre_expected: [6]i32 = .{ 4, 5, 7, 6, 8, 9 };

    try root.preWalk(&res);

    for (0..res.items.len) |i| {
        try expect(pre_expected[i] == res.items[i]);
    }

    const in_expected: [6]i32 = .{ 7, 5, 4, 8, 6, 9 };
    res.clearRetainingCapacity();
    try root.inWalk(&res);

    for (0..res.items.len) |i| {
        try expect(in_expected[i] == res.items[i]);
    }

    const pos_expected: [6]i32 = .{ 7, 5, 8, 9, 6, 4 };
    res.clearRetainingCapacity();
    try root.posWalk(&res);

    for (0..res.items.len) |i| {
        try expect(pos_expected[i] == res.items[i]);
    }
}
