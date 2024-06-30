const std = @import("std");
const rfc = @import("rail_fence_cipher");

const io = std.io;
const List = std.ArrayList;
const testing = std.testing;

fn testRailFenceEncode(
    decoded: []const u8,
    encoded: []const u8,
    rails: usize,
) !void {
    const alloc = std.testing.allocator;

    var out = try List(u8).initCapacity(alloc, decoded.len);
    defer out.deinit();
    const writer = out.writer();

    try rfc.encode(decoded, rails, writer);
    const result = out.items;
    try testing.expectEqualStrings(encoded, result);
}

fn testRailFenceDecode(
    decoded: []const u8,
    encoded: []const u8,
    rails: usize,
) !void {
    const alloc = std.testing.allocator;

    var fbs = io.fixedBufferStream(encoded);
    const reader = fbs.reader();
    const buffer: []u8 = try alloc.alloc(u8, encoded.len);
    defer alloc.free(buffer);

    const result = try rfc.decode(reader, rails, buffer, encoded.len);
    try testing.expectEqualStrings(decoded, result);
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
