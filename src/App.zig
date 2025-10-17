const std = @import("std");
const dvui = @import("dvui");

const azem = @import("azem.zig");

// modules
const App = @This();
const Engine = azem.Engine;
const Theme = azem.Theme;

// app fields
allocator: std.mem.Allocator = undefined,
root_path: [:0]const u8 = undefined,
window: *dvui.Window = undefined,

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;

// runs before the first frame, after backend and dvui.window.init()
pub fn init(win: *dvui.Window) !void {
    const allocator = gpa.allocator();

    std.log.info("creating azem.app", .{});
    azem.app = try allocator.create(App);
    azem.app.* = .{
        .allocator = allocator,
        .window = win,
    };

    switch (dvui.backend.kind) {
        .web => {
            std.log.info("web: skipping chdir", .{});
        },
        else => {
            // run from the executable directory to locate relative assets
            var buffer: [1024]u8 = undefined;
            const path = std.fs.selfExeDirPath(buffer[0..]) catch ".";
            std.posix.chdir(path) catch {};
            azem.app.* = .{ .root_path = allocator.dupeZ(u8, path) catch "." };
        },
    }

    std.log.info("creating azem.eng", .{});
    azem.eng = try allocator.create(Engine);
    azem.eng.* = Engine.init(azem.app) catch unreachable;

    std.log.info("creating azem.thm", .{});
    azem.thm = try allocator.create(Theme);
    azem.thm.* = Theme.init(azem.app) catch unreachable;
    Theme.set(azem.app, azem.thm);

    // initialize new theme system
    std.log.info("initializing new theme system", .{});
    const jbm_ttf = @embedFile("fonts/JetBrainsMono-VariableFont_wght.ttf");
    const jbm_italic_ttf = @embedFile("fonts/JetBrainsMono-Italic-VariableFont_wght.ttf");
    dvui.addFont("JetBrainsMono-VariableFont_wght", jbm_ttf, null) catch {};
    dvui.addFont("JetBrainsMono-Italic-VariableFont_wght", jbm_italic_ttf, null) catch {};

    azem.new_thm = &azem.theme.presets.catppuccin_mocha;
    azem.new_thm.apply();
}

pub fn deinit() void {
    azem.eng.deinit() catch unreachable;
}

pub fn frame() !dvui.App.Result {
    return try azem.eng.tick();
}
