// =========================================================================================
// BUILTINS ATOMICOS - ATOMIC RMW (@atomicRmw, @cmpxchgStrong)
// =========================================================================================
// Operaciones atomicas Read-Modify-Write y Compare-And-Swap.
// =========================================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    
    defer stdout.flush() catch {};
    
    try stdout.print(">>> Builtins Atomicos: @atomicRmw y @cmpxchgStrong\n\n", .{});
    
    var contador: u32 = 100;
    
    // AtomicRmw: suma 50 de forma atomica
    const viejo = @atomicRmw(u32, &contador, .Add, 50, .seq_cst);
    try stdout.print("  @atomicRmw(.Add): valor viejo={d}, nuevo={d}\n", .{ viejo, contador });
    
    // Compare-And-Swap
    var estado: u32 = 0;
    const resultado = @cmpxchgStrong(u32, &estado, 0, 1, .seq_cst, .seq_cst);
    try stdout.print("  @cmpxchgStrong: exito={s}, estado actual={d}\n\n", .{ if (resultado == null) "SI" else "NO", estado });
    
    try stdout.print(">>> Ejecucion completada exitosamente!\n", .{});
}
