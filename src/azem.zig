const std = @import("std");

const dvui = @import("dvui");

pub const version: std.SemanticVersion = .{
    .major = 0,
    .minor = 1,
    .patch = 4,
};

// modules
pub const Engine = @import("Engine.zig");
pub const Maze = @import("Maze.zig");
pub const App = @import("App.zig");
pub const Theme = @import("Theme.zig");
pub const Color = @import("Color.zig");

// helpers
pub const colors = Color.Palettes.CatppuccinMocha;

// global pointers
pub var eng: *Engine = undefined;
pub var app: *App = undefined;
pub var thm: *Theme = undefined;

pub const dvui_app: dvui.App = .{ .config = .{ .options = .{
    .size = .{ .w = 800.0, .h = 800.0 },
    .min_size = .{ .w = 400, .h = 400 },
    .title = "azem-dev",
    .window_init_options = .{},
} }, .frameFn = App.frame, .initFn = App.init, .deinitFn = App.deinit };

pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};
