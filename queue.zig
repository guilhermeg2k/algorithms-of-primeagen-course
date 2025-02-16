const std = @import("std");
const expect = std.testing.expect;

pub fn Queue(comptime T: type) type {
    const Node = struct {
        const Self = @This();

        value: T,
        next: ?*Self,
    };

    return struct {
        const Self = @This();
        len: usize,
        head: ?*Node,
        tail: ?*Node,
        alloc: std.mem.Allocator,

        fn init(alloc: std.mem.Allocator) Self {
            return Self{ .alloc = alloc, .len = 0, .head = null, .tail = null };
        }

        fn deinit(self: *Self) void {
            while (self.head) |curr| {
                const next = curr.next;
                self.alloc.destroy(curr);
                self.head = next;
            }
        }

        fn peek(self: *Self) ?T {
            if (self.head) |head| {
                return head.value;
            }
            return null;
        }

        fn enqueue(self: *Self, item: T) !void {
            const node = try self.alloc.create(Node);
            node.value = item;
            node.next = null;

            if (self.len == 0) {
                self.head = node;
            } else {
                self.tail.?.next = node;
            }

            self.tail = node;
            self.len += 1;
        }

        fn deque(self: *Self) ?T {
            if (self.len == 0) return null;

            const head = self.head;
            const head_v = self.head.?.value;

            self.head = self.head.?.next;

            self.alloc.destroy(head.?);
            self.len -= 1;

            return head_v;
        }
    };
}

const I32Queue = Queue(i32);

test "Queue" {
    var queue = I32Queue.init(std.testing.allocator);
    defer queue.deinit();

    // Simple enq
    try queue.enqueue(1);
    try expect(queue.peek() == 1);

    //Simple enq
    const v = queue.deque();
    try expect(v == 1);

    //Multiple enqs
    const arr = [_]i32{ 1, 2, 4, 6, 32, 100, 43, 1235, 312, 6553 };
    for (arr) |curr| {
        try queue.enqueue(curr);
    }

    try expect(queue.len == 10);
    try expect(queue.head.?.value == 1);
    try expect(queue.tail.?.value == 6553);

    // Multiple deqs
    for (arr) |curr| {
        const q_v = queue.deque();
        try expect(q_v == curr);
    }

    try expect(queue.len == 0);
}
