// =========================================================================================
// BUILTINS MEMORIA - MEMSET (@memset)
// =========================================================================================
// Llena una region de memoria con un byte repetido.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Memoria: @memset (Llenado de Memoria)\n\n", .{});
    
    var buffer_destino = [_]u8{0} ** 8;
    @memset(&buffer_destino, 42); // 42 = caracter '*'
    
    try stdout.print("  Buffer llenado: {s}\n\n", .{buffer_destino});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
