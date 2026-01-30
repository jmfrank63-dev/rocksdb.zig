const std = @import("std");
const rdb = @import("rocksdb");
const lib = @import("lib.zig");

const Allocator = std.mem.Allocator;

const ColumnFamilyHandle = lib.ColumnFamilyHandle;

pub const WriteBatch = struct {
    inner: *rdb.rocksdb_writebatch_t,

    const Self = @This();

    pub fn init() WriteBatch {
        return .{ .inner = rdb.rocksdb_writebatch_create().? };
    }

    pub fn deinit(self: WriteBatch) void {
        rdb.rocksdb_writebatch_destroy(self.inner);
    }

    pub fn put(
        self: *const Self,
        column_family: ColumnFamilyHandle,
        key: []const u8,
        value: []const u8,
    ) void {
        rdb.rocksdb_writebatch_put_cf(
            self.inner,
            column_family,
            key.ptr,
            key.len,
            value.ptr,
            value.len,
        );
    }

    pub fn delete(
        self: *const Self,
        column_family: ColumnFamilyHandle,
        key: []const u8,
    ) void {
        rdb.rocksdb_writebatch_delete_cf(
            self.inner,
            column_family,
            key.ptr,
            key.len,
        );
    }

    pub fn deleteRange(
        self: *const Self,
        column_family: ColumnFamilyHandle,
        start_key: []const u8,
        end_key: []const u8,
    ) void {
        rdb.rocksdb_writebatch_delete_range_cf(
            self.inner,
            column_family,
            start_key.ptr,
            start_key.len,
            end_key.ptr,
            end_key.len,
        );
    }
};

test "WriteBatch put/delete" {
    const database = @import("database.zig");
    const allocator = std.testing.allocator;

    var dir = std.testing.tmpDir(.{});
    defer dir.cleanup();
    const path = try dir.dir.realpathAlloc(allocator, ".");
    defer allocator.free(path);

    var err_str: ?lib.Data = null;
    defer if (err_str) |e| e.deinit();

    var db, const families = try database.DB.open(
        allocator,
        path,
        .{ .create_if_missing = true, .create_missing_column_families = true },
        &.{.{ .name = "default" }},
        false,
        &err_str,
    );
    defer db.deinit();
    defer allocator.free(families);

    const cf = families[0].handle;
    db = db.withDefaultColumnFamily(cf);

    var batch = WriteBatch.init();
    defer batch.deinit();
    batch.put(cf, "a", "1");
    batch.put(cf, "b", "2");
    try db.write(batch, &err_str);

    const val = try db.get(null, "a", &err_str);
    defer if (val) |v| v.deinit();
    try std.testing.expectEqualSlices(u8, "1", val.?.data);

    var delete_batch = WriteBatch.init();
    defer delete_batch.deinit();
    delete_batch.delete(cf, "a");
    try db.write(delete_batch, &err_str);

    const after_delete = try db.get(null, "a", &err_str);
    try std.testing.expect(after_delete == null);
}
