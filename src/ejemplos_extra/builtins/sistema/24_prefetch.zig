// =========================================================================================
// BUILTINS SISTEMA - PREFETCH (@prefetch)
// =========================================================================================
// Sugiere a la CPU precargar datos en cache L1/L2/L3.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Sistema: @prefetch (Precarga de Cache)\n\n", .{});
    
    var dato: u32 = 42;
    
    // Sugerir precarga en cache L1 para lectura
    const opciones = std.builtin.PrefetchOptions{
        .rw = .read,
        .locality = 3,
        .cache = .data,
    };
    @prefetch(&dato, opciones);
    
    try stdout.print("  Prefetch emitido para dato: {d}\n\n", .{dato});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
