const std = @import("std");
const dvui = @import("dvui");
const builtin = @import("builtin");

const dc = dvui.backend.c;

const is_debug = builtin.mode == .Debug;

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
const allocator = gpa.allocator();

fn addTask(k: []const u8) !void {
    const string = try allocator.dupe(u8, k);
    _ = try tasks.getOrPutValue(string, .{ .delete = false, .index = task_counter });
    task_counter += 1;
}

pub fn main() !void {
    try addTask("do stuff");
    try addTask("do things");

    defer _ = gpa.deinit();
    defer tasks.deinit();
    defer {
        for (tasks.keys()) |key| allocator.free(key);
    }

    var backend = try dvui.backend.initWindow(.{
        .gpa = allocator,
        .vsync = true,
        .size = .{},
        .title = "Todo List",
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

var tasks = std.StringArrayHashMap(struct { delete: bool, index: usize }).init(allocator);
var task_counter: usize = 0;

fn frame() !void {
    var scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both });
    defer scroll.deinit();

    var box = try dvui.box(@src(), .vertical, .{ .expand = .both });
    defer box.deinit();
    {
        var iter = tasks.iterator();
        while (iter.next()) |task| {
            if (task.value_ptr.delete) {
                const ptr = task.key_ptr.*;
                const removed = tasks.orderedRemove(task.key_ptr.*);
                allocator.free(ptr);
                std.debug.assert(removed);
                iter = tasks.iterator();
            }
        }
    }

    const opts = dvui.ButtonWidget.defaults.override(.{ .border = .all(1) });

    var iter = tasks.iterator();
    while (iter.next()) |task| {
        var span = try dvui.box(@src(), .horizontal, .{
            .expand = .horizontal,
            .id_extra = task.value_ptr.index,
        });
        defer span.deinit();

        const delete = try dvui.button(@src(), "X", .{}, opts);
        task.value_ptr.delete = delete;

        var tl = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .gravity_y = 0.5 });
        defer tl.deinit();

        try tl.addText(task.key_ptr.*, .{});
    }

    {
        var span = try dvui.box(@src(), .horizontal, .{ .expand = .horizontal });
        defer span.deinit();

        const add_button = try dvui.button(@src(), "Add", .{}, opts);
        var add_text = try dvui.textEntry(@src(), .{}, .{});
        if (add_button) {
            try addTask(add_text.getText());
            add_text.len = 0;
        }
        add_text.deinit();
    }
}
