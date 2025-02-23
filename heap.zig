const std = @import("std");
const expect = std.testing.expect;

fn MinHeap(comptime T: type) type {
    return struct {
        const Self = @This();
        len: usize = 0,
        alloc: std.mem.Allocator,
        data: std.ArrayList(T),

        fn init(alloc: std.mem.Allocator) !Self {
            return .{ .alloc = alloc, .len = 0, .data = std.ArrayList(T).init(alloc) };
        }

        fn deinit(self: *Self) void {
            self.data.deinit();
        }

        fn insert(self: *Self, item: T) !void {
            if (self.len < self.data.items.len) {
                self.data.items[self.len] = item;
                self.len += 1;
                self.hipifyUp(self.len - 1);
                return;
            }

            try self.data.append(item);
            self.len += 1;
            self.hipifyUp(self.len - 1);
        }

        fn pop(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }

            const out = self.data.items[0];
            const last = self.data.items[self.len - 1];
            self.len -= 1;

            if (self.len >= 1) {
                self.data.items[0] = last;
                self.hipifyDown(0);
            }

            return out;
        }

        fn hipifyUp(self: *Self, item_index: usize) void {
            if (item_index == 0) return;

            const item = self.data.items[item_index];
            const parent_index = getParent(item_index);
            const parent = self.data.items[parent_index];

            if (parent > item) {
                self.data.items[item_index] = parent;
                self.data.items[parent_index] = item;
                self.hipifyUp(parent_index);
            }
        }

        fn hipifyDown(self: *Self, item_index: usize) void {
            const left_id = getLeft(item_index);
            const right_id = getRight(item_index);

            if (item_index >= self.len or left_id >= self.len) {
                return;
            }

            const item = self.data.items[item_index];
            const left = self.data.items[left_id];
            const right = self.data.items[right_id];

            if (left > right and item > right) {
                self.data.items[right_id] = item;
                self.data.items[item_index] = right;
                self.hipifyDown(right_id);
            } else if (right > left and item > left) {
                self.data.items[left_id] = item;
                self.data.items[item_index] = left;
                self.hipifyDown(left_id);
            }
        }

        fn getParent(item_index: usize) usize {
            return (item_index - 1) / 2;
        }

        fn getLeft(item_index: usize) usize {
            return item_index * 2 + 1;
        }

        fn getRight(item_index: usize) usize {
            return item_index * 2 + 2;
        }

        fn printData(self: *Self) void {
            for (self.data.items) |i| {
                std.debug.print("{d}\n", .{i});
            }
        }
    };
}

const I32Heap = MinHeap(i32);

test "min heap" {
    var heap = try I32Heap.init(std.testing.allocator);
    defer heap.deinit();

    try heap.insert(5);
    try heap.insert(3);
    try heap.insert(69);
    try heap.insert(420);
    try heap.insert(4);
    try heap.insert(1);
    try heap.insert(8);
    try heap.insert(7);

    try expect(heap.len == 8);
    try expect(heap.pop() == 1);

    try expect(heap.pop() == 3);
    try expect(heap.pop() == 4);
    try expect(heap.pop() == 5);
    try expect(heap.len == 4);
    try expect(heap.pop() == 7);
    try expect(heap.pop() == 8);
    try expect(heap.pop() == 69);

    try expect(heap.pop() == 420);
    try expect(heap.len == 0);

    try heap.insert(5);
    try expect(heap.pop() == 5);
    try expect(heap.len == 0);
}
