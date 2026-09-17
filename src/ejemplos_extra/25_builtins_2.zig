// =========================================================================================
// MASTERCLASS: FUNCIONES BUILTIN (PARTE 2) - BITS, HARDWARE Y CONTROL (ZIG 0.16.0)
// =========================================================================================
//
// Esta guia cubre 8 builtins fundamentales para la programacion de bajo nivel extrema:
//
// CONTENIDO DE LA MASTERCLASS:
// 1. Magia de Bits: @bitCast (Transmutacion de tipos sin penalizacion).
// 2. Anatomia de Memoria: @bitSizeOf y @bitOffsetOf (Estructuras empaquetadas).
// 3. Endianness y Patrones: @byteSwap y @bitReverse (Redes y Criptografia).
// 4. Hardware Acelerado FPU: @mulAdd (Fused Multiply-Add).
// 5. Control del Optimizador y Depuracion: @branchHint y @breakpoint.
//
// Todo el codigo esta en ASCII 7-bit (cero acentos) para compatibilidad universal.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");

// =========================================================================================
// ZIG 0.16.0 "JUICY MAIN" - ENTRY POINT
// =========================================================================================
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Buffer de 16KB para salida rapida a consola
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);

    try modulo1_TransmutacionDeTipos(stdout);
    try modulo2_AnatomiaDeMemoria(stdout);
    try modulo3_EndiannessYPatrones(stdout);
    try modulo4_MatematicasFPU(stdout);
    try modulo5_OptimizadorYDebug(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: TRANSMUTACION DE TIPOS (@bitCast)
// =========================================================================================
fn modulo1_TransmutacionDeTipos(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: @bitCast (Transmutacion a nivel de Bits)\n", .{});

    // @bitCast toma los bits exactos de una variable y los reinterpreta como otro tipo.
    // REGLA DE ORO: Ambos tipos deben tener EXACTAMENTE el mismo tamano (@sizeOf).
    // Nota: El tipo de destino se infiere por la variable que recibe el valor.

    const flotante: f32 = -15.5; // Un float en IEEE 754

    // Leemos la representacion binaria cruda del float como si fuera un entero (u32)
    const representacion_cruda: u32 = @bitCast(flotante);

    // Y podemos volver a transformarlo sin perder precision
    const flotante_recuperado: f32 = @bitCast(representacion_cruda);

    try stdout.print("  Valor f32 original: {d:.1}\n", .{flotante});
    try stdout.print("  Bits crudos (u32 hex): 0x{X}\n", .{representacion_cruda});
    try stdout.print("  f32 recuperado desde u32: {d:.1}\n\n", .{flotante_recuperado});

    // IMPORTANTE: @bitCast esta prohibido para punteros. Para punteros se usa @ptrCast.
}

// =========================================================================================
// MODULO 2: ANATOMIA DE MEMORIA Y PACKED STRUCTS (@bitSizeOf, @bitOffsetOf)
// =========================================================================================
// Declaramos un "packed struct" donde el control de memoria es absoluto (a nivel de bit)
const CabeceraRed = packed struct(u8) {
    version: u4, // Ocupa 4 bits (Offsets 0, 1, 2, 3)
    bandera: u1, // Ocupa 1 bit  (Offset 4)
    reserva: u3, // Ocupa 3 bits (Offsets 5, 6, 7)
};

fn modulo2_AnatomiaDeMemoria(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: @bitSizeOf y @bitOffsetOf\n", .{});

    // @sizeOf(T) devuelve bytes. @bitSizeOf(T) devuelve BITS.
    const bits_u4 = @bitSizeOf(u4);
    const bits_struct = @bitSizeOf(CabeceraRed);

    // @bitOffsetOf(Tipo, "campo") te dice en que bit exacto comienza un campo dentro
    // de su estructura. Vital para programar drivers o protocolos binarios.
    const offset_version = @bitOffsetOf(CabeceraRed, "version");
    const offset_bandera = @bitOffsetOf(CabeceraRed, "bandera");
    const offset_reserva = @bitOffsetOf(CabeceraRed, "reserva");

    try stdout.print("  Tamano de u4: {d} bits\n", .{bits_u4});
    try stdout.print("  Tamano total CabeceraRed: {d} bits ({d} byte)\n", .{ bits_struct, @sizeOf(CabeceraRed) });
    try stdout.print("  Offset del campo 'version': bit {d}\n", .{offset_version});
    try stdout.print("  Offset del campo 'bandera': bit {d}\n", .{offset_bandera});
    try stdout.print("  Offset del campo 'reserva': bit {d}\n\n", .{offset_reserva});
}

// =========================================================================================
// MODULO 3: ENDIANNESS Y CRIPTOGRAFIA (@byteSwap, @bitReverse)
// =========================================================================================
fn modulo3_EndiannessYPatrones(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: @byteSwap y @bitReverse\n", .{});

    // 1. @byteSwap: Cambia el Endianness (orden de los BYTES).
    // Ejemplo: Convertir de Little Endian (x86) a Big Endian (Redes TCP/IP).
    const ip_cruda: u32 = 0x12345678;
    const ip_swapeada = @byteSwap(ip_cruda);

    try stdout.print("  Original (u32):   0x{X}\n", .{ip_cruda});
    try stdout.print("  ByteSwap (u32):   0x{X}\n", .{ip_swapeada}); // Deberia ser 0x78563412

    // 2. @bitReverse: Invierte el patron binario a nivel de BITS individuales.
    // Muy utilizado en algoritmos de criptografia, FFT o generacion de CRC.
    const patron: u8 = 0b10110110; // Decimal: 182
    const patron_reverso = @bitReverse(patron); // Deberia ser 0b01101101 (Decimal: 109)

    try stdout.print("  Original (u8):    0b{b} (Decimal: {d})\n", .{ patron, patron });
    try stdout.print("  BitReverse (u8):  0b0{b} (Decimal: {d})\n\n", .{ patron_reverso, patron_reverso });
}

// =========================================================================================
// MODULO 4: MATEMATICAS POR HARDWARE FPU (@mulAdd)
// =========================================================================================
fn modulo4_MatematicasFPU(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Fused Multiply-Add (@mulAdd)\n", .{});

    // @mulAdd implementa FMA: (A * B) + C
    // Por que usar @mulAdd en lugar de escribir `a * b + c`?
    // 1. Es mas rapido (usa una sola instruccion de CPU dedicada si esta disponible).
    // 2. Es mas preciso (hace un solo redondeo al final, en lugar de redondear la
    //    multiplicacion y luego volver a redondear la suma).

    const a: f32 = 2.0;
    const b: f32 = 3.0;
    const c: f32 = 4.0;

    const resultado = @mulAdd(f32, a, b, c);

    try stdout.print("  Operacion: ({d:.1} * {d:.1}) + {d:.1}\n", .{ a, b, c });
    try stdout.print("  Resultado usando FMA (@mulAdd): {d:.1}\n\n", .{resultado});
}

// =========================================================================================
// MODULO 5: OPTIMIZADOR Y DEPURACION (@branchHint, @breakpoint)
// =========================================================================================
fn modulo5_OptimizadorYDebug(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Hints del Optimizador y Debugging\n", .{});

    // 1. @branchHint: Le susurra al compilador (LLVM) que camino de un 'if' o 'switch'
    // es mas probable que ocurra. Esto optimiza el 'branch prediction' de la CPU.
    // Solo puede ser la PRIMERA sentencia dentro de un bloque.

    const simulacion_error_critico = false;

    if (simulacion_error_critico) {
        // Le decimos a la CPU: "Oye, casi NUNCA entraremos aqui, optimiza el 'else'".
        @branchHint(.unlikely);
        try stdout.print("    [Error] Entramos al camino lento.\n", .{});
    } else {
        @branchHint(.likely);
        try stdout.print("  [Branch Hint] Camino feliz optimizado.\n", .{});
    }

    // 2. @breakpoint(): Inserta una trampa (Trap) de hardware 'int3' especifica
    // para debuggers (como GDB o LLDB).
    // Si ejecutas el codigo sin un debugger acoplado, el SO cerrara el programa (Crash).
    // Por ende, lo mantenemos comentado en la guia de produccion.

    // @breakpoint();

    try stdout.print("  [@breakpoint] Instruccion de parada de GDB/LLDB (comentada por seguridad).\n", .{});
    try stdout.print("  NOTA: A diferencia de @trap(), @breakpoint permite continuar la ejecucion.\n\n", .{});
}

// =========================================================================================
// UTILIDADES DE IMPRESION
// =========================================================================================
fn imprimirCabecera(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\     ___ _   _ ___ _  _____ ___ _  _ ___ 
        \\    | _ ) | | |_ _| |__   _|_ _| \| / __|
        \\    | _ \ |_| || || |__| |  | || .` \__ \
        \\    |___/\___/|___|____|_| |___|_|\_|___/
        \\                                                            
        \\    MASTERCLASS 9: BITS Y HARDWARE BUILTINS (ZIG 0.16.0)
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\ FIN DE LA MASTERCLASS.
        \\====================================================================
        \\ RESUMEN:
        \\ - @bitCast reinterpreta la memoria asumiendo el mismo tamano exacto.
        \\ - @bitSizeOf y @bitOffsetOf son reyes trabajando con Packed Structs.
        \\ - @byteSwap arregla problemas de Endianness al leer datos de red.
        \\ - @mulAdd usa instrucciones especiales de procesador (FMA) mas precisas.
        \\ - @branchHint exprime ciclos extra ayudando al predictor de saltos.
        \\====================================================================
        \\
    , .{});
}
