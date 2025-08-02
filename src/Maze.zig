const std = @import("std");
const Maze = @This();

const WallInfo = packed struct {
    right: bool = false,
    bottom: bool = false,

    pub fn hasAnyWall(self: WallInfo) bool {
        return self.right or self.bottom;
    }
};

width: u32,
height: u32,
walls: []WallInfo,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !Maze {
    if (width == 0 or height == 0) return error.InvalidDimensions;

    const total_cells = @as(u64, width) * @as(u64, height);
    if (total_cells > std.math.maxInt(usize)) return error.MazeTooLarge;

    const walls = try allocator.alloc(WallInfo, @intCast(total_cells));
    @memset(walls, WallInfo{});

    return Maze{
        .width = width,
        .height = height,
        .walls = walls,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Maze) void {
    self.allocator.free(self.walls);
    self.* = undefined;
}

inline fn getIndex(self: Maze, x: u32, y: u32) ?usize {
    if (x >= self.width or y >= self.height) return null;
    return @as(usize, y) * @as(usize, self.width) + @as(usize, x);
}

pub fn getWall(self: Maze, x: u32, y: u32) ?WallInfo {
    const idx = self.getIndex(x, y) orelse return null;
    return self.walls[idx];
}

pub fn toDVUIMaze(self: Maze) DVUIMazeData {
    var cells: [16][16]DVUIMazeCell = std.mem.zeroes([16][16]DVUIMazeCell);

    const render_width = @min(self.width, 16);
    const render_height = @min(self.height, 16);

    // set boundary walls
    for (0..16) |i| {
        cells[0][i].north = true; // top boundary
        cells[15][i].south = true; // bottom boundary
        cells[i][0].west = true; // left boundary
        cells[i][15].east = true; // right boundary
    }

    for (0..render_height) |y| {
        for (0..render_width) |x| {
            const wall_info = self.getWall(@intCast(x), @intCast(y)) orelse continue;

            // convert right wall to east wall of current cell
            if (wall_info.right) {
                cells[y][x].east = true;
                // set west wall of adjacent cell if it exists
                if (x + 1 < 16) {
                    cells[y][x + 1].west = true;
                }
            }

            // convert bottom wall to south wall of current cell
            if (wall_info.bottom) {
                cells[y][x].south = true;
                // set north wall of adjacent cell if it exists
                if (y + 1 < 16) {
                    cells[y + 1][x].north = true;
                }
            }
        }
    }

    return DVUIMazeData{
        .name = "maze",
        .cells = cells,
    };
}

pub fn parseText(text: []const u8, allocator: std.mem.Allocator) !Maze {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_allocator = arena.allocator();

    var lines = std.ArrayList([]const u8).init(temp_allocator);

    var line_iter = std.mem.tokenizeAny(u8, text, "\n\r");
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len > 0) {
            try lines.append(trimmed);
        }
    }

    if (lines.items.len < 3) return error.MazeTooSmall;

    const first_line_len = lines.items[0].len;
    if (first_line_len < 3) return error.InvalidMazeFormat;

    const height: u32 = @intCast(@divTrunc(lines.items.len - 1, 2));
    const width: u32 = @intCast(@divTrunc(first_line_len - 1, 2));

    var maze = try Maze.init(allocator, width, height);
    errdefer maze.deinit();

    for (0..height) |y| {
        for (0..width) |x| {
            const wall_idx = y * width + x;

            const right_row = y * 2 + 1;
            const right_col = x * 2 + 2;
            if (right_row < lines.items.len and right_col < lines.items[right_row].len) {
                const char = lines.items[right_row][right_col];
                maze.walls[wall_idx].right = (char == '|' or char == '+');
            } else {
                maze.walls[wall_idx].right = (x == width - 1);
            }

            const bottom_row = y * 2 + 2;
            const bottom_col = x * 2 + 1;
            if (bottom_row < lines.items.len and bottom_col < lines.items[bottom_row].len) {
                const char = lines.items[bottom_row][bottom_col];
                maze.walls[wall_idx].bottom = (char == '-' or char == '+');
            } else {
                maze.walls[wall_idx].bottom = (y == height - 1);
            }
        }
    }

    return maze;
}

