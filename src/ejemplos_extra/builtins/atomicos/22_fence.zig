// =========================================================================================
// BUILTINS ATOMICOS - FENCE (@fence)
// =========================================================================================
// Barrera de memoria para ordenar operaciones atomicas.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Atomicos: @fence (Barrera de Memoria)\n\n", .{});
    
    var dato: u32 = 0;
    
    // Barrera acquire antes de leer
    @fence(.acquire);
    const valor = dato;
    
    // Barrera release despues de escribir
    dato = 42;
    @fence(.release);
    
    try stdout.print("  Barreras aplicadas correctamente. Valor={d}\n\n", .{valor});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
