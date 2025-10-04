# AGENTS.md

This Zig maze visualization application uses the DVUI UI framework with multiple build targets.

## Build Commands

- `zig build run` or `zig build` - Build and run native application (default)
- `zig build c` - Compile native executable only
- `zig build web` - Build web version and open in browser
- `zig build wc` - Compile web version only
- `zig build ws` - Serve web version on localhost:8000
- `zig build wp` - Create optimized build for publishing

No test suite is present in this codebase.

## Code Style

- Use PascalCase for types, and functions returning types
- Use camelCase for variables and private functions
- Use snake_case for file names and struct fields
- Import std first, then external dependencies, then local modules
- Use `const Self = @This();` pattern for struct methods
- Prefer `try` over `catch` for error handling
- Use explicit return types for public functions
- Global pointers prefixed with module abbreviation (eng, app, thm)
- Constants use SCREAMING_SNAKE_CASE sparingly
- Prefer `defer` for cleanup operations
- Use snake_case for most comments and documentation

