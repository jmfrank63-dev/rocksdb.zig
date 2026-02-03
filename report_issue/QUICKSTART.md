# Quick Start Guide for Bug Report

This directory contains everything needed to report the lld-link + MSVC Debug CRT issue to the Zig project.

## Files in This Directory

1. **README.md** - Comprehensive issue description and analysis
2. **GITHUB_ISSUE.md** - Ready-to-paste GitHub issue text
3. **WORKAROUND.md** - Detailed workaround documentation
4. **minimal_repro.zig** - Minimal Zig code demonstrating the issue
5. **test_lib.c** - Simple C library to compile with MSVC Debug
6. **build.zig** - Build configuration showing the problem
7. **build_test_lib.bat** - Script to build test library with MSVC
8. **test_with_msvc_linker.bat** - Demonstrates that MSVC linker works

## How to Use This Report

### For Reporting to Zig GitHub

1. **Read the issue**: Review `README.md` to understand the problem

2. **Test locally** (optional but recommended):

   ```cmd
   cd report_issue
   build_test_lib.bat
   zig build test -Dtarget=native-windows-msvc
   ```

   This will reproduce the error on your system.

3. **Create GitHub issue**:

   - Go to: <https://github.com/ziglang/zig/issues/new>
   - Copy contents from `GITHUB_ISSUE.md`
   - Paste into issue body
   - Add link to your repository's `report_issue` directory
   - Submit

### For Sharing with Team

Share the `WORKAROUND.md` file which explains:

- Why the issue happens
- Current workaround (use release mode)
- Future solutions
- Test results proving the wrapper is correct

## Test Results Summary

| Configuration                       | Result                   |
| ----------------------------------- | ------------------------ |
| Zig Release + Zig-built RocksDB     | ✅ 114/114 tests pass    |
| Zig Release + MSVC Release RocksDB  | ✅ All tests pass        |
| **MSVC Debug + MSVC linker**        | **✅ All tests pass**    |
| Zig Debug + Zig lld-link            | ❌ Duplicate symbols     |

## Key Points for Issue Report

1. **Issue is confirmed**: MSVC's linker works, lld-link doesn't
2. **Not a code problem**: Same code succeeds with MSVC linker
3. **Minimal repro**: Simple standalone example provided
4. **Real-world impact**: Blocks using any MSVC Debug libraries
5. **Workaround exists**: Use release mode (works perfectly)

## Expected Timeline

- **Immediate**: Use release mode workaround (fully functional)
- **Short term**: Zig team reviews and confirms issue
- **Medium term**: Zig adds API for debug CRT or improves lld-link
- **Long term**: Debug mode works seamlessly

## Questions?

If you have questions about the issue:

1. Review README.md for technical details
2. Review WORKAROUND.md for current solutions
3. Check `../test_cpp/test_restore_msvc_debug.c` for proof of concept

The core RocksDB wrapper is production-ready using release mode!
