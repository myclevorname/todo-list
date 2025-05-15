const std = @import("std");
const dvui = @import("dvui");
const builtin = @import("builtin");
const folders = @import("folders");

const dc = dvui.backend.c;

const is_debug = builtin.mode == .Debug;

const TaskList = struct {
    map: std.StringArrayHashMap(struct { delete: bool, index: usize }),
    allocator: std.mem.Allocator,
    counter: u64 = 0,

    fn append(self: *TaskList, task: []const u8) !void {
        if (task.len == 0) return;
        const string = try self.allocator.dupe(u8, task);
        errdefer self.allocator.free(string);
        _ = try self.map.getOrPutValue(string, .{ .delete = false, .index = self.counter });
        self.counter += 1;
    }
    fn restore(self: *TaskList, file: std.fs.File) !void {
        const reader = file.reader();

        const buffer = try reader.readAllAlloc(self.allocator, 1 << 16);
        defer self.allocator.free(buffer);
        if (buffer.len == 0) return;

        var iter = std.mem.splitAny(u8, buffer, &.{ '\r', '\n' });

        try self.append(iter.first());

        while (iter.next()) |task| try self.append(task);
    }
    fn save(self: *const TaskList, file: std.fs.File) !void {
        try file.seekTo(0);
        try file.setEndPos(0);

        const writer = file.writer();

        for (self.map.keys()) |line| {
            try writer.writeAll(line);
            try writer.writeByte('\n');
        }
    }
    fn freeDeleted(self: *TaskList) void {
        var iter = self.map.iterator();
        while (iter.next()) |task| {
            if (task.value_ptr.delete) {
                const ptr = task.key_ptr.*;
                const removed = self.map.orderedRemove(task.key_ptr.*);
                self.allocator.free(ptr);
                std.debug.assert(removed);
                iter = self.map.iterator();
            }
        }
    }
    fn init(allocator: std.mem.Allocator) TaskList {
        return .{ .allocator = allocator, .map = .init(allocator) };
    }
    fn deinit(self: *TaskList) void {
        for (self.map.keys()) |key| self.allocator.free(key);
        self.map.deinit();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var tasks = TaskList.init(allocator);
    defer tasks.deinit();

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

    if (file) |f| tasks.restore(f) catch std.debug.print("Failed to read from tasks file\n", .{});

    defer if (file) |f| tasks.save(f) catch std.debug.print("Cannot write tasks to tasks file", .{});

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

        try frame(&tasks);

        _ = try window.end(.{});

        backend.setCursor(window.cursorRequested());

        dc.EndDrawing();
    }
}

fn frame(tasks: *TaskList) !void {
    var scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both });
    defer scroll.deinit();

    var box = try dvui.box(@src(), .vertical, .{ .expand = .both });
    defer box.deinit();

    tasks.freeDeleted();

    const opts = dvui.ButtonWidget.defaults.override(.{ .border = .all(1) });

    var iter = tasks.map.iterator();
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
            try tasks.append(add_text.getText());
            add_text.len = 0;
        }
        add_text.deinit();
    }
}
