const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");

const Color = @This();
r: u8 = 0xff,
g: u8 = 0xff,
b: u8 = 0xff,
a: u8 = 0xff,

pub const Palettes = struct {
    pub const CatppuccinMocha = struct {
        pub const rosewater = dvui.Color.fromHex("#f5e0dc");
        pub const flamingo = dvui.Color.fromHex("#f2cdcd");
        pub const pink = dvui.Color.fromHex("#f5c2e7");
        pub const mauve = dvui.Color.fromHex("#cba6f7");
        pub const red = dvui.Color.fromHex("#f38ba8");
        pub const maroon = dvui.Color.fromHex("#eba0ac");
        pub const peach = dvui.Color.fromHex("#fab387");
        pub const yellow = dvui.Color.fromHex("#f9e2af");
        pub const green = dvui.Color.fromHex("#a6e3a1");
        pub const teal = dvui.Color.fromHex("#94e2d5");
        pub const sky = dvui.Color.fromHex("#89dceb");
        pub const sapphire = dvui.Color.fromHex("#74c7ec");
        pub const blue = dvui.Color.fromHex("#89b4fa");
        pub const lavender = dvui.Color.fromHex("#b4befe");

        pub const text = dvui.Color.fromHex("#cdd6f4");
        pub const subtext1 = dvui.Color.fromHex("#bac2de");
        pub const subtext0 = dvui.Color.fromHex("#a6adc8");
        pub const overlay2 = dvui.Color.fromHex("#9399b2");
        pub const overlay1 = dvui.Color.fromHex("#7f849c");
        pub const overlay0 = dvui.Color.fromHex("#6c7086");
        pub const surface2 = dvui.Color.fromHex("#585b70");
        pub const surface1 = dvui.Color.fromHex("#45475a");
        pub const surface0 = dvui.Color.fromHex("#313244");
        pub const base = dvui.Color.fromHex("#1e1e2e");
        pub const mantle = dvui.Color.fromHex("#181825");
        pub const crust = dvui.Color.fromHex("#11111b");
    };

    pub const CatppuccinLatte = struct {
        pub const rosewater = dvui.Color.fromHex("#dc8a78");
        pub const flamingo = dvui.Color.fromHex("#dd7878");
        pub const pink = dvui.Color.fromHex("#ea76cb");
        pub const mauve = dvui.Color.fromHex("#8839ef");
        pub const red = dvui.Color.fromHex("#d20f39");
        pub const maroon = dvui.Color.fromHex("#e64553");
        pub const peach = dvui.Color.fromHex("#fe640b");
        pub const yellow = dvui.Color.fromHex("#df8e1d");
        pub const green = dvui.Color.fromHex("#40a02b");
        pub const teal = dvui.Color.fromHex("#179299");
        pub const sky = dvui.Color.fromHex("#04a5e5");
        pub const sapphire = dvui.Color.fromHex("#209fb5");
        pub const blue = dvui.Color.fromHex("#1e66f5");
        pub const lavender = dvui.Color.fromHex("#7287fd");

        pub const text = dvui.Color.fromHex("#4c4f69");
        pub const subtext1 = dvui.Color.fromHex("#5c5f77");
        pub const subtext0 = dvui.Color.fromHex("#6c6f85");
        pub const overlay2 = dvui.Color.fromHex("#7c7f93");
        pub const overlay1 = dvui.Color.fromHex("#8c8fa1");
        pub const overlay0 = dvui.Color.fromHex("#9ca0b0");
        pub const surface2 = dvui.Color.fromHex("#acb0be");
        pub const surface1 = dvui.Color.fromHex("#bcc0cc");
        pub const surface0 = dvui.Color.fromHex("#ccd0da");
        pub const base = dvui.Color.fromHex("#eff1f5");
        pub const mantle = dvui.Color.fromHex("#e6e9ef");
        pub const crust = dvui.Color.fromHex("#dce0e8");
    };

    pub const OneDark = struct {
        pub const red = dvui.Color.fromHex("#e06c75");
        pub const green = dvui.Color.fromHex("#98c379");
        pub const yellow = dvui.Color.fromHex("#e5c07b");
        pub const blue = dvui.Color.fromHex("#61afef");
        pub const purple = dvui.Color.fromHex("#c678dd");
        pub const cyan = dvui.Color.fromHex("#56b6c2");
        pub const white = dvui.Color.fromHex("#abb2bf");
        pub const black = dvui.Color.fromHex("#282c34");
        pub const bright_black = dvui.Color.fromHex("#5c6370");
        pub const background = dvui.Color.fromHex("#282c34");
        pub const foreground = dvui.Color.fromHex("#abb2bf");
        pub const selection = dvui.Color.fromHex("#3e4451");
        pub const comment = dvui.Color.fromHex("#7f848e");
    };
};

/// returns normalized RGBA components as floats (0.0 - 1.0)
pub fn toNormalizedRGBA(color: dvui.Color) struct { r: f32, g: f32, b: f32, a: f32 } {
    return .{
        .r = @as(f32, @floatFromInt(color.r)) / 255.0,
        .g = @as(f32, @floatFromInt(color.g)) / 255.0,
        .b = @as(f32, @floatFromInt(color.b)) / 255.0,
        .a = @as(f32, @floatFromInt(color.a)) / 255.0,
    };
}

/// returns normalized RGB components as floats (0.0 - 1.0), ignoring alpha
pub fn toNormalizedRGB(color: dvui.Color) struct { r: f32, g: f32, b: f32 } {
    return .{
        .r = @as(f32, @floatFromInt(color.r)) / 255.0,
        .g = @as(f32, @floatFromInt(color.g)) / 255.0,
        .b = @as(f32, @floatFromInt(color.b)) / 255.0,
    };
}
