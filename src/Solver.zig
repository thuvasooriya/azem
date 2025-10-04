const std = @import("std");
const Maze = @import("Maze.zig");

pub const Position = struct {
    x: u8,
    y: u8,

    pub fn eql(self: Position, other: Position) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn toIndex(self: Position, width: u32) usize {
        return @as(usize, self.y) * @as(usize, width) + @as(usize, self.x);
    }
};

pub const CellState = enum {
    unvisited,
    frontier,
    visited,
    path,
};

pub const SolverState = struct {
    cells: []CellState,
    start: Position,
    goal: Position,
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, start: Position, goal: Position) !SolverState {
        const total_cells = @as(usize, width) * @as(usize, height);
        const cells = try allocator.alloc(CellState, total_cells);
        @memset(cells, .unvisited);

        return SolverState{
            .cells = cells,
            .start = start,
            .goal = goal,
            .allocator = allocator,
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *SolverState) void {
        self.allocator.free(self.cells);
        self.* = undefined;
    }

    pub fn reset(self: *SolverState) void {
        @memset(self.cells, .unvisited);
    }

    pub fn getCellState(self: SolverState, pos: Position) CellState {
        const idx = pos.toIndex(self.width);
        return self.cells[idx];
    }

    pub fn setCellState(self: *SolverState, pos: Position, state: CellState) void {
        const idx = pos.toIndex(self.width);
        self.cells[idx] = state;
    }
};

pub const Algorithm = enum {
    bfs,
    dfs,
    astar,
};

pub const StepResult = enum {
    running,
    found,
    no_path,
};

pub const Solver = union(Algorithm) {
    bfs: BFSSolver,
    dfs: DFSSolver,
    astar: AStarSolver,

    pub fn init(allocator: std.mem.Allocator, algorithm: Algorithm, maze: *const Maze.DVUIMazeData, start: Position, goal: Position) !Solver {
        return switch (algorithm) {
            .bfs => Solver{ .bfs = try BFSSolver.init(allocator, maze, start, goal) },
            .dfs => Solver{ .dfs = try DFSSolver.init(allocator, maze, start, goal) },
            .astar => Solver{ .astar = try AStarSolver.init(allocator, maze, start, goal) },
        };
    }

    pub fn deinit(self: *Solver) void {
        switch (self.*) {
            inline else => |*solver| solver.deinit(),
        }
    }

    pub fn step(self: *Solver) !StepResult {
        return switch (self.*) {
            inline else => |*solver| try solver.step(),
        };
    }

    pub fn getState(self: *Solver) *SolverState {
        return switch (self.*) {
            inline else => |*solver| &solver.state,
        };
    }

    pub fn reset(self: *Solver) !void {
        switch (self.*) {
            inline else => |*solver| try solver.reset(),
        }
    }
};

const BFSSolver = struct {
    state: SolverState,
    queue: std.ArrayList(Position),
    parent: std.AutoHashMap(Position, Position),
    maze: *const Maze.DVUIMazeData,
    allocator: std.mem.Allocator,
    finished: bool,

    pub fn init(allocator: std.mem.Allocator, maze: *const Maze.DVUIMazeData, start: Position, goal: Position) !BFSSolver {
        var state = try SolverState.init(allocator, 16, 16, start, goal);
        var queue: std.ArrayList(Position) = .{};
        try queue.append(allocator, start);
        state.setCellState(start, .frontier);

        return BFSSolver{
            .state = state,
            .queue = queue,
            .parent = std.AutoHashMap(Position, Position).init(allocator),
            .maze = maze,
            .allocator = allocator,
            .finished = false,
        };
    }

    pub fn deinit(self: *BFSSolver) void {
        self.state.deinit();
        self.queue.deinit(self.allocator);
        self.parent.deinit();
    }

    pub fn step(self: *BFSSolver) !StepResult {
        if (self.finished) return .found;
        if (self.queue.items.len == 0) {
            self.finished = true;
            return .no_path;
        }

        const current = self.queue.orderedRemove(0);
        self.state.setCellState(current, .visited);

        if (current.eql(self.state.goal)) {
            try self.reconstructPath();
            self.finished = true;
            return .found;
        }

        var neighbors = try self.getNeighbors(current);
        defer neighbors.deinit(self.allocator);
        for (neighbors.items) |neighbor| {
            const neighbor_state = self.state.getCellState(neighbor);
            if (neighbor_state == .unvisited) {
                self.state.setCellState(neighbor, .frontier);
                try self.queue.append(self.allocator, neighbor);
                try self.parent.put(neighbor, current);
            }
        }

        return .running;
    }

    pub fn reset(self: *BFSSolver) !void {
        self.state.reset();
        self.queue.clearRetainingCapacity();
        self.parent.clearRetainingCapacity();
        try self.queue.append(self.allocator, self.state.start);
        self.state.setCellState(self.state.start, .frontier);
        self.finished = false;
    }

    fn reconstructPath(self: *BFSSolver) !void {
        var current = self.state.goal;
        while (!current.eql(self.state.start)) {
            self.state.setCellState(current, .path);
            current = self.parent.get(current) orelse return;
        }
        self.state.setCellState(self.state.start, .path);
    }

    fn getNeighbors(self: *BFSSolver, pos: Position) !std.ArrayList(Position) {
        var neighbors: std.ArrayList(Position) = .{};
        const cell = self.maze.cells[pos.y][pos.x];

        if (!cell.north and pos.y > 0) {
            try neighbors.append(self.allocator, .{ .x = pos.x, .y = pos.y - 1 });
        }
        if (!cell.east and pos.x < 15) {
            try neighbors.append(self.allocator, .{ .x = pos.x + 1, .y = pos.y });
        }
        if (!cell.south and pos.y < 15) {
            try neighbors.append(self.allocator, .{ .x = pos.x, .y = pos.y + 1 });
        }
        if (!cell.west and pos.x > 0) {
            try neighbors.append(self.allocator, .{ .x = pos.x - 1, .y = pos.y });
        }

        return neighbors;
    }
};

