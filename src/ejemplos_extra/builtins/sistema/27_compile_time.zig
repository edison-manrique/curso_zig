// =========================================================================================
// BUILTINS SISTEMA - COMPILE TIME (@compileError, @compileLog)
// =========================================================================================
// Herramientas de depuracion y control en tiempo de compilacion.
// Nota: @inComptime fue removido en Zig 0.16.0 por ser redundante
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Sistema: Tiempo de Compilacion\n\n", .{});
    
    // En Zig 0.16.0, @inComptime fue removido porque es redundante
    // Todo codigo dentro de un bloque 'comptime' ya esta en tiempo de compilacion
    try stdout.print("  @inComptime: removido en Zig 0.16.0 (redundante)\n", .{});
    try stdout.print("  Use bloques 'comptime {{ }}' para ejecutar codigo en compilacion\n\n", .{});
    
    // Ejemplo de bloque comptime
    comptime {
        const valor = 42;
        _ = valor; // Usamos la variable para evitar warnings
    }
    
    // @compileError y @compileLog estan comentados para permitir compilacion
    // comptime {
    //     @compileError("Error forzado");
    //     @compileLog("Log de compilacion");
    // }
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
