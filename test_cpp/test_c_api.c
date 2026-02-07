// Test BackupEngine restore using RocksDB C API (same as Zig wrapper uses)
// This more accurately tests what our wrapper does

#include <rocksdb/c.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <io.h>

#ifdef _WIN32
#include <windows.h>
#define rmdir _rmdir
#define mkdir(path, mode) _mkdir(path)
#else
#include <unistd.h>
#include <sys/stat.h>
#endif

void cleanup_dir(const char* path) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "rd /s /q \"%s\" 2>nul", path);
    system(cmd);
}

void ensure_dir(const char* path) {
    cleanup_dir(path);
    mkdir(path, 0755);
}

int main() {
    printf("=== RocksDB C API Backup/Restore Test ===\n");
    printf("Testing BackupEngine using C API (same as Zig wrapper)\n\n");

    const char* db_path = "test_cpp/db_c";
    const char* backup_path = "test_cpp/backup_c";
    const char* restore_path = "test_cpp/restored_db_c";

    ensure_dir(db_path);
    ensure_dir(backup_path);
    ensure_dir(restore_path);

    char* err = NULL;

    // Create and populate database
    printf("1. Creating database and adding data...\n");
    {
        rocksdb_options_t* options = rocksdb_options_create();
        rocksdb_options_set_create_if_missing(options, 1);

        rocksdb_t* db = rocksdb_open(options, db_path, &err);
        if (err) {
            printf("ERROR opening database: %s\n", err);
            free(err);
            return 1;
        }

        rocksdb_writeoptions_t* wopts = rocksdb_writeoptions_create();
        
        rocksdb_put(db, wopts, "key1", 4, "value1", 6, &err);
        if (err) {
            printf("ERROR putting key1: %s\n", err);
            free(err);
            return 1;
        }

        rocksdb_put(db, wopts, "key2", 4, "value2", 6, &err);
        if (err) {
            printf("ERROR putting key2: %s\n", err);
            free(err);
            return 1;
        }

        printf("   Added keys to database\n");

        // Create backup
        printf("2. Opening BackupEngine...\n");
        rocksdb_options_t* backup_opts = rocksdb_options_create();
        rocksdb_backup_engine_t* backup_engine = rocksdb_backup_engine_open(backup_opts, backup_path, &err);
        if (err) {
            printf("ERROR opening backup engine: %s\n", err);
            free(err);
            return 1;
        }

        printf("3. Creating backup...\n");
        rocksdb_backup_engine_create_new_backup(backup_engine, db, &err);
        if (err) {
            printf("ERROR creating backup: %s\n", err);
            free(err);
            return 1;
        }

        printf("   Backup created successfully\n");

        printf("4. Closing BackupEngine #1...\n");
        rocksdb_backup_engine_close(backup_engine);
       rocksdb_options_destroy(backup_opts);

        rocksdb_writeoptions_destroy(wopts);
        printf("5. Closing database...\n");
        rocksdb_close(db);
        rocksdb_options_destroy(options);
    }

    // Restore from backup (this is where the assertion might trigger)
    printf("6. Opening BackupEngine #2 for restore...\n");
    {
        rocksdb_options_t* backup_opts = rocksdb_options_create();
        rocksdb_backup_engine_t* backup_engine = rocksdb_backup_engine_open(backup_opts, backup_path, &err);
        if (err) {
            printf("ERROR opening backup engine for restore: %s\n", err);
            free(err);
            return 1;
        }

        printf("7. Restoring from latest backup...\n");
        rocksdb_restore_options_t* restore_opts = rocksdb_restore_options_create();
        rocksdb_backup_engine_restore_db_from_latest_backup(backup_engine, restore_path, restore_path, restore_opts, &err);
        if (err) {
            printf("ERROR restoring backup: %s\n", err);
            free(err);
            return 1;
        }

        printf("   Restored successfully\n");

        rocksdb_restore_options_destroy(restore_opts);

        printf("8. Closing BackupEngine #2...\n");
        rocksdb_backup_engine_close(backup_engine);
        rocksdb_options_destroy(backup_opts);
        printf("   BackupEngine closed\n");
    }

    // Verify restored data
    printf("9. Verifying restored data...\n");
    {
        rocksdb_options_t* options = rocksdb_options_create();
        rocksdb_t* db = rocksdb_open(options, restore_path, &err);
        if (err) {
            printf("ERROR opening restored database: %s\n", err);
            free(err);
            return 1;
        }

        rocksdb_readoptions_t* ropts = rocksdb_readoptions_create();

        size_t vallen;
        char* val1 = rocksdb_get(db, ropts, "key1", 4, &vallen, &err);
        if (err || !val1 || vallen != 6 || memcmp(val1, "value1", 6) != 0) {
            printf("ERROR: key1 mismatch\n");
            return 1;
        }
        free(val1);

        char* val2 = rocksdb_get(db, ropts, "key2", 4, &vallen, &err);
        if (err || !val2 || vallen != 6 || memcmp(val2, "value2", 6) != 0) {
            printf("ERROR: key2 mismatch\n");
            return 1;
        }
        free(val2);

        printf("   Data verified successfully\n");

        rocksdb_readoptions_destroy(ropts);
        rocksdb_close(db);
        rocksdb_options_destroy(options);
    }

    printf("\n=== TEST PASSED ===\n");
    printf("All operations completed successfully!\n");

    cleanup_dir(db_path);
    cleanup_dir(backup_path);
    cleanup_dir(restore_path);

    return 0;
}
