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
- ✅ DBOptions: 11 options (create_if_missing, create_missing_column_families, max_open_files, write_buffer_size, max_write_buffer_number, max_background_jobs, compression, compression_opts, use_direct_reads, use_direct_io_for_flush_and_compaction, enable_statistics)
- ✅ ReadOptions: 5 options (verify_checksums, fill_cache, tailing, readahead_size, and defaults)
- ✅ WriteOptions: 2 options (sync, disable_WAL)
- ✅ CompressionOptions: 4 options (window_bits, max_dict_bytes, zstd_max_train_bytes, parallel_threads)

## Priority 1: Critical Options & Configuration

### DBOptions Expansion

- [x] `write_buffer_size` - Memory budget for writes
- [x] `max_write_buffer_number` - Number of memtables
- [x] `compression` - Compression type (none, snappy, zstd, lz4)
- [x] `compression_opts` - Compression level settings
- [ ] `block_cache` - LRU/LFU cache configuration
- [ ] `block_size` - SST block size
- [x] `max_background_jobs` - Parallel compaction/flush threads
- [x] `use_direct_reads` / `use_direct_io_for_flush_and_compaction` - Direct I/O
- [x] `statistics` - Performance monitoring

### New v10.9.1 Options

- [ ] `max_manifest_file_size` - Auto-tuning for manifest size
- [ ] `max_manifest_space_amp_pct` - Space amplification control
- [ ] `target_file_size_is_upper_bound` - Precise file size control

### ReadOptions

- [x] `verify_checksums` - Data integrity checking
- [x] `fill_cache` - Block cache population control
- [ ] `snapshot` - Point-in-time reads
- [x] `readahead_size` - Prefetch optimization

### WriteOptions

- [x] `sync` - Force fsync for durability
- [x] `disable_WAL` - Skip write-ahead log
- [ ] `low_pri` - Low priority writes

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

### Breaking Changes Strategy

- Keep existing API stable
- Add new fields as optional with sensible defaults
- Use builder pattern for complex option structures
- Version compatibility with RocksDB releases

### Testing Strategy

- Unit tests for each option
- Integration tests for feature combinations
- Memory leak detection (already implemented)
- Performance benchmarks for critical paths

## Related Issues

- Windows shared library build (currently failing CI)
- AllocationFailure testing for complex scenarios
- Documentation generation from RocksDB headers

---

**Status Legend:**

- ✅ Implemented and tested
- [ ] Not yet implemented
- 🚧 Work in progress
- ❌ Not feasible / not applicable

**Last Updated:** January 30, 2026 (58 tests passing, 11 DBOptions + 5 ReadOptions + 2 WriteOptions + CompressionOptions)
