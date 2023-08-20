const std = @import("std");
const expect = std.testing.expect;

const GROW_VALUE = 4;

fn RingBuffer(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,
        head: usize,
        tail: usize,
        len: usize,
        alloc: std.mem.Allocator,

        fn init(alloc: std.mem.Allocator) !Self {
            return Self{ .items = try alloc.alloc(T, GROW_VALUE), .head = 0, .tail = 0, .len = 0, .alloc = alloc };
        }

        fn deinit(self: *Self) void {
            self.alloc.free(self.items);
        }

        fn get(self: *Self, index: usize) ?T {
            if (index > self.len - 1) {
                return null;
            }
            const index_on_buffer = (self.head + index) % self.items.len;
            return self.items[index_on_buffer];
        }

        fn push(self: *Self, item: T) !void {
            const buffer_size = self.items.len;
            const is_first_item = self.head == 0 and self.tail == 0 and self.len == 0;

            var new_tail = self.tail + 1;
            var new_head = self.head;

            if (is_first_item or new_tail == buffer_size) {
                new_tail = 0;
            }

            if (!is_first_item and new_tail == self.head) {
                const new_items = try self.alloc.alloc(T, self.items.len + GROW_VALUE);

                if (self.tail > self.head) {
                    @memcpy(new_items[0..self.len], self.items[0..self.len]);
                } else {
                    @memcpy(new_items[0 .. buffer_size - self.head], self.items[self.head..buffer_size]);
                    @memcpy(new_items[buffer_size - self.head .. buffer_size - self.head + self.tail + 1], self.items[0 .. self.tail + 1]);
                }

                self.alloc.free(self.items);
                self.items = new_items;
                new_tail = self.len;
                new_head = 0;
            }

            self.items[new_tail] = item;
            self.tail = new_tail;
            self.head = new_head;
            self.len += 1;
        }

        fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            const value = self.items[self.tail];
            const buffer_size = self.items.len;
            const is_last_item = self.len == 1;

            var new_tail: usize = self.tail;
            var new_head: usize = self.head;

            if (!is_last_item) {
                new_tail = if (@as(i128, self.tail) - 1 < 0) buffer_size - 1 else self.tail - 1;
            } else {
                new_tail = 0;
                new_head = 0;
            }

            self.tail = new_tail;
            self.head = new_head;
            self.len -= 1;

            return value;
        }

        fn shift(self: *Self) ?T {
            if (self.len == 0) return null;
            const value = self.items[self.head];
            const buffer_size = self.items.len;
            const is_last_item = self.len == 1;

            var new_tail: usize = self.tail;
            var new_head: usize = self.head + 1;

            if (!is_last_item) {
                if (new_head == buffer_size) {
                    new_head = 0;
                }
            } else {
                new_tail = 0;
                new_head = 0;
            }

            self.tail = new_tail;
            self.head = new_head;
            self.len -= 1;

            return value;
        }

        fn unshift(self: *Self, item: T) !void {
            const buffer_size = self.items.len;
            const is_first_item = self.len == 0 and self.head == 0 and self.tail == 0;

            var new_head = self.head;
            var new_tail = self.tail;

            if (!is_first_item) {
                new_head = if (@as(i128, self.head) - 1 < 0) buffer_size - 1 else self.head - 1;
                if (new_head == self.tail) {
                    var new_items = try self.alloc.alloc(T, self.len + GROW_VALUE);

                    if (self.tail > self.head) {
                        @memcpy(new_items[1 .. self.len + 1], self.items[0..self.len]);
                    } else {
                        @memcpy(new_items[1 .. buffer_size - self.head + 1], self.items[self.head..buffer_size]);
                        @memcpy(new_items[buffer_size - self.head + 1 .. buffer_size - self.head + self.tail + 2], self.items[0 .. self.tail + 1]);
                    }

                    self.alloc.free(self.items);
                    self.items = new_items;
                    new_head = 0;
                    new_tail = self.len;
                }
            }

            self.items[new_head] = item;
            self.head = new_head;
            self.tail = new_tail;
            self.len += 1;
        }

        fn print(self: *Self) void {
            std.log.warn("h={} t={} l={} items={d}", .{ self.head, self.tail, self.len, self.items });
        }
    };
}

const I32RingBuffer = RingBuffer(i32);

test "Ring Buffer" {
    var rb = try I32RingBuffer.init(std.testing.allocator);
    defer rb.deinit();
    const arr = [_]i32{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };

    // Push
    try rb.push(-1);
    try expect(rb.get(0) == -1);
    try expect(rb.len == 1);

    //Push over capacity
    for (arr[0..5], 0..5) |v, i| {
        try rb.push(v);
        try expect(rb.get(i + 1) == v);
    }

    try expect(rb.len == 6);

    // Pop
    for (0..5) |i| {
        const pop_v = rb.pop().?;
        try expect(pop_v == arr[arr.len - i - 6]);
    }

    try expect(rb.pop() == -1);
    try expect(rb.head == 0 and rb.tail == 0 and rb.len == 0);

    for (arr[0..5], 0..5) |v, i| {
        try rb.push(v);
        try expect(rb.get(i) == v);
    }

    //Shift
    try expect(rb.len == 5);
    try expect(rb.shift() == 0);
    try expect(rb.shift() == 1);
    try expect(rb.len == 3);

    // Pop after shiftting
    try expect(rb.pop() == 4);
    try expect(rb.shift() == 2);
    try expect(rb.head == 3 and rb.tail == 3 and rb.len == 1);
    try expect(rb.pop() == 3);
    try expect(rb.head == 0 and rb.tail == 0 and rb.len == 0);

    // Pop and shift with len = 0
    try expect(rb.pop() == null);
    try expect(rb.shift() == null);

    // Unshift with len = 0
    try rb.unshift(-1);
    try expect(rb.get(0) == -1);
    try expect(rb.head == 0 and rb.tail == 0 and rb.len == 1);

    // Unshift when buffer is full
    for (arr[0..7]) |v| {
        try rb.push(v);
    }

    try rb.unshift(-2);
    try expect(rb.get(0) == -2 and rb.get(rb.len - 1) == 6);
    try expect(rb.head == 0 and rb.tail == rb.len - 1 and rb.len == 9);

    //Unshift after shifting
    _ = rb.shift();
    _ = rb.shift();
    try rb.unshift(-3);
    try expect(rb.get(0) == -3);
    try expect(rb.len == 8);
    try rb.unshift(-4);
    try expect(rb.get(0) == -4 and rb.get(1) == -3);
    try expect(rb.len == 9);

    //Unshift with tail is behind head
    _ = rb.shift();
    _ = rb.shift();
    _ = rb.shift();
    _ = rb.shift();

    for (arr[0..5]) |v| {
        try rb.push(v);
    }

    try rb.unshift(-1);
    try rb.unshift(-2);
    try expect(rb.get(0) == -2 and rb.get(1) == -1);
    try expect(rb.head == 2 and rb.tail == 1 and rb.len == 12);
    try rb.unshift(-3);
    try expect(rb.get(0) == -3 and rb.get(rb.len - 1) == 4);
    try expect(rb.head == 0 and rb.tail == rb.len - 1 and rb.len == 13);

    // Pop with tail behind head
    _ = rb.shift();
    _ = rb.shift();

    for (arr[0..5]) |v| {
        try rb.push(v);
    }

    for (0..rb.len) |_| {
        _ = rb.pop();
    }

    try expect(rb.head == 0 and rb.tail == 0 and rb.len == 0);
}