pub const DVUIMazeCell = packed struct {
    north: bool = false,
    east: bool = false,
    south: bool = false,
    west: bool = false,
};

pub const DVUIMazeData = struct {
    name: []const u8,
    cells: [16][16]DVUIMazeCell,
};

pub const Examples = struct {
    const example_texts = [_]struct {
        name: []const u8,
        text: []const u8,
    }{
        .{ .name = "APEC 2018", .text = examples.apec2018 },
        .{ .name = "APEC 2017", .text = examples.apec2017 },
        .{ .name = "JAPAN 2017", .text = examples.japan2017 },
        .{ .name = "APEC 2016", .text = examples.apec2016 },
        .{ .name = "APEC 2015", .text = examples.apec2015 },
        .{ .name = "JAPAN 2015", .text = examples.japan2015 },
        .{ .name = "APEC 2014", .text = examples.apec2014 },
        .{ .name = "JAPAN 2014", .text = examples.japan2014 },
        .{ .name = "APEC 2013", .text = examples.apec2013 },
        .{ .name = "JAPAN 2013", .text = examples.japan2013 },
    };

    pub const maze_names = blk: {
        var names: [example_texts.len][]const u8 = undefined;
        for (example_texts, 0..) |example, i| {
            names[i] = example.name;
        }
        break :blk names;
    };

    pub fn getExampleMazes(allocator: std.mem.Allocator) ![10]DVUIMazeData {
        var result: [10]DVUIMazeData = undefined;

        for (example_texts, 0..) |example, i| {
            if (parseText(example.text, allocator)) |maze| {
                var mutable_maze = maze;
                defer mutable_maze.deinit();
                result[i] = mutable_maze.toDVUIMaze();
                result[i].name = example.name;
            } else |err| {
                std.log.warn("failed to parse maze {s}: {}", .{ example.name, err });
                result[i] = createFallbackMaze(example.name, i);
            }
        }

        return result;
    }

    fn createFallbackMaze(name: []const u8, pattern_seed: usize) DVUIMazeData {
        var cells: [16][16]DVUIMazeCell = std.mem.zeroes([16][16]DVUIMazeCell);

        // Set boundary walls using modern range iteration
        for (0..16) |i| {
            cells[0][i].north = true;
            cells[15][i].south = true;
            cells[i][0].west = true;
            cells[i][15].east = true;
        }

        for (1..15) |y| {
            for (1..15) |x| {
                const pattern = (x + y * 16 + pattern_seed) % 4;
                switch (pattern) {
                    0 => {
                        if ((x + y) % 3 == 0) {
                            cells[y][x].east = true;
                        }
                    },
                    1 => {
                        if ((x * y) % 5 == 0) {
                            cells[y][x].south = true;
                        }
                    },
                    2 => {
                        if (x % 4 == 2) {
                            cells[y][x].north = true;
                        }
                    },
                    3 => {
                        if (y % 4 == 2) {
                            cells[y][x].west = true;
                        }
                    },
                    else => unreachable,
                }
            }
        }

        return DVUIMazeData{
            .name = name,
            .cells = cells,
        };
    }
};

