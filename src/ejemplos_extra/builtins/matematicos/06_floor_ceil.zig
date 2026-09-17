// =========================================================================================
// BUILTINS MATEMATICOS - REDONDEO (@floor, @ceil, @trunc, @round)
// =========================================================================================
// Diferentes modos de redondeo de numeros flotantes a enteros.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Matematicos: Redondeo (@floor, @ceil, @trunc, @round)\n\n", .{});
    
    const valor_positivo: f32 = 1.6;
    const valor_negativo: f32 = -1.6;
    
    // @floor: redondea hacia abajo (hacia -infinito)
    try stdout.print("  @floor(1.6) = {d:.1}\n", .{@floor(valor_positivo)});
    try stdout.print("  @floor(-1.6) = {d:.1}\n", .{@floor(valor_negativo)});
    
    // @ceil: redondea hacia arriba (hacia +infinito)
    try stdout.print("  @ceil(1.6) = {d:.1}\n", .{@ceil(valor_positivo)});
    try stdout.print("  @ceil(-1.6) = {d:.1}\n", .{@ceil(valor_negativo)});
    
    // @trunc: trunca decimales (hacia cero)
    try stdout.print("  @trunc(1.6) = {d:.1}\n", .{@trunc(valor_positivo)});
    try stdout.print("  @trunc(-1.6) = {d:.1}\n", .{@trunc(valor_negativo)});
    
    // @round: redondea al entero mas cercano (.5 se aleja de cero)
    try stdout.print("  @round(1.4) = {d:.1}\n", .{@round(@as(f32, 1.4))});
    try stdout.print("  @round(1.5) = {d:.1}\n", .{@round(@as(f32, 1.5))});
    try stdout.print("  @round(-2.5) = {d:.1}\n\n", .{@round(@as(f32, -2.5))});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
