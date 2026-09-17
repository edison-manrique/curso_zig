// =========================================================================================
// BUILTINS SISTEMA - COMPILE TIME (@compileError, @compileLog, @inComptime)
// =========================================================================================
// Herramientas de depuracion y control en tiempo de compilacion.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Sistema: Tiempo de Compilacion\n\n", .{});
    
    // @inComptime: verifica si se esta en tiempo de compilacion
    const es_comptime = comptime @inComptime();
    try stdout.print("  @inComptime en bloque comptime: {s}\n", .{if (es_comptime) "SI" else "NO"});
    
    const es_runtime = @inComptime();
    try stdout.print("  @inComptime en runtime: {s}\n\n", .{if (es_runtime) "SI" else "NO"});
    
    // @compileError y @compileLog estan comentados para permitir compilacion
    // comptime {
    //     @compileError("Error forzado");
    //     @compileLog("Log de compilacion");
    // }
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
