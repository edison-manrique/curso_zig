// =========================================================================================
// BUILTINS BITWISE - BIT REVERSE (@bitReverse)
// =========================================================================================
// Invierte el patron de bits a nivel individual. Util en criptografia y FFT.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Bitwise: @bitReverse (Inversion de Bits)\n\n", .{});
    
    // Patron binario: 0b10110110 = 182 decimal
    const patron: u8 = 0b10110110;
    try stdout.print("  Original:   0b{b} ({d})\n", .{ patron, patron });
    
    // Inversion de bits: 0b01101101 = 109 decimal
    const reverso = @bitReverse(patron);
    try stdout.print("  Revertido:  0b{b} ({d})\n\n", .{ reverso, reverso });
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
