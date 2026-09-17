// =========================================================================================
// BUILTINS MEMORIA - MEMCPY (@memcpy)
// =========================================================================================
// Copia bytes de una region a otra. Las regiones NO deben solaparse.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Memoria: @memcpy (Copia de Memoria)\n\n", .{});
    
    const origen = [_]u8{ 'Z', 'I', 'G', '-', '0', '.', '1', '6' };
    var destino: [8]u8 = undefined;
    
    @memcpy(&destino, &origen);
    try stdout.print("  Copiado: {s}\n\n", .{destino});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
