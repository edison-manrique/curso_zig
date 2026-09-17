// =========================================================================================
// MASTERCLASS: MEMORIA EN BLOQUE, PUNTEROS CRUDOS Y PLATAFORMAS (ZIG 0.16.0)
// =========================================================================================
//
// CONTENIDO DE LA MASTERCLASS (12 Builtins cubiertos):
// 1. Manipulacion de Memoria: @memcpy, @memset y @memmove (Control de solapamiento).
// 2. Matematicas y Bits: @min, @mod, @mulWithOverflow y @popCount.
// 3. Punteros y Hardware: @ptrCast, @ptrFromInt y @prefetch (Caché L1/L2/L3).
// 4. Arquitectura y Control: @wasmMemorySize, @wasmMemoryGrow y @panic.
//
// Todo el codigo esta en ASCII puro para compatibilidad universal con terminales.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");

// =========================================================================================
// ZIG 0.16.0 "JUICY MAIN" - ENTRY POINT
// =========================================================================================
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);

    try modulo1_MemoriasEnBloque(stdout);
    try modulo2_MatematicasYBits(stdout);
    try modulo3_PunterosYPrefetch(stdout);
    try modulo4_PlataformasYControl(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: MANIPULACION DE MEMORIA EN BLOQUE (@memcpy, @memset, @memmove)
// =========================================================================================
fn modulo1_MemoriasEnBloque(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Operaciones de Memoria en Bloque\n", .{});

    // 1. @memset: Llena una region de memoria con un elemento repetido de forma eficiente.
    var buffer_destino = [_]u8{0} ** 8;
    @memset(&buffer_destino, 42); // Llena el array con el byte 42 (caracter '*')
    try stdout.print("  @memset aplicado: {s}\n", .{buffer_destino});

    // 2. @memcpy: Copia bytes de una region a otra.
    // REGLA DE ORO: Las dos regiones de memoria NO deben solaparse (overlap).
    // Si se solapan, causara Comportamiento Indefinido (UB).
    const origen = [_]u8{ 'Z', 'I', 'G', '0', '.', '1', '6', '.' };
    var destino: [8]u8 = undefined;

    @memcpy(&destino, &origen);
    try stdout.print("  @memcpy aplicado: {s}\n", .{destino});

    // 3. @memmove: Copia bytes al igual que @memcpy, pero SI permite solapamiento.
    // Se usa para desplazar datos dentro de un mismo buffer.
    var buffer_solapado = [_]u8{ '1', '2', '3', '4', '5' };

    // Desplazamos los elementos 1,2,3 (indice 0..3) a la derecha (indice 2..5)
    // El '3' se solaparia si usaramos memcpy. memmove lo previene.
    @memmove(buffer_solapado[2..5], buffer_solapado[0..3]);

    try stdout.print("  @memmove (solapamiento permitido): {s}\n\n", .{buffer_solapado});
}

// =========================================================================================
// MODULO 2: MATEMATICAS Y BITS (@min, @mod, @mulWithOverflow, @popCount)
// =========================================================================================
fn modulo2_MatematicasYBits(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Operaciones Matematicas y Bitwise de CPU\n", .{});

    // 1. @min: Encuentra el valor minimo entre multiples opciones (integers, floats, vectores)
    const minimo = @min(15, -42, 999, 0);
    try stdout.print("  @min del conjunto: {d}\n", .{minimo});

    // 2. @mod: Devuelve el residuo matematico de la division (Modulus division).
    // Nota: Para numeros negativos, el modulo en Zig es congruente con la division floor.
    const residuo = @mod(-5, 3); // -5 = 3 * (-2) + 1. El residuo es 1.
    try stdout.print("  @mod de -5 modulo 3: {d}\n", .{residuo});

    // 3. @mulWithOverflow: Multiplica dos enteros y retorna una tupla { resultado, flag_overflow }.
    const a: u8 = 50;
    const b: u8 = 10;
    const tupla = @mulWithOverflow(a, b); // 50 * 10 = 500 (Desborda el limite u8 de 255)

    try stdout.print("  Multiplicacion: {d} * {d}\n", .{ a, b });
    try stdout.print("  Resultado truncado: {d} | Hubo Overflow? {s}\n", .{ tupla[0], if (tupla[1] == 1) "SI" else "NO" });

    // 4. @popCount: Cuenta cuantos bits estan encendidos (en '1') dentro de un entero.
    // Tambien conocido como Hamming Weight o Population Count.
    const patron: u8 = 0b1011_0110; // Tiene exactamente 5 bits en '1'
    const conteo_unos = @popCount(patron);
    try stdout.print("  Bits activos (@popCount) en 0b10110110: {d}\n\n", .{conteo_unos});
}

// =========================================================================================
// MODULO 3: PUNTEROS Y PREFETCH DE CACHE (@ptrCast, @ptrFromInt, @prefetch)
// =========================================================================================
fn modulo3_PunterosYPrefetch(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Casts de Punteros y Pre-busqueda de Cache\n", .{});

    var valor_real: u32 = 0xDEADBEEF;

    // 1. @ptrCast: Convierte un puntero de un tipo a otro de manera estricta y segura.
    // REGLA: No puede alterar alineacion (usa @alignCast) ni quitar const (usa @constCast).
    const ptr_u32: *u32 = &valor_real;
    const ptr_i32: *i32 = @ptrCast(ptr_u32);
    try stdout.print("  @ptrCast ejecutado. Valor leido como i32: 0x{X}\n", .{ptr_i32.*});

    // 2. @ptrFromInt: Convierte una direccion de memoria (usize) de vuelta a un puntero funcional.
    const direccion: usize = @intFromPtr(ptr_u32);
    const ptr_recuperado: *u32 = @ptrFromInt(direccion);
    try stdout.print("  @ptrFromInt recupero el puntero a la direccion: 0x{X}\n", .{@intFromPtr(ptr_recuperado)});

    // 3. @prefetch: Le dice al hardware (CPU) que cargue una direccion de memoria en las
    // caches de datos mas rapidas (L1, L2 o L3) antes de que la aplicacion intente leerla.
    // Esto previene los destructivos 'Cache Misses' en estructuras masivas de datos.
    const opciones_prefetch = std.builtin.PrefetchOptions{
        .rw = .read,
        .locality = 3, // Maxima localidad temporal (mantener en cache L1)
        .cache = .data,
    };

    @prefetch(ptr_u32, opciones_prefetch);
    try stdout.print("  [Exito] @prefetch emitio una sugerencia de carga en Cache L1 para la CPU.\n\n", .{});
}

// =========================================================================================
// MODULO 4: PLATAFORMAS (WASM) Y CONTROL DE PANICOS (@wasm*, @panic)
// =========================================================================================
fn modulo4_PlataformasYControl(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Plataforma WebAssembly (Wasm) y Panicos\n", .{});

    // 1. @wasmMemorySize / @wasmMemoryGrow:
    // Estas son intrinsicas de muy bajo nivel para interactuar con la RAM de WebAssembly.
    // Retornan/Crean espacio en unidades de 'Wasm Pages' (cada pagina mide 64KB).
    //
    // MEDIDA DE SEGURIDAD EXTREMA EN COMPILACION:
    // Si compilasemos esto en x86/ARM de forma directa, LLVM daria un error estatico.
    // Para hacerlo compilable en cualquier maquina, protegemos la ejecucion con un comptime if
    // que analiza la arquitectura destino. El compilador de Zig solo lo analizara si compilas para WASM.
    comptime {
        if (builtin.target.cpu.arch == .wasm32 or builtin.target.cpu.arch == .wasm64) {
            const tamano_actual = @wasmMemorySize(0);
            _ = @wasmMemoryGrow(0, 1); // Crece la memoria en 1 pagina (64KB)
            _ = tamano_actual;
        }
    }

    try stdout.print("  [Wasm Check] Intrinsicas @wasmMemory* protegidas en tiempo de compilacion.\n", .{});

    // 2. @panic: Invoca el manejador de fallos fatales del programa.
    // Detiene el hilo actual e imprime el stack trace. Lo dejamos dentro de un 'if (false)'
    // para que la ejecucion de este manual termine exitosamente.
    if (false) {
        @panic("Detencion forzada por error critico no recuperable.");
    }

    try stdout.print("  [@panic] Manejador de fallos del sistema listo (protegido por seguridad).\n\n", .{});
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
        \\    MASTERCLASS 13: MEMORIA EN BLOQUE Y HARDWARE (ZIG 0.16.0)
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\ FIN DE LA MASTERCLASS.
        \\====================================================================
        \\ CONCEPTOS CLAVE REPASADOS:
        \\ - @memcpy requiere que los punteros no tengan solapamiento (noalias).
        \\ - @memmove es seguro de usar cuando las regiones de memoria se solapan.
        \\ - @mulWithOverflow y @popCount otorgan operaciones directas de silicio.
        \\ - @prefetch previene el cuello de botella mas destructivo de la CPU: la RAM.
        \\ - El compilador de Zig es selectivo con sus targets (Intrinsicas Wasm).
        \\====================================================================
        \\
    , .{});
}
