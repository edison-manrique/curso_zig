// =========================================================================================
// BUILTINS ATOMICOS - ATOMIC LOAD (@atomicLoad)
// =========================================================================================
// Lee un valor de memoria de forma atomica (segura entre hilos).
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Atomicos: @atomicLoad (Carga Atomica)\n\n", .{});
    
    var variable: u32 = 100;
    
    // Lectura atomica con orden .acquire
    const lectura = @atomicLoad(u32, &variable, .acquire);
    try stdout.print("  Valor leido atomicamente: {d}\n\n", .{lectura});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
