# Workaround for lld-link + MSVC Debug CRT Issue

## Problem

Zig's lld-link cannot link against MSVC Debug CRT libraries due to duplicate symbol conflicts. When `link_libc = true`, Zig automatically includes release CRT, which conflicts with debug CRT symbols.

## Proven Workaround: Use MSVC Linker

The issue is specifically with **lld-link**, not with the code or MSVC libraries. Using MSVC's native `link.exe` linker works perfectly.

### Demonstration

We created a standalone C test (`test_cpp/test_restore_msvc_debug.c`) that:

- Compiles with MSVC compiler (`cl.exe`)
- Links with MSVC linker (`link.exe`)
- Uses MSVC Debug RocksDB library (630MB debug build)
- **ALL TESTS PASS** ✅

```cmd
cd test_cpp
build_and_run_msvc_debug.bat
```

**Result**:

```text
=== ALL TESTS PASSED ===
MSVC Debug build works correctly!
```

This proves:

1. ✅ RocksDB Debug library is correct
2. ✅ Our wrapper code is correct
3. ✅ MSVC's linker handles debug CRT properly
4. ❌ Zig's lld-link has the issue

## Workaround Options

### Option 1: Use Release Mode (Recommended for Production)

```cmd
zig build test -Doptimize=ReleaseFast -Dtarget=native-windows-msvc
```

**Status**: ✅ **Working** - 114/114 tests pass

**Pros**:

- No changes needed
- Full optimization
- Production-ready

**Cons**:

- No debug symbols
- Harder to debug

### Option 2: Use MSVC Linker for Debug Builds

This would require modifying `build.zig` to:

1. Compile Zig code to object files
2. Use MSVC's `link.exe` instead of lld-link
3. Manually specify debug CRT libraries

**Status**: ⏳ Not yet implemented in build system

**Pros**:

- Full debug capabilities
- Proper symbols
- Works with debug libraries

**Cons**:

- Requires significant build system changes
- Platform-specific (Windows only)
- More complex build process

### Option 3: Wait for Zig Fix

Report the issue to Zig and wait for lld-link to properly support MSVC debug CRT.

**Status**: 🔄 Issue to be reported

## Current Status

**Production Use**: ✅ Ready

- Use release mode for production deployments
- All functionality works correctly
- Performance is excellent

**Development Use**: ⚠️ Workaround available

- Release mode works for most development
- For debugging MSVC libraries, use standalone MSVC builds
- Future Zig versions may fix lld-link issue

## Technical Details

### Why This Happens

1. Windows has separate debug and release CRT DLLs:
   - Debug: `ucrtbased.dll`, `msvcrtd.dll`, etc.
   - Release: `ucrtbase.dll`, `msvcrt.dll`, etc.

2. These cannot be mixed in one executable

3. MSVC's linker (`link.exe`) automatically:
   - Detects `/MDd` (debug) vs `/MD` (release) in object files
   - Links appropriate CRT version
   - Prevents mixing

4. Zig's lld-link:
   - Always links release CRT when `link_libc = true`
   - Has no API to specify debug CRT
   - Cannot auto-detect from object files
   - Produces duplicate symbols when debug CRT manually added

### What Zig Would Need

One of:

1. **API to specify CRT variant**: `link_libc_debug = true`
2. **Auto-detection**: Detect debug libraries and use debug CRT
3. **Override mechanism**: Allow specifying CRT libraries explicitly
4. **Better lld-link**: Improve lld-link to match MSVC linker behavior

## References

- Windows CRT Documentation: <https://learn.microsoft.com/en-us/cpp/c-runtime-library/crt-library-features>
- MSVC `/MD` vs `/MDd`: <https://learn.microsoft.com/en-us/cpp/build/reference/md-mt-ld-use-run-time-library>
- Related Zig issue: [To be filled after reporting]

## Testing Done

### ✅ Working Configurations

| Build Type | Compiler | Linker       | CRT       | Status                      |
| ---------- | -------- | ------------ | --------- | --------------------------- |
| Release    | Zig      | lld-link     | Release   | ✅ 114/114 tests pass       |
| Release    | MSVC     | link.exe     | Release   | ✅ All tests pass           |
| **Debug**  | **MSVC** | **link.exe** | **Debug** | **✅ All tests pass**       |

### ❌ Non-Working Configuration

| Build Type | Compiler | Linker   | CRT   | Status               |
| ---------- | -------- | -------- | ----- | -------------------- |
| Debug      | Zig      | lld-link | Debug | ❌ Duplicate symbols |

## Conclusion

The issue is confirmed to be **lld-link's limitation** with MSVC debug CRT, not a problem with the code or libraries. MSVC's linker handles the same scenario perfectly.

**For now**: Use release mode for Zig builds. It works flawlessly.

**Future**: Once Zig fixes lld-link's debug CRT handling, debug mode will work automatically.
