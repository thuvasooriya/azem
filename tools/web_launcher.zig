const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var server_path: ?[]const u8 = null;
    var port: u16 = 8000;
    var serve_dir: []const u8 = ".";

    // parse arguments
    var i: usize = 1;
    while (i < args.len) {
        if (std.mem.eql(u8, args[i], "--server")) {
            if (i + 1 < args.len) {
                server_path = args[i + 1];
                i += 2;
            } else {
                print("--server requires a path\n", .{});
                return;
            }
        } else if (std.mem.eql(u8, args[i], "--port")) {
            if (i + 1 < args.len) {
                port = std.fmt.parseInt(u16, args[i + 1], 10) catch {
                    print("[i] invalid port number: {s}\n", .{args[i + 1]});
                    return;
                };
                i += 2;
            } else {
                print("--port requires a value\n", .{});
                return;
            }
        } else if (std.mem.eql(u8, args[i], "--dir")) {
            if (i + 1 < args.len) {
                serve_dir = args[i + 1];
                i += 2;
            } else {
                print("--dir requires a value\n", .{});
                return;
            }
        } else {
            i += 1;
        }
    }

    if (server_path == null) {
        print("--server argument is required\n", .{});
        return;
    }

    print("[i] starting HTTP server...\n", .{});

    // start the http server as a child process
    const port_str = try std.fmt.allocPrint(allocator, "{d}", .{port});
    defer allocator.free(port_str);

    var server_process = std.process.Child.init(&[_][]const u8{
        server_path.?,
        "--port",
        port_str,
        "--dir",
        serve_dir,
    }, allocator);

    server_process.stdout_behavior = .Inherit;
    server_process.stderr_behavior = .Inherit;

    try server_process.spawn();

    // give the server a moment to start up
    std.time.sleep(1 * std.time.ns_per_s);

    print("[i] opening browser...\n", .{});

    const url = try std.fmt.allocPrint(allocator, "http://localhost:{d}", .{port});
    defer allocator.free(url);

    // try different commands based on the platform
    const builtin = @import("builtin");
    const open_cmd = if (builtin.os.tag == .macos)
        &[_][]const u8{ "open", url }
    else if (builtin.os.tag == .windows)
        &[_][]const u8{ "cmd", "/c", "start", url }
    else
        &[_][]const u8{ "xdg-open", url };

    var open_process = std.process.Child.init(open_cmd, allocator);
    _ = open_process.spawnAndWait() catch |err| {
        print("[i] failed to open browser: {any}. please manually open {s}\n", .{ err, url });
    };

    print("[i] server is running. press ctrl+c to stop.\n", .{});

    // wait for the server process to finish (or be interrupted)
    _ = server_process.wait() catch {};
}
