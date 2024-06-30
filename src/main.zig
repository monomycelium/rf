const std = @import("std");
const clap = @import("clap");
const rfc = @import("rail_fence_cipher");

const log = std.log;
const io = std.io;
const fs = std.fs;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help            Display this help and exit.
        \\-r, --rails <usize>   Number of rails (key).
        \\-s, --stdout          Write data to stdout instead of file.
        \\-d, --decode          Decode data instead of encoding it.
        \\<file>
    );

    const parsers = comptime .{
        .file = clap.parsers.string,
        .usize = clap.parsers.int(usize, 10),
    };
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = alloc,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    if (res.args.rails == null or res.positionals.len == 0)
        return clap.usage(std.io.getStdErr().writer(), clap.Help, &params);

    for (res.positionals) |arg| {
        const stdin: bool = std.mem.eql(u8, arg, "-");
        const stdout: bool = res.args.stdout != 0 or stdin;

        const input: fs.File = if (stdin) std.io.getStdIn() else fs.cwd().openFile(arg, .{ .mode = if (stdout) .read_only else .read_write }) catch |err| {
            log.err("failed to open input `{s}`: {any}\n", .{ if (stdin) "stdin" else arg, err});
            continue;
        };
        defer if (!stdin) input.close();
        const output: fs.File = if (stdout) std.io.getStdOut() else input;

        if (res.args.decode == 0) { // encode
            const size: u64 = input.getEndPos() catch |e| switch (e) {
                error.Unseekable => 0,
                else => return e,
            };
            if (size > std.math.maxInt(usize)) return error.FileTooBig;

            const buf: []u8 = try input.readToEndAllocOptions(alloc, std.math.maxInt(usize), @truncate(size), @alignOf(u8), null);
            defer alloc.free(buf);

            var buffered = std.io.bufferedWriter(output.writer());
            const writer = buffered.writer();
            if (!stdout) try output.seekTo(0);
            defer buffered.flush() catch undefined;

            try rfc.encode(buf, res.args.rails.?, writer);
        } else { // decode
            const size: u64 = input.getEndPos() catch |e| switch (e) {
                error.Unseekable => 0,
                else => return e,
            };
            if (size > std.math.maxInt(usize)) return error.FileTooBig;

            var out: ?[]u8 = null;
            var ret: []u8 = undefined;
            defer if (out) |r| alloc.free(r);

            if (size > 0) {
                var buffered = std.io.bufferedReader(input.reader());
                const reader = buffered.reader();

                out = try alloc.alloc(u8, @truncate(size));
                ret = try rfc.decode(reader, res.args.rails.?, out.?, out.?.len);
            } else {
                const buf: []u8 = try input.readToEndAllocOptions(alloc, std.math.maxInt(usize), null, @alignOf(u8), null);
                defer alloc.free(buf);
                var fbs = std.io.fixedBufferStream(buf);
                const reader = fbs.reader();

                out = try alloc.alloc(u8, buf.len);
                ret = try rfc.decode(reader, res.args.rails.?, out.?, out.?.len);
            }

            if (!stdout) try output.seekTo(0);
            try output.writeAll(ret);
        }
    }
}
