const std = @import("std");
const clap = @import("clap");
const rfc = @import("rail_fence_cipher");

const log = std.log;
const debug = std.debug;
const io = std.io;
const fs = std.fs;

pub fn main() !void {
    const alloc = std.heap.raw_c_allocator;

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
        const file: fs.File = fs.cwd().openFile(arg, .{.mode = .read_write}) catch |err| {
            log.err("failed to open file: {any}\n", .{err});
            continue;
        };
        defer file.close();
        // TODO: change mode dynamically
        // TODO: do stuff
    }
}
