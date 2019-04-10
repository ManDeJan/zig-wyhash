const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("wyhash", "src/main.zig");
    lib.setBuildMode(mode);

    var tests = b.addTest("test/test.zig");
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);

    b.default_step.dependOn(&lib.step);
    b.installArtifact(lib);
}
