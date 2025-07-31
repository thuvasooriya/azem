const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/azem.zig");

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

        const compile_step = b.step("azem", "compile azem");
        compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
        b.getInstallStep().dependOn(compile_step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(compile_step);

        const run_step = b.step("run-azem", "run azem");
        run_step.dependOn(&run_cmd.step);
        b.default_step.dependOn(run_step);
    }

    {
        const web_target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        });

        const dvui_dep = b.dependency("dvui", .{ .target = web_target, .optimize = optimize, .backend = .web });

        const web_app = b.addExecutable(.{
            .name = "web",
            .root_source_file = root_source_file,
            .target = web_target,
            .optimize = optimize,
            .link_libc = false,
            .strip = if (optimize == .ReleaseFast or optimize == .ReleaseSmall) true else false,
        });

        web_app.entry = .disabled;
        web_app.root_module.addImport("dvui", dvui_dep.module("dvui_web"));

        const install_wasm = b.addInstallArtifact(web_app, .{
            .dest_dir = .{ .override = .{ .custom = "bin" } },
        });

        // const install_noto = b.addInstallBinFile(b.path("NotoSansKR-Regular.ttf"), "NotoSansKR-Regular.ttf");
        // compile_step.dependOn(&install_noto.step);

        const compile_step = b.step("compile-web", "compile the web app");
        compile_step.dependOn(&install_wasm.step);
        compile_step.dependOn(&b.addInstallFileWithDir(b.path("assets/index.html"), .prefix, "bin/index.html").step);
        const web_js = dvui_dep.namedLazyPath("web.js");
        compile_step.dependOn(&b.addInstallFileWithDir(web_js, .prefix, "bin/web.js").step);
        b.getInstallStep().dependOn(compile_step);

        // TODO: find some other cross-platform way to do this
        const serve_cmd = b.addSystemCommand(&[_][]const u8{ "just", "serve" });
        serve_cmd.step.dependOn(compile_step);
        const serve_step = b.step("serve-web", "serve the web-app");
        serve_step.dependOn(&serve_cmd.step);
        const open_cmd = b.addSystemCommand(&[_][]const u8{ "open", "http://localhost:8000" });
        const open_step = b.step("web", "open the localhost");
        open_step.dependOn(&open_cmd.step);
        open_cmd.step.dependOn(serve_step);
    }
}
