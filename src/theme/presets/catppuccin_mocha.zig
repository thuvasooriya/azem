const dvui = @import("dvui");
const ColorPalette = @import("../colors.zig").ColorPalette;
const LayoutConfig = @import("../layout.zig").LayoutConfig;
const Theme = @import("../theme.zig").Theme;

const font1 = "JetBrainsMono-VariableFont_wght";
const font1_italic = "JetBrainsMono-Italic-VariableFont_wght";

pub const theme = blk: {
    @setEvalBranchQuota(5000);
    break :blk Theme{
        .name = "catppuccin mocha",

        .dvui_theme = .{
            .name = "catppuccin mocha",
            .dark = true,

            .focus = dvui.Color.fromHex("#f5c2e7"),

            .fill = dvui.Color.fromHex("#11111b"),
            .text = dvui.Color.fromHex("#cdd6f4"),
            .border = dvui.Color.fromHex("#1e1e2e"),

            .control = .{
                .fill = dvui.Color.fromHex("#181825"),
            },

            .window = .{
                .fill = dvui.Color.fromHex("#11111b"),
            },

            .highlight = .{
                .fill = dvui.Color.fromHex("#f9e2af"),
                .text = dvui.Color.fromHex("#11111b"),
            },

            .err = .{
                .fill = dvui.Color.fromHex("#f38ba8"),
                .text = dvui.Color.fromHex("#11111b"),
            },

            .font_body = .{ .size = 16, .id = .fromName(font1) },
            .font_heading = .{ .size = 16, .id = .fromName(font1) },
            .font_caption = .{ .size = 14, .id = .fromName(font1_italic) },
            .font_caption_heading = .{ .size = 14, .id = .fromName(font1) },
            .font_title = .{ .size = 32, .id = .fromName(font1) },
            .font_title_1 = .{ .size = 24, .id = .fromName(font1) },
            .font_title_2 = .{ .size = 20, .id = .fromName(font1) },
            .font_title_3 = .{ .size = 18, .id = .fromName(font1) },
            .font_title_4 = .{ .size = 17, .id = .fromName(font1_italic) },
        },

        .colors = @import("../colors.zig").catppuccin_mocha,
        .layout = LayoutConfig.init(16),
    };
};
