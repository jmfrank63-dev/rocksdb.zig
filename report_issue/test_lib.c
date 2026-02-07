// Simple C library to be compiled with MSVC Debug CRT (/MDd)
// This demonstrates the issue when Zig's lld-link tries to link against
// libraries built with debug CRT

#include <stdlib.h>

// Simple function that doesn't use CRT
int test_add(int a, int b) {
    return a + b;
}

// Function that uses debug CRT malloc/free
// This is where the duplicate symbol issues manifest
void test_alloc_free(void) {
    // Allocate using debug CRT's malloc
    void* ptr = malloc(100);
    if (ptr) {
        // Free using debug CRT's free
        free(ptr);
    }
}
