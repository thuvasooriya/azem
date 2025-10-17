const dvui = @import("dvui");
const std = @import("std");

var current_theme: ?*const Theme = null;

pub fn setTheme(theme: *const Theme) void {
    current_theme = theme;
}

fn getTheme() *const Theme {
    return current_theme orelse @panic("theme not initialized");
}

const Theme = @import("theme.zig").Theme;

pub fn panel(accent_color: dvui.Color) dvui.Options {
    const layout = getTheme().layout;
    return .{
        .expand = .both,
        .background = true,
        .padding = layout.padding_panel,
        .corner_radius = layout.corner_radius_panel,
        .border = layout.border_panel,
        .color_border = accent_color.opacity(0.2),
    };
}

pub fn compactPanel(accent_color: dvui.Color) dvui.Options {
    const layout = getTheme().layout;
    return .{
        .expand = .both,
        .background = true,
        .padding = layout.padding_compact,
        .corner_radius = layout.corner_radius_button,
        .border = layout.border_thin,
        .color_border = accent_color.opacity(0.3),
    };
}

pub fn accentButton(color: dvui.Color) dvui.Options {
    const layout = getTheme().layout;
    return .{
        .expand = .horizontal,
        .min_size_content = .{ .h = layout.min_button_height },
        .color_fill = color.opacity(0.3),
        .corner_radius = layout.corner_radius_button,
        .font_style = .caption,
    };
}

pub fn smallButton(color: dvui.Color) dvui.Options {
    const layout = getTheme().layout;
    return .{
        .min_size_content = .{ .w = 50, .h = layout.min_button_height },
        .color_fill = color,
        .corner_radius = layout.corner_radius_button,
    };
}

pub fn toggleButton(color: dvui.Color, active: bool) dvui.Options {
    const layout = getTheme().layout;
    return .{
        .expand = .horizontal,
        .color_fill = if (active) color.opacity(0.4) else dvui.themeGet().control.fill.?,
        .corner_radius = layout.corner_radius_button,
    };
}

pub fn panedOptions(direction: dvui.enums.Direction, split_ratio: *f32, handle_dynamic: bool) dvui.PanedWidget.InitOptions {
    const layout = getTheme().layout;
    return .{
        .direction = direction,
        .split_ratio = split_ratio,
        .collapsed_size = 500,
        .handle_size = layout.handle_size,
        .handle_margin = layout.handle_margin,
        .handle_dynamic = if (handle_dynamic)
            .{ .handle_size_max = layout.handle_size, .distance_max = 200 }
        else
            null,
    };
}

pub fn sectionTitle(color: dvui.Color) dvui.Options {
    return .{
        .font_style = .title_2,
        .background = false,
        .color_text = color,
        .gravity_x = 0.5,
    };
}

pub fn subsectionTitle() dvui.Options {
    return .{
        .font_style = .title_4,
        .background = false,
    };
}

pub fn infoOverlay(text_color: dvui.Color) dvui.Options {
    const layout = getTheme().layout;
    return .{
        .font_style = .title_4,
        .gravity_x = 0.5,
        .background = true,
        .color_fill = dvui.themeGet().window.fill.?.opacity(0.7),
        .color_text = text_color,
        .padding = .{ .x = 8, .y = 4, .w = 8, .h = 4 },
        .corner_radius = layout.corner_radius_button,
    };
}

pub fn emptyStateText(color: dvui.Color) dvui.Options {
    return .{
        .font_style = .body,
        .color_text = color,
        .gravity_x = 0.5,
        .gravity_y = 0.5,
        .expand = .both,
    };
}

pub fn consoleMessage(row_index: usize) dvui.Options {
    const layout = getTheme().layout;
    const theme = dvui.themeGet();
    return .{
        .id_extra = row_index,
        .expand = .horizontal,
        .background = (row_index % 2 == 0),
        .color_fill = if (row_index % 2 == 0)
            theme.fill.lighten(if (theme.dark) 10 else -10).opacity(0.4)
        else
            undefined,
        .corner_radius = layout.corner_radius_button,
    };
}
