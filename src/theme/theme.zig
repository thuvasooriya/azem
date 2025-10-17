const std = @import("std");
const dvui = @import("dvui");

pub const ColorPalette = @import("colors.zig").ColorPalette;
pub const LayoutConfig = @import("layout.zig").LayoutConfig;
pub const OptionBuilders = @import("options.zig");

pub const colors = @import("colors.zig");
pub const layout = @import("layout.zig");
pub const options = @import("options.zig");

pub const Theme = struct {
    name: []const u8,
    dvui_theme: dvui.Theme,
    colors: ColorPalette,
    layout: LayoutConfig,

    pub fn apply(self: *const Theme) void {
        dvui.themeSet(self.dvui_theme);
        OptionBuilders.setTheme(self);
    }

    pub fn variant(self: Theme, changes: ThemeChanges) Theme {
        var new = self;
        if (changes.font_size_delta) |delta| {
            new.dvui_theme = new.dvui_theme.fontSizeAdd(delta);
            new.layout = new.layout.scaleFonts(delta);
        }
        if (changes.colors) |cols| new.colors = cols;
        if (changes.layout) |lay| new.layout = lay;
        return new;
    }
};

pub const ThemeChanges = struct {
    font_size_delta: ?f32 = null,
    colors: ?ColorPalette = null,
    layout: ?LayoutConfig = null,
};

pub const presets = struct {
    pub const catppuccin_mocha = @import("presets/catppuccin_mocha.zig").theme;
};
