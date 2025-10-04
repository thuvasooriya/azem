const std = @import("std");
const dvui = @import("dvui");

const azem = @import("azem.zig");
const App = azem.App;
const Engine = @This();
const Maze = azem.Maze;

/// this arena is for small per-frame editor allocations
arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,

const maze_names = Maze.Examples.maze_names;
var cached_mazes: ?[10]Maze.DVUIMazeData = null;
var console_state: ?ConsoleState = null;
var pane_state: ?PaneState = null;

pub fn init(app: *App) !Engine {
    return Engine{
        .arena = std.heap.ArenaAllocator.init(std.heap.page_allocator),
        .allocator = app.allocator,
    };
}

pub fn tick(eng: *Engine) !dvui.App.Result {
    var scaler = dvui.scale(@src(), .{
        .scale = &dvui.currentWindow().content_scale,
        .pinch_zoom = .global,
    }, .{
        .expand = .both,
        .rect = .cast(dvui.windowRect()),
        .background = true,
        .color_fill = .fromColor(azem.thm.color_background),
    });
    scaler.deinit();

    const pane_state_ptr = getPaneState(eng.allocator);
    cached_mazes = cached_mazes orelse try Maze.Examples.getExampleMazes(eng.allocator);

    var sidebar_paned = dvui.paned(@src(), .{
        .direction = .horizontal,
        .split_ratio = &pane_state_ptr.sidebar_split,
        .collapsed_size = 500,
        .handle_size = azem.thm.size_handle,
        .handle_margin = azem.thm.size_margin_symmetric_handle,
        .handle_dynamic = .{ .handle_size_max = azem.thm.size_handle, .distance_max = 200 },
        .uncollapse_ratio = azem.thm.ratio_sidebar,
    }, .{
        .expand = .both,
        .margin = azem.thm.size_margin_azem,
    });
    defer sidebar_paned.deinit();

    if (pane_state_ptr.switch_to_sidebar) {
        pane_state_ptr.switch_to_sidebar = false;
        sidebar_paned.animateSplit(0);
        pane_state_ptr.active_pane = .sidebar;
    }

    const switch_to_maze = pane_state_ptr.switch_to_maze;
    pane_state_ptr.switch_to_maze = false;
    if (switch_to_maze) {
        sidebar_paned.animateSplit(1);
    }

    if (dvui.firstFrame(sidebar_paned.wd.id)) {
        sidebar_paned.split_ratio.* = azem.thm.ratio_sidebar;
    }

    if (sidebar_paned.showFirst()) {
        var console_paned = dvui.paned(@src(), .{
            .direction = .vertical,
            .split_ratio = &pane_state_ptr.console_split,
            .collapsed_size = 500,
            .handle_size = azem.thm.size_handle,
            .handle_dynamic = .{ .handle_size_max = azem.thm.size_handle, .distance_max = 200 },
            .handle_margin = azem.thm.size_margin_symmetric_handle,
            .uncollapse_ratio = azem.thm.ratio_console,
        }, .{ .expand = .both });
        defer console_paned.deinit();

        if (pane_state_ptr.switch_to_console) {
            pane_state_ptr.switch_to_console = false;
            console_paned.animateSplit(0);
            pane_state_ptr.active_pane = .console;
        }

        if (switch_to_maze) {
            console_paned.animateSplit(1);
        }

        if (dvui.firstFrame(console_paned.wd.id)) console_paned.split_ratio.* = azem.thm.ratio_console;

        if (console_paned.showFirst()) try maze_layout();
        if (console_paned.showSecond()) try console_layout();
    }
    if (sidebar_paned.showSecond()) try sidebar_layout();

    return .ok;
}

