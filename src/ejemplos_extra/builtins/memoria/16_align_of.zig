// =========================================================================================
// BUILTINS MEMORIA - ALIGN OF (@alignOf)
// =========================================================================================
// Devuelve el alineamiento requerido en bytes para un tipo.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Memoria: @alignOf (Alineamiento)\n\n", .{});
    
    try stdout.print("  alignOf(u8): {d} bytes\n", .{@alignOf(u8)});
    try stdout.print("  alignOf(u16): {d} bytes\n", .{@alignOf(u16)});
    try stdout.print("  alignOf(u32): {d} bytes\n", .{@alignOf(u32)});
    try stdout.print("  alignOf(f64): {d} bytes\n\n", .{@alignOf(f64)});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
