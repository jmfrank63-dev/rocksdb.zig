# RocksDB Zig Wrapper - Feature Roadmap

This document outlines missing RocksDB features that could be added to the Zig wrapper.

## Current Status

The wrapper provides basic key-value operations with column families. It's suitable for simple storage use cases but lacks most advanced RocksDB features.

**Currently Wrapped:**

- ✅ Basic operations (put, get, delete, merge)
- ✅ Column families (create, basic lookup)
- ✅ Iterators (forward/reverse)
- ✅ Write batches
- ✅ Merge operators (StringAppend, UInt64Add, Max + custom callback support)
- ✅ Basic metadata (liveFiles, properties)
- ✅ DB.destroy: Delete database from filesystem
- ✅ Checkpoint: Consistent point-in-time snapshots
- ✅ BackupEngine: Incremental backups with rotation and restore
- ✅ DBOptions: Core options + compaction/write performance tuning + block-based table options
- ⏳ DynamicDBOptions: 3 options pending C API (max_manifest_space_amp_pct, target_file_size_is_upper_bound, allow_trivial_move)
- ✅ ReadOptions: 6 options (verify_checksums, fill_cache, tailing, readahead_size, snapshot, and defaults)
- ⏳ DynamicReadOptions: 1 option pending C API (allow_unprepared_value - v9.8.0+)
- ✅ WriteOptions: 3 options (sync, disable_WAL, low_pri)
- ✅ CompressionOptions: 4 options (window_bits, max_dict_bytes, zstd_max_train_bytes, parallel_threads)
- ✅ BlockCacheOptions: 1 option (size_bytes for LRU cache)
- ✅ Snapshots: Create and release snapshots for point-in-time reads

## Priority 1: Critical Options & Configuration ✅ COMPLETE

### DBOptions Expansion

- [x] `write_buffer_size` - Memory budget for writes
- [x] `max_write_buffer_number` - Number of memtables
- [x] `compression` - Compression type (none, snappy, zstd, lz4)
- [x] `compression_opts` - Fine-grained compression settings
- [x] `block_cache` - LRU cache configuration
- [x] `block_size` - SST block size
- [x] `max_background_jobs` - Parallel compaction/flush threads
- [x] `use_direct_reads` / `use_direct_io_for_flush_and_compaction` - Direct I/O
- [x] `statistics` - Performance monitoring

### New v10.9.1 Options

- [x] `max_manifest_file_size` - Set manifest file size threshold
- ⏳ `max_manifest_space_amp_pct` - Space amplification control (implemented in DynamicDBOptions, awaiting C API)
- ⏳ `target_file_size_is_upper_bound` - Precise file size control (implemented in DynamicDBOptions, awaiting C API)

### ReadOptions

- [x] `verify_checksums` - Data integrity checking
- [x] `fill_cache` - Block cache population control
- [x] `snapshot` - Point-in-time reads
- [x] `readahead_size` - Prefetch optimization

### WriteOptions

- [x] `sync` - Force fsync for durability
- [x] `disable_WAL` - Skip write-ahead log
- [x] `low_pri` - Low priority writes

## Priority 2: Performance Features ✅ COMPLETE

### Bloom Filters & Indexing

- [x] `filter_policy` - Bloom filter configuration
- [x] `whole_key_filtering` - Key vs prefix filtering
- [x] `index_type` - Binary search vs hash index

### Compaction Control

- [x] `level_compaction_dynamic_level_bytes` - Auto-level sizing
- [x] `target_file_size_base` / `target_file_size_multiplier` - File sizing
- [x] `max_bytes_for_level_base` / `max_bytes_for_level_multiplier` - Level sizing
- [x] Manual compaction trigger API (compactRange)
- ⏳ `allow_trivial_move` (v10.9.1) - Efficient file movement (implemented in DynamicDBOptions, awaiting C API)

### Write Performance

- [x] `allow_concurrent_memtable_write` - Parallel writes
- [x] `enable_pipelined_write` - Pipelined writes
- [x] `max_total_wal_size` - WAL size limit

## Priority 3: Advanced Features

### Transactions

- [x] `OptimisticTransactionDB` - Optimistic transactions
- [x] `TransactionDB` - Pessimistic transactions with locking
- [x] Transaction options (isolation levels, deadlock detection)

### Merge Operators

- [x] Basic DB.merge() API method
- [x] Built-in merge operator wrappers (StringAppend, UInt64Add, Max)
- [x] Custom merge operator callback support via ColumnFamilyOptions

