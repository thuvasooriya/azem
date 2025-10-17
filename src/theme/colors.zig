const dvui = @import("dvui");

pub const ColorPalette = struct {
    maze_walls: dvui.Color,
    maze_start: dvui.Color,
    maze_goal: dvui.Color,
    maze_path: dvui.Color,

    console_info: dvui.Color,
    console_success: dvui.Color,
    console_warning: dvui.Color,
    console_error: dvui.Color,

    sidebar_accent: dvui.Color,
    console_accent: dvui.Color,
    maze_accent: dvui.Color,
};

pub const catppuccin_mocha = blk: {
    @setEvalBranchQuota(5000);
    break :blk ColorPalette{
        .maze_walls = dvui.Color.fromHex("#fab387").opacity(0.7),
        .maze_start = dvui.Color.fromHex("#a6e3a1"),
        .maze_goal = dvui.Color.fromHex("#f38ba8"),
        .maze_path = dvui.Color.fromHex("#89b4fa"),

        .console_info = dvui.Color.fromHex("#89dceb"),
        .console_success = dvui.Color.fromHex("#a6e3a1"),
        .console_warning = dvui.Color.fromHex("#f9e2af"),
        .console_error = dvui.Color.fromHex("#f38ba8"),

        .sidebar_accent = dvui.Color.fromHex("#89b4fa"),
        .console_accent = dvui.Color.fromHex("#a6e3a1"),
        .maze_accent = dvui.Color.fromHex("#fab387"),
    };
};

pub const catppuccin_latte = blk: {
    @setEvalBranchQuota(5000);
    break :blk ColorPalette{
        .maze_walls = dvui.Color.fromHex("#fe640b").opacity(0.7),
        .maze_start = dvui.Color.fromHex("#40a02b"),
        .maze_goal = dvui.Color.fromHex("#d20f39"),
        .maze_path = dvui.Color.fromHex("#1e66f5"),

        .console_info = dvui.Color.fromHex("#04a5e5"),
        .console_success = dvui.Color.fromHex("#40a02b"),
        .console_warning = dvui.Color.fromHex("#df8e1d"),
        .console_error = dvui.Color.fromHex("#d20f39"),

        .sidebar_accent = dvui.Color.fromHex("#1e66f5"),
        .console_accent = dvui.Color.fromHex("#40a02b"),
        .maze_accent = dvui.Color.fromHex("#fe640b"),
    };
};
