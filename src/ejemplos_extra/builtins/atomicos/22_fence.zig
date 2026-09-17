// =========================================================================================
// BUILTINS ATOMICOS - FENCE (Barreras de Memoria)
// =========================================================================================
// Barrera de memoria para ordenar operaciones atomicas.
// En Zig 0.16.0, no existe std.atomic.fence ni @fence directamente.
// Se usa @atomicRmw con operacion Noop para simular el efecto de fence.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Atomicos: Barreras de Memoria (simuladas)\n\n", .{});
    
    var dato: u32 = 0;
    
    // En Zig 0.16.0, usamos @atomicRmw con operacion Noop para simular fence acquire
    _ = @atomicRmw(u32, &dato, .Add, 0, .acquire);
    const valor = dato;
    
    // Barrera release usando atomicRmw con operacion Noop
    dato = 42;
    _ = @atomicRmw(u32, &dato, .Add, 0, .release);
    
    try stdout.print("  Barreras aplicadas correctamente via atomicRmw. Valor={d}\n\n", .{valor});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
