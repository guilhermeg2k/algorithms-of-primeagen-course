const std = @import("std");
const expect = std.testing.expect;

fn Matrix(comptime T: type) type {
    return [MAZE_ROWS][MAZE_COLS]T;
}

const Maze = Matrix(u8);
const Seen = Matrix(bool);

const Point = struct { x: i32 = 0, y: i32 = 0 };
const DIRECTIONS = [_][2]i32{ .{ 0, 1 }, .{ 0, -1 }, .{ 1, 0 }, .{ -1, 0 } };
const MAZE_COLS = 12;
const MAZE_ROWS = 6;

fn walk(maze: Maze, wall: u8, curr: Point, end: Point, seen: *Seen, path: *std.ArrayList(Point)) !bool {
    const out_of_maze = curr.x < 0 or curr.x > maze[0].len or curr.y < 0 or curr.y > maze.len;
    const x: usize = @intCast(curr.x);
    const y: usize = @intCast(curr.y);

    if (out_of_maze) {
        return false;
    }

    const is_wall = maze[y][x] == wall;
    if (is_wall) {
        return false;
    }

    const have_seen = seen[y][x];
    if (have_seen) {
        return false;
    }

    const is_end = curr.x == end.x and curr.y == end.y;
    if (is_end) {
        try path.append(.{ .x = curr.x, .y = curr.y });
        return true;
    }

    seen[y][x] = true;

    try path.append(.{ .x = curr.x, .y = curr.y });

    for (DIRECTIONS) |dir| {
        if (try walk(maze, wall, .{ .x = dir[1] + curr.x, .y = dir[0] + curr.y }, end, seen, path)) {
            return true;
        }
    }

    _ = path.pop();
    return false;
}

fn solve(maze: Maze, wall: u8, start: Point, end: Point, allocator: std.mem.Allocator) !std.ArrayList(Point) {
    var path = std.ArrayList(Point).init(allocator);
    var seen = std.mem.zeroes(Seen);
    _ = try walk(maze, wall, start, end, &seen, &path);
    return path;
}

test "Maze Solver" {
    const maze = [MAZE_ROWS][MAZE_COLS]u8{
        [_]u8{
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            ' ',
            'x',
        },
        [_]u8{
            'x',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            'x',
            ' ',
            'x',
        },
        [_]u8{
            'x',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            'x',
            ' ',
            'x',
        },
        .{
            'x',
            ' ',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            ' ',
            'x',
        },
        [_]u8{
            'x',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            'x',
        },
        [_]u8{
            'x',
            ' ',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
            'x',
        },
    };

    const maze_result = [_]Point{
        .{ .x = 10, .y = 0 },
        .{ .x = 10, .y = 1 },
        .{ .x = 10, .y = 2 },
        .{ .x = 10, .y = 3 },
        .{ .x = 10, .y = 4 },
        .{ .x = 9, .y = 4 },
        .{ .x = 8, .y = 4 },
        .{ .x = 7, .y = 4 },
        .{ .x = 6, .y = 4 },
        .{ .x = 5, .y = 4 },
        .{ .x = 4, .y = 4 },
        .{ .x = 3, .y = 4 },
        .{ .x = 2, .y = 4 },
        .{ .x = 1, .y = 4 },
        .{ .x = 1, .y = 5 },
    };

    const result = try solve(maze, 'x', .{ .x = 10, .y = 0 }, .{ .x = 1, .y = 5 }, std.testing.allocator);
    defer result.deinit();

    try expect(maze_result.len == result.items.len);
    for (result.items, 0..result.items.len) |res, i| {
        try expect(res.x == maze_result[i].x and res.y == maze_result[i].y);
    }
}
