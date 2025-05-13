const std = @import("std");
const dvui = @import("dvui");
const builtin = @import("builtin");

const dc = dvui.backend.c;

const is_debug = builtin.mode == .Debug;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var backend = try dvui.backend.initWindow(.{
        .gpa = allocator,
        .vsync = true,
        .size = .{},
        .title = "Hello!",
    });
    backend.log_events = is_debug;
    defer backend.deinit();

    var window = try dvui.Window.init(@src(), allocator, backend.backend(), .{});
    defer window.deinit();

    while (true) {
        dc.BeginDrawing();

        try window.begin(std.time.nanoTimestamp());

        if (try backend.addAllEvents(&window)) break;
        backend.clear();

        try frame();

        _ = try window.end(.{});

        backend.setCursor(window.cursorRequested());

        dc.EndDrawing();
    }
}

fn frame() !void {
    //try dvui.renderText(.{
    //    .font = dvui.themeGet().font_heading,
    //    .text = "Hello, World!",
    //    .rs = .{ .r = .all(1) },
    //    .color = .white,
    //    .debug = true,
    //});
    
    var tl = dvui.TextLayoutWidget.init(@src(), .{}, .{ .expand = .both });
    try tl.install(.{});

    try tl.addText("YAY!!!\n", .{ .font_style = .title });
    try tl.addText("It worked!", .{ .font_style = .body });

    defer tl.deinit();


}