pub fn maze_layout() !void {
    const vbox = dvui.box(@src(), .{ .dir = .vertical }, .{
        .expand = .ratio,
        .background = true,
        .padding = azem.thm.size_padding_panel,
        .color_fill = .fromColor(azem.thm.color_fill_panel),
        .corner_radius = azem.thm.size_corner_radius_panel,
        .border = azem.thm.size_border_panel,
        .color_border = .fromColor(azem.colors.peach.opacity(0.2)),
    });
    defer vbox.deinit();

    var maze_box = dvui.box(@src(), .{}, .{ .expand = .both });
    defer maze_box.deinit();

    const global_maze_id: dvui.WidgetId = @enumFromInt(@as(u64, @bitCast([8]u8{ 'm', 'a', 'z', 'e', '_', 'i', 'd', 0 })));
    const selected_maze = dvui.dataGetPtrDefault(null, global_maze_id, "selected_maze", usize, 0);

    const console = getConsoleState(std.heap.page_allocator);
    const pane_state_ptr = getPaneState(std.heap.page_allocator);

    const maze_index = if (selected_maze.* >= cached_mazes.?.len) 0 else selected_maze.*;
    const current_maze = &cached_mazes.?[maze_index];

    const grid_size: comptime_int = 16;
    const box_rect = maze_box.data().rectScale().r;

    const padding: f32 = 20;
    const available_size = @min(box_rect.w, box_rect.h) - padding;
    const cell_size = available_size / @as(f32, @floatFromInt(grid_size));
    const total_size = @as(f32, @floatFromInt(grid_size)) * cell_size;

    const start_x = box_rect.x + (box_rect.w - total_size) * 0.5;
    const start_y = box_rect.y + (box_rect.h - total_size) * 0.5;

    const grid_color = azem.colors.overlay0.opacity(0.18);
    const grid_thickness: f32 = cell_size * 0.07;
    for (0..grid_size) |i| {
        const x = start_x + @as(f32, @floatFromInt(i)) * cell_size;
        dvui.Path.stroke(.{ .points = &.{ .{ .x = x, .y = start_y }, .{ .x = x, .y = start_y + total_size } } }, .{ .thickness = grid_thickness, .color = grid_color });
        const y = start_y + @as(f32, @floatFromInt(i)) * cell_size;
        dvui.Path.stroke(.{ .points = &.{ .{ .x = start_x, .y = y }, .{ .x = start_x + total_size, .y = y } } }, .{ .thickness = grid_thickness, .color = grid_color });
    }

    const wall_color = azem.thm.color_maze_walls;
    const wall_thickness: f32 = @max(2.0, cell_size * 0.08);

    for (current_maze.cells, 0..) |row, row_idx| {
        for (row, 0..) |cell, col_idx| {
            const cell_x = start_x + @as(f32, @floatFromInt(col_idx)) * cell_size;
            const cell_y = start_y + @as(f32, @floatFromInt(row_idx)) * cell_size;

            if (cell.north) {
                dvui.Path.stroke(.{ .points = &.{
                    .{ .x = cell_x, .y = cell_y },
                    .{ .x = cell_x + cell_size, .y = cell_y },
                } }, .{ .thickness = wall_thickness, .color = wall_color });
            }

            if (cell.east) {
                dvui.Path.stroke(.{ .points = &.{
                    .{ .x = cell_x + cell_size, .y = cell_y },
                    .{ .x = cell_x + cell_size, .y = cell_y + cell_size },
                } }, .{ .thickness = wall_thickness, .color = wall_color });
            }

            if (cell.south) {
                dvui.Path.stroke(.{ .points = &.{
                    .{ .x = cell_x, .y = cell_y + cell_size },
                    .{ .x = cell_x + cell_size, .y = cell_y + cell_size },
                } }, .{ .thickness = wall_thickness, .color = wall_color });
            }

            if (cell.west) {
                dvui.Path.stroke(.{ .points = &.{
                    .{ .x = cell_x, .y = cell_y },
                    .{ .x = cell_x, .y = cell_y + cell_size },
                } }, .{ .thickness = wall_thickness, .color = wall_color });
            }
        }
    }

    if (pane_state_ptr.isSidebarCollapsed()) {
        var info_layout = dvui.textLayout(@src(), .{}, .{
            .font_style = .title_4,
            .gravity_x = 0.5,
            .background = true,
            .color_fill = .fromColor(azem.thm.color_fill_window.opacity(0.7)),
            .color_text = .fromColor(azem.colors.peach),
            .padding = .{ .x = 8, .y = 4, .w = 8, .h = 4 },
            .corner_radius = .{ .x = 4, .y = 4, .w = 4, .h = 4 },
        });
        info_layout.format("{s}", .{current_maze.name}, .{});
        info_layout.deinit();
    }

    if (pane_state_ptr.isSidebarCollapsed() or pane_state_ptr.isConsoleCollapsed()) {
        var tooltip: dvui.FloatingTooltipWidget = .init(@src(), .{
            .active_rect = vbox.data().borderRectScale().r,
            .interactive = true,
            .position = .sticky,
        }, .{
            .background = true,
        });
        defer tooltip.deinit();

        if (tooltip.shown()) {
            var animator = dvui.animate(@src(), .{ .kind = .alpha, .duration = 250_000 }, .{ .expand = .both });
            defer animator.deinit();

            var controls_box = dvui.box(@src(), .{ .dir = .vertical }, .{
                .expand = .both,
            });
            defer controls_box.deinit();

            if (pane_state_ptr.isSidebarCollapsed()) {
                if (dvui.button(@src(), "show sidebar", .{}, .{
                    .expand = .horizontal,
                    .min_size_content = .{ .h = 16 },
                    .color_fill = .fromColor(azem.colors.blue.opacity(0.3)),
                    .corner_radius = .all(4),
                    .font_style = .caption,
                })) {
                    pane_state_ptr.switchToSidebar();
                    console.addMessage(.info, "switched to sidebar", .{}) catch {};
                }
            }

            if (pane_state_ptr.isConsoleCollapsed()) {
                if (dvui.button(@src(), "show console", .{}, .{
                    .expand = .horizontal,
                    .min_size_content = .{ .h = 16 },
                    .color_fill = .fromColor(azem.colors.green.opacity(0.3)),
                    .corner_radius = .all(4),
                    .font_style = .caption,
                })) {
                    pane_state_ptr.switchToConsole();
                    console.addMessage(.info, "switched to console", .{}) catch {};
                }
            }
        }
    }
}

