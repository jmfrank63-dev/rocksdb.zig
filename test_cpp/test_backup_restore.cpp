// Test to reproduce BackupEngine restore assertion failure in RocksDB debug builds
// Mimics the Zig wrapper's restore test workflow

#include <rocksdb/db.h>
#include <rocksdb/options.h>
#include <rocksdb/utilities/backup_engine.h>
#include <rocksdb/table.h>
#include <iostream>
#include <filesystem>
#include <cassert>

namespace fs = std::filesystem;

void cleanup_dir(const std::string& path) {
    if (fs::exists(path)) {
        fs::remove_all(path);
    }
}

void ensure_dir(const std::string& path) {
    cleanup_dir(path);
    fs::create_directories(path);
}

int main() {
    std::cout << "Testing BackupEngine restore workflow with RocksDB C++ API\n";
    std::cout << "Build mode: " << 
#ifdef NDEBUG
        "Release"
#else
        "Debug"
#endif
        << "\n\n";

    const std::string db_path = "test_cpp/db";
    const std::string backup_path = "test_cpp/backup";
    const std::string restore_path = "test_cpp/restored_db";

    // Test 1: With default options (block cache enabled)
    std::cout << "=== Test 1: Default options (block cache enabled) ===\n";
    {
        ensure_dir(db_path);
        ensure_dir(backup_path);
        ensure_dir(restore_path);

        // Create and populate database
        {
            rocksdb::DB* db;
            rocksdb::Options options;
            options.create_if_missing = true;
            
            rocksdb::Status s = rocksdb::DB::Open(options, db_path, &db);
            assert(s.ok());
            
            s = db->Put(rocksdb::WriteOptions(), "key1", "value1");
            assert(s.ok());
            s = db->Put(rocksdb::WriteOptions(), "key2", "value2");
            assert(s.ok());
            
            std::cout << "  Created DB and added data\n";
            
            // Create backup
            rocksdb::BackupEngine* backup_engine;
            rocksdb::BackupEngineOptions backup_opts(backup_path);
            rocksdb::Status s2 = rocksdb::BackupEngine::Open(rocksdb::Env::Default(), 
                                                            backup_opts, 
                                                            &backup_engine);
            assert(s2.ok());
            
            s2 = backup_engine->CreateNewBackup(db);
            assert(s2.ok());
            std::cout << "  Created backup\n";
            
            delete backup_engine;
            std::cout << "  Closed BackupEngine #1\n";
            
            delete db;
            std::cout << "  Closed DB\n";
        }
        
        // Restore from backup
        {
            rocksdb::BackupEngine* backup_engine;
            rocksdb::BackupEngineOptions backup_opts(backup_path);
            rocksdb::Status s = rocksdb::BackupEngine::Open(rocksdb::Env::Default(), 
                                                           backup_opts, 
                                                           &backup_engine);
            assert(s.ok());
            std::cout << "  Opened BackupEngine #2\n";
            
            s = backup_engine->RestoreDBFromLatestBackup(restore_path, restore_path);
            assert(s.ok());
            std::cout << "  Restored from backup\n";
            
            delete backup_engine;
            std::cout << "  Closed BackupEngine #2\n";
        }
        
        // Verify restored data
        {
            rocksdb::DB* db;
            rocksdb::Options options;
            rocksdb::Status s = rocksdb::DB::Open(options, restore_path, &db);
            assert(s.ok());
            
            std::string value;
            s = db->Get(rocksdb::ReadOptions(), "key1", &value);
            assert(s.ok());
            assert(value == "value1");
            
            s = db->Get(rocksdb::ReadOptions(), "key2", &value);
            assert(s.ok());
            assert(value == "value2");
            
            std::cout << "  Verified restored data\n";
            
            delete db;
        }
        
        std::cout << "  Test 1 PASSED\n\n";
    }

    // Test 2: With block cache disabled (like our Zig wrapper does)
    std::cout << "=== Test 2: Block cache disabled ===\n";
    {
        cleanup_dir(db_path);
        cleanup_dir(backup_path);
        cleanup_dir(restore_path);
        ensure_dir(db_path);
        ensure_dir(backup_path);
        ensure_dir(restore_path);

        // Create and populate database with no block cache
        {
            rocksdb::DB* db;
            rocksdb::Options options;
            options.create_if_missing = true;
            
            // Disable block cache
            rocksdb::BlockBasedTableOptions table_options;
            table_options.no_block_cache = true;
            options.table_factory.reset(rocksdb::NewBlockBasedTableFactory(table_options));
            
            rocksdb::Status s = rocksdb::DB::Open(options, db_path, &db);
            assert(s.ok());
            
            s = db->Put(rocksdb::WriteOptions(), "key1", "value1");
            assert(s.ok());
            s = db->Put(rocksdb::WriteOptions(), "key2", "value2");
            assert(s.ok());
            
            std::cout << "  Created DB (no cache) and added data\n";
            
            // Create BackupEngine with no block cache
            rocksdb::BackupEngineOptions backup_opts(backup_path);
            backup_opts.backup_env = rocksdb::Env::Default();
            
            rocksdb::BackupEngine* backup_engine;
            rocksdb::Status s2 = rocksdb::BackupEngine::Open(rocksdb::Env::Default(), 
                                                            backup_opts, 
                                                            &backup_engine);
            assert(s2.ok());
            
            s2 = backup_engine->CreateNewBackup(db);
            assert(s2.ok());
            std::cout << "  Created backup\n";
            
            delete backup_engine;
            std::cout << "  Closed BackupEngine #1\n";
            
            delete db;
            std::cout << "  Closed DB\n";
        }
        
        // Restore from backup
        {
            rocksdb::BackupEngineOptions backup_opts(backup_path);
            backup_opts.backup_env = rocksdb::Env::Default();
            
            rocksdb::BackupEngine* backup_engine;
            rocksdb::Status s = rocksdb::BackupEngine::Open(rocksdb::Env::Default(), 
                                                           backup_opts, 
                                                           &backup_engine);
            assert(s.ok());
            std::cout << "  Opened BackupEngine #2\n";
            
            s = backup_engine->RestoreDBFromLatestBackup(restore_path, restore_path);
            assert(s.ok());
            std::cout << "  Restored from backup\n";
            
            delete backup_engine;
            std::cout << "  Closed BackupEngine #2\n";
        }
        
        // Verify restored data
        {
            rocksdb::DB* db;
            rocksdb::Options options;
            rocksdb::BlockBasedTableOptions table_options;
            table_options.no_block_cache = true;
            options.table_factory.reset(rocksdb::NewBlockBasedTableFactory(table_options));
            
            rocksdb::Status s = rocksdb::DB::Open(options, restore_path, &db);
            assert(s.ok());
            
            std::string value;
            s = db->Get(rocksdb::ReadOptions(), "key1", &value);
            assert(s.ok());
            assert(value == "value1");
            
            s = db->Get(rocksdb::ReadOptions(), "key2", &value);
            assert(s.ok());
            assert(value == "value2");
            
            std::cout << "  Verified restored data\n";
            
            delete db;
        }
        
        std::cout << "  Test 2 PASSED\n\n";
    }

    std::cout << "All tests completed successfully!\n";
    
    // Cleanup
    cleanup_dir(db_path);
    cleanup_dir(backup_path);
    cleanup_dir(restore_path);
    
    return 0;
}
