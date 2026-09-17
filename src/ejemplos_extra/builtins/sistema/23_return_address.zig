// =========================================================================================
// BUILTINS SISTEMA - RETURN ADDRESS (@returnAddress, @frameAddress)
// =========================================================================================
// Obtiene direcciones de ejecucion para debugging y introspeccion.
// =========================================================================================

const std = @import("std");

fn obtenerRetorno() usize {
    return @returnAddress();
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Sistema: @returnAddress y @frameAddress\n\n", .{});
    
    const addr_retorno = obtenerRetorno();
    const addr_frame = @frameAddress();
    
    try stdout.print("  Direccion de retorno: 0x{X}\n", .{addr_retorno});
    try stdout.print("  Direccion del frame: 0x{X}\n\n", .{addr_frame});
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
