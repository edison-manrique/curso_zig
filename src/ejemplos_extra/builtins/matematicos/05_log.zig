// =========================================================================================
// BUILTINS MATEMATICOS - LOGARITMOS (@log, @log2, @log10)
// =========================================================================================
// Funciones logaritmicas aceleradas por hardware FPU.
// @log(x) = ln(x) (logaritmo natural)
// @log2(x) = log base 2
// @log10(x) = log base 10
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Matematicos: Logaritmos (@log, @log2, @log10)\n\n", .{});
    
    // Logaritmo natural ln(e) = 1
    const e: f32 = 2.71828182;
    const log_natural = @log(e);
    try stdout.print("  log(e) = ln(e) = {d:.1}\n", .{log_natural});
    
    // Logaritmo base 2: log2(8) = 3
    const log_b2 = @log2(@as(f32, 8.0));
    try stdout.print("  log2(8.0) = {d:.1}\n", .{log_b2});
    
    // Logaritmo base 10: log10(100) = 2
    const log_b10 = @log10(@as(f32, 100.0));
    try stdout.print("  log10(100.0) = {d:.1}\n\n", .{log_b10});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
