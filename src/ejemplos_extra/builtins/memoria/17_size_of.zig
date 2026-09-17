// =========================================================================================
// BUILTINS MEMORIA - SIZE OF (@sizeOf)
// =========================================================================================
// Devuelve el tamano en bytes necesario para almacenar un tipo.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Memoria: @sizeOf (Tamaño de Tipos)\n\n", .{});
    
    try stdout.print("  sizeOf(u8): {d} bytes\n", .{@sizeOf(u8)});
    try stdout.print("  sizeOf(u16): {d} bytes\n", .{@sizeOf(u16)});
    try stdout.print("  sizeOf(u32): {d} bytes\n", .{@sizeOf(u32)});
    try stdout.print("  sizeOf(u64): {d} bytes\n", .{@sizeOf(u64)});
    try stdout.print("  sizeOf(f32): {d} bytes\n\n", .{@sizeOf(f32)});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
