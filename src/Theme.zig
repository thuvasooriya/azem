const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const azem = @import("azem.zig");
const objc = @import("objc");

const font1 = "JetBrainsMono-VariableFont_wght";
const font1italic = "JetBrainsMono-Italic-VariableFont_wght";
const jbm_ttf = @embedFile("fonts/" ++ font1 ++ ".ttf");
const jbm_italic_ttf = @embedFile("fonts/" ++ font1italic ++ ".ttf");

const Theme = @This();
const App = azem.App;
const Color = azem.Color;

name: []const u8 = undefined,
dark: bool = true,

color_background: dvui.Color = undefined,
color_fill_panel: dvui.Color = undefined,
color_fill_button: dvui.Color = undefined,

color_fill_window: dvui.Color = undefined,
color_fill_hover: dvui.Color = undefined,
color_fill_press: dvui.Color = undefined,
color_fill_control: dvui.Color = undefined,
color_border: dvui.Color = undefined,

color_text: dvui.Color = undefined,
color_primary: dvui.Color = undefined,
color_secondary: dvui.Color = undefined,
color_accent: dvui.Color = undefined,
color_error: dvui.Color = undefined,
color_success: dvui.Color = undefined,

color_maze_walls: dvui.Color = undefined,

size_font: f32 = undefined,
size_handle: f32 = undefined,
size_gap_panel: f32 = undefined,
size_border_panel: dvui.Rect = undefined,
size_border_thin: dvui.Rect = undefined,
size_padding_panel: dvui.Rect = undefined,
size_corner_radius_panel: dvui.Rect = undefined,

size_margin_azem: dvui.Rect = undefined,
size_margin_symmetric_handle: f32 = undefined,

ratio_sidebar: f32 = undefined,
ratio_console: f32 = undefined,

allocator: std.mem.Allocator = undefined,
app: *App = undefined,

pub fn init(
    app: *App,
) !Theme {
    dvui.addFont(font1, jbm_ttf, null) catch {};
    dvui.addFont(font1italic, jbm_italic_ttf, null) catch {};

    var thm: Theme = .{
        .allocator = app.allocator,
        .app = app,
        .name = "test",
        .color_background = azem.colors.crust,
        .color_fill_panel = azem.colors.crust,
        .color_fill_window = azem.colors.crust,
        .color_fill_hover = azem.colors.base,
        .color_fill_press = azem.colors.surface0,
        .color_fill_control = azem.colors.mantle,
        .color_primary = azem.colors.blue,
        .color_secondary = azem.colors.mauve,
        .color_accent = azem.colors.yellow,
        .color_text = azem.colors.text,
        .color_error = azem.colors.red,
        .color_success = azem.colors.green,
        .color_border = azem.colors.base,

        .color_maze_walls = azem.colors.peach.opacity(0.7),

        .size_font = 16,
        .size_gap_panel = 10,

        .size_padding_panel = .all(10),
        .size_border_panel = .all(1),
        .size_border_thin = .all(1),
        .size_corner_radius_panel = .all(9),

        .ratio_console = 0.7,
        .ratio_sidebar = 0.7,
    };
    thm.size_margin_azem = switch (dvui.backend.kind) {
        .web => .all(thm.size_gap_panel),
        else => .{ .x = thm.size_gap_panel, .y = 0, .h = thm.size_gap_panel, .w = thm.size_gap_panel },
    };
    thm.size_handle = thm.size_font / 8;
    thm.size_margin_symmetric_handle = (thm.size_gap_panel - thm.size_handle) / 2;
    return thm;
}

pub fn set(
    app: *App,
    thm: *Theme,
) void {
    var theme = dvui.themeGet();
    theme.dark = thm.dark;
    theme.name = thm.name;
    theme.fill = thm.color_background;
    theme.window.fill = thm.color_fill_window;

    theme.text = thm.color_text;
    theme.text_press = thm.color_text;

    theme.control.fill = thm.color_fill_control;
    theme.fill_hover = thm.color_fill_hover;
    theme.border = thm.color_border;
    theme.fill_press = thm.color_fill_press;
    theme.highlight.fill = thm.color_accent;
    theme.err.fill = thm.color_error;

    theme.font_body = .{ .id = .fromName(font1), .size = thm.size_font };
    theme.font_caption = .{ .id = .fromName(font1italic), .size = (thm.size_font - 2) };
    theme.font_title = .{ .id = .fromName(font1), .size = (thm.size_font - 1) };
    theme.font_title_1 = .{ .id = .fromName(font1), .size = (thm.size_font + 1) };
    theme.font_title_2 = .{ .id = .fromName(font1), .size = thm.size_font };
    theme.font_title_3 = .{ .id = .fromName(font1), .size = (thm.size_font - 1) };
    theme.font_heading = .{ .id = .fromName(font1), .size = (thm.size_font - 1) };
    theme.font_title_4 = .{ .id = .fromName(font1italic), .size = (thm.size_font - 2) };

    setTitlebarColor(app.window, theme.fill);
    dvui.themeSet(theme);
}

fn setTitlebarColor(win: *dvui.Window, color: dvui.Color) void {
    // this sets the native window titlebar color on macos currently only for sdl3
    if (builtin.os.tag == .macos) {
        switch (dvui.backend.kind) {
            .sdl3 => {
                const native_window: ?*objc.app_kit.Window = @ptrCast(
                    dvui.backend.c.SDL_GetPointerProperty(
                        dvui.backend.c.SDL_GetWindowProperties(win.backend.impl.window),
                        dvui.backend.c.SDL_PROP_WINDOW_COCOA_WINDOW_POINTER,
                        null,
                    ),
                );
                if (native_window) |window| {
                    window.setTitlebarAppearsTransparent(true);
                    const nc = Color.toNormalizedRGBA(color);
                    window.setBackgroundColor(
                        objc.app_kit.Color.colorWithRed_green_blue_alpha(nc.r, nc.g, nc.b, nc.a),
                    );
                }
            },
            else => {
                std.log("skipping titlebar color config for this backend", .{});
            },
        }
    }
}
