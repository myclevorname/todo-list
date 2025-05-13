const std = @import("std");
const dvui = @import("dvui");
const builtin = @import("builtin");
const folders = @import("folders");

const dc = dvui.backend.c;

const is_debug = builtin.mode == .Debug;

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
const allocator = gpa.allocator();

var tasks = std.StringArrayHashMap(struct { delete: bool, index: usize }).init(allocator);
var task_counter: usize = 0;

fn addTask(k: []const u8) !void {
    if (k.len == 0) return;
    const string = try allocator.dupe(u8, k);
    _ = try tasks.getOrPutValue(string, .{ .delete = false, .index = task_counter });
    task_counter += 1;
}

/// Reads the tasks into `tasks`.
fn readTasks(reader: anytype) !void {
    const buffer = try reader.readAllAlloc(allocator, 1 << 16);
    defer allocator.free(buffer);
    if (buffer.len == 0) return;

    var iter = std.mem.splitAny(u8, buffer, &.{ '\r', '\n' });

    try addTask(iter.first());

    while (iter.next()) |t| try addTask(t);
}

fn writeTasks(file: std.fs.File) !void {
    try file.seekTo(0);
    try file.setEndPos(0);

    const writer = file.writer();

    if (tasks.count() == 0) return;

    for (tasks.keys()) |line| {
        try writer.writeAll(line);
        try writer.writeByte('\n');
    }
}

pub fn main() !void {
    defer _ = gpa.deinit();
    defer tasks.deinit();
    defer {
        for (tasks.keys()) |key| allocator.free(key);
    }
    const file = blk: {
        const path = (folders.getPath(allocator, .data) catch break :blk null) orelse break :blk null;
        defer allocator.free(path);

        var base = std.fs.cwd().makeOpenPath(path, .{}) catch break :blk null;
        defer base.close();

        var subdir = base.makeOpenPath("todo", .{}) catch break :blk null;
        defer subdir.close();

        const file = subdir.createFile("tasks", .{ .read = true, .truncate = false }) catch break :blk null;
        break :blk file;
    };
    defer if (file) |f| f.close();

    if (file) |f| {
        readTasks(f.reader()) catch {};
    }

    defer if (file) |f| writeTasks(f) catch std.debug.print("Cannot write tasks to file", .{});

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
