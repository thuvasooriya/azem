const std = @import("std");
const dvui = @import("dvui");

const azem = @import("azem.zig");
const App = azem.App;
const Engine = @This();
const Maze = azem.Maze;

/// this arena is for small per-frame editor allocations, such as path joins, null terminations and labels.
/// do not free these allocations, instead, this allocator will be .reset(.retain_capacity) each frame
arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,

var cached_mazes: ?[3]Maze.DVUIMazeData = null;

fn getExampleMazes(allocator: std.mem.Allocator) ![3]Maze.DVUIMazeData {
    if (cached_mazes) |mazes| return mazes;

    cached_mazes = try Maze.Examples.getExampleMazes(allocator);
    return cached_mazes.?;
}

pub fn init(app: *App) !Engine {
    const eng: Engine = .{
        .arena = std.heap.ArenaAllocator.init(std.heap.page_allocator),
        .allocator = app.allocator,
    };
    return eng;
}

const tl_opts: dvui.Options = .{ .expand = .horizontal, .font_style = .title_2, .background = false };

pub fn tick(eng: *Engine) !dvui.App.Result {
    _ = eng;
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

    // horizontal : (maze/console) | sidebar
    var sidebar_paned = dvui.paned(@src(), .{
        .direction = .horizontal,
        .collapsed_size = 500,
        .handle_size = azem.thm.size_handle,
        .uncollapse_ratio = azem.thm.ratio_sidebar,
    }, .{
        .expand = .both,
        .margin = azem.thm.size_margin_azem,
    });
    defer sidebar_paned.deinit();

    if (dvui.firstFrame(sidebar_paned.wd.id)) {
        sidebar_paned.split_ratio.* = azem.thm.ratio_sidebar;
    }

    if (sidebar_paned.showFirst()) {
        // vertical : maze / console
        var console_paned = dvui.paned(
            @src(),
            .{
                .direction = .vertical,
                .collapsed_size = 500,
                .handle_size = azem.thm.size_handle,
                .uncollapse_ratio = azem.thm.ratio_console,
            },
            .{ .expand = .both },
        );
        defer console_paned.deinit();
        if (dvui.firstFrame(console_paned.wd.id)) console_paned.split_ratio.* = azem.thm.ratio_console;

        if (console_paned.showFirst()) try maze_layout();
        if (console_paned.showSecond()) try console_layout();
    }

    if (sidebar_paned.showSecond()) try sidebar_layout();

    return .ok;
}

pub fn maze_layout() !void {
    const vbox = dvui.box(@src(), .{ .dir = .vertical }, .{
        .expand = .both,
        .background = true,
        .padding = azem.thm.size_padding_panel,
        .margin = azem.thm.size_margin_maze,
        .color_fill = .fromColor(azem.thm.color_fill_panel),
        .corner_radius = azem.thm.size_corner_radius_panel,
        .border = azem.thm.size_border_panel,
        .color_border = .fromColor(azem.colors.peach.opacity(0.2)),
    });
    defer vbox.deinit();

    try renderMaze();
}

pub fn console_layout() !void {
    const vbox2 = dvui.box(@src(), .{ .dir = .vertical }, .{
        .expand = .both,
        .background = true,
        .padding = azem.thm.size_padding_panel,
        .margin = azem.thm.size_margin_console,
        .color_fill = .fromColor(azem.thm.color_fill_panel),
        .corner_radius = azem.thm.size_corner_radius_panel,
        .border = azem.thm.size_border_panel,
        .color_border = .fromColor(azem.colors.green.opacity(0.2)),
    });
    defer vbox2.deinit();

    var tl = dvui.textLayout(@src(), .{}, .{
        .expand = .horizontal,
        .font_style = .title_2,
        .background = false,
        .color_text = .fromColor(azem.colors.green),
    });
    tl.format("console", .{}, .{});
    tl.deinit();
}

