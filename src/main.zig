const std = @import("std");
const clap = @import("clap");
const rfc = @import("rail_fence_cipher");

const log = std.log;
const debug = std.debug;
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
    if (res.args.rails == null)
        return clap.usage(std.io.getStdErr().writer(), clap.Help, &params);

    std.debug.print("rails: {}\n", .{res.args.rails.?});
    std.debug.print("files to {s}: ", .{if (res.args.decode == 0) "encode" else "decode"});
    for (res.positionals, 0..) |arg, i|
        std.debug.print("{s}{s}", .{arg, if (i == res.positionals.len - 1) "\n" else ", "});

    for (res.positionals) |arg| {
        const stdin: bool = std.mem.eql(u8, arg, "-");
        const stdout: bool = res.args.stdout != 0 or stdin;

        const input: fs.File = if (stdin) std.io.getStdIn()
            else fs.cwd().openFile(arg, .{.mode = if (stdout) .read_only else .read_write}) catch |err| {
                log.err("failed to open input: {any}\n", .{err});
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
            defer buffered.flush();

            try rfc.encode(buf, res.args.rails.?, writer);
        } else { // decode
            var buffered = std.io.bufferedReader(output.reader());
            const reader = buffered.reader();
            
            // TODO: implement calling decode function.
        }
    }
}
