// =========================================================================================
// MASTERCLASS: FUNCIONES BUILTIN FUNDAMENTALES EN ZIG (EDICION ZIG 0.16.0)
// =========================================================================================
//
// Las funciones "Builtin" (precedidas por @) son proveidas directamente por el
// compilador de Zig. No son funciones de libreria; son instrucciones que el
// compilador entiende magicamente para generar codigo maquina hiper-optimizado.
//
// CONTENIDO DE LA MASTERCLASS (8 Builtins):
// 1. Tipos Seguros: @as (Coercion de tipos).
// 2. Matematicas Seguras: @addWithOverflow (Evitar crashes por desbordamiento).
// 3. Control de Alineacion: @alignOf y @alignCast (Arquitectura y Memoria).
// 4. Hardware Especifico: @addrSpaceCast (GPU y Microcontroladores).
// 5. Concurrencia Lock-Free: @atomicLoad, @atomicStore, y @atomicRmw.
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

    // Buffer de 16KB para soportar toda la impresion de la Masterclass
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);

    try modulo1_CoercionSegura(stdout);
    try modulo2_MatematicasSeguras(stdout);
    try modulo3_AlineacionYMemoria(stdout);
    try modulo4_ConcurrenciaAtomica(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: TIPOS SEGUROS (@as)
// =========================================================================================
fn modulo1_CoercionSegura(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: @as (Coercion Segura)\n", .{});

    // @as(Tipo, valor) fuerza la conversion de un tipo a otro, PERO SOLO SI ES SEGURA.
    // Es decir, si no hay perdida de datos. Si la conversion es insegura, no compilara.

    const numero_pequeno: u8 = 250;

    // Coercion valida: Todo u8 cabe perfectamente en un u32
    const numero_grande = @as(u32, numero_pequeno);

    // En Zig, @as se usa mucho para inicializar literales sin tener que declarar
    // variables explicitas:
    const suma = @as(f32, 10.5) + @as(f32, 2.0);

    try stdout.print("  [OK] Coercion de u8 (250) a u32 exitosa: {d}\n", .{numero_grande});
    try stdout.print("  [OK] Literales anonimos con @as: 10.5 + 2.0 = {d:.1}\n\n", .{suma});
}

// =========================================================================================
// MODULO 2: MATEMATICAS SEGURAS (@addWithOverflow)
// =========================================================================================
fn modulo2_MatematicasSeguras(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: @addWithOverflow (Evitar Crashes)\n", .{});

    // En Zig, si sumas 250 + 10 en un tipo u8 (max 255), el programa hara "Panic"
    // y crasheara por seguridad. Para controlar esto manualmente, usamos @addWithOverflow.

    const a: u8 = 250;
    const b: u8 = 10;

    // Retorna una tupla: { resultado_truncado, bit_de_desbordamiento }
    // El bit es un u1 (1 si desbordo, 0 si fue exitoso).
    const tupla = @addWithOverflow(a, b);

    const valor = tupla[0];
    const hubo_overflow = tupla[1] == 1;

    try stdout.print("  Suma: {d} + {d} (en un tipo u8, limite 255)\n", .{ a, b });
    try stdout.print("  Resultado truncado: {d}\n", .{valor});
    try stdout.print("  Hubo Desbordamiento (Overflow)? {s}\n\n", .{if (hubo_overflow) "SI" else "NO"});
}

// =========================================================================================
// MODULO 3: ALINEACION, MEMORIA Y HARDWARE (@alignOf, @alignCast, @addrSpaceCast)
// =========================================================================================
fn modulo3_AlineacionYMemoria(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Alineacion y Espacios de Direcciones\n", .{});

    // 1. @alignOf(Tipo): Nos dice en que multiplo de bytes debe estar alojado un
    // tipo en RAM para que la CPU lo procese eficientemente.
    const alineacion_u32 = @alignOf(u32);
    try stdout.print("  Un 'u32' debe estar alineado en memoria cada {d} bytes.\n", .{alineacion_u32});

    // 2. @alignCast(puntero): Zig es estricto. Si recibes un buffer de bytes generico,
    // su alineacion es 1. No puedes simplemente castearlo a un u32 (alineacion 4).
    // Debes prometerle al compilador que la direccion es multiplo de 4 usando @alignCast.

    // Declaramos un array de bytes forzando explicitamente su alineacion a 4.
    var bytes_crudos align(4) = [_]u8{ 0xAA, 0xBB, 0xCC, 0xDD };

    // Obtenemos un puntero opaco/generico
    const ptr_generico: *u8 = &bytes_crudos[0];

    // Magia: @ptrCast cambia el tipo, pero @alignCast valida la alineacion.
    // Si la alineacion no es multiplo de 4 en ejecucion, ocurrira un panic de seguridad.
    const ptr_estructurado: *align(4) u32 = @ptrCast(@alignCast(ptr_generico));

    try stdout.print("  Lectura exitosa tras @alignCast: 0x{X}\n", .{ptr_estructurado.*});

    // 3. @addrSpaceCast(puntero): Transforma punteros entre diferentes dominios de memoria.
    // Se usa principalmente en GPUs, WebAssembly o Microcontroladores donde la
    // memoria de programa, la RAM y los registros viven en "Address Spaces" distintos.
    // En una CPU normal, esto se convierte en una operacion "no-op" (no hace nada).
    const ptr_espacio: *u8 = @addrSpaceCast(ptr_generico);

    try stdout.print("  @addrSpaceCast resuelto. Punteros apuntan al mismo sitio? {s}\n\n", .{if (ptr_espacio == ptr_generico) "SI" else "NO"});
}

// =========================================================================================
// MODULO 4: CONCURRENCIA LOCK-FREE (@atomicLoad, @atomicStore, @atomicRmw)
// =========================================================================================
fn modulo4_ConcurrenciaAtomica(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Operaciones Atomicas (Concurrencia Hilos)\n", .{});

    // Cuando multiples hilos (Threads) leen y escriben en la misma variable,
    // ocurren "Race Conditions" y la informacion se corrompe.
    // Para solucionarlo sin usar lentos "Mutexes" o "Locks", la CPU tiene
    // instrucciones atomicas (indivisibles).

    var memoria_compartida: u32 = 0;

    // 1. @atomicStore: Escribe un valor de forma 100% segura entre hilos.
    // .monotonic es el ordenamiento mas rapido (no sincroniza otros punteros).
    @atomicStore(u32, &memoria_compartida, 100, .monotonic);

    // 2. @atomicLoad: Lee un valor garantizando que no se lea un valor a medio escribir.
    const lectura_segura = @atomicLoad(u32, &memoria_compartida, .acquire);
    try stdout.print("  [Load/Store] Valor leido atomicamente: {d}\n", .{lectura_segura});

    // 3. @atomicRmw (Read-Modify-Write): El corazon del Lock-Free programming.
    // Lee el valor, le aplica una operacion y guarda el resultado de manera indivisible.
    // NOTA: Los miembros del enum 'builtin.AtomicRmwOp' se escriben en mayuscula inicial
    // (.Add, .Sub, .Xchg), mientras que 'builtin.AtomicOrder' va en minuscula (.seq_cst).
    const valor_viejo = @atomicRmw(u32, &memoria_compartida, .Add, 50, .seq_cst);

    // .seq_cst (Sequential Consistency) es el nivel de ordenamiento mas estricto.

    try stdout.print("  [@atomicRmw] Valor viejo capturado: {d}\n", .{valor_viejo});
    try stdout.print("  [@atomicRmw] Valor nuevo en memoria (100 + 50): {d}\n", .{memoria_compartida});
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
        \\    MASTERCLASS 8: BUILT-IN FUNCTIONS (ZIG 0.16.0)
        \\====================================================================
        \\ Estas funciones no son "librerias", son capacidades inyectadas 
        \\ por el compilador para controlar el hardware a nivel milimetrico.
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\
        \\====================================================================
        \\ FIN DE LA MASTERCLASS.
        \\====================================================================
        \\ RESUMEN DE SEGURIDAD EN ZIG:
        \\ - Zig no permite cast inseguros. @as soluciona conversiones sanas.
        \\ - Zig paniquea si te pasas de los limites de un entero. @addWithOverflow lo controla.
        \\ - Zig te protege de caidas de CPU por punteros desalineados usando @alignCast.
        \\ - Zig te da el maximo rendimiento concurrente con operaciones @atomic*.
        \\====================================================================
        \\
    , .{});
}
