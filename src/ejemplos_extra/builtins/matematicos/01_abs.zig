// =========================================================================================
// BUILTINS MATEMATICOS - VALOR ABSOLUTO (@abs)
// =========================================================================================
// @abs devuelve el valor absoluto de un numero.
// Para enteros firmados, devuelve un tipo sin firma para evitar overflow.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Matematicos: @abs (Valor Absoluto)\n\n", .{});
    
    // Valor absoluto de entero firmado
    const entero_negativo: i32 = -12345;
    const abs_entero: u32 = @abs(entero_negativo);
    try stdout.print("  @abs de i32 (-12345): {d} (Tipo: {any})\n", .{ abs_entero, @TypeOf(abs_entero) });
    
    // Valor absoluto de flotante
    const flotante_negativo: f32 = -3.1415;
    const abs_flotante = @abs(flotante_negativo);
    try stdout.print("  @abs de f32 (-3.1415): {d:.4}\n", .{abs_flotante});
    
    // Valor absoluto de positivo (sin cambios)
    const positivo: i32 = 42;
    const abs_positivo = @abs(positivo);
    try stdout.print("  @abs de i32 (42): {d}\n\n", .{abs_positivo});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
