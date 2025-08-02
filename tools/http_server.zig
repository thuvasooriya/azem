const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Config = struct {
    port: u16,
    serve_dir: []const u8,
};

fn parseArgs(allocator: Allocator) !Config {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var config = Config{
        .port = 8000,
        .serve_dir = ".",
    };

    var i: usize = 1;
    while (i < args.len) {
        if (std.mem.eql(u8, args[i], "--port") or std.mem.eql(u8, args[i], "-p")) {
            if (i + 1 < args.len) {
                config.port = std.fmt.parseInt(u16, args[i + 1], 10) catch {
                    std.debug.print("invalid port number: {s}\n", .{args[i + 1]});
                    std.process.exit(1);
                };
                i += 2;
            } else {
                std.debug.print("port option requires a value\n", .{});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, args[i], "--dir") or std.mem.eql(u8, args[i], "-d")) {
            if (i + 1 < args.len) {
                config.serve_dir = try allocator.dupe(u8, args[i + 1]);
                i += 2;
            } else {
                std.debug.print("directory option requires a value\n", .{});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, args[i], "--help") or std.mem.eql(u8, args[i], "-h")) {
            std.debug.print("usage: {s} [options]\n", .{args[0]});
            std.debug.print("options:\n", .{});
            std.debug.print("  --port, -p <port>     port to listen on (default: 8000)\n", .{});
            std.debug.print("  --dir, -d <directory> directory to serve (default: current directory)\n", .{});
            std.debug.print("  --help, -h            show this help message\n", .{});
            std.process.exit(0);
        } else {
            i += 1;
        }
    }

    return config;
}

fn getContentType(file_path: []const u8) []const u8 {
    const ext = std.fs.path.extension(file_path);

    if (std.mem.eql(u8, ext, ".html")) return "text/html";
    if (std.mem.eql(u8, ext, ".css")) return "text/css";
    if (std.mem.eql(u8, ext, ".js")) return "application/javascript";
    if (std.mem.eql(u8, ext, ".wasm")) return "application/wasm";
    if (std.mem.eql(u8, ext, ".json")) return "application/json";
    if (std.mem.eql(u8, ext, ".png")) return "image/png";
    if (std.mem.eql(u8, ext, ".jpg") or std.mem.eql(u8, ext, ".jpeg")) return "image/jpeg";
    if (std.mem.eql(u8, ext, ".gif")) return "image/gif";
    if (std.mem.eql(u8, ext, ".svg")) return "image/svg+xml";
    if (std.mem.eql(u8, ext, ".ico")) return "image/x-icon";

    return "application/octet-stream";
}

fn serveFile(allocator: Allocator, request: *std.http.Server.Request, file: std.fs.File, content_type: []const u8) !void {
    const file_size = try file.getEndPos();
    const content = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(content);

    try request.respond(content, .{
        .status = .ok,
        .extra_headers = &.{
            .{ .name = "content-type", .value = content_type },
            .{ .name = "cache-control", .value = "no-cache" },
        },
    });
}

fn handleRequest(allocator: Allocator, request: *std.http.Server.Request, serve_dir: []const u8) !void {
    const method = request.head.method;
    const target = request.head.target;

    std.debug.print("{s} {s}\n", .{ @tagName(method), target });

    if (method != .GET and method != .HEAD) {
        try request.respond("method not allowed", .{ .status = .method_not_allowed });
        return;
    }

    // clean the target path - remove query parameters and fragments
    var clean_target = target;
    if (std.mem.indexOf(u8, target, "?")) |idx| {
        clean_target = target[0..idx];
    }
    if (std.mem.indexOf(u8, clean_target, "#")) |idx| {
        clean_target = clean_target[0..idx];
    }

    // if requesting root, serve index.html
    if (std.mem.eql(u8, clean_target, "/")) {
        clean_target = "/index.html";
    }

    // build the file path
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const file_path = std.fmt.bufPrint(&path_buf, "{s}{s}", .{ serve_dir, clean_target }) catch {
        try request.respond("URI too long", .{ .status = .uri_too_long });
        return;
    };

    // get the absolute path
    const abs_path = std.fs.realpathAlloc(allocator, file_path) catch |err| switch (err) {
        error.FileNotFound => {
            try request.respond("not found", .{ .status = .not_found });
            return;
        },
        error.AccessDenied => {
            try request.respond("forbidden", .{ .status = .forbidden });
            return;
        },
        else => {
            std.debug.print("error resolving path {s}: {any}\n", .{ file_path, err });
            try request.respond("internal server error", .{ .status = .internal_server_error });
            return;
        },
    };
    defer allocator.free(abs_path);

    // Security check: ensure the resolved path is still within serve directory
    const abs_serve_dir = std.fs.realpathAlloc(allocator, serve_dir) catch {
        try request.respond("internal server error", .{ .status = .internal_server_error });
        return;
    };
    defer allocator.free(abs_serve_dir);

    if (!std.mem.startsWith(u8, abs_path, abs_serve_dir)) {
        try request.respond("forbidden", .{ .status = .forbidden });
        return;
    }

    // Try to open the file
    const file = std.fs.openFileAbsolute(abs_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            try request.respond("not found", .{ .status = .not_found });
            return;
        },
        error.AccessDenied => {
            try request.respond("forbidden", .{ .status = .forbidden });
            return;
        },
        else => {
            std.debug.print("error opening file {s}: {any}\n", .{ abs_path, err });
            try request.respond("internal server error", .{ .status = .internal_server_error });
            return;
        },
    };
    defer file.close();

    // determine content type based on file extension
    const content_type = getContentType(abs_path);
    try serveFile(allocator, request, file, content_type);
}

fn handleConnection(allocator: Allocator, connection: std.net.Server.Connection, serve_dir: []const u8) !void {
    defer connection.stream.close();

    var read_buffer: [8192]u8 = undefined;
    var http_server = std.http.Server.init(connection, &read_buffer);

    while (http_server.state == .ready) {
        var request = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => break,
            else => {
                std.debug.print("error receiving HTTP head: {any}\n", .{err});
                break;
            },
        };

        handleRequest(allocator, &request, serve_dir) catch |err| {
            std.debug.print("error handling request: {any}\n", .{err});
        };
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const config = parseArgs(allocator) catch |err| {
        std.debug.print("error parsing arguments: {any}\n", .{err});
        return;
    };

    // convert serve_dir to absolute path to avoid issues
    const abs_serve_dir = std.fs.path.resolve(allocator, &[_][]const u8{config.serve_dir}) catch |err| {
        std.debug.print("error resolving serve directory: {any}\n", .{err});
        return;
    };
    defer allocator.free(abs_serve_dir);

    const address = std.net.Address.parseIp("127.0.0.1", config.port) catch unreachable;
    var net_server = address.listen(.{ .reuse_address = true }) catch |err| {
        std.debug.print("failed to listen on port {d}: {any}\n", .{ config.port, err });
        return;
    };
    defer net_server.deinit();

    std.debug.print("HTTP server running at http://localhost:{d}/\n", .{config.port});
    std.debug.print("serving directory: {s}\n", .{abs_serve_dir});

    while (true) {
        const connection = net_server.accept() catch |err| {
            std.debug.print("failed to accept connection: {any}\n", .{err});
            continue;
        };

        handleConnection(allocator, connection, abs_serve_dir) catch |err| {
            std.debug.print("error handling connection: {any}\n", .{err});
        };
    }
}
