const std = @import("std");
const testing = std.testing;
const c = @cImport({
    @cInclude("rail_fence_cipher.h");
});

fn testRailFenceEncode(
    decoded: []const u8,
    encoded: []const u8,
    rails: usize,
) !void {
    const alloc = std.heap.raw_c_allocator;
    
    const res: ?[*]u8 = c.encode(.{.len = decoded.len, .ptr = @constCast(decoded.ptr)}, rails);
    if (res == null) return error.Null;

    var result: []u8 = undefined;
    result.ptr = res.?;
    result.len = decoded.len;

    try testing.expectEqualStrings(encoded, result);
    alloc.free(result);
}

fn testRailFenceDecode(
    decoded: []const u8,
    encoded: []const u8,
    rails: usize,
) !void {
    const alloc = std.heap.raw_c_allocator;
    
    const res: ?[*]u8 = c.decode(.{.len = encoded.len, .ptr = @constCast(encoded.ptr)}, rails);
    if (res == null) return error.Null;

    var result: []u8 = undefined;
    result.ptr = res.?;
    result.len = encoded.len;

    try testing.expectEqualStrings(decoded, result);
    alloc.free(result);
}

test "encode" {
    try testRailFenceEncode("loremipsumdolorsitamet", "lmulieoeismoostmtrpdra", 3);
    try testRailFenceEncode("XOXOXOXOXOXOXOXOXO", "XXXXXXXXXOOOOOOOOO", 2);
    try testRailFenceEncode("WEAREDISCOVEREDFLEEATONCE", "WECRLTEERDSOEEFEAOCAIVDEN", 3);
    try testRailFenceEncode("EXERCISES", "ESXIEECSR", 4);
}

test "decode" {
    try testRailFenceDecode("loremipsumdolorsitamet", "lmulieoeismoostmtrpdra", 3);
    try testRailFenceDecode("THEDEVILISINTHEDETAILS", "TEITELHDVLSNHDTISEIIEA", 3);
    try testRailFenceDecode("EXERCISMISAWESOME", "EIEXMSMESAORIWSCE", 5);
    try testRailFenceDecode("112358132134558914423337761098715972584418167651094617711286", "133714114238148966225439541018335470986172518171757571896261", 6);
}
