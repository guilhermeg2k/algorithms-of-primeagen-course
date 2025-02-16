const std = @import("std");
const q = @import("queue.zig");

const I32BTree = BTree(i32);
const testing = std.testing;

fn BTree(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        left: ?*Self = null,
        right: ?*Self = null,
    };
}

fn compare(a: ?*const I32BTree, b: ?*const I32BTree) bool {
    if (a == null and b == null) return true;

    if (a == null or b == null) return false;

    if (a.?.value != b.?.value) return false;

    return compare(a.?.left, b.?.left) and compare(a.?.right, b.?.right);
}

test "Tree compare" {
    var node1: I32BTree = .{ .value = 8 };
    var node2: I32BTree = .{ .value = 9 };
    var node3: I32BTree = .{ .value = 6, .left = &node1, .right = &node2 };
    var node4: I32BTree = .{ .value = 7 };
    var node5: I32BTree = .{ .value = 5, .left = &node4 };
    const tree1: I32BTree = .{ .value = 4, .left = &node5, .right = &node3 };

    var node11: I32BTree = .{ .value = 9 };
    var node21: I32BTree = .{ .value = 10 };
    var node31: I32BTree = .{ .value = 6, .left = &node11, .right = &node21 };
    var node41: I32BTree = .{ .value = 7 };
    var node51: I32BTree = .{ .value = 5, .left = &node41 };
    const tree11: I32BTree = .{ .value = 4, .left = &node51, .right = &node31 };

    try testing.expect(compare(&tree1, &tree11) == false);

    try testing.expect(compare(&tree11, &tree11) == true);
    try testing.expect(compare(&tree1, &tree1) == true);
}