### Backup & Recovery

- [x] `BackupEngine` - Incremental backups with getBackupInfo, purgeOldBackups, verifyBackup
- [x] `Checkpoint` - Consistent snapshots with configurable WAL flushing
- [x] Restore from backup - restoreFromLatestBackup and restoreFromBackup with RestoreOptions

### Batch Operations

- [ ] `MultiGet` - Batch reads for better performance
- [ ] `MultiPutEntity` - Batch writes with wide columns

## Priority 4: Operational Features

### Monitoring & Statistics

- [ ] Statistics collection API
- [ ] `GetProperty` for all properties (cache size, mem usage, etc.)
- [ ] Histogram support
- [ ] Performance context

### TTL & Cleanup

- [ ] TTL database support (automatic expiration)
- [ ] `DeleteFilesInRange` improvements
- [ ] Compaction filter for custom cleanup

### Rate Limiting

- [ ] `RateLimiter` for I/O throttling
- [ ] Write rate limiting
- [ ] Read rate limiting

### Universal Compaction

- [ ] Universal compaction style
- [ ] `CompactionOptionsUniversal` wrapper

## Priority 5: Specialized Features

### Column Family Management

- [ ] Multi-CF options migration (v10.9.1 API)
- [ ] Drop column family
- [ ] CF metadata introspection

### Snapshots

- [ ] Create snapshot
- [ ] Release snapshot
- [ ] Snapshot iteration

### Error Handling Improvements

- [ ] Background error detection
- [ ] Error listener callbacks
- [ ] Corruption detection utilities

### SstFileWriter

- [ ] Write SST files directly
- [ ] Ingest external SST files

## Implementation Plan (Remaining Work)

1. **Batch Operations**

- Implement `MultiGet` (C API) with CF support
- Implement `MultiPutEntity` (or emulate via WriteBatch if C API missing)
- Tests for mixed CF and error propagation

1. **Monitoring & Statistics**

- Expand `GetProperty` coverage and typed helpers
- Add statistics + histogram accessors
- Tests verifying properties and counters return data

1. **Backup & Recovery** ✅ COMPLETE

- ✅ Checkpoint wrapper: create(), destroy() with configurable WAL flushing
- ✅ BackupEngine wrapper: open(), createNewBackup(), getBackupInfo(), purgeOldBackups(), verifyBackup(), close()
- ✅ Restore flow: restoreFromLatestBackup(), restoreFromBackup() with RestoreOptions
- ✅ RestoreOptions: keep_log_files option with convert() helper

1. **Transactions**

- Add `OptimisticTransactionDB` and `TransactionDB` (if exposed in C API)
- Add transaction options (isolation/deadlock) or placeholders if C++-only
- Tests for commit/rollback and concurrency

1. **Merge Operators** ✅ COMPLETE

- MergeOperator type with proper lifetime management and move semantics
- Built-in merge operators: StringAppend (with delimiter), UInt64Add, Max
- Full integration with ColumnFamilyOptions
- Safety features: memory leak prevention, double-free protection, null handle safety
- Comprehensive test coverage for all merge operators (94 total tests)
- Multi-CF support with different merge operators per CF
- Documentation of performance characteristics (full merge only, no partial merge)

1. **TTL & Cleanup**

- TTL DB support (if C API available)
- Compaction filters for cleanup (or placeholders if C++-only)
- Tests for expiry/cleanup

1. **Rate Limiting**

- `RateLimiter` integration in options
- Tests for option acceptance

1. **Universal Compaction**

- `CompactionOptionsUniversal` wrapper
- Tests for DB open with universal compaction

1. **Column Family Management**

- Drop CF + CF metadata introspection
- Multi-CF options migration helpers
- Tests for create/drop/metadata

1. **Snapshot Iteration**

- Snapshot-bound iterators with stability tests

1. **SstFileWriter / External SST**

- Wrap SST writer and ingestion APIs
- Tests for write+ingest flow

## Implementation Notes

### Design Principles

1. **Type Safety**: Use Zig's type system to prevent misuse
2. **RAII**: Ensure proper cleanup with defer patterns
3. **Error Handling**: All RocksDB errors propagate as Zig errors
4. **Documentation**: Document all options with defaults and effects
5. **Testing**: Comprehensive tests for each feature
6. **Zero-Cost**: No overhead beyond RocksDB's native cost
7. **Dynamic Options Pattern**: Options not yet in C API are implemented via string-based rocksdb_set_options() in DynamicDBOptions/DynamicReadOptions structs for easy migration when C API is extended

