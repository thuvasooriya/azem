const dvui = @import("dvui");

pub const LayoutConfig = struct {
    gap_panel: f32,
    gap_small: f32,
    gap_large: f32,

    handle_size: f32,
    handle_margin: f32,
    min_button_height: f32,

    border_panel: dvui.Rect,
    border_thin: dvui.Rect,
    padding_panel: dvui.Rect,
    padding_compact: dvui.Rect,

    corner_radius_panel: dvui.Rect,
    corner_radius_button: dvui.Rect,

    ratio_sidebar: f32,
    ratio_console: f32,

    margin_window: dvui.Rect,

    pub fn init(base_size: f32) LayoutConfig {
        const handle = base_size / 8;
        const gap = base_size * 0.625;
        return .{
            .gap_panel = gap,
            .gap_small = base_size * 0.25,
            .gap_large = base_size * 1.0,

            .handle_size = handle,
            .handle_margin = (gap - handle) / 2,
            .min_button_height = base_size,

            .border_panel = .all(1),
            .border_thin = .all(1),
            .padding_panel = .all(gap),
            .padding_compact = .all(base_size * 0.25),

            .corner_radius_panel = .all(base_size * 0.5625),
            .corner_radius_button = .all(base_size * 0.25),

            .ratio_sidebar = 0.7,
            .ratio_console = 0.7,

            .margin_window = if (dvui.backend.kind == .web)
                .all(gap)
            else
                .{ .x = gap, .y = 0, .h = gap, .w = gap },
        };
    }

    pub fn scaleFonts(self: LayoutConfig, delta: f32) LayoutConfig {
        var new = self;
        new.min_button_height += delta;
        return new;
    }

    pub fn compact(self: LayoutConfig) LayoutConfig {
        var new = self;
        new.gap_panel = self.gap_small;
        new.padding_panel = self.padding_compact;
        return new;
    }
};

pub const default = LayoutConfig.init(16);
