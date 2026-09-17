// =========================================================================================
// BUILTINS SISTEMA - TRAP (@trap, @panic)
// =========================================================================================
// Instrucciones de trampa de hardware y manejo de panicos.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Sistema: @trap y @panic\n\n", .{});
    
    try stdout.print("  @trap: instruccion de parada irreversible (protegida)\n", .{});
    try stdout.print("  @panic: manejador de fallos con stack trace (protegido)\n\n", .{});
    
    // Protegidos para no abortar la ejecucion
    if (false) {
        @trap();
        @panic("Error critico");
    }
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
