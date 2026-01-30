const std = @import("std");
const rdb = @import("rocksdb");

const Allocator = std.mem.Allocator;

/// data that was allocated by rocksdb and must be freed by rocksdb
pub const Data = struct {
    data: []const u8,
    free: *const fn (?*anyopaque) callconv(.c) void,

    pub fn deinit(self: Data) void {
        self.free(@ptrCast(@constCast(self.data.ptr)));
    }

    pub fn format(
        self: Data,
        writer: anytype,
    ) !void {
        try writer.writeAll(self.data);
    }
};

pub fn copy(allocator: Allocator, in: [*c]const u8) Allocator.Error![]u8 {
    return copyLen(allocator, in, std.mem.len(in));
}

pub fn copyLen(allocator: Allocator, in: [*c]const u8, len: usize) Allocator.Error![]u8 {
    const ret = try allocator.dupe(u8, in[0..len]);
    return ret;
}

test "Data format and copy helpers" {
    const allocator = std.testing.allocator;

    const text = "hello";
    const noop_free = struct {
        fn free(_: ?*anyopaque) callconv(.c) void {}
    }.free;

    var data = Data{ .data = text, .free = noop_free };
    defer data.deinit();

    var buffer: [16]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    try data.format(stream.writer());
    try std.testing.expectEqualSlices(u8, text, stream.getWritten());

    const copied = try copy(allocator, @ptrCast(text.ptr));
    defer allocator.free(copied);
    try std.testing.expectEqualSlices(u8, text, copied);

    const copied_len = try copyLen(allocator, @ptrCast(text.ptr), 3);
    defer allocator.free(copied_len);
    try std.testing.expectEqualSlices(u8, "hel", copied_len);
}