pub fn console_layout() !void {
    const vbox = dvui.box(@src(), .{ .dir = .vertical }, .{
        .expand = .both,
        .background = true,
        .padding = azem.thm.size_padding_panel,
        .color_fill = .fromColor(azem.thm.color_fill_panel),
        .corner_radius = azem.thm.size_corner_radius_panel,
        .border = azem.thm.size_border_panel,
        .color_border = .fromColor(azem.colors.green.opacity(0.2)),
    });
    defer vbox.deinit();

    const console = getConsoleState(std.heap.page_allocator);
    const pane_state_ptr = getPaneState(std.heap.page_allocator);
    {
        var scroll_area = dvui.scrollArea(@src(), .{
            .scroll_info = &console.scroll_info,
            .vertical_bar = .auto_overlay,
            .horizontal_bar = .hide,
        }, .{
            .expand = .both,
            .background = false,
        });
        defer scroll_area.deinit();

        if (console.messages.items.len == 0) {
            var empty_text = dvui.textLayout(@src(), .{}, .{
                .font_style = .body,
                .color_text = .fromColor(azem.colors.overlay0),
                .gravity_x = 0.5,
                .gravity_y = 0.5,
                .expand = .both,
            });
            empty_text.format("no messages yet...\ntry selecting a maze or clicking a button!", .{}, .{});
            empty_text.deinit();
        } else {
            for (console.messages.items, 0..) |msg, i| {
                var msg_box = dvui.box(@src(), .{ .dir = .horizontal }, .{
                    .id_extra = i,
                    .expand = .horizontal,
                    .background = (i % 2 == 0),
                    .color_fill = if (i % 2 == 0)
                        .fromColor(azem.colors.surface0.opacity(0.4))
                    else
                        undefined,
                    .corner_radius = .all(4),
                    // .padding = .{ .x = 6, .y = 3, .w = 6, .h = 3 },
                });
                defer msg_box.deinit();

                switch (dvui.backend.kind) {
                    .web => {},
                    else => {
                        var timestamp_buffer: [64]u8 = undefined;
                        const timestamp_str = ConsoleState.formatTimestamp(msg.timestamp, &timestamp_buffer) catch "???";

                        var timestamp_text = dvui.textLayout(@src(), .{}, .{
                            .font_style = .body,
                            .color_text = .fromColor(azem.colors.overlay1),
                            .min_size_content = .{ .w = 50 },
                            .background = false,
                        });
                        timestamp_text.format("{s}", .{timestamp_str}, .{});
                        timestamp_text.deinit();
                    },
                }

                // var prefix_text = dvui.textLayout(@src(), .{}, .{
                //     .font_style = .body,
                //     .color_text = .fromColor(msg.level.getColor()),
                //     .min_size_content = .{ .w = 20 },
                //     .background = false,
                // });
                // prefix_text.format("{s}", .{msg.level.getPrefix()}, .{});
                // prefix_text.deinit();

                var content_text = dvui.textLayout(@src(), .{}, .{
                    .font_style = .body,
                    .color_text = .fromColor(msg.level.getColor()),
                    .expand = .horizontal,
                    .background = false,
                });
                content_text.format("{s}", .{msg.text}, .{});
                content_text.deinit();
            }
        }
        {
            var tt: dvui.FloatingTooltipWidget = .init(@src(), .{
                .active_rect = vbox.data().borderRectScale().r,
                .interactive = true,
                .position = .sticky,
            }, .{
                .background = false,
                .border = .{},
            });
            defer tt.deinit();
            if (tt.shown()) {
                var animator = dvui.animate(@src(), .{ .kind = .alpha, .duration = 250_000 }, .{ .expand = .both });
                defer animator.deinit();

                var vbox2 = dvui.box(@src(), .{ .dir = .horizontal }, dvui.FloatingTooltipWidget.defaults.override(.{
                    .expand = .both,
                }));
                defer vbox2.deinit();

                const auto_scroll_label = if (console.auto_scroll) "auto" else "manual";
                if (dvui.button(@src(), auto_scroll_label, .{}, .{
                    .min_size_content = .{ .w = 50, .h = 16 },
                    .color_fill = if (console.auto_scroll)
                        .fromColor(azem.colors.green.opacity(0.3))
                    else
                        .fromColor(azem.colors.surface1),
                })) {
                    console.auto_scroll = !console.auto_scroll;
                    console.addMessage(.info, "auto-scroll {s}", .{if (console.auto_scroll) "enabled" else "disabled"}) catch {};
                }

                if (dvui.button(@src(), "clear", .{}, .{
                    .min_size_content = .{ .w = 50, .h = 16 },
                    .color_fill = .fromColor(azem.colors.red.opacity(0.2)),
                })) {
                    console.clear();
                    console.addMessage(.success, "console cleared", .{}) catch {};
                }
                if (pane_state_ptr.isMazeCollapsed()) {
                    if (dvui.button(@src(), "show maze", .{}, .{
                        .expand = .horizontal,
                        .min_size_content = .{ .h = 16 },
                        .color_fill = .fromColor(azem.colors.peach.opacity(0.3)),
                        .corner_radius = .all(4),
                        .font_style = .caption,
                    })) {
                        pane_state_ptr.switchToMaze();
                        console.addMessage(.info, "switched to maze", .{}) catch {};
                    }
                }

                if (pane_state_ptr.isSidebarCollapsed()) {
                    if (dvui.button(@src(), "show sidebar", .{}, .{
                        .expand = .horizontal,
                        .min_size_content = .{ .h = 16 },
                        .color_fill = .fromColor(azem.colors.blue.opacity(0.3)),
                        .corner_radius = .all(4),
                        .font_style = .caption,
                    })) {
                        pane_state_ptr.switchToSidebar();
                        console.addMessage(.info, "switched to sidebar", .{}) catch {};
                    }
                }
            }
        }
    }

    if (console.scroll_to_bottom_after) {
        console.scroll_info.scrollToOffset(.vertical, std.math.maxInt(usize));
        console.scroll_to_bottom_after = false;
    }
}

