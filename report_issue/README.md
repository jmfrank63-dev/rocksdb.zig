# Zig lld-link Cannot Link MSVC Debug CRT Libraries

## Summary

When using `zig build test` with `-Dtarget=native-windows-msvc` and linking against MSVC Debug CRT libraries (`msvcrtd.lib`, `ucrtd.lib`, etc.), lld-link fails with duplicate symbol errors. The same code compiles and runs successfully when using MSVC's native `link.exe` linker.

## Environment

- **Zig Version**: 0.15.2
- **OS**: Windows 11
- **MSVC Version**: Visual Studio 2022 Community (19.44.35207)
- **Target**: `native-windows-msvc` (x86_64-windows-msvc)

## Problem Description

When setting `.link_libc = true` in Zig, the build system automatically links the **release** Windows CRT (`libucrt.lib`). When manually adding **debug** CRT libraries to link against MSVC Debug-built libraries, lld-link produces duplicate symbol errors because both release and debug CRT symbols are present:

```text
error: lld-link: duplicate symbol: _cexit
    note: defined at minkernel\crts\ucrt\src\appcrt\startup\exit.cpp:321
    note:            libucrt.lib(exit.obj)
    note: defined at ucrtd.lib(ucrtbased.dll)
```

### Root Cause

1. Zig's `link_libc = true` automatically links **release CRT** (`libucrt.lib`)
2. No API exists in Zig 0.15.2 to specify "use debug CRT instead"
3. Manually adding debug CRT libraries creates conflicts with auto-linked release CRT
4. MSVC's linker handles this correctly when compiling the same code

## Minimal Reproducible Example

See the files in this directory:

- `minimal_repro.zig` - Minimal Zig test that calls a C function
- `build.zig` - Build configuration attempting to use MSVC Debug CRT
- `test_lib.c` - Simple C library compiled with MSVC Debug mode
- `build_test_lib.bat` - Script to build the C library with MSVC Debug

### Steps to Reproduce

1. Build the test C library with MSVC Debug CRT:

   ```cmd
   cd report_issue
   build_test_lib.bat
   ```

2. Try to build with Zig (will fail):

   ```cmd
   zig build test -Dtarget=native-windows-msvc
   ```

3. Build with MSVC linker (succeeds):

   ```cmd
   test_with_msvc_linker.bat
   ```

## Expected Behavior

Zig should either:

1. Provide an API to specify debug vs release CRT when `link_libc = true`
2. Auto-detect when debug CRT libraries are linked and use debug CRT instead of release
3. Allow overriding the default CRT libraries without conflicts

## Actual Behavior

lld-link produces duplicate symbol errors when attempting to link both release and debug CRT.

## Workaround

Use MSVC's native linker (`link.exe`) instead of lld-link. See `WORKAROUND.md` for details.

## Impact

This prevents Zig from being used with:

- MSVC Debug-built libraries (common in Windows development)
- Development workflows requiring debug CRT for debugging
- Mixed debug/release builds on Windows

## Related Context

This issue was discovered while wrapping RocksDB v10.9.1 in Zig. The wrapper works perfectly with:

- ✅ Zig-built RocksDB in Release mode (114/114 tests pass)
- ✅ MSVC-built RocksDB Release mode (all tests pass)
- ✅ MSVC-built RocksDB Debug mode **with MSVC linker** (all tests pass)
- ❌ MSVC-built RocksDB Debug mode **with Zig/lld-link** (duplicate symbols)

The issue is specifically with lld-link's handling of MSVC debug CRT, not with the Zig wrapper code.

## Additional Information

Windows has strict rules about mixing debug and release CRT:

- Debug CRT: `ucrtd.lib`, `msvcrtd.lib`, `msvcprtd.lib`, `vcruntimed.lib`
- Release CRT: `libucrt.lib`, `msvcrt.lib`, `msvcprt.lib`, `vcruntime.lib`

These cannot be mixed in a single executable. MSVC's linker handles this automatically based on the `/MDd` (debug) or `/MD` (release) flag. Zig's lld-link currently always includes release CRT when `link_libc = true`, with no way to override this behavior.
