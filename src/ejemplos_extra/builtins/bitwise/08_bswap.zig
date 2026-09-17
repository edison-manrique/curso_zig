// =========================================================================================
// BUILTINS BITWISE - BYTE SWAP (@byteSwap)
// =========================================================================================
// Cambia el orden de los bytes (endianness). Util para redes (TCP/IP).
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Bitwise: @byteSwap (Cambio de Endianness)\n\n", .{});
    
    // Valor en little-endian (x86)
    const valor: u32 = 0x12345678;
    try stdout.print("  Original: 0x{X}\n", .{valor});
    
    // Swap de bytes para big-endian (redes)
    const swapeado = @byteSwap(valor);
    try stdout.print("  ByteSwap: 0x{X}\n\n", .{swapeado});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