pub fn sidebar_layout() !void {
    const vbox = dvui.box(@src(), .{ .dir = .vertical }, .{
        .expand = .both,
        .background = true,
        .color_fill = .fromColor(azem.thm.color_fill_panel),
        .padding = azem.thm.size_padding_panel,
        .corner_radius = azem.thm.size_corner_radius_panel,
        .border = azem.thm.size_border_panel,
        .color_border = .fromColor(azem.colors.blue.opacity(0.2)),
    });
    defer vbox.deinit();

    const console = getConsoleState(std.heap.page_allocator);
    const pane_state_ptr = getPaneState(std.heap.page_allocator);

    var tl = dvui.textLayout(@src(), .{}, .{
        .font_style = .title_2,
        .background = false,
        .color_text = .fromColor(azem.colors.blue),
        .gravity_x = 0.5,
    });
    tl.format("controls", .{}, .{});
    tl.deinit();

    var tl2 = dvui.textLayout(@src(), .{}, .{ .font_style = .title_4 });
    tl2.format("select maze:", .{}, .{});
    tl2.deinit();

    const global_maze_id: dvui.WidgetId = @enumFromInt(@as(u64, @bitCast([8]u8{ 'm', 'a', 'z', 'e', '_', 'i', 'd', 0 })));
    const selected_maze = dvui.dataGetPtrDefault(null, global_maze_id, "selected_maze", usize, 0);
    const previous_selection = dvui.dataGetPtrDefault(null, global_maze_id, "prev_selection", usize, std.math.maxInt(usize));

    const selection_changed = dvui.dropdown(@src(), &maze_names, selected_maze, .{
        .expand = .horizontal,
        .min_size_content = .{ .h = 30 },
    });

    if (selection_changed or previous_selection.* != selected_maze.*) {
        dvui.refresh(null, @src(), global_maze_id);

        if (previous_selection.* == std.math.maxInt(usize)) {
            console.addMessage(.success, "loaded maze: {s}", .{maze_names[selected_maze.*]}) catch {};
        } else {
            console.addMessage(.info, "changed maze: {s} -> {s}", .{ maze_names[previous_selection.*], maze_names[selected_maze.*] }) catch {};
        }
        previous_selection.* = selected_maze.*;
    }

    _ = dvui.spacer(@src(), .{ .expand = .vertical });

    const btn_opts: dvui.Options = .{ .expand = .horizontal };
    if (dvui.button(@src(), "start solving", .{}, btn_opts)) {
        console.addMessage(.success, "maze solving algorithm started!", .{}) catch {};
        console.addMessage(.info, "analyzing maze structure...", .{}) catch {};
    }

    if (dvui.button(@src(), "reset", .{}, btn_opts)) {
        console.addMessage(.warning, "maze state reset", .{}) catch {};
    }

    if (dvui.button(@src(), "step", .{}, btn_opts)) {
        console.addMessage(.info, "single step executed", .{}) catch {};
    }

    if (pane_state_ptr.isSidebarOnly()) {
        var tooltip: dvui.FloatingTooltipWidget = .init(@src(), .{
            .active_rect = vbox.data().borderRectScale().r,
            .interactive = true,
            .position = .sticky,
        }, .{
            .background = true,
        });
        defer tooltip.deinit();

        if (tooltip.shown()) {
            var animator = dvui.animate(@src(), .{ .kind = .alpha, .duration = 250_000 }, .{ .expand = .both });
            defer animator.deinit();

            var controls_box = dvui.box(@src(), .{ .dir = .vertical }, .{
                .expand = .both,
            });
            defer controls_box.deinit();

            if (dvui.button(@src(), "show maze/console", .{}, .{
                .expand = .horizontal,
                .min_size_content = .{ .h = 16 },
                .color_fill = .fromColor(azem.colors.peach.opacity(0.3)),
                .corner_radius = .all(4),
                .font_style = .caption,
            })) {
                pane_state_ptr.switchToMaze();
                console.addMessage(.info, "switched to maze/console", .{}) catch {};
            }
        }
    }
}

