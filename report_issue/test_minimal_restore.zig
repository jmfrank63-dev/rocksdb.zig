const std = @import("std");
const rdb = @cImport({
    @cInclude("rocksdb/c.h");
});

pub fn main() !void {
    std.debug.print("=== Minimal RocksDB C API Backup/Restore Test ===\n", .{});

    const db_path = "test-minimal/db";
    const backup_path = "test-minimal/backup";
    const restore_path = "test-minimal/restored";

    // Clean up
    std.fs.cwd().deleteTree("test-minimal") catch {};
    try std.fs.cwd().makeDir("test-minimal");
    try std.fs.cwd().makeDir(db_path);
    try std.fs.cwd().makeDir(backup_path);

    var err: [*c]u8 = null;

    // Step 1: Create DB and add data
    std.debug.print("1. Creating database...\n", .{});
    {
        const opts = rdb.rocksdb_options_create();
        defer rdb.rocksdb_options_destroy(opts);
        rdb.rocksdb_options_set_create_if_missing(opts, 1);

        // Disable block cache
        const table_opts = rdb.rocksdb_block_based_options_create();
        defer rdb.rocksdb_block_based_options_destroy(table_opts);
        rdb.rocksdb_block_based_options_set_no_block_cache(table_opts, 1);
        rdb.rocksdb_options_set_block_based_table_factory(opts, table_opts);

        const db = rdb.rocksdb_open(opts, db_path, &err);
        if (err != null) {
            std.debug.print("ERROR: {s}\n", .{err});
            return error.Failed;
        }
        defer rdb.rocksdb_close(db);

        const wopts = rdb.rocksdb_writeoptions_create();
        defer rdb.rocksdb_writeoptions_destroy(wopts);

        rdb.rocksdb_put(db, wopts, "key1", 4, "value1", 6, &err);
        if (err != null) {
            std.debug.print("ERROR: {s}\n", .{err});
            return error.Failed;
        }

        std.debug.print("   Added data\n", .{});

        // Step 2: Create backup
        std.debug.print("2. Creating backup...\n", .{});
        const backup_opts = rdb.rocksdb_options_create();
        defer rdb.rocksdb_options_destroy(backup_opts);

        // Disable block cache in backup engine too
        const backup_table_opts = rdb.rocksdb_block_based_options_create();
        defer rdb.rocksdb_block_based_options_destroy(backup_table_opts);
        rdb.rocksdb_block_based_options_set_no_block_cache(backup_table_opts, 1);
        rdb.rocksdb_options_set_block_based_table_factory(backup_opts, backup_table_opts);

        const backup_engine = rdb.rocksdb_backup_engine_open(backup_opts, backup_path, &err);
        if (err != null) {
            std.debug.print("ERROR: {s}\n", .{err});
            return error.Failed;
        }

        rdb.rocksdb_backup_engine_create_new_backup(backup_engine, db, &err);
        if (err != null) {
            std.debug.print("ERROR: {s}\n", .{err});
            return error.Failed;
        }

        std.debug.print("   Backup created\n", .{});
        std.debug.print("3. Closing BackupEngine #1...\n", .{});
        rdb.rocksdb_backup_engine_close(backup_engine);
        std.debug.print("   BackupEngine #1 closed\n", .{});
    }

    std.debug.print("4. DB closed\n", .{});

    // Step 3: Restore (THIS IS WHERE THE ASSERTION MIGHT TRIGGER)
    std.debug.print("5. Opening BackupEngine #2 for restore...\n", .{});
    {
        const backup_opts = rdb.rocksdb_options_create();
        defer rdb.rocksdb_options_destroy(backup_opts);

        // Disable block cache
        const backup_table_opts = rdb.rocksdb_block_based_options_create();
        defer rdb.rocksdb_block_based_options_destroy(backup_table_opts);
        rdb.rocksdb_block_based_options_set_no_block_cache(backup_table_opts, 1);
        rdb.rocksdb_options_set_block_based_table_factory(backup_opts, backup_table_opts);

        const backup_engine = rdb.rocksdb_backup_engine_open(backup_opts, backup_path, &err);
        if (err != null) {
            std.debug.print("ERROR: {s}\n", .{err});
            return error.Failed;
        }

        std.debug.print("6. Restoring from latest backup...\n", .{});
        const restore_opts = rdb.rocksdb_restore_options_create();
        defer rdb.rocksdb_restore_options_destroy(restore_opts);

        rdb.rocksdb_backup_engine_restore_db_from_latest_backup(backup_engine, restore_path, restore_path, restore_opts, &err);
        if (err != null) {
            std.debug.print("ERROR: {s}\n", .{err});
            return error.Failed;
        }

        std.debug.print("   Restored successfully\n", .{});
        std.debug.print("7. Closing BackupEngine #2...\n", .{});
        rdb.rocksdb_backup_engine_close(backup_engine);
        std.debug.print("   BackupEngine #2 closed (THIS IS WHERE ASSERTION MAY TRIGGER)\n", .{});
    }

    // Step 4: Verify
    std.debug.print("8. Verifying restored data...\n", .{});
    {
        const opts = rdb.rocksdb_options_create();
        defer rdb.rocksdb_options_destroy(opts);

        const table_opts = rdb.rocksdb_block_based_options_create();
        defer rdb.rocksdb_block_based_options_destroy(table_opts);
        rdb.rocksdb_block_based_options_set_no_block_cache(table_opts, 1);
        rdb.rocksdb_options_set_block_based_table_factory(opts, table_opts);

        const db = rdb.rocksdb_open(opts, restore_path, &err);
        if (err != null) {
            std.debug.print("ERROR: {s}\n", .{err});
            return error.Failed;
        }
        defer rdb.rocksdb_close(db);

        const ropts = rdb.rocksdb_readoptions_create();
        defer rdb.rocksdb_readoptions_destroy(ropts);

        var vallen: usize = undefined;
        const val = rdb.rocksdb_get(db, ropts, "key1", 4, &vallen, &err);
        defer if (val != null) rdb.rocksdb_free(val);

        if (err != null or val == null) {
            std.debug.print("ERROR: Failed to read\n", .{});
            return error.Failed;
        }

        if (vallen != 6 or std.mem.eql(u8, val[0..6], "value1") == false) {
            std.debug.print("ERROR: Value mismatch\n", .{});
            return error.Failed;
        }

        std.debug.print("   Data verified!\n", .{});
    }

    std.debug.print("\n=== ALL STEPS COMPLETED SUCCESSFULLY ===\n", .{});

    // Cleanup
    std.fs.cwd().deleteTree("test-minimal") catch {};
}
