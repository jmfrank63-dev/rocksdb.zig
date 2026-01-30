const std = @import("std");
const rdb = @import("rocksdb");

const Allocator = std.mem.Allocator;

/// data that was allocated by rocksdb and must be freed by rocksdb
pub const Data = struct {
    data: []const u8,
    free: *const fn (?*anyopaque) callconv(.c) void,

    /// Frees the data using the provided free function.
    /// IMPORTANT: This should only be called once per Data instance.
    /// Calling deinit() multiple times on the same Data will cause double-free.
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

test "Copy empty string" {
    const allocator = std.testing.allocator;

    const text = "";
    const copied = try copy(allocator, @ptrCast(text.ptr));
    defer allocator.free(copied);
    try std.testing.expectEqualSlices(u8, "", copied);
}

test "Copy zero length via copyLen" {
    const allocator = std.testing.allocator;

    const text = "hello";
    const copied = try copyLen(allocator, @ptrCast(text.ptr), 0);
    defer allocator.free(copied);
    try std.testing.expect(copied.len == 0);
}

test "Data format with different content" {
    const noop_free = struct {
        fn free(_: ?*anyopaque) callconv(.c) void {}
    }.free;

    const text = "test content";
    const data = Data{ .data = text, .free = noop_free };
    defer data.deinit();

    var buffer: [32]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    try data.format(stream.writer());
    try std.testing.expectEqualSlices(u8, text, stream.getWritten());
}

test "BUG: Data deinit semantics unclear - double free risk" {
    // This test documents the current behavior where deinit can be called multiple times.
    // This is dangerous in real usage with rocksdb_free as it would double-free.
    // Decision needed: either make idempotent or document as single-use only.
    var call_count: usize = 0;
    const counting_free = struct {
        fn free(ptr: ?*anyopaque) callconv(.c) void {
            if (ptr) |p| {
                const count_ptr: *usize = @ptrCast(@alignCast(p));
                count_ptr.* += 1;
            }
        }
    }.free;

    const data = Data{ .data = std.mem.asBytes(&call_count), .free = counting_free };

    // First deinit
    data.deinit();
    try std.testing.expectEqual(@as(usize, 1), call_count);

    // Second deinit would double-free with real rocksdb_free!
    // For now, this test just documents the behavior.
    // TODO: Make Data.deinit idempotent or document as single-use
}

test "Copy with large buffer" {
    const allocator = std.testing.allocator;

    // Create a larger buffer to test
    var large_buf: [1024]u8 = undefined;
    for (&large_buf, 0..) |*byte, i| {
        byte.* = @intCast(i % 256);
    }

    const copied = try copyLen(allocator, @ptrCast(&large_buf), large_buf.len);
    defer allocator.free(copied);

    try std.testing.expectEqual(large_buf.len, copied.len);
    try std.testing.expectEqualSlices(u8, &large_buf, copied);
}
