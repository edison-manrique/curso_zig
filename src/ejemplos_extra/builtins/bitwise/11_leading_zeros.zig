// =========================================================================================
// BUILTINS BITWISE - LEADING ZEROS (@clz)
// =========================================================================================
// Cuenta ceros a la izquierda del primer bit '1'. Util en tablas hash y radix trees.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Bitwise: @clz (Ceros a la Izquierda)\n\n", .{});
    
    // 12 = 0b00001100 en u8 (tiene 4 ceros a la izquierda)
    const numero: u8 = 12;
    const ceros = @clz(numero);
    
    try stdout.print("  Numero: {d} (0b{b:0>8})\n", .{ numero, numero });
    try stdout.print("  Ceros a la izquierda: {d}\n\n", .{ceros});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