pub fn deinit(eng: *Engine) !void {
    if (console_state) |*console| {
        console.deinit();
        console_state = null;
    }
    eng.arena.deinit();
}

fn getConsoleState(allocator: std.mem.Allocator) *ConsoleState {
    if (console_state == null) {
        console_state = ConsoleState.init(allocator);
        console_state.?.addMessage(.info, "maze console initialized", .{}) catch {};
        console_state.?.addMessage(.info, "select a maze and start exploring!", .{}) catch {};
    }
    return &console_state.?;
}

fn getPaneState(allocator: std.mem.Allocator) *PaneState {
    if (pane_state == null) {
        pane_state = PaneState.init(allocator);
    }
    return &pane_state.?;
}

const ConsoleMessage = struct {
    text: []const u8,
    timestamp: u64,
    level: MessageLevel,

    const MessageLevel = enum {
        info,
        success,
        warning,
        err,

        pub fn getColor(self: MessageLevel) dvui.Color {
            return switch (self) {
                .info => azem.colors.text,
                .success => azem.colors.green,
                .warning => azem.colors.yellow,
                .err => azem.colors.red,
            };
        }

        // pub fn getPrefix(self: MessageLevel) []const u8 {
        //     return switch (self) {
        //         .info => "[i]",
        //         .success => "[s]",
        //         .warning => "[!]",
        //         .err => "[e]",
        //     };
        // }
    };
};

