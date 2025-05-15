const std = @import("std");
const dvui = @import("dvui");
const builtin = @import("builtin");
const folders = @import("folders");

const dc = dvui.backend.c;

const is_debug = builtin.mode == .Debug;

const TaskList = struct {
    list: std.DoublyLinkedList(void),
    allocator: std.mem.Allocator,
    counter: u64 = 0,

    fn append(self: *TaskList, task: []const u8) !void {
        if (task.len == 0) return;
        const string = try self.allocator.dupe(u8, task);
        errdefer self.allocator.free(string);
        const elem = try self.allocator.create(Element);
        elem.* = .{ .index = self.counter, .string = string };
        self.list.append(&elem.node);
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
        var current = self.list.first;
        while (current) |x| {
            current = x.next;
            const element: *Element = @fieldParentPtr("node", x);
            try writer.print("{s}\n", .{element.string});
        }
    }
    fn freeDeleted(self: *TaskList) void {
        var current = self.list.first;
        while (current) |x| {
            current = x.next;
            const element: *Element = @fieldParentPtr("node", x);
            if (element.to_free) {
                self.list.remove(x);
                self.allocator.free(element.string);
                self.allocator.destroy(element);
            }
        }
    }
    fn init(allocator: std.mem.Allocator) TaskList {
        return .{ .allocator = allocator, .list = .{} };
    }
    const Element = struct {
        node: std.DoublyLinkedList(void).Node = .{ .data = {} },
        index: u64,
        string: []const u8,
        to_free: bool = false,
    };
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    // defer _ = gpa.deinit(); // The OS is going to release the memory used by the program anyway
    const allocator = gpa.allocator();

    var tasks = TaskList.init(allocator);

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

    var iter = tasks.list.first;
    while (iter) |task| {
        iter = task.next;

        const element: *TaskList.Element = @fieldParentPtr("node", task);
        var span = try dvui.box(@src(), .horizontal, .{
            .expand = .horizontal,
            .id_extra = element.index,
        });
        defer span.deinit();

        element.to_free = try dvui.button(@src(), "×", .{}, opts);

        var tl = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .gravity_y = 0.5 });
        defer tl.deinit();

        const string = element.string;

        try tl.addText(string, .{});
    }

    {
        var span = try dvui.box(@src(), .horizontal, .{ .expand = .horizontal });
        defer span.deinit();

        const add_button = try dvui.button(@src(), "+", .{}, opts);
        var add_text = try dvui.textEntry(@src(), .{}, .{});
        if (add_button or add_text.enter_pressed) {
            try tasks.append(add_text.getText());
            add_text.len = 0;
        }
        add_text.deinit();
    }
}
