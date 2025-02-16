const std = @import("std");
const q = @import("queue.zig");

const I32BTree = BTree(i32);
const I32Array = std.ArrayList(i32);
const BTreeQueue = q.Queue(*I32BTree);

const testing = std.testing;

fn BTree(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        left: ?*Self = null,
        right: ?*Self = null,
    };
}

fn bfs(tree: *const I32BTree, search: i32) bool {
    const queue = BTreeQueue.init(std.testing.allocator);
    try queue.enqueue(&tree);

    if (tree.value == search) return true;

    while (queue.len != 0) {
        const curr = queue.deque();

        if (curr.left.?.value == search || curr.right.?.value) return true;

        try queue.enqueue(curr.left);
        try queue.enqueue(curr.right);
    }

    return false;
}

test "BTree" {
    var node1: I32BTree = .{ .value = 8 };
    var node2: I32BTree = .{ .value = 9 };
    var node3: I32BTree = .{ .value = 6, .left = &node1, .right = &node2 };
    var node4: I32BTree = .{ .value = 7 };
    var node5: I32BTree = .{ .value = 5, .left = &node4 };
    const root: I32BTree = .{ .value = 4, .left = &node5, .right = &node3 };

    const res = bfs(&root, 9);
    try testing.expect(res == true);
}
