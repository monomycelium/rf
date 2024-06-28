const std = @import("std");
const mem = std.mem;

/// Encode `data` using `key` rails in Rail Fence Cipher, writing encoded data using `writer`.
pub fn encode(data: []const u8, key: usize, writer: anytype) !void {
    if (key == 0) return error.InvalidKey;
    if (key == 1 or data.len <= key) return writer.writeAll(data);
    
    const increment: usize = 2 * (key - 1);

    for (0..key) |i| {
        var data_index: usize = i;

        if (i == 0 or i == key - 1) {
            while (data_index < data.len) : (data_index += increment)
                try writer.writeByte(data[data_index]);
        } else {
            var previous_increment: usize = 2 * i;
            while (data_index < data.len) { 
                try writer.writeByte(data[data_index]);
                previous_increment = increment - previous_increment;
                data_index += previous_increment;
            }
        }
    }
}

/// Decrypt `length` bytes read from `reader` using `key` rails in Rail Fence Cipher,
/// writing decoded data to `buffer`.
pub fn decode(reader: anytype, key: usize, buffer: []u8, length: usize) ![]u8 {
    if (key == 0) return error.InvalidKey;
    if (key == 1 or length <= key) {
        const n = try reader.readAtLeast(buffer, length);

        var buf: []u8 = undefined;
        buf.ptr = buffer.ptr;
        buf.len = @min(n, length);

        return buf;
    }

    const increment: usize = 2 * (key - 1);
    var count: usize = 0;

    outer: for (0..key) |i| {
        var data_index: usize = i;

        if (i == 0 or i == key - 1) {
            while (data_index < length) : (data_index += increment) {
                buffer[data_index] = reader.readByte() catch |e| if (e == error.NoEofError) break :outer else return e;
                count += 1;
            }
        } else {
            var previous_increment: usize = 2 * i;
            while (data_index < length) { 
                buffer[data_index] = reader.readByte() catch |e| if (e == error.NoEofError) break :outer else return e;
                count += 1;
                previous_increment = increment - previous_increment;
                data_index += previous_increment;
            }
        }
    }

    var buf: []u8 = undefined;
    buf.ptr = buffer.ptr;
    buf.len = count;
    return buf;
}
