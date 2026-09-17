// =========================================================================================
// BUILTINS MATEMATICOS - RAIZ CUADRADA (@sqrt)
// =========================================================================================
// @sqrt calcula la raiz cuadrada de un numero flotante usando instrucciones FPU.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Matematicos: @sqrt (Raiz Cuadrada)\n\n", .{});
    
    // Raiz cuadrada de diferentes valores
    const valor1: f32 = 16.0;
    const raiz1 = @sqrt(valor1);
    try stdout.print("  sqrt(16.0) = {d:.1}\n", .{raiz1});
    
    const valor2: f32 = 2.0;
    const raiz2 = @sqrt(valor2);
    try stdout.print("  sqrt(2.0) = {d:.6}\n", .{raiz2});
    
    const valor3: f64 = 81.0;
    const raiz3 = @sqrt(valor3);
    try stdout.print("  sqrt(81.0) = {d:.1}\n", .{raiz3});
    
    try stdout.print("\n>>> Ejecucion completada exitosamente!\n", .{});
}
