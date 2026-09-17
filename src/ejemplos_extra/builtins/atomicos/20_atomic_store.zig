// =========================================================================================
// BUILTINS ATOMICOS - ATOMIC STORE (@atomicStore)
// =========================================================================================
// Escribe un valor en memoria de forma atomica (segura entre hilos).
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Atomicos: @atomicStore (Almacenamiento Atomico)\n\n", .{});
    
    var variable: u32 = 0;
    
    // Escritura atomica con orden .monotonic
    @atomicStore(u32, &variable, 42, .monotonic);
    try stdout.print("  Valor escrito atomicamente: {d}\n\n", .{variable});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
