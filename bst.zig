const std = @import("std");

const expect = std.testing.expect;
const I32BTree = BSTree(i32);

fn BSTree(comptime T: type) type {
    const Node = struct {
        const Self = @This();
        value: T,
        left: ?*Self = null,
        right: ?*Self = null,

        pub fn find(self: *const Self, v: T) bool {
            if (self.value == v) return true;

            if (v < self.value) {
                if (self.left) |l| {
                    return l.find(v);
                }

                return false;
            }

            if (self.right) |r| {
                return r.find(v);
            }

            return false;
        }

        fn find_highest(self: *Self) *Self {
            if (self.right) |r| {
                return r.find_highest();
            }

            return self;
        }
    };

    return struct {
        const Self = @This();
        alloc: std.mem.Allocator,
        _root: ?*Node = null,

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{ .alloc = alloc };
        }

        pub fn deinit(self: *Self) void {
            if (self._root) |r| {
                self.destroy_node(r);
            }
        }

        pub fn find(self: *const Self, v: T) bool {
            if (self._root) |r| {
                return r.find(v);
            }
            return false;
        }

        pub fn insert(self: *Self, v: T) !void {
            if (self._root) |root| {
                if (v < root.value) {
                    if (root.left) |l| {
                        return self.insert_into_node(l, v);
                    }
                }

                if (root.right) |r| {
                    return self.insert_into_node(r, v);
                }

                return self.insert_into_node(root, v);
            }

            const node = try self.new_node(v);
            self._root = node;
        }

        pub fn delete(self: *Self, v: T) !void {
            if (self._root) |r| {
                self._root = try self.delete_from_node(r, v);
            }
        }

        fn delete_node_from_node(self: *Self, node: *Node, v: *Node) void {
            if (node.left == v) {
                self.destroy_node(node.left.?);
                node.left = null;
                return;
            }

            if (node.right == v) {
                self.destroy_node(node.right.?);
                node.right = null;
                return;
            }

            if (v.value < node.value) {
                if (node.left) |l| {
                    return self.delete_node_from_node(l, v);
                }
                return;
            }

            if (node.right) |r| {
                self.delete_node_from_node(r, v);
            }
        }

        fn delete_from_node(self: *Self, node: *Node, v: T) !?*Node {
            if (v == node.value) {
                if (node.left == null and node.right == null) {
                    self.destroy_node(node);
                    return null;
                }

                if (node.left) |l| {
                    const highest_of_left = l.find_highest();
                    node.value = highest_of_left.value;

                    if (highest_of_left.left) |hl| {
                        try self.insert_node_into_node(node, hl);
                    }

                    highest_of_left.left = null;
                    highest_of_left.right = null;
                    self.delete_node_from_node(node, highest_of_left);
                    if (node.left == highest_of_left) {
                        node.left = null;
                    }
                }
                return node;
            }

            if (v < node.value) {
                if (node.left) |l| {
                    node.left = try self.delete_from_node(l, v);
                }
            }

            if (node.right) |r| {
                node.right = try self.delete_from_node(r, v);
            }

            return node;
        }

        fn new_node(self: *const Self, v: T) !*Node {
            var node = try self.alloc.create(Node);

            node.value = v;
            node.left = null;
            node.right = null;

            return node;
        }

        fn destroy_node(self: *Self, node: *Node) void {
            if (node.left) |l| {
                self.destroy_node(l);
            }

            if (node.right) |r| {
                self.destroy_node(r);
            }

            self.alloc.destroy(node);
        }

        fn insert_into_node(self: *Self, node: *Node, v: T) !void {
            if (v < node.value) {
                if (node.left) |l| {
                    return self.insert_into_node(l, v);
                }

                const new_left_node = try self.new_node(v);
                node.left = new_left_node;
                return;
            }

            if (node.right) |r| {
                return self.insert_into_node(r, v);
            }

            const new_right_node = try self.new_node(v);
            node.right = new_right_node;
        }

        fn insert_node_into_node(self: *Self, node: *Node, v: *Node) !void {
            if (v.value < node.value) {
                if (node.left) |l| {
                    return self.insert_node_into_node(l, v);
                }

                node.left = v;
                return;
            }

            if (node.right) |r| {
                return self.insert_node_into_node(r, v);
            }
            node.right = v;
        }
    };
}

test "BSTree" {
    var bst = I32BTree.init(std.testing.allocator);
    defer bst.deinit();

    const values = [_]i32{ 10, 5, 15, 2, 7, 12, 17, 1, 3, 6, 8, 11, 13, 16, 18 };

    for (values) |value| {
        try bst.insert(value);
    }

    // Ensure all values exist before deletion
    for (values) |value| {
        try expect(bst.find(value) == true);
    }

    // // Case 1: Delete a leaf node (no children)
    // try bst.delete(3);
    // try expect(bst.find(3) == false);

    // Case 2: Delete a node with one child
    try bst.delete(2);
    try expect(bst.find(2) == false);
    try expect(bst.find(1) == true); // 1 should still be present

    // Case 3: Delete a node with two children
    try bst.delete(5);
    try expect(bst.find(5) == false);
    try expect(bst.find(6) == true);
    try expect(bst.find(7) == true);

    // Case 4: Delete the root node
    try bst.delete(10);
    try expect(bst.find(10) == false);

    // Case 5: Delete a non-existent value (should not affect the tree)
    try bst.delete(100); // 100 is not in the tree
    for (values) |value| {
        if (value != 3 and value != 2 and value != 5 and value != 10) {
            try expect(bst.find(value) == true);
        }
    }
}
