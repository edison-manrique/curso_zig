// =========================================================================================
// BUILTINS MATEMATICOS - TRIGONOMETRIA (@sin, @cos, @tan)
// =========================================================================================
// Funciones trigonometricas aceleradas por hardware FPU.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Matematicos: Trigonometria (@sin, @cos, @tan)\n\n", .{});
    
    // pi/2 radianes (90 grados)
    const pi_medio: f32 = 1.57079632;
    
    const sen = @sin(pi_medio);
    const cos = @cos(pi_medio);
    try stdout.print("  sin(pi/2) = {d:.4}\n", .{sen});
    try stdout.print("  cos(pi/2) = {d:.4}\n", .{cos});
    
    // pi/4 radianes (45 grados) - tangente debe ser ~1.0
    const pi_cuarto: f32 = 0.78539816;
    const tan = @tan(pi_cuarto);
    try stdout.print("  tan(pi/4) = {d:.4}\n\n", .{tan});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
