const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/azem.zig");

    // native os targets
    // tested on macos
    {
        // const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize, .backend = .raylib });
        const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize, .backend = .sdl3 });

        const azem_mod = b.createModule(.{
            .root_source_file = root_source_file,
            .optimize = optimize,
            .target = target,
        });

        // azem_mod.addImport("dvui", dvui_dep.module("dvui_raylib"));
        azem_mod.addImport("dvui", dvui_dep.module("dvui_sdl3"));

        const exe = b.addExecutable(.{
            .name = "azem",
            .root_module = azem_mod,
        });

        if (optimize != .Debug) {
            switch (target.result.os.tag) {
                .windows => exe.subsystem = .Windows,
                else => exe.subsystem = .Posix,
            }
        }

        if (target.result.os.tag == .macos) {
            if (b.lazyDependency("mach_objc", .{
                .target = target,
                .optimize = optimize,
            })) |dep| {
                exe.root_module.addImport("objc", dep.module("mach-objc"));
            }
        }

        const compile_step = b.step("c", "compile azem");
        compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
        b.getInstallStep().dependOn(compile_step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(compile_step);

        const run_step = b.step("run", "run azem");
        run_step.dependOn(&run_cmd.step);
        b.default_step.dependOn(run_step);
    }

    // web target local development flow
    {
        const web_target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        });
        const custom_path = "web";
        const artifact_opts: std.Build.Step.InstallArtifact.Options = .{ .dest_dir = .{ .override = .{ .custom = custom_path } } };

        const dvui_dep = b.dependency("dvui", .{ .target = web_target, .optimize = optimize, .backend = .web });

        const web_app = b.addExecutable(.{
            .name = "azem",
            .root_source_file = root_source_file,
            .target = web_target,
            .optimize = optimize,
            .link_libc = false,
            .strip = if (optimize == .ReleaseFast or optimize == .ReleaseSmall) true else false,
        });

        web_app.entry = .disabled;
        web_app.root_module.addImport("dvui", dvui_dep.module("dvui_web"));

        const install_wasm = b.addInstallArtifact(web_app, artifact_opts);

        const compile_step = b.step("wc", "compile the web app");
        compile_step.dependOn(&install_wasm.step);
        compile_step.dependOn(&b.addInstallFileWithDir(b.path("public/index.html"), .prefix, custom_path ++ "/index.html").step);
        const web_js = dvui_dep.namedLazyPath("web.js");
        compile_step.dependOn(&b.addInstallFileWithDir(web_js, .prefix, custom_path ++ "/web.js").step);
        b.getInstallStep().dependOn(compile_step);

        const server_exe = b.addExecutable(.{
            .name = "http-server",
            .root_source_file = b.path("tools/http_server.zig"),
            .target = target,
            .optimize = optimize,
        });

        const install_server = b.addInstallArtifact(server_exe, artifact_opts);
        const serve_cmd = b.addRunArtifact(server_exe);
        serve_cmd.addArg("--port");
        serve_cmd.addArg("8000");
        serve_cmd.addArg("--dir");
        serve_cmd.addArg("zig-out/" ++ custom_path);
        serve_cmd.step.dependOn(compile_step);
        serve_cmd.step.dependOn(&install_server.step);

        const serve_step = b.step("ws", "serve the web-app");
        serve_step.dependOn(&serve_cmd.step);

        const launcher_exe = b.addExecutable(.{
            .name = "web-launcher",
            .root_source_file = b.path("tools/web_launcher.zig"),
            .target = target,
            .optimize = optimize,
        });

        const install_launcher = b.addInstallArtifact(launcher_exe, artifact_opts);

        const launch_cmd = b.addRunArtifact(launcher_exe);
        launch_cmd.addArg("--server");
        launch_cmd.addFileArg(server_exe.getEmittedBin());
        launch_cmd.addArg("--port");
        launch_cmd.addArg("8000");
        launch_cmd.addArg("--dir");
        launch_cmd.addArg("zig-out/" ++ custom_path);
        launch_cmd.step.dependOn(compile_step);
        launch_cmd.step.dependOn(&install_server.step);
        launch_cmd.step.dependOn(&install_launcher.step);

        const web_step = b.step("web", "compile, serve and open the web-app");
        web_step.dependOn(&launch_cmd.step);
    }

    // web target publish workflow
    {
        const web_target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        });

        const dvui_dep = b.dependency("dvui", .{ .target = web_target, .optimize = .ReleaseSmall, .backend = .web });

        const publish_app = b.addExecutable(.{
            .name = "azem",
            .root_source_file = root_source_file,
            .target = web_target,
            .optimize = .ReleaseSmall,
            .link_libc = false,
            .strip = true,
        });

        publish_app.entry = .disabled;
        publish_app.root_module.addImport("dvui", dvui_dep.module("dvui_web"));

        const install_publish_wasm = b.addInstallArtifact(publish_app, .{
            .dest_dir = .{ .override = .{ .custom = "../public" } },
        });

        const publish_web_js = dvui_dep.namedLazyPath("web.js");
        const install_publish_js = b.addInstallFileWithDir(publish_web_js, .prefix, "../public/web.js");

        const publish_step = b.step("wp", "create optimized build in docs/ directory");
        publish_step.dependOn(&install_publish_wasm.step);
        publish_step.dependOn(&install_publish_js.step);
    }
}
