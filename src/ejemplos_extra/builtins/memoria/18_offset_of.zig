// =========================================================================================
// BUILTINS MEMORIA - OFFSET OF (@offsetOf, @bitOffsetOf)
// =========================================================================================
// Devuelve el offset en bytes/bits de un campo dentro de un struct.
// =========================================================================================

const std = @import("std");

const MiStruct = struct {
    campo1: u8,
    campo2: u32,
    campo3: u16,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Memoria: @offsetOf y @bitOffsetOf\n\n", .{});
    
    try stdout.print("  Offset de campo1: {d} bytes\n", .{@offsetOf(MiStruct, "campo1")});
    try stdout.print("  Offset de campo2: {d} bytes\n", .{@offsetOf(MiStruct, "campo2")});
    try stdout.print("  Offset de campo3: {d} bytes\n\n", .{@offsetOf(MiStruct, "campo3")});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
