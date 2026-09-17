// =========================================================================================
// BUILTINS MATEMATICOS - POTENCIAS (@exp, @exp2)
// =========================================================================================
// Funciones exponenciales aceleradas por hardware FPU.
// @exp(x) = e^x (numero de Euler)
// @exp2(x) = 2^x
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Matematicos: Potencias (@exp, @exp2)\n\n", .{});
    
    // Exponencial natural e^1
    const exp_natural = @exp(@as(f32, 1.0));
    try stdout.print("  exp(1.0) = e^1 = {d:.4} (Numero de Euler)\n", .{exp_natural});
    
    // Potencia de base 2: 2^3 = 8
    const exp_base2 = @exp2(@as(f32, 3.0));
    try stdout.print("  exp2(3.0) = 2^3 = {d:.1}\n", .{exp_base2});
    
    // Potencia de base 2: 2^10 = 1024
    const exp_base2_10 = @exp2(@as(f32, 10.0));
    try stdout.print("  exp2(10.0) = 2^10 = {d:.1}\n\n", .{exp_base2_10});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
