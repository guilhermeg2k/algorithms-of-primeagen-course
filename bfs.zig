const std = @import("std");
const q = @import("queue.zig");

const I32BTree = BTree(i32);
const I32Array = std.ArrayList(i32);
const BTreeQueue = q.Queue(*const I32BTree);

const testing = std.testing;

fn BTree(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        left: ?*Self = null,
        right: ?*Self = null,
    };
}

fn bfs(tree: *const I32BTree, search: i32) !bool {
    if (tree.value == search) return true;

    var queue = BTreeQueue.init(std.testing.allocator);
    defer queue.deinit();
    try queue.enqueue(tree);

    while (queue.len != 0) {
        const curr = queue.deque();
        std.debug.print("{d}\n", .{curr.?.value});

        if (curr) |c| {
            if (c.left) |l| {
                if (l.value == search) return true;
                try queue.enqueue(@as(*const I32BTree, l));
            }

            if (c.right) |r| {
                if (r.value == search) return true;
                try queue.enqueue(@as(*const I32BTree, r));
            }
        }
    }

    return false;
}

test "BTree" {
    var node0: I32BTree = .{ .value = 10 };
    var node1: I32BTree = .{ .value = 8 };
    var node2: I32BTree = .{ .value = 9, .right = &node0 };
    var node3: I32BTree = .{ .value = 6, .left = &node1, .right = &node2 };
    var node4: I32BTree = .{ .value = 7 };
    var node5: I32BTree = .{ .value = 5, .left = &node4 };
    const root: I32BTree = .{ .value = 4, .left = &node5, .right = &node3 };

    const res = try bfs(&root, 10);
    try testing.expect(res == true);
}