const DFSSolver = struct {
    state: SolverState,
    stack: std.ArrayList(Position),
    parent: std.AutoHashMap(Position, Position),
    maze: *const Maze.DVUIMazeData,
    allocator: std.mem.Allocator,
    finished: bool,

    pub fn init(allocator: std.mem.Allocator, maze: *const Maze.DVUIMazeData, start: Position, goal: Position) !DFSSolver {
        var state = try SolverState.init(allocator, 16, 16, start, goal);
        var stack: std.ArrayList(Position) = .{};
        try stack.append(allocator, start);
        state.setCellState(start, .frontier);

        return DFSSolver{
            .state = state,
            .stack = stack,
            .parent = std.AutoHashMap(Position, Position).init(allocator),
            .maze = maze,
            .allocator = allocator,
            .finished = false,
        };
    }

    pub fn deinit(self: *DFSSolver) void {
        self.state.deinit();
        self.stack.deinit(self.allocator);
        self.parent.deinit();
    }

    pub fn step(self: *DFSSolver) !StepResult {
        if (self.finished) return .found;
        if (self.stack.items.len == 0) {
            self.finished = true;
            return .no_path;
        }

        const current = self.stack.pop() orelse return .no_path;
        self.state.setCellState(current, .visited);

        if (current.eql(self.state.goal)) {
            try self.reconstructPath();
            self.finished = true;
            return .found;
        }

        var neighbors = try self.getNeighbors(current);
        defer neighbors.deinit(self.allocator);
        for (neighbors.items) |neighbor| {
            const neighbor_state = self.state.getCellState(neighbor);
            if (neighbor_state == .unvisited) {
                self.state.setCellState(neighbor, .frontier);
                try self.stack.append(self.allocator, neighbor);
                try self.parent.put(neighbor, current);
            }
        }

        return .running;
    }

    pub fn reset(self: *DFSSolver) !void {
        self.state.reset();
        self.stack.clearRetainingCapacity();
        self.parent.clearRetainingCapacity();
        try self.stack.append(self.allocator, self.state.start);
        self.state.setCellState(self.state.start, .frontier);
        self.finished = false;
    }

    fn reconstructPath(self: *DFSSolver) !void {
        var current = self.state.goal;
        while (!current.eql(self.state.start)) {
            self.state.setCellState(current, .path);
            current = self.parent.get(current) orelse return;
        }
        self.state.setCellState(self.state.start, .path);
    }

    fn getNeighbors(self: *DFSSolver, pos: Position) !std.ArrayList(Position) {
        var neighbors: std.ArrayList(Position) = .{};
        const cell = self.maze.cells[pos.y][pos.x];

        if (!cell.north and pos.y > 0) {
            try neighbors.append(self.allocator, .{ .x = pos.x, .y = pos.y - 1 });
        }
        if (!cell.east and pos.x < 15) {
            try neighbors.append(self.allocator, .{ .x = pos.x + 1, .y = pos.y });
        }
        if (!cell.south and pos.y < 15) {
            try neighbors.append(self.allocator, .{ .x = pos.x, .y = pos.y + 1 });
        }
        if (!cell.west and pos.x > 0) {
            try neighbors.append(self.allocator, .{ .x = pos.x - 1, .y = pos.y });
        }

        return neighbors;
    }
};

