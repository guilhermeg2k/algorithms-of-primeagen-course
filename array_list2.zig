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
            const defaut_grow_value = 4;
            return Self{
                .len = 0,
                .alloc = alloc,
                .items = try alloc.alloc(T, defaut_grow_value),
                .capacity = defaut_grow_value,
                .grow_value = defaut_grow_value,
            };
        }

        fn deinit(self: *Self) void {
            self.alloc.free(self.items);
        }

        fn push(self: *Self, item: T) !void {
            if (self.capacity == self.len) {
                try self.grow_capacity();
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
            if (self.capacity == self.len) {
                try self.grow_capacity();
            }
            const items = try self.alloc.alloc(T, self.capacity);
            @memcpy(items[1 .. self.len + 1], self.items[0..self.len]);
            self.alloc.free(self.items);
            self.items = items;
            self.items[0] = item;
            self.len += 1;
        }

        fn shift(self: *Self) !T {
            const item = self.items[0];
            const items = try self.alloc.alloc(T, self.capacity);

            @memcpy(items[0 .. self.len - 1], self.items[1..self.len]);
            self.alloc.free(self.items);
            self.items = items;
            self.len -= 1;

            return item;
        }

        fn grow_capacity(self: *Self) !void {
            const new_capacity = self.capacity + self.grow_value;
            const new_items = try self.alloc.alloc(T, new_capacity);
            @memcpy(new_items[0..self.len], self.items);
            self.alloc.free(self.items);
            self.items = new_items;
            self.capacity = new_capacity;
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
