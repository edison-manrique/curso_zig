// =========================================================================================
// BUILTINS MATEMATICOS - MINIMO Y MAXIMO (@min, @max)
// =========================================================================================
// Encuentra el valor minimo o maximo entre multiples valores.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Matematicos: Min/Max (@min, @max)\n\n", .{});
    
    // Encontrar el minimo entre varios valores
    const minimo = @min(15, -42, 999, 0, 7);
    try stdout.print("  @min(15, -42, 999, 0, 7) = {d}\n", .{minimo});
    
    // Encontrar el maximo entre varios valores
    const maximo = @max(10, 50, 5, 100, 2);
    try stdout.print("  @max(10, 50, 5, 100, 2) = {d}\n\n", .{maximo});
    
    // Tambien funciona con flotantes
    const min_float = @min(@as(f32, 3.14), @as(f32, 2.71), @as(f32, 1.41));
    try stdout.print("  @min(3.14, 2.71, 1.41) = {d:.2}\n\n", .{min_float});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