pub const examples = struct {
    pub const apec2018 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|                               |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| | |                           |
        \\+ + + + +-+-+ +-+-+-+-+-+-+-+-+ +
        \\| | | |     |       | |   |     |
        \\+ + + +-+-+ +-+-+-+ + + + + + + +
        \\| | |       |       | | | | | | |
        \\+ + + +-+ +-+ +-+-+-+ + + + +-+ +
        \\| | | |     |         | | |   | |
        \\+ + + + + +-+-+-+-+-+ + + +-+ + +
        \\| | | | | | |       | | | |   | |
        \\+ + + + +-+ + +-+-+ + + + + +-+ +
        \\| | | |   | | |   | | | | |   | |
        \\+ + + +-+ + + + + + + + + +-+ + +
        \\| | | |     |     | |   |   | | |
        \\+ + + + +-+ + +-+-+ + + +-+ + + +
        \\| | | | |   |       | |   |   | |
        \\+ + + +-+ + +-+-+ +-+-+ + +-+ + +
        \\| | | |   | | |   |   | |   | | |
        \\+ + + + + +-+ + +-+ + +-+-+ +-+ +
        \\| | | | | | |   |   | |       | |
        \\+ + + + +-+ + +-+ +-+ +-+-+-+ + +
        \\| | | |     |       | |   |   | |
        \\+ + + +-+ +-+-+-+-+-+ + + + + + +
        \\|   | |                 |   | | |
        \\+ + + +-+-+-+-+-+-+-+-+-+-+-+ + +
        \\| | |                         | |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;

    pub const apec2017 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|                               |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+ + +
        \\| |       |   |       |     | | |
        \\+ + +-+-+ + + + +-+-+ + +-+ + + +
        \\| | |     | |   |   | |   | | | |
        \\+ + + + +-+ +-+-+ + + +-+ + + + +
        \\| | | | |   | |   | | |   | | | |
        \\+ + + +-+ +-+ + +-+ + + +-+ + + +
        \\| | | |   | |     | | |   | | | |
        \\+ + + + +-+ + +-+ + + +-+ + + + +
        \\| | | | | |       |   |   | | | |
        \\+ + + + + + +-+-+-+-+-+-+ + + + +
        \\| | |   |     |   |       | | | |
        \\+ + +-+-+ +-+ + + + +-+ + + + + +
        \\| | |         |   |     | | | | |
        \\+ + + +-+-+-+-+-+ +-+ + +-+ + + +
        \\| | |   |         |   | |   | | |
        \\+ + +-+ + +-+ +-+-+ + +-+ +-+ + +
        \\| | |   |   | |     | |   | | | |
        \\+ + + +-+ + +-+-+ + +-+ +-+ + + +
        \\| | |   | | | |   | |   |   | | |
        \\+ + +-+ + +-+ + +-+-+ +-+ + + + +
        \\| |   |   |   |   |   |   | | | |
        \\+ +-+ + +-+ + +-+ + +-+ +-+ + + +
        \\|   | |     |     |     |   | | |
        \\+ + + +-+-+-+-+-+-+-+-+-+-+ + + +
        \\| | |                         | |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;

    pub const japan2017 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\| |                             |
        \\+ + + +-+-+-+-+-+-+-+-+-+-+ + +-+
        \\|   | |       |                 |
        \\+ +-+ + +-+-+ + +-+-+ + + +-+-+ +
        \\|     | |   |   |   |   |       |
        \\+ +-+ + + + +-+-+ + +-+-+-+-+ + +
        \\|     |   |                     |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+ + +-+ +
        \\| |   |   |     |               |
        \\+ + + +-+ + + + + + + + +-+-+ + +
        \\| | |   |   | |     |   |       |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+ +-+ +
        \\| |   |     |       |   |       |
        \\+ +-+ + + +-+ + +-+ + + +-+ +-+ +
        \\| |   | |   | |                 |
        \\+ + +-+ +-+ + + + +-+-+-+-+ +-+ +
        \\| | |   |   | |     |           |
        \\+ + + +-+ +-+ +-+-+ + + +-+-+-+ +
        \\| |   |     |                   |
        \\+ +-+-+ +-+-+-+-+-+-+-+-+-+-+ + +
        \\| |     |   | |     |           |
        \\+ + + + + + + + + + + + + + + + +
        \\| |   |   |     |       |       |
        \\+ +-+ + +-+-+ +-+-+ +-+ + +-+ + +
        \\| |   |   | | |     |   |       |
        \\+ + + + + + + + + + + + + + + + +
        \\| | |     |     |       |       |
        \\+ + + +-+-+ +-+-+-+-+-+ + + + + +
        \\|   | | | |                     |
        \\+ + + + + + + + + + + + + + + + +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;
    pub const apec2016 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|                               |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| | |       |   |   |         | |
        \\+ + + +-+ +-+ + + + + +-+-+-+ + +
        \\| | | | |     | | | | |   |   | |
        \\+ + + + +-+-+-+ + + + +-+ + +-+ +
        \\| | | |         | | | |     |   |
        \\+ + + + +-+-+-+ + + + +-+ +-+ + +
        \\| | | | |   | | | |   |   | | | |
        \\+ + + + + + + +-+ +-+-+ +-+ + + +
        \\| | | |   | |     |       |   | |
        \\+ + + +-+-+ + +-+-+-+ +-+-+ + + +
        \\| | | |     | |   |     | | | | |
        \\+ + + + + +-+ + + + +-+-+ + + + +
        \\| | | | | |   |         |   | | |
        \\+ + + + +-+ +-+-+-+-+-+ + + + + +
        \\| | | | |     |       | | | | | |
        \\+ + + + + +-+-+-+-+ + + + +-+-+ +
        \\| | | | |   |       | | |     | |
        \\+ + + + + + + +-+ +-+ + +-+-+ + +
        \\| | | |   | |       | |     | | |
        \\+ + + +-+-+ +-+ +-+ + +-+-+ + + +
        \\| |   |     |       | |   | | | |
        \\+ +-+ + +-+-+ +-+ +-+ + + + + + +
        \\|   | |             |   |   | | |
        \\+ + + +-+-+-+-+-+-+-+-+-+-+-+ + +
        \\| | |                         | |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;
    pub const apec2015 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|                               |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+-+-+ +-+
        \\| |                             |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+ + +
        \\| | |         |               | |
        \\+ + + + +-+-+ +-+ +-+-+-+-+-+-+ +
        \\| | | |     |   |             | |
        \\+ + + + + +-+-+ +-+-+-+-+-+-+ + +
        \\| | | | |     |     |   |   | | |
        \\+ + + + + + +-+ +-+ + + + + + + +
        \\| | | | | |   |   |   | | | | | |
        \\+ + + + + + + +-+ +-+-+ + + + + +
        \\| | | | | | |   |   |   | | | | |
        \\+ + + +-+ + + + +-+-+ +-+ + + + +
        \\| | | | |   | |   |     | | | | |
        \\+ + + + + + + + + + +-+-+ + + + +
        \\| | | | | |   |   |     | | | | |
        \\+ + + + + +-+ +-+-+-+-+ + + + + +
        \\| | | | |     |       | | | | | |
        \\+ + + + +-+-+-+-+-+ +-+ + + + + +
        \\| | | | |         |   | | | | | |
        \\+ + + + + +-+-+-+ +-+ + + + + + +
        \\| | | | | |     | |   | | | | | |
        \\+ + + + + + +-+ + + + + + + + + +
        \\| | | | |   |   |   | |   | | | |
        \\+ + + + +-+-+ +-+ +-+-+ + + + + +
        \\|   | |         |     | | |   | |
        \\+ + + + +-+-+ +-+ +-+-+-+-+-+ + +
        \\| | |           |             | |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;
    pub const japan2015 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|                               |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                           | |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+ +-+ +
        \\| | |   |                 |   | |
        \\+ + + + + + +-+-+-+-+ +-+ +-+ + +
        \\| | | | | |           | |   |   |
        \\+ + + + + +-+ +-+-+ +-+ +-+ +-+ +
        \\| | | | |   |   |   |     |   | |
        \\+ + + + + +-+-+ + +-+ + +-+ +-+ +
        \\| | | | |     |   |   |     | | |
        \\+ + + + + +-+-+ + +-+ +-+ +-+ +-+
        \\| | | | |   |   |   |   | |     |
        \\+ + + + + +-+ +-+-+ +-+ +-+-+ +-+
        \\| | | |   |   |   |   |   |     |
        \\+ + + + +-+ +-+ + +-+ +-+ + +-+ +
        \\| | | | |   |       |   |   |   |
        \\+ + + +-+ +-+ +-+-+ +-+ +-+-+ +-+
        \\| |   |   | |   |   | |   |     |
        \\+ + +-+ +-+ +-+ + +-+ +-+ +-+ +-+
        \\| | |   |     |   |     |   |   |
        \\+ +-+ +-+ + +-+ + +-+ + +-+ +-+ +
        \\| |   |   |     |     |   |   | |
        \\+ +-+ + +-+-+ +-+-+ +-+-+ + +-+ +
        \\| |     | |     |     | |   |   |
        \\+ +-+ + + + +-+ + +-+ + + +-+ +-+
        \\|   | |     | |   | |     |     |
        \\+-+ + +-+ +-+ +-+-+ +-+ +-+-+ +-+
        \\|   |     |     |     | |   |   |
        \\+ + +-+-+-+ +-+ + +-+ +-+ + +-+ +
        \\| |         |       |     |     |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;
    pub const apec2014 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|                               |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+-+-+ + +
        \\| |   |       |               | |
        \\+ + + + +-+-+ +-+ +-+-+-+-+-+-+ +
        \\| | | |   |     |     |       | |
        \\+ + + +-+ +-+-+ + +-+ +-+ +-+ + +
        \\| | | | |     | | |     |   | | |
        \\+ + + + +-+-+ + +-+-+ +-+-+ + + +
        \\| | |       | |     |     | | | |
        \\+ + +-+-+-+ + +-+ +-+-+-+ + + + +
        \\| |   | |   |   |     | | | | | |
        \\+ +-+ + + +-+ + +-+ +-+ + + + + +
        \\| | |   |   | |   |     | | | | |
        \\+ + +-+ +-+ + +-+ + + +-+ + + + +
        \\| |   |   |   |   | |   |   | | |
        \\+ + + +-+ +-+ + + + + + +-+-+ + +
        \\| | | |     | |   | | |     | | |
        \\+ + + +-+-+ +-+-+-+ + + + + + + +
        \\| | | |   |     |   |   | | | | |
        \\+ + + + + +-+ +-+-+-+-+-+-+ + + +
        \\| | | | |   |   |     | |   | | |
        \\+ + + + +-+ +-+ + + +-+ +-+ + + +
        \\| | | | |   |     | |     |   | |
        \\+ + + + + +-+-+-+-+ +-+ + +-+ + +
        \\| | | | |           |   | | | | |
        \\+ + + + +-+-+-+-+-+-+ +-+ + +-+ +
        \\|   | |                 |     | |
        \\+ + + +-+-+-+-+-+-+-+-+-+-+-+ + +
        \\| | |                         | |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;

    pub const apec2013 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|                               |
        \\+ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\+ + +-+-+-+-+-+-+-+-+ +-+-+-+-+ +
        \\| | |             |           | |
        \\+ + + +-+-+-+ +-+-+-+-+ +-+-+ + +
        \\| | | | |   |     | |   |     | |
        \\+ + + + + + +-+-+ + + +-+ +-+-+ +
        \\| | | |   | |   |   | |       | |
        \\+ + + + +-+ + + +-+ + +-+-+-+ + +
        \\| | | |   | | |   |   |       | |
        \\+ + + +-+ + + +-+ +-+-+ +-+-+-+ +
        \\| | |     | | |       |     | | |
        \\+ + +-+-+-+ + +-+-+-+ +-+-+ + + +
        \\| | |   |   | |     |       | | |
        \\+ + + + +-+ + + + + +-+-+-+-+ + +
        \\| | | |   | | |   |     |     | |
        \\+ + + +-+ + + +-+-+-+ +-+ + + + +
        \\| | | |   |   |     |   | | | | |
        \\+ + + + +-+ +-+-+ + +-+ + +-+ + +
        \\| | | |     |   | |   |       | |
        \\+ + + +-+-+-+ + + +-+ +-+ +-+ + +
        \\| | |       | | |   |   |   | | |
        \\+ + +-+-+-+ + + +-+ +-+ +-+ + + +
        \\| | |       | | |     |   |   | |
        \\+ + + +-+-+-+ + +-+-+ +-+ +-+ + +
        \\|   | |       | |       |   | | |
        \\+ + + +-+-+-+ + +-+-+-+ +-+ + + +
        \\| | |         |         |     | |
        \\+ + +-+-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;
    pub const japan2014 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|   |                           |
        \\+ + + +-+-+-+-+-+-+-+-+-+-+-+-+ +
        \\| | |   |                     | |
        \\+ + + +-+ +-+-+-+-+-+-+-+-+-+ + +
        \\| | | |     |               |   |
        \\+ + + +-+ +-+ +-+-+-+-+-+-+ +-+-+
        \\| | | |     | |           |   | |
        \\+ + + +-+ +-+ + +-+-+-+-+ +-+ + +
        \\| | | |     | |     |     | |   |
        \\+ + + +-+ +-+ +-+-+ +-+ + + + + +
        \\| | | |     | | |   |   | |   | |
        \\+ + + + +-+-+ + + +-+ + +-+ +-+ +
        \\| | | |           |   | |       |
        \\+ + + +-+-+-+ +-+-+ + +-+ +-+ +-+
        \\| | | |   |   |     | |         |
        \\+ + + + + +-+ + + + +-+ +-+-+ +-+
        \\| | | | | |   |   | |     | |   |
        \\+ + + + + + +-+ +-+-+ +-+-+ +-+ +
        \\| | | | |   |     |     |     | |
        \\+ + + + +-+-+ +-+-+ +-+-+ +-+ + +
        \\| | | | | |     |     |     | | |
        \\+ + + + + + +-+-+ +-+-+ + +-+ + +
        \\| | | | |     |     |   |   | | |
        \\+ + + + + +-+-+ +-+-+ +-+-+ + + +
        \\| | | |     |     |     |   | | |
        \\+ + + + +-+-+ +-+-+ +-+ + + + + +
        \\| | | | | |     |     |   | | | |
        \\+ + + +-+ +-+ +-+ + + + + + + + +
        \\| | | |     |     | |   |   | | |
        \\+ + + + +-+ +-+-+-+-+-+-+-+ + + +
        \\| |       |                 |   |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;
    pub const japan2013 =
        \\+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        \\|   |                       |   |
        \\+ +-+ +-+-+-+-+-+-+-+-+-+ + + + +
        \\|     |                 | | | | |
        \\+ +-+-+ + +-+-+-+-+-+-+ +-+ + + +
        \\|   |   | |         |     |   | |
        \\+ +-+ +-+ + +-+ +-+ +-+-+ +-+-+ +
        \\| |       | |     | |   |     | |
        \\+ +-+ +-+-+ +-+ +-+ + + + +-+ + +
        \\| |     |   |     |   | | |   | |
        \\+ +-+ +-+ +-+-+ +-+-+-+ + +-+ + +
        \\| |     |   |     |   | |   | | |
        \\+ + +-+ +-+ +-+ +-+ + + +-+ + + +
        \\| |       | |       | |   | | | |
        \\+ + +-+-+ + +-+ +-+-+ +-+ + + + +
        \\| |     | |   |   |   | | | | | |
        \\+ +-+-+ + +-+ + + + +-+ + + + + +
        \\| |     | |   |   |   |   | | | |
        \\+ + +-+-+ + +-+-+-+-+ +-+ + + + +
        \\| |     |     |   |   |   | | | |
        \\+ +-+-+ +-+-+ + + + +-+ +-+ + + +
        \\| |     |   |   |   | | |   | | |
        \\+ + +-+-+ + +-+-+-+-+ + +-+ + + +
        \\| |       | |       |   |   | | |
        \\+ + +-+-+-+ + + +-+ +-+ + +-+ + +
        \\| |   |   |   |     |   | | | | |
        \\+ + + + + +-+-+-+-+ + +-+ + + + +
        \\| | |   |     |   |     | |   | |
        \\+ + +-+-+ + +-+ + +-+-+ + + +-+ +
        \\| | | | | |     |         | |   |
        \\+ + + + +-+-+-+-+-+-+-+-+-+ +-+ +
        \\| |                             |
        \\.-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ;
};