pub fn sidebar_layout() !void {
    const vbox = dvui.box(@src(), .{ .dir = .vertical }, .{
        .expand = .both,
        .background = true,
        .color_fill = .fromColor(azem.thm.color_fill_panel),
        .padding = azem.thm.size_padding_panel,
        .margin = azem.thm.size_margin_sidebar,
        .corner_radius = azem.thm.size_corner_radius_panel,
        .border = azem.thm.size_border_panel,
        .color_border = .fromColor(azem.colors.blue.opacity(0.2)),
    });
    defer vbox.deinit();

    var tl = dvui.textLayout(@src(), .{}, tl_opts);
    tl.format("controls", .{}, .{});
    tl.deinit();

    {
        var tl2 = dvui.textLayout(@src(), .{}, .{ .font_style = .title_4 });
        tl2.format("select maze:", .{}, .{});
        tl2.deinit();

        const maze_names = [_][]const u8{ "APEC 2018", "APEC 2017", "JAPAN 2017" };
        const global_maze_id: dvui.WidgetId = @enumFromInt(@as(u64, @bitCast([8]u8{ 'm', 'a', 'z', 'e', '_', 'i', 'd', 0 })));
        const selected_maze = dvui.dataGetPtrDefault(null, global_maze_id, "selected_maze", usize, 0);

        const selection_changed = dvui.dropdown(@src(), &maze_names, selected_maze, .{
            .expand = .horizontal,
            .min_size_content = .{ .h = 30 },
        });

        if (selection_changed) {
            dvui.refresh(null, @src(), global_maze_id);
            std.log.info("maze selection changed to: {s}", .{maze_names[selected_maze.*]});
        }

        var info_text = dvui.textLayout(@src(), .{}, .{ .font_style = .caption });
        info_text.format("selected: {s}", .{maze_names[selected_maze.*]}, .{});
        info_text.deinit();
    }

    _ = dvui.spacer(@src(), .{ .expand = .vertical });

    const label = if (dvui.Examples.show_demo_window) "Hide Demo" else "Show Demo";
    if (dvui.button(@src(), label, .{}, .{
        .tag = "show-demo-btn",
        .expand = .horizontal,
    })) {
        dvui.Examples.show_demo_window = !dvui.Examples.show_demo_window;
    }

    if (dvui.Examples.show_demo_window) {
        dvui.Examples.demo();
    }

    const btn_opts: dvui.Options = .{ .expand = .horizontal };
    {
        if (dvui.button(@src(), "Start Solving", .{}, btn_opts)) {
            // TODO: Start maze solving algorithm
        }
        if (dvui.button(@src(), "Reset", .{}, btn_opts)) {
            // TODO: Reset maze state
        }
        if (dvui.button(@src(), "Step", .{}, btn_opts)) {
            // TODO: Single step through algorithm
        }
    }
}

fn renderMaze() !void {
    var maze_box = dvui.box(@src(), .{}, .{ .expand = .both });
    defer maze_box.deinit();

    const global_maze_id: dvui.WidgetId = @enumFromInt(@as(u64, @bitCast([8]u8{ 'm', 'a', 'z', 'e', '_', 'i', 'd', 0 })));
    const selected_maze = dvui.dataGetPtrDefault(null, global_maze_id, "selected_maze", usize, 0);

    const temp_allocator = std.heap.page_allocator;
    const example_mazes = getExampleMazes(temp_allocator) catch |err| {
        var error_text = dvui.textLayout(@src(), .{}, .{ .color_text = .fromColor(azem.thm.color_error) });
        error_text.format("error loading maze: {}", .{err}, .{});
        error_text.deinit();
        return;
    };

    const maze_index = if (selected_maze.* >= example_mazes.len) 0 else selected_maze.*;
    const current_maze = &example_mazes[maze_index];

    const grid_size: comptime_int = 16;
    const box_rect = maze_box.data().rectScale().r;

    const padding: f32 = 20;
    const available_size = @min(box_rect.w, box_rect.h) - padding;
    const cell_size = available_size / @as(f32, @floatFromInt(grid_size));
    const total_size = @as(f32, @floatFromInt(grid_size)) * cell_size;

    const start_x = box_rect.x + (box_rect.w - total_size) * 0.5;
    const start_y = box_rect.y + (box_rect.h - total_size) * 0.5;

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

pub fn deinit(eng: *Engine) !void {
    eng.arena.deinit();
}
