// Minimal test that demonstrates the lld-link + MSVC Debug CRT issue
// This test calls a simple C function from a library built with MSVC Debug mode

const std = @import("std");

// External C function from our test library (built with MSVC /MDd)
extern "c" fn test_add(a: c_int, b: c_int) c_int;
extern "c" fn test_alloc_free() void;

test "call C function from MSVC Debug library" {
    // Simple arithmetic test
    const result = test_add(2, 3);
    try std.testing.expectEqual(@as(c_int, 5), result);

    // Test memory allocation/deallocation
    // This uses the debug CRT's malloc/free
    test_alloc_free();
}

test "basic libc usage in Zig" {
    // This demonstrates that Zig's libc normally works fine
    const allocator = std.heap.c_allocator;
    const mem = try allocator.alloc(u8, 100);
    defer allocator.free(mem);

    @memset(mem, 0);
    try std.testing.expectEqual(@as(u8, 0), mem[0]);
}
