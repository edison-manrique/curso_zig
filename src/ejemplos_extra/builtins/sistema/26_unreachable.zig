// =========================================================================================
// BUILTINS SISTEMA - UNREACHABLE (@unreachable)
// =========================================================================================
// Indica al compilador que un codigo nunca sera alcanzado.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Sistema: @unreachable\n\n", .{});
    
    const valor: u32 = 1;
    
    if (valor == 1) {
        try stdout.print("  Caso normal ejecutado\n", .{});
    } else {
        // El compilador asume que esto nunca pasa
        unreachable;
    }
    
    try stdout.print("  @unreachable ayuda al optimizador\n\n", .{});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
