// Pure C test to verify restore works with MSVC Debug build
// Compile with: cl.exe (MSVC compiler + MSVC linker, no Zig involved)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
#include <direct.h>
#include <sys/stat.h>
#include "rocksdb/c.h"

#ifdef _WIN32
#include <windows.h>
#define rmdir(path) _rmdir(path)
#define unlink(path) _unlink(path)
#else
#include <unistd.h>
#include <dirent.h>
#endif

// Helper to recursively delete directory
void delete_directory(const char* path) {
#ifdef _WIN32
    char search_path[512];
    snprintf(search_path, sizeof(search_path), "%s\\*", path);
    
    WIN32_FIND_DATAA find_data;
    HANDLE hFind = FindFirstFileA(search_path, &find_data);
    
    if (hFind != INVALID_HANDLE_VALUE) {
        do {
            if (strcmp(find_data.cFileName, ".") != 0 && strcmp(find_data.cFileName, "..") != 0) {
                char full_path[512];
                snprintf(full_path, sizeof(full_path), "%s\\%s", path, find_data.cFileName);
                
                if (find_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                    delete_directory(full_path);
                } else {
                    _chmod(full_path, _S_IWRITE);
                    DeleteFileA(full_path);
                }
            }
        } while (FindNextFileA(hFind, &find_data));
        FindClose(hFind);
    }
    _rmdir(path);
#else
    // Unix implementation
    DIR* dir = opendir(path);
    if (dir) {
        struct dirent* entry;
        while ((entry = readdir(dir)) != NULL) {
            if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
                char full_path[512];
                snprintf(full_path, sizeof(full_path), "%s/%s", path, entry->d_name);
                unlink(full_path);
            }
        }
        closedir(dir);
    }
    rmdir(path);
#endif
}

int main(void) {
    printf("=== Testing RocksDB Restore with MSVC Debug Build ===\n");
    printf("This test uses pure MSVC toolchain (cl.exe + link.exe)\n\n");
    
    const char* db_path = "test_db_msvc_debug";
    const char* backup_path = "test_backup_msvc_debug";
    const char* restore_path = "test_restore_msvc_debug";
    
    char* err = NULL;
    
    // Cleanup
    delete_directory(db_path);
    delete_directory(backup_path);
    delete_directory(restore_path);
    
    // Create DB
    printf("1. Creating database...\n");
    rocksdb_options_t* options = rocksdb_options_create();
    rocksdb_options_set_create_if_missing(options, 1);
    
    rocksdb_t* db = rocksdb_open(options, db_path, &err);
    if (err) {
        printf("ERROR opening DB: %s\n", err);
        return 1;
    }
    printf("   ✓ Database created\n");
    
    // Write data
    printf("2. Writing test data...\n");
    rocksdb_writeoptions_t* write_opts = rocksdb_writeoptions_create();
    rocksdb_put(db, write_opts, "key1", 4, "value1", 6, &err);
    if (err) {
        printf("ERROR writing: %s\n", err);
        return 1;
    }
    rocksdb_put(db, write_opts, "key2", 4, "value2", 6, &err);
    if (err) {
        printf("ERROR writing: %s\n", err);
        return 1;
    }
    printf("   ✓ Data written\n");
    
    // Create backup
    printf("3. Creating backup...\n");
    rocksdb_backup_engine_t* backup_engine = rocksdb_backup_engine_open(options, backup_path, &err);
    if (err) {
        printf("ERROR opening backup engine: %s\n", err);
        return 1;
    }
    
    rocksdb_backup_engine_create_new_backup(backup_engine, db, &err);
    if (err) {
        printf("ERROR creating backup: %s\n", err);
        return 1;
    }
    printf("   ✓ Backup created\n");
    
    // Close DB
    rocksdb_close(db);
    printf("   ✓ Database closed\n");
    
    // Restore from backup
    printf("4. Restoring from backup...\n");
    rocksdb_restore_options_t* restore_opts = rocksdb_restore_options_create();
    rocksdb_restore_options_set_keep_log_files(restore_opts, 0);
    
    rocksdb_backup_engine_restore_db_from_latest_backup(
        backup_engine, 
        restore_path, 
        restore_path,
        restore_opts, 
        &err
    );
    
    if (err) {
        printf("ERROR restoring: %s\n", err);
        rocksdb_restore_options_destroy(restore_opts);
        rocksdb_backup_engine_close(backup_engine);
        return 1;
    }
    printf("   ✓ Restore completed\n");
    
    // Verify restored data
    printf("5. Verifying restored data...\n");
    rocksdb_t* restored_db = rocksdb_open(options, restore_path, &err);
    if (err) {
        printf("ERROR opening restored DB: %s\n", err);
        return 1;
    }
    
    rocksdb_readoptions_t* read_opts = rocksdb_readoptions_create();
    size_t val_len;
    char* value = rocksdb_get(restored_db, read_opts, "key1", 4, &val_len, &err);
    if (err) {
        printf("ERROR reading key1: %s\n", err);
        return 1;
    }
    if (!value || val_len != 6 || memcmp(value, "value1", 6) != 0) {
        printf("ERROR: key1 verification failed\n");
        return 1;
    }
    free(value);
    
    value = rocksdb_get(restored_db, read_opts, "key2", 4, &val_len, &err);
    if (err) {
        printf("ERROR reading key2: %s\n", err);
        return 1;
    }
    if (!value || val_len != 6 || memcmp(value, "value2", 6) != 0) {
        printf("ERROR: key2 verification failed\n");
        return 1;
    }
    free(value);
    printf("   ✓ Data verified\n");
    
    // Cleanup
    rocksdb_close(restored_db);
    rocksdb_readoptions_destroy(read_opts);
    rocksdb_restore_options_destroy(restore_opts);
    rocksdb_backup_engine_close(backup_engine);
    rocksdb_writeoptions_destroy(write_opts);
    rocksdb_options_destroy(options);
    
    delete_directory(db_path);
    delete_directory(backup_path);
    delete_directory(restore_path);
    
    printf("\n=== ALL TESTS PASSED ===\n");
    printf("MSVC Debug build works correctly!\n");
    
    return 0;
}
