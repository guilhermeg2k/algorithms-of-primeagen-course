const std = @import("std");

const expect = std.testing.expect;

const LinkedListError = error{ IndexOutOfTheBounds, ItemNotFound };

fn LinkedList(comptime T: type) type {
    const Node = struct {
        const Self = @This();
        value: T,
        next: ?*Self = null,
        prev: ?*Self = null,
    };

    return struct {
        const Self = @This();
        len: usize = 0,
        alloc: std.mem.Allocator,
        _head: ?*Node = null,
        _tail: ?*Node = null,

        fn init(alloc: std.mem.Allocator) Self {
            return .{
                .alloc = alloc,
            };
        }

        fn deinit(self: *Self) void {
            var current = self._head;
            while (current) |curr| {
                const next = curr.next;
                self.alloc.destroy(curr);
                current = next;
            }
        }

        fn getNodeAt(self: *Self, index: usize) !*Node {
            if (self.len == 0) return LinkedListError.IndexOutOfTheBounds;
            if (index > self.len - 1) return LinkedListError.IndexOutOfTheBounds;

            var current = self._head.?;

            for (0..index) |_| {
                current = current.next.?;
            }

            return current;
        }

        fn getItemNode(self: *Self, item: T) !*Node {
            var current = self._head;

            while (current) |curr| {
                if (item == curr.value) {
                    return curr;
                }
                current = curr.next;
            }

            return LinkedListError.ItemNotFound;
        }

        fn removeNode(self: *Self, node: *Node) void {
            var prev = node.prev;
            var next = node.next;

            if (node.prev) |p| {
                p.next = next;
            } else {
                self._head = next;
            }

            if (node.next) |n| {
                n.prev = prev;
            } else {
                self._tail = prev;
            }

            self.len -= 1;
            self.alloc.destroy(node);
        }

        fn append(self: *Self, item: T) !void {
            var node = try self.alloc.create(Node);

            node.value = item;
            node.prev = self._tail;
            node.next = null;

            if (self._head == null) {
                self._head = node;
            }

            if (self._tail) |tail| {
                tail.next = node;
            }

            self._tail = node;
            self.len += 1;
        }

        fn prepend(self: *Self, item: T) !void {
            var node = try self.alloc.create(Node);

            node.value = item;
            node.next = self._head;
            node.prev = null;

            if (self._tail == null) {
                self._tail = node;
            }

            if (self._head) |head| {
                head.prev = node;
            }

            self._head = node;
            self.len += 1;
        }

        fn get(self: *Self, index: usize) !T {
            if (index > self.len - 1) return LinkedListError.IndexOutOfTheBounds;

            var current: *Node = self._head.?;
            for (0..index) |_| {
                current = current.next.?;
            }

            return current.value;
        }

        fn insertAt(self: *Self, item: T, index: usize) !void {
            const nodeAtIndex = try self.getNodeAt(index);

            var node = try self.alloc.create(Node);
            node.value = item;
            node.prev = nodeAtIndex.prev;

            if (nodeAtIndex.prev) |prev| {
                prev.next = node;
            } else {
                self._head = node;
            }

            node.next = nodeAtIndex;
            nodeAtIndex.prev = node;
            self.len += 1;
        }

        fn removeAt(self: *Self, index: usize) !void {
            const node = try self.getNodeAt(index);
            self.removeNode(node);
        }

        fn remove(self: *Self, item: T) !void {
            var node = try self.getItemNode(item);
            self.removeNode(node);
        }

        fn print(self: *Self) void {
            var current = self._head;
            while (current) |curr| {
                std.log.warn("{} -> ", .{curr.value});
                current = curr.next;
            }
            std.log.warn("\n", .{});
        }
    };
}

const I32LinkedList = LinkedList(i32);

test "Linked list" {
    const allocator = std.testing.allocator;

    var list = I32LinkedList.init(allocator);
    defer list.deinit();

    const arr = [_]i32{ 32, 40, 56, 32, 34 };
    // Multiple Appends
    for (arr, 0..arr.len) |v, i| {
        try list.append(v);
        try expect(try list.get(i) == v);
    }

    //Remove at head
    try list.removeAt(0);
    try expect(try list.get(0) == 40);

    //Remove at tail
    try list.removeAt(list.len - 1);
    try expect(try list.get(list.len - 1) == 32);

    //Multiple Removes
    try list.removeAt(1);
    try list.removeAt(0);
    try list.removeAt(list.len - 1);
    try expect(list.len == 0);

    //Muliple Prepends
    for (arr, 0..arr.len) |v, i| {
        try list.prepend(v);
        const len = list.len;
        try expect(try list.get(len - 1 - i) == v);
    }

    //Remove element
    try list.remove(40);
    try list.append(40);

    try expect(try list.get(3) == 32);

    //Multiple Removes
    for (arr) |v| {
        try list.remove(v);
    }
    try expect(list.len == 0);
    //Append + inserAt
    try list.append(53);
    try list.insertAt(32, 0);
    try list.insertAt(40, 1);
}
