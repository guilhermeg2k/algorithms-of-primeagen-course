const std = @import("std");
const expect = std.testing.expect;

fn Stack(comptime T: type) type {
    const Node = struct {
        const Self = @This();

        value: T,
        next: ?*Self,
    };

    return struct {
        const Self = @This();

        len: usize = 0,
        head: ?*Node,
        alloc: std.mem.Allocator,

        fn init(alloc: std.mem.Allocator) Self {
            return .{ .alloc = alloc, .len = 0, .head = null };
        }

        fn deinit(self: *Self) void {
            while (self.head) |curr| {
                self.head = curr.next;
                self.alloc.destroy(curr);
            }
        }

        fn push(self: *Self, item: T) !void {
            const node = try self.alloc.create(Node);
            node.value = item;
            node.next = null;
            self.len += 1;

            if (self.len == 0) {
                self.head = node;
                return;
            }

            node.next = self.head;
            self.head = node;
        }

        fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            const head = self.head.?;
            defer self.alloc.destroy(head);

            self.head = head.next;
            self.len -= 1;

            return head.value;
        }

        fn peek(self: *Self) ?T {
            return if (self.head) |head| head.value else null;
        }
    };
}

const I32Stack = Stack(i32);

test "Stack" {
    var s = I32Stack.init(std.testing.allocator);
    defer s.deinit();

    //Simple push
    try s.push(32);
    try expect(s.peek() == 32);
    try expect(s.len == 1);

    //Simple pop
    try expect(s.pop() == 32);
    try expect(s.len == 0);

    //Multiple push
    const arr = [_]i32{ 1, 5, 7, 8, 9, 10 };
    for (arr) |v| {
        try s.push(v);
        try expect(s.peek() == v);
    }
    try expect(s.peek() == arr[arr.len - 1]);
    try expect(s.len == arr.len);

    //Multiple pop
    for (arr, 0..arr.len) |_, i| {
        const arr_v = arr[arr.len - i - 1];
        try expect(s.pop() == arr_v);
    }

    try expect(s.len == 0);
}
