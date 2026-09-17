// =========================================================================================
// BUILTINS MEMORIA - MEMCMP (Comparacion de Memoria)
// =========================================================================================
// Compara dos regiones de memoria byte por byte.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Memoria: Comparacion de Memoria\n\n", .{});
    
    const a = [_]u8{ 1, 2, 3, 4 };
    const b = [_]u8{ 1, 2, 3, 4 };
    const c = [_]u8{ 1, 2, 3, 5 };
    
    const igual = std.mem.eql(u8, &a, &b);
    const diferente = std.mem.eql(u8, &a, &c);
    
    try stdout.print("  a == b: {s}\n", .{if (igual) "IGUALES" else "DIFERENTES"});
    try stdout.print("  a == c: {s}\n\n", .{if (diferente) "IGUALES" else "DIFERENTES"});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
