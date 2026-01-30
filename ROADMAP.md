# RocksDB Zig Wrapper - Feature Roadmap

This document outlines missing RocksDB features that could be added to the Zig wrapper.

## Current Status

The wrapper provides basic key-value operations with column families. It's suitable for simple storage use cases but lacks most advanced RocksDB features.

**Currently Wrapped:**

- ✅ Basic operations (put, get, delete)
- ✅ Column families (create, basic lookup)
- ✅ Iterators (forward/reverse)
- ✅ Write batches
- ✅ Basic metadata (liveFiles, properties)
- ✅ DB.destroy: Delete database from filesystem
- ✅ DBOptions: 14 options (create_if_missing, create_missing_column_families, max_open_files, write_buffer_size, max_write_buffer_number, max_background_jobs, max_manifest_file_size, compression, compression_opts, block_cache, block_size, use_direct_reads, use_direct_io_for_flush_and_compaction, enable_statistics)
- ⏳ DynamicDBOptions: 2 options pending C API (max_manifest_space_amp_pct, target_file_size_is_upper_bound)
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

## Priority 2: Performance Features

### Bloom Filters & Indexing

- [ ] `filter_policy` - Bloom filter configuration
- [ ] `whole_key_filtering` - Key vs prefix filtering
- [ ] `index_type` - Binary search vs hash index

### Compaction Control

- [ ] `level_compaction_dynamic_level_bytes` - Auto-level sizing
- [ ] `target_file_size_base` / `target_file_size_multiplier` - File sizing
- [ ] `max_bytes_for_level_base` / `max_bytes_for_level_multiplier` - Level sizing
- [ ] Manual compaction trigger API
- [ ] `allow_trivial_move` (v10.9.1) - Efficient file movement

### Write Performance

- [ ] `allow_concurrent_memtable_write` - Parallel writes
- [ ] `enable_pipelined_write` - Pipelined writes
- [ ] `max_total_wal_size` - WAL size limit

## Priority 3: Advanced Features

### Transactions

- [ ] `OptimisticTransactionDB` - Optimistic transactions
- [ ] `TransactionDB` - Pessimistic transactions with locking
- [ ] Transaction options (isolation levels, deadlock detection)

### Merge Operators

- [ ] Basic merge operator support
- [ ] Associative merge operators
- [ ] Custom merge logic

### Backup & Recovery

- [ ] `BackupEngine` - Incremental backups
- [ ] `Checkpoint` - Consistent snapshots
- [ ] Restore from backup

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
- **Options**: max_manifest_space_amp_pct (v10.9.1), target_file_size_is_upper_bound (v10.9.1)
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
  - Hard limit of 2 options (expand buffer array if adding more)
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

**Last Updated:** January 30, 2026 (Comprehensive test suite including edge cases, 14 DBOptions + 6 ReadOptions + 3 WriteOptions + 2 DynamicDBOptions + 1 DynamicReadOptions + CompressionOptions + BlockCacheOptions + Snapshots + DB.destroy)

**Priority 1: ✅ COMPLETE** - All critical options and configuration features implemented
