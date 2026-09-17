// =========================================================================================
// MASTERCLASS: MATEMATICAS ESTRICTAS, SIMD Y DIRECTIVAS DEL COMPILADOR (ZIG 0.16.0)
// =========================================================================================
//
// CONTENIDO DE LA MASTERCLASS (13 Builtins cubiertos):
// 1. Matematicas y Bits Estrictos: @rem, @shlExact, @shlWithOverflow, @shrExact.
// 2. Programacion SIMD Avanzada: @splat, @reduce, @select, @shuffle.
// 3. Directivas de Compilador y Scope: @setEvalBranchQuota, @setFloatMode,
//    @setRuntimeSafety, @sizeOf.
// 4. Introspeccion y Diagnostico: @src, @returnAddress.
//
// Todo el codigo esta en ASCII puro para compatibilidad universal con terminales.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");

// Helper para demostrar @returnAddress sin problemas de inline
fn obtenerDireccionDeRetorno() usize {
    return @returnAddress();
}

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

    try modulo1_AritmeticaEstrictaYBits(stdout);
    try modulo2_SIMDAvanzado(stdout);
    try modulo3_DirectivasCompilador(stdout);
    try modulo4_DiagnosticosEInspeccion(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: MATEMATICAS Y BITS ESTRICTOS (@rem, @shlExact, @shlWithOverflow, @shrExact)
// =========================================================================================
fn modulo1_AritmeticaEstrictaYBits(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Aritmetica Estricta y Desplazamiento de Bits\n", .{});

    // 1. @rem: Residuo de la division. A diferencia de @mod, el residuo en Zig
    // redondea hacia cero (congruente con la division truncada @divTrunc).
    const residuo_rem = @rem(-5, 3); // -5 = 3 * (-1) + (-2). El residuo es -2.
    try stdout.print("  @rem de -5 entre 3: {d}\n", .{residuo_rem});

    // 2. @shlExact: Realiza un desplazamiento a la izquierda (<<).
    // Garantiza que ningun bit con valor "1" sea expulsado fuera del limite del tipo.
    // Si se expulsa un bit "1", causa un Panic de seguridad de desbordamiento de bits.
    const base_shl: u8 = 4; // 0b0000_0100
    const shl_resultado = @shlExact(base_shl, 2); // 4 << 2 = 16 (0b0001_0000). Es seguro.
    try stdout.print("  @shlExact(4, 2): {d}\n", .{shl_resultado});

    // 3. @shlWithOverflow: Desplaza a la izquierda y retorna una tupla { resultado, flag_overflow }.
    // Si un bit "1" se sale de los limites del tipo, el flag_overflow se pone en 1.
    const desborde_shl = @shlWithOverflow(@as(u8, 128), 1); // 128 << 1 = 256 (Desborda u8)
    try stdout.print("  @shlWithOverflow(128, 1) -> Resultado: {d} | Overflow? {s}\n", .{ desborde_shl[0], if (desborde_shl[1] == 1) "SI" else "NO" });

    // 4. @shrExact: Realiza un desplazamiento a la derecha (>>).
    // Garantiza que ningun bit con valor "1" sea expulsado y descartado.
    const base_shr: u8 = 16; // 0b0001_0000
    const shr_resultado = @shrExact(base_shr, 2); // 16 >> 2 = 4 (0b0000_0100). Es seguro.
    try stdout.print("  @shrExact(16, 2): {d}\n\n", .{shr_resultado});
}

// =========================================================================================
// MODULO 2: PROGRAMACION VECTORIAL SIMD AVANZADA (@splat, @reduce, @select, @shuffle)
// =========================================================================================
fn modulo2_SIMDAvanzado(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Programacion SIMD y Manipulacion de Vectores\n", .{});

    // 1. @splat: Transforma un escalar (un numero individual) en un vector o array
    // completo duplicando su valor en cada elemento.
    const escalar: i32 = 10;
    const vector_splat: @Vector(4, i32) = @splat(escalar); // { 10, 10, 10, 10 }
    const array_splat: [4]i32 = @splat(escalar); // [ 10, 10, 10, 10 ]

    try stdout.print("  @splat Vector: {any} | @splat Array: {any}\n", .{ vector_splat, array_splat });

    // 2. @reduce: Aplica una operacion horizontal secuencial sobre todo el vector
    // para colapsarlo a un unico escalar de forma eficiente.
    const suma_vectorial = @reduce(.Add, vector_splat); // 10 + 10 + 10 + 10
    try stdout.print("  @reduce (.Add) del vector: {d}\n", .{suma_vectorial});

    // 3. @select: Elige elementos entre dos vectores basandose en una mascara booleana.
    // Si la mascara es 'true', selecciona el elemento de 'a', si es 'false' selecciona de 'b'.
    const mascara = @Vector(4, bool){ true, false, true, false };
    const vec_a = @Vector(4, i32){ 1, 2, 3, 4 };
    const vec_b = @Vector(4, i32){ 10, 20, 30, 40 };
    const seleccion = @select(i32, mascara, vec_a, vec_b); // { 1, 20, 3, 40 }

    try stdout.print("  @select aplicado: {any}\n", .{seleccion});

    // 4. @shuffle: Construye un nuevo vector mezclando, duplicando o reordenando
    // elementos de uno o dos vectores basandose en un array de indices (mascara).
    const vec_letras = @Vector(7, u8){ 'o', 'l', 'h', 'e', 'r', 'z', 'w' };
    const indices_mezcla = @Vector(5, i32){ 2, 3, 1, 1, 0 };

    // Mezclamos vec_letras consigo mismo (pasando undefined en el segundo operando)
    // Indices: 2='h', 3='e', 1='l', 1='l', 0='o'
    const mezcla: @Vector(5, u8) = @shuffle(u8, vec_letras, undefined, indices_mezcla);

    // CORRECCION ZIG 0.16.0: Coercionamos el Vector a un Array normal de bytes de forma segura,
    // y enviamos su referencia (&mezcla_array) al formateador de cadenas "{s}".
    const mezcla_array: [5]u8 = mezcla;

    try stdout.print("  @shuffle aplicado (Swizzling): {s}\n\n", .{&mezcla_array});
}

// =========================================================================================
// MODULO 3: DIRECTIVAS DEL COMPILADOR (@setEvalBranchQuota, @setFloatMode, @setRuntimeSafety, @sizeOf)
// =========================================================================================
fn modulo3_DirectivasCompilador(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Directivas del Compilador y Control de Ambito\n", .{});

    // 1. @setEvalBranchQuota: Incrementa la cuota de saltos hacia atras en ejecucion comptime.
    // Evita que bucles masivos en tiempo de compilacion provoquen errores estaticos.
    comptime {
        @setEvalBranchQuota(2500); // Elevamos el limite estandar de 1000 a 2500
        var i = 0;
        while (i < 1500) : (i += 1) {} // Este bucle superaria el limite estandar de no ser por la directiva
    }
    try stdout.print("  [Exito] @setEvalBranchQuota incremento la cuota de compilacion.\n", .{});

    // 2. @setFloatMode: Modifica las reglas de optimizacion de coma flotante en el ambito actual.
    // .optimized permite optimizaciones agresivas de hardware (Fast-Math, algebra equivalente),
    // ignorando la precision estricta de la norma IEEE 754 a cambio de maximo rendimiento.
    {
        @setFloatMode(.optimized);
        const f_val = @as(f32, 1.1) + @as(f32, 2.2);
        _ = f_val;
    }
    try stdout.print("  [Exito] @setFloatMode (.optimized) configurado para matematicas rapidas.\n", .{});

    // 3. @setRuntimeSafety: Activa o desactiva las pruebas de seguridad de desbordamiento,
    // division por cero o indices fuera de rango para el bloque actual en runtime.
    {
        @setRuntimeSafety(true); // Fuerza seguridad en este bloque, incluso en optimizacion ReleaseFast
        const temp_size = @sizeOf(u64); // @sizeOf: bytes necesarios para almacenar un tipo (8)
        try stdout.print("  [Exito] @setRuntimeSafety forzado. @sizeOf(u64) es: {d} bytes\n\n", .{temp_size});
    }
}

// =========================================================================================
// MODULO 4: DIAGNOSTICOS E INSPECCION (@src, @returnAddress)
// =========================================================================================
fn modulo4_DiagnosticosEInspeccion(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Introspeccion y Diagnostico de Codigo\n", .{});

    // 1. @src: Devuelve un struct 'std.builtin.SourceLocation' con la informacion exacta
    // de donde esta colocada esta linea en el codigo fuente (linea, columna, archivo, funcion).
    const ubicacion = @src();

    try stdout.print("  Diagnostico de Ubicacion (@src):\n", .{});
    try stdout.print("    Archivo: {s}\n", .{ubicacion.file});
    try stdout.print("    Funcion: {s}\n", .{ubicacion.fn_name});
    try stdout.print("    Linea de codigo: {d} | Columna: {d}\n", .{ ubicacion.line, ubicacion.column });

    // 2. @returnAddress: Devuelve la direccion en memoria de la siguiente instruccion de maquina
    // que se ejecutara cuando la funcion actual termine.
    const direccion_retorno = obtenerDireccionDeRetorno();
    try stdout.print("  Direccion de retorno de la funcion (EIP/RIP): 0x{X}\n\n", .{direccion_retorno});
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
        \\    MASTERCLASS 14: ARITMETICA ESTRICTA Y DIRECTIVAS (ZIG 0.16.0)
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
        \\ - @rem redondea hacia cero, a diferencia de la division modular @mod.
        \\ - @shlExact y @shrExact garantizan que ningun bit valioso se pierda en el cambio.
        \\ - Las intrinsicas SIMD (@shuffle, @select) otorgan paralelismo nativo.
        \\ - @setEvalBranchQuota evita crashes del compilador en bucles comptime masivos.
        \\ - @src es el pilar de un motor de Logs moderno y seguro en sistemas.
        \\====================================================================
        \\
    , .{});
}
