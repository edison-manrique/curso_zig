// =========================================================================================
// BUILTINS BITWISE - POPCOUNT (@popCount)
// =========================================================================================
// Cuenta cuantos bits estan encendidos (en '1'). Tambien llamado Hamming Weight.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Bitwise: @popCount (Conteo de Bits Activos)\n\n", .{});
    
    // 0b10110110 tiene 5 bits en '1'
    const patron: u8 = 0b10110110;
    const conteo = @popCount(patron);
    
    try stdout.print("  Patron: 0b{b}\n", .{patron});
    try stdout.print("  Bits activos: {d}\n\n", .{conteo});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
