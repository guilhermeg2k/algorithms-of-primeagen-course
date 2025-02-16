const std = @import("std");
const expect = std.testing.expect;

fn ArrayList(comptime T: type) type {
    return struct {
        const Self = @This();
        grow_value: usize,
        capacity: usize,
        len: usize,
        items: []T,
        alloc: std.mem.Allocator,

        fn init(alloc: std.mem.Allocator) !Self {
            return Self{ .alloc = alloc, .grow_value = 4, .capacity = 4, .len = 0, .items = try alloc.alloc(T, 4) };
        }

        fn deinit(self: *Self) void {
            self.alloc.free(self.items);
        }

        fn push(self: *Self, item: T) !void {
            if (self.len == self.capacity) {
                const newCapacity = self.capacity + self.grow_value;
                const newItems = try self.alloc.alloc(T, newCapacity);
                @memcpy(newItems[0..self.len], self.items);
                newItems[self.len] = item;

                self.len += 1;
                self.capacity = newCapacity;

                self.alloc.free(self.items);
                self.items = newItems;
                return;
            }
            self.items[self.len] = item;
            self.len += 1;
        }

        fn pop(self: *Self) ?T {
            self.len -= 1;
            return self.items[self.len];
        }

        fn get(self: *Self, index: usize) ?T {
            if (index > self.len - 1) return null;
            return self.items[index];
        }

        fn unshift(self: *Self, item: T) !void {
            if (self.len == self.capacity) {
                const newCapacity = self.capacity + self.grow_value;
                const newItems = try self.alloc.alloc(T, newCapacity);

                for (0..self.len) |i| {
                    newItems[i + 1] = self.items[i];
                }

                newItems[0] = item;

                self.len += 1;
                self.capacity = newCapacity;
                self.alloc.free(self.items);
                self.items = newItems;
                return;
            }

            var i = self.len;
            while (i > 0) {
                self.items[i] = self.items[i - 1];
                i -= 1;
            }

            self.items[0] = item;
            self.len += 1;
        }

        fn shift(self: *Self) !T {
            const v = self.items[0];

            for (0..self.len - 1) |i| {
                self.items[i] = self.items[i + 1];
            }

            self.len -= 1;
            return v;
        }
    };
}

test "ArrayList" {
    var al = try ArrayList(i32).init(std.testing.allocator);
    defer al.deinit();
    const arr = [_]i32{ 1, 4, 2, 3, 5, 6, 8, 9, 10 };

    // Pushing to max capacity
    for (arr[0..4], 0..4) |v, i| {
        try al.push(v);
        try expect(al.get(i) == v);
    }

    try expect(al.len == 4 and al.capacity == 4);

    //Pushing over capacity
    for (arr[0..6], 0..6) |v, i| {
        try al.push(v);
        try expect(al.get(i + 4) == v);
    }
    try expect(al.len == 10 and al.capacity == 12);
    try expect(al.pop() == 6 and al.len == 9);

    //Getting invalid index
    try expect(al.get(24324) == null);

    //Shift
    try expect(try al.shift() == 1);
    try expect(al.get(0) == 4);
    try expect(al.get(al.len - 1) == 5);

    //Unshift
    try al.unshift(50);
    try expect(al.get(0) == 50 and al.get(1) == 4);

    for (arr) |v| {
        try al.unshift(v);
        try expect(al.get(0) == v);
    }

    try expect(al.get(0) == arr[arr.len - 1]);
    try expect(al.get(arr.len) == 50);
    try expect(al.get(al.len - 1) == 5);
}
