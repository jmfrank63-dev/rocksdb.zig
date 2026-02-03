# GitHub Issue Template for Zig Repository

Copy and paste this into a new issue at <https://github.com/ziglang/zig/issues/new>

---

**Title**: lld-link fails to link MSVC Debug CRT libraries on Windows

**Version**: Zig 0.15.2

**OS/Architecture**: Windows 11 x64, target: native-windows-msvc

## Summary

When linking against libraries built with MSVC Debug CRT (`/MDd`), lld-link produces duplicate symbol errors. The same code links successfully with MSVC's native `link.exe` linker.

## Root Cause

When `link_libc = true`, Zig's build system automatically links the **release** Windows CRT (`libucrt.lib`). There is no API to specify debug CRT instead. When debug CRT libraries are manually added to link against MSVC Debug-built libraries, lld-link errors with duplicate symbols from both release and debug CRT.

## Minimal Reproduction

A complete minimal reproduction is available here:
[Link to your repository's report_issue directory]

Quick reproduction:

```zig
// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const tests = b.addTest(.{
        .root_source_file = b.path("test.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    tests.linkLibC(); // Auto-links release CRT
    
    if (target.result.os.tag == .windows and target.result.abi == .msvc) {
        // Link library built with MSVC Debug /MDd
        tests.addObjectFile(b.path("debug_lib.lib"));
        
        // Try to add debug CRT - causes duplicate symbols
        tests.addLibraryPath(.{ .cwd_relative = "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.26100.0/ucrt/x64" });
        tests.linkSystemLibrary("ucrtd");
        tests.linkSystemLibrary("msvcrtd");
    }
    
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
```

## Error Output

```text
error: lld-link: duplicate symbol: _cexit
    note: defined at minkernel\crts\ucrt\src\appcrt\startup\exit.cpp:321
    note:            libucrt.lib(exit.obj)
    note: defined at ucrtd.lib(ucrtbased.dll)
error: lld-link: duplicate symbol: _invalid_parameter_noinfo
    note: defined at minkernel\crts\ucrt\src\appcrt\misc\invalid_parameter.cpp:129
    note:            libucrt.lib(invalid_parameter.obj)
    note: defined at ucrtd.lib(ucrtbased.dll)
```

## Expected Behavior

One of the following:

1. Provide an API like `linkLibCDebug()` or `link_debug_crt = true`
2. Auto-detect when debug CRT libraries are needed and use them
3. Allow overriding default CRT without conflicts (similar to how we can override libc++ with `link_libcpp = false`)

## Actual Behavior

lld-link always uses release CRT when `link_libc = true`, with no way to override. Manually adding debug CRT causes duplicate symbol conflicts.

## Workaround

Use MSVC's native `link.exe` linker instead of lld-link:

```c
// test.c - compile with MSVC
// cl.exe /MDd test.c debug_lib.lib ucrtd.lib msvcrtd.lib
// Result: ✅ Links successfully
```

We verified this works by creating a standalone C test that uses MSVC's linker with the same debug libraries - all tests pass.

## Impact

This prevents Zig from being used with:

- Libraries built with MSVC Debug mode (common in Windows development)
- Development workflows requiring debug CRT for debugging
- Mixed debug/release scenarios on Windows

Many Windows libraries ship both release and debug builds. Currently, Zig can only link the release versions.

## Additional Context

- Windows requires separate debug and release CRT (cannot be mixed)
- MSVC's linker auto-detects CRT type from `/MDd` vs `/MD` flags
- lld-link lacks this auto-detection and API for manual selection
- Issue discovered while wrapping RocksDB, but affects any MSVC Debug library

## Related Issues

- [Related zig issue if any]

## System Information

```text
zig version: 0.15.2
MSVC version: 19.44.35207 (Visual Studio 2022)
Windows SDK: 10.0.26100.0
```

---

**Labels**: `os-windows`, `linking`, `msvc`, `enhancement`
