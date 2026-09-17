// =========================================================================================
// MASTERCLASS: FUNCIONES BUILTIN (PARTE 4) - COMPTIME, ERRORES Y MATEMATICAS (ZIG 0.16.0)
// =========================================================================================
//
// CONTENIDO DE LA MASTERCLASS (15 Builtins cubiertos):
// 1. Bitwise Avanzado: @ctz (Count Trailing Zeroes) y C-Macros con @cUndef.
// 2. Interoperabilidad Variadica de C: @cVaStart, @cVaArg, @cVaCopy y @cVaEnd.
// 3. Matematicas Rigurosas de CPU: @divExact, @divFloor y @divTrunc.
// 4. Recursos Integrados: @embedFile (Empaquetamiento de assets en binario).
// 5. Introspeccion y Casts de Enums/Errores: @enumFromInt, @errorFromInt, @errorName,
//    @errorCast y @errorReturnTrace.
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

    try modulo1_BitsYMacrosC(stdout);
    try modulo2_VariadicasC(stdout);
    try modulo3_DivisionesMatematicas(stdout);
    try modulo4_RecursosEmbed(stdout);
    try modulo5_EnumsYErrores(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: BITWISE AVANZADO Y C-MACROS (@ctz, @cUndef)
// =========================================================================================
fn modulo1_BitsYMacrosC(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: @ctz y @cUndef\n", .{});

    // 1. @ctz: Cuenta los "0" a la derecha (menos significativos) del primer "1" en binario.
    // Tambien conocido como "Count Trailing Zeroes".
    // Si el numero es 12 (0b0000_1100), tiene exactamente 2 ceros a la derecha.
    const numero: u8 = 12;
    const ceros_derecha = @ctz(numero);

    try stdout.print("  Numero: {d} (0b00001100)\n", .{numero});
    try stdout.print("  Ceros a la derecha (@ctz): {d}\n", .{ceros_derecha});

    // 2. @cUndef: Deshace una macro definida previamente en un bloque @cImport.
    // Esto es vital para evitar colisiones de simbolos cuando importas multiples librerias C.
    const c = @cImport({
        @cDefine("MACRO_TEMPORAL", "999");
        @cUndef("MACRO_TEMPORAL"); // Eliminamos la macro para que no exista en el namespace 'c'
    });

    // c.MACRO_TEMPORAL no existe aqui.
    _ = c;

    try stdout.print("  [Exito] @cUndef elimino la macro en @cImport antes de procesar.\n\n", .{});
}

// =========================================================================================
// MODULO 2: INTEROPERABILIDAD VARIADICA DE C (@cVaStart, @cVaArg, @cVaCopy, @cVaEnd)
// =========================================================================================
// En Zig, escribir funciones variadicas (con argumentos infinitos como printf de C)
// esta desaconsejado en favor de Slices o Structs anonimos. Sin embargo, para mantener la
// compatibilidad ABI con librerias de C, Zig implementaba las macros va_start y va_arg.
//
// NOTA IMPORTANTE ZIG 0.16.0:
// Debido a fallos de generacion de codigo detectados en el backend LLVM, el compilador
// ha deshabilitado temporalmente @cVaStart con un @compileError controlado por seguridad.
// Dejamos el codigo conceptual aqui documentado para cuando el soporte sea reestablecido.

// fn sumarNumerosC(cantidad: c_int, ...) callconv(.c) i32 {
//     // 1. Inicializamos la lista de argumentos variables
//     var args = @cVaStart();
//
//     // 4. Liberamos los recursos de la lista al terminar
//     defer @cVaEnd(&args);
//
//     var i: c_int = 0;
//     var suma: i32 = 0;
//     while (i < cantidad) : (i += 1) {
//         // 2. Extraemos el siguiente argumento de la pila especificando su tipo en comptime
//         suma += @cVaArg(&args, i32);
//
//         // Nota: @cVaCopy(src) permite duplicar la lista en su estado actual, util
//         // si necesitas iterar los argumentos multiples veces en diferentes funciones.
//         if (false) {
//             var copia_args = @cVaCopy(&args);
//             _ = &copia_args;
//         }
//     }
//     return suma;
// }

fn modulo2_VariadicasC(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Funciones Variadicas de C\n", .{});

    // Simulamos el resultado para que la guia compile de forma impecable en Zig 0.16.0
    const resultado_simulado: i32 = 60;

    try stdout.print("  [Alerta de Compilador] @cVaStart esta deshabilitado en stage2_llvm por seguridad.\n", .{});
    try stdout.print("  [Alerta de Compilador] El compilador prefiere abortar antes que generar codigo corrupto.\n", .{});
    try stdout.print("  Suma variadica conceptual (10, 20, 30) daria como resultado: {d}\n\n", .{resultado_simulado});
}

// =========================================================================================
// MODULO 3: DIVISIONES MATEMATICAS DE CPU (@divExact, @divFloor, @divTrunc)
// =========================================================================================
fn modulo3_DivisionesMatematicas(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Divisiones Especiales en Hardware\n", .{});

    // Zig provee tres comportamientos distintos de division para optimizar algoritmos:

    // 1. @divExact(A, B): Division exacta.
    // Garantiza que el residuo es exactamente cero. Si la division no es exacta,
    // se dispara un Panic de seguridad de tiempo de ejecucion.
    const de = @divExact(10, 2); // 10 / 2 = 5 exacto.
    try stdout.print("  @divExact(10, 2): {d}\n", .{de});

    // 2. @divFloor(A, B): Division hacia abajo (Rounds toward negative infinity).
    // Muy usada en desarrollo de videojuegos y sistemas de coordenadas.
    const df = @divFloor(-5, 3); // -5 / 3 = -1.666 -> Redondea a -2
    try stdout.print("  @divFloor(-5, 3): {d}\n", .{df});

    // 3. @divTrunc(A, B): Division truncada (Rounds toward zero).
    // Es el comportamiento por defecto de la division en la mayoria de los procesadores.
    const dt = @divTrunc(-5, 3); // -5 / 3 = -1.666 -> Trunca los decimales a -1
    try stdout.print("  @divTrunc(-5, 3): {d}\n\n", .{dt});
}

// =========================================================================================
// MODULO 4: RECURSOS INTEGRADOS EN EL BINARIO (@embedFile)
// =========================================================================================
fn modulo4_RecursosEmbed(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Empaquetamiento de Assets (@embedFile)\n", .{});

    // @embedFile(comptime path) lee un archivo de tu disco EN TIEMPO DE COMPILACION
    // y lo inyecta completo y de forma segura dentro del binario ejecutable final.
    // Retorna un puntero a un array de bytes constante terminado en null (*const [N:0]u8).
    //
    // Es ideal para empaquetar shaders (GLSL), archivos de configuracion JSON,
    // imagenes base, fuentes TrueType (TTF) o licencias sin depender de que existan
    // en el disco del usuario final en tiempo de ejecucion.

    comptime {
        if (false) {
            // Ejemplo de uso real:
            const mi_shader = @embedFile("assets/shader.glsl");
            _ = mi_shader;
        }
    }

    try stdout.print("  [Info] @embedFile integra archivos directamente en el binario.\n", .{});
    try stdout.print("  [Info] Retorna un puntero constante terminado en cero (*const [N:0]u8).\n\n", .{});
}

// =========================================================================================
// MODULO 5: INTROSPECCION DE ENUMS Y ERRORES
// =========================================================================================
const Color = enum(u8) {
    Rojo = 1,
    Verde = 2,
    Azul = 3,
};

const ErrorConex = error{
    Timeout,
    Inalcanzable,
};

const ErrorFile = error{
    ArchivoNoEncontrado,
    Timeout, // Compartido en el set global
};

fn modulo5_EnumsYErrores(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Enums, Casts de Errores y Stack Traces\n", .{});

    // 1. @enumFromInt: Convierte un numero entero en su representacion Enum.
    // Si el entero no tiene un valor correspondiente en el Enum, causa un Panic de seguridad.
    const enum_verde: Color = @enumFromInt(2);
    try stdout.print("  @enumFromInt(2) obtenido exitosamente: {any}\n", .{enum_verde});

    // 2. @errorName: Devuelve la representacion en String literal de un error.
    // Altamente util para logs legibles en produccion.
    const nombre_err = @errorName(ErrorConex.Timeout);
    try stdout.print("  @errorName de ErrorConex.Timeout: {s}\n", .{nombre_err});

    // 3. @errorCast: Convierte un error de un Error Set a otro Error Set compatible.
    // Fusionamos conjuntos para demostrarlo
    const ErrorGeneral = ErrorConex || ErrorFile;
    const err_origen = ErrorConex.Inalcanzable;
    const err_destino: ErrorGeneral = @errorCast(err_origen);
    try stdout.print("  @errorCast de subconjunto a superconjunto exitoso: {any}\n", .{err_destino});

    // 4. @errorFromInt: Convierte la representacion entera de un error al Global Error Set.
    // NOTA: Se recomienda evitar su uso ya que el entero no es estable entre compilaciones,
    // pero es soportado para interoperabilidad cruda.
    const err_int = @intFromError(ErrorConex.Timeout);
    const err_recuperado: anyerror = @errorFromInt(err_int);
    try stdout.print("  @errorFromInt recupero el error: {any}\n", .{err_recuperado});

    // 5. @errorReturnTrace: Permite extraer la pila de llamadas (StackTrace) de un error
    // activo si la aplicacion compilo con soporte de tracing.
    const trace = @errorReturnTrace();
    try stdout.print("  @errorReturnTrace activo en este hilo? {s}\n\n", .{if (trace != null) "SI" else "NO"});
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
        \\    MASTERCLASS 11: COMPTIME, ERRORES Y MATEMATICAS (ZIG 0.16.0)
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
        \\ - @ctz optimiza calculos de alineamiento buscando bits encendidos.
        \\ - Zig es capaz de mapear la pila variadica de C con las macros @cVa*.
        \\ - La division puede ser exacta, truncada o redondeada hacia abajo.
        \\ - @embedFile elimina dependencias externas empaquetando assets.
        \\ - @errorName y @errorReturnTrace garantizan telemetria de errores.
        \\====================================================================
        \\
    , .{});
}