const ConsoleState = struct {
    messages: std.ArrayList(ConsoleMessage),
    scroll_info: dvui.ScrollInfo = .{},
    auto_scroll: bool = true,
    max_messages: usize = 1000,
    message_counter: u64 = 0,
    app_start_time: u64,
    scroll_to_bottom_after: bool = false,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        const start_time = if (dvui.backend.kind == .web)
            0
        else
            @as(u64, @intCast(@max(0, std.time.milliTimestamp())));

        return Self{
            .messages = std.ArrayList(ConsoleMessage).init(allocator),
            .app_start_time = start_time,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.messages.items) |msg| {
            self.messages.allocator.free(msg.text);
        }
        self.messages.deinit();
    }

    fn getTimestamp(self: *Self) u64 {
        self.message_counter += 1;

        if (dvui.backend.kind == .web) {
            return self.message_counter;
        } else {
            const current_time = @as(u64, @intCast(@max(0, std.time.milliTimestamp())));
            return current_time - self.app_start_time;
        }
    }

    fn formatTimestamp(timestamp: u64, buffer: []u8) ![]const u8 {
        if (dvui.backend.kind == .web) {
            return try std.fmt.bufPrint(buffer, "#{d:0>3}", .{timestamp});
        } else {
            const total_seconds = @divTrunc(timestamp, 1000);
            const minutes = @divTrunc(total_seconds, 60);
            const seconds = @mod(total_seconds, 60);
            const ms = @mod(timestamp, 1000);
            const display_minutes = @min(minutes, 99);
            return try std.fmt.bufPrint(buffer, "{d:0>2}:{d:0>2}.{d:0>3}", .{ display_minutes, seconds, ms });
        }
    }

    pub fn addMessage(self: *Self, level: ConsoleMessage.MessageLevel, comptime fmt: []const u8, args: anytype) !void {
        const timestamp = self.getTimestamp();
        const message_text = try std.fmt.allocPrint(self.messages.allocator, fmt, args);

        const msg = ConsoleMessage{
            .text = message_text,
            .timestamp = timestamp,
            .level = level,
        };

        try self.messages.append(msg);

        if (self.messages.items.len > self.max_messages) {
            const old_msg = self.messages.orderedRemove(0);
            self.messages.allocator.free(old_msg.text);
        }

        if (self.auto_scroll) {
            self.scroll_to_bottom_after = true;
        }
    }

    pub fn clear(self: *Self) void {
        for (self.messages.items) |msg| {
            self.messages.allocator.free(msg.text);
        }
        self.messages.clearRetainingCapacity();
    }
};

const PaneState = struct {
    sidebar_split: f32 = 0.5,
    console_split: f32 = 0.5,
    active_pane: ActivePane = .maze,
    allocator: std.mem.Allocator = undefined,
    switch_to_sidebar: bool = false,
    switch_to_console: bool = false,
    switch_to_maze: bool = false,

    const ActivePane = enum {
        maze,
        console,
        sidebar,

        pub fn getName(self: ActivePane) []const u8 {
            return switch (self) {
                .maze => "maze",
                .console => "console",
                .sidebar => "sidebar",
            };
        }
    };

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn isMazeCollapsed(self: *Self) bool {
        return self.console_split == 0;
    }
    pub fn isConsoleCollapsed(self: *Self) bool {
        return self.console_split == 1;
    }
    pub fn isSidebarCollapsed(self: *Self) bool {
        return self.sidebar_split == 1;
    }
    pub fn isSidebarOnly(self: *Self) bool {
        return self.sidebar_split == 0;
    }

    pub fn switchToSidebar(self: *Self) void {
        self.switch_to_sidebar = true;
    }

    pub fn switchToConsole(self: *Self) void {
        self.switch_to_console = true;
    }

    pub fn switchToMaze(self: *Self) void {
        self.switch_to_maze = true;
    }
};
