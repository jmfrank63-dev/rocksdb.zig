const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // This demonstrates the issue:
    // 1. We have a library built with MSVC Debug CRT (test_lib.lib)
    // 2. We try to link it with Zig's lld-link
    // 3. lld-link fails because it auto-includes release CRT (libucrt.lib)
    //    which conflicts with the debug CRT symbols in test_lib.lib

    // Create a module for the test
    const test_mod = b.createModule(.{
        .root_source_file = b.path("minimal_repro.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_module = test_mod,
    });

    // Link libc (this auto-includes RELEASE CRT on Windows)
    tests.linkLibC();

    // Try to add debug CRT libraries
    // This causes duplicate symbols because Zig already linked release CRT
    if (target.result.os.tag == .windows and target.result.abi == .msvc) {
        // Try common Windows SDK paths
        // Note: This path may vary - adjust for your Windows SDK version
        const sdk_paths = [_][]const u8{
            "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.26100.0/ucrt/x64",
            "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.22621.0/ucrt/x64",
            "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.22000.0/ucrt/x64",
            "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/ucrt/x64",
        };

        // Try to add first available SDK path
        for (sdk_paths) |sdk_path| {
            tests.addLibraryPath(.{ .cwd_relative = sdk_path });
            break; // Only need one path
        }

        // Link our test library (built with MSVC Debug /MDd)
        tests.addObjectFile(b.path("test_lib.lib"));

        // Attempt to link debug CRT (conflicts with release CRT from linkLibC)
        tests.linkSystemLibrary("ucrtd"); // Debug Universal CRT
        tests.linkSystemLibrary("msvcrtd"); // Debug C runtime
        tests.linkSystemLibrary("msvcprtd"); // Debug C++ runtime
        tests.linkSystemLibrary("vcruntimed"); // Debug VC runtime
    }

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