### Dynamic Options Architecture

Options waiting for C API exposure are separated into `Dynamic*Options` structs:

#### DynamicDBOptions (Functional)

- **Status**: ✅ Fully functional with complete error visibility
- **Options**: max_manifest_space_amp_pct (v10.9.1), target_file_size_is_upper_bound (v10.9.1), allow_trivial_move (v10.9.1)
- **Applied**: Post-open in `DB.open()` via `applyDynamicDBOptions()`
- **Error Handling**:
  - Returns `error.RocksDBSetOptions` if RocksDB rejects the option
  - Error messages are properly surfaced via `err_str` parameter
  - RocksDB error buffers are freed automatically via `rocksdb_free`
- **Implementation Details**:
  - Keys: Static NUL-terminated literals (`"key\x00"`) - zero allocation overhead
  - Values: Dynamically allocated and NUL-terminated with explicit `+1` byte
  - All errors visible, surfaced, and properly freed (no leaks)
  - Proper cleanup via defer blocks even on error
- **Limitations**:
  - Hard limit of 3 options (expand buffer array if adding more)
  - Some options may not be settable on already-open database (RocksDB limitation)

#### DynamicReadOptions (Placeholder)

- **Status**: 🔄 Waiting for C API (cannot be applied yet)
- **Options**: allow_unprepared_value (v9.8.0+, BlobDB feature)
- **Why Not Applied**: Read options are per-read settings, not DB-wide. They require direct C API setters (like `rocksdb_readoptions_set_allow_unprepared_value`), which don't exist yet. Unlike `rocksdb_set_options`, there's no string-based API for read options.
- **Migration**: When C API is available, move to `ReadOptions` struct and apply in `convert()`

#### Migration Path When C API is Extended

1. Remove from `Dynamic*Options` struct
2. Add as regular field to main Options struct
3. Update `convert()` function with the setter
4. Remove from `applyDynamic*Options()` functions
5. Run tests to verify

This approach provides:

- Clear separation of C API vs dynamic options
- Easy audit trail and issue tracking
- Type-safe Zig interface while waiting for C API
- Zero migration cost when C API is available
- Proper NUL-termination for all C string arguments

### Breaking Changes Strategy: Keep existing API stable

- Add new fields as optional with sensible defaults
- Use builder pattern for complex option structures
- Version compatibility with RocksDB releases

### Testing Strategy

- Unit tests for each option (65+ tests passing)
- Integration tests for feature combinations
- Error propagation tests - verify RocksDBSetOptions is returned on rejection
- Memory leak detection (already implemented)
- Performance benchmarks for critical paths
- NUL-termination validation via actual C API calls

## Related Issues & Tracked Features

- [x] NUL-termination for keys and values - Both properly terminated via explicit allocation
- [x] Error visibility for dynamic options - Returns error.RocksDBSetOptions with full diagnostics
- [x] Error message surfacing - RocksDB error strings properly copied to err_str and freed
- [x] DynamicDBOptions with max_manifest_space_amp_pct & target_file_size_is_upper_bound
- ⏳ DynamicReadOptions allow_unprepared_value - Waiting for C API
  - [Tracked in rocksdb#14114](https://github.com/facebook/rocksdb/issues/14114)
- Windows shared library build (currently failing CI)
- AllocationFailure testing for complex scenarios
- Documentation generation from RocksDB headers
- C API exposure requests:
  - [allow_unprepared_value](https://github.com/facebook/rocksdb/issues/14114)
  - [max_manifest_space_amp_pct](https://github.com/facebook/rocksdb/pull/xxxxx) (pending)
  - [target_file_size_is_upper_bound](https://github.com/facebook/rocksdb/pull/xxxxx) (pending)

---

**Status Legend:**

- ✅ Implemented and tested
- 🔄 Placeholder / waiting for dependency
- [ ] Not yet implemented
- 🚧 Work in progress
- ❌ Not feasible / not applicable

**Last Updated:** February 3, 2026 (Test suite: 108 tests passing; Priority 1 & 2 complete; Priority 3 now includes transactions, merge operators, and backup & recovery)

**Priority 1: ✅ COMPLETE** - All critical options and configuration features implemented
**Priority 2: ✅ COMPLETE** - All core performance features implemented
**Priority 3 Progress: ✅ Transactions, ✅ Merge Operators, ✅ Backup & Recovery | ⏳ Batch Operations
