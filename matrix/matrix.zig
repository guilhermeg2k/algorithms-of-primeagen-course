const std = @import("std");

const MatrixError = error{InvalidIndex};

fn Matrix(comptime T: type) type {
    return struct {
        const Self = @This();

        width: usize,
        height: usize,
        internal_array: []T,
        alloc: std.mem.Allocator,

        fn init(width: usize, height: usize, alloc: std.mem.Allocator) !Self {
            const internal_array = try alloc.alloc(T, width * height);
            return .{ .width = width, .height = height, .internal_array = internal_array, .alloc = alloc };
        }

        fn deinit(self: *Self) void {
            self.alloc.free(self.internal_array);
        }

        fn getIndex(self: *Self, row_index: usize, col_index: usize) !usize {
            if (col_index + 1 > self.width or row_index + 1 > self.height) {
                return MatrixError.InvalidIndex;
            }

            return row_index * self.width + col_index;
        }

        fn set(self: *Self, value: T, row_index: usize, col_index: usize) !void {
            const index = try self.getIndex(row_index, col_index);
            self.internal_array[index] = value;
        }

        fn setRow(self: *Self, row: []const T, row_index: usize) !void {
            if (row_index > self.height - 1) {
                return MatrixError.InvalidIndex;
            }

            const start_index = try self.getIndex(row_index, 0);
            const end_index = try self.getIndex(row_index, row.len - 1);
            @memcpy(self.internal_array[start_index .. end_index + 1], row);
        }

        fn setCol(self: *Self, col: []T, col_index: usize) !void {
            if (col_index > self.width - 1) {
                return MatrixError.InvalidIndex;
            }

            for (col, 0..) |row_item, i| {
                try self.set(row_item, i, col_index);
                if (i + 1 > self.internal_array.len) {
                    break;
                }
            }
        }

        fn get(self: *Self, x: usize, y: usize) !?T {
            const index = try self.getIndex(x, y);
            return self.internal_array[index];
        }

        fn getRow(self: *Self, row_index: usize) ![]T {
            const start_index = try self.getIndex(row_index, 0);
            const end_index = try self.getIndex(row_index, self.width - 1);

            return self.internal_array[start_index..end_index];
        }

        fn getCol(self: *Self, col_index: usize) !std.ArrayList(T) {
            if (col_index > self.height - 1) {
                return MatrixError.InvalidIndex;
            }

            var col = std.ArrayList(T).init(self.alloc);

            for (0..self.height) |i| {
                const index = try self.getIndex(i, col_index);
                try col.append(self.internal_array[index]);
            }

            return col;
        }
    };
}

const I32Matrix = Matrix(i32);
const t = std.testing;
const expect = std.testing.expect;

test "Matrix" {
    var m = try I32Matrix.init(5, 5, std.testing.allocator);
    defer m.deinit();

    // Set Get
    try m.set(10, 1, 1);
    try expect(try m.get(1, 1) == 10);

    // Set row, get Row
    var arr = [_]i32{ 10, 33 };
    try m.setRow(&arr, 0);

    const row = try m.getRow(0);
    try t.expectEqualDeep(row[0..arr.len], &arr);

    // Set col, get col
    var expected_col = [_]i32{ 10, 33, 44, 55 };
    try m.setCol(&expected_col, 2);

    const col = try m.getCol(2);
    defer col.deinit();

    try t.expectEqualDeep(col.items[0..expected_col.len], &expected_col);
}