const AStarSolver = struct {
    const Node = struct {
        pos: Position,
        g_score: f32,
        f_score: f32,
    };

    state: SolverState,
    open_set: std.ArrayList(Node),
    parent: std.AutoHashMap(Position, Position),
    g_scores: std.AutoHashMap(Position, f32),
    maze: *const Maze.DVUIMazeData,
    allocator: std.mem.Allocator,
    finished: bool,

    pub fn init(allocator: std.mem.Allocator, maze: *const Maze.DVUIMazeData, start: Position, goal: Position) !AStarSolver {
        var state = try SolverState.init(allocator, 16, 16, start, goal);
        var open_set: std.ArrayList(Node) = .{};
        var g_scores = std.AutoHashMap(Position, f32).init(allocator);

        const h = heuristic(start, goal);
        try open_set.append(allocator, .{ .pos = start, .g_score = 0, .f_score = h });
        try g_scores.put(start, 0);
        state.setCellState(start, .frontier);

        return AStarSolver{
            .state = state,
            .open_set = open_set,
            .parent = std.AutoHashMap(Position, Position).init(allocator),
            .g_scores = g_scores,
            .maze = maze,
            .allocator = allocator,
            .finished = false,
        };
    }

    pub fn deinit(self: *AStarSolver) void {
        self.state.deinit();
        self.open_set.deinit(self.allocator);
        self.parent.deinit();
        self.g_scores.deinit();
    }

    pub fn step(self: *AStarSolver) !StepResult {
        if (self.finished) return .found;
        if (self.open_set.items.len == 0) {
            self.finished = true;
            return .no_path;
        }

        const current_idx = self.findLowestFScore();
        const current = self.open_set.orderedRemove(current_idx);
        self.state.setCellState(current.pos, .visited);

        if (current.pos.eql(self.state.goal)) {
            try self.reconstructPath();
            self.finished = true;
            return .found;
        }

        var neighbors = try self.getNeighbors(current.pos);
        defer neighbors.deinit(self.allocator);
        for (neighbors.items) |neighbor| {
            const tentative_g = current.g_score + 1.0;
            const current_g = self.g_scores.get(neighbor) orelse std.math.inf(f32);

            if (tentative_g < current_g) {
                try self.parent.put(neighbor, current.pos);
                try self.g_scores.put(neighbor, tentative_g);
                const f_score = tentative_g + heuristic(neighbor, self.state.goal);

                const neighbor_state = self.state.getCellState(neighbor);
                if (neighbor_state == .unvisited) {
                    self.state.setCellState(neighbor, .frontier);
                    try self.open_set.append(self.allocator, .{ .pos = neighbor, .g_score = tentative_g, .f_score = f_score });
                } else {
                    for (self.open_set.items) |*node| {
                        if (node.pos.eql(neighbor)) {
                            node.g_score = tentative_g;
                            node.f_score = f_score;
                            break;
                        }
                    }
                }
            }
        }

        return .running;
    }

    pub fn reset(self: *AStarSolver) !void {
        self.state.reset();
        self.open_set.clearRetainingCapacity();
        self.parent.clearRetainingCapacity();
        self.g_scores.clearRetainingCapacity();
        const h = heuristic(self.state.start, self.state.goal);
        try self.open_set.append(.{ .pos = self.state.start, .g_score = 0, .f_score = h });
        try self.g_scores.put(self.state.start, 0);
        self.state.setCellState(self.state.start, .frontier);
        self.finished = false;
    }

    fn findLowestFScore(self: *AStarSolver) usize {
        var min_idx: usize = 0;
        var min_score = self.open_set.items[0].f_score;
        for (self.open_set.items, 0..) |node, i| {
            if (node.f_score < min_score) {
                min_score = node.f_score;
                min_idx = i;
            }
        }
        return min_idx;
    }

    fn heuristic(a: Position, b: Position) f32 {
        const dx = @abs(@as(i16, a.x) - @as(i16, b.x));
        const dy = @abs(@as(i16, a.y) - @as(i16, b.y));
        return @as(f32, @floatFromInt(dx + dy));
    }

    fn reconstructPath(self: *AStarSolver) !void {
        var current = self.state.goal;
        while (!current.eql(self.state.start)) {
            self.state.setCellState(current, .path);
            current = self.parent.get(current) orelse return;
        }
        self.state.setCellState(self.state.start, .path);
    }

    fn getNeighbors(self: *AStarSolver, pos: Position) !std.ArrayList(Position) {
        var neighbors: std.ArrayList(Position) = .{};
        const cell = self.maze.cells[pos.y][pos.x];

        if (!cell.north and pos.y > 0) {
            try neighbors.append(self.allocator, .{ .x = pos.x, .y = pos.y - 1 });
        }
        if (!cell.east and pos.x < 15) {
            try neighbors.append(self.allocator, .{ .x = pos.x + 1, .y = pos.y });
        }
        if (!cell.south and pos.y < 15) {
            try neighbors.append(self.allocator, .{ .x = pos.x, .y = pos.y + 1 });
        }
        if (!cell.west and pos.x > 0) {
            try neighbors.append(self.allocator, .{ .x = pos.x - 1, .y = pos.y });
        }

        return neighbors;
    }
};
