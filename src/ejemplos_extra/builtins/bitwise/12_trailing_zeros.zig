// =========================================================================================
// BUILTINS BITWISE - TRAILING ZEROS (@ctz)
// =========================================================================================
// Cuenta ceros a la derecha del primer bit '1'. Util en alineamiento y arboles.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Bitwise: @ctz (Ceros a la Derecha)\n\n", .{});
    
    // 12 = 0b00001100 en u8 (tiene 2 ceros a la derecha)
    const numero: u8 = 12;
    const ceros = @ctz(numero);
    
    try stdout.print("  Numero: {d} (0b{b:0>8})\n", .{ numero, numero });
    try stdout.print("  Ceros a la derecha: {d}\n\n", .{ceros});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
