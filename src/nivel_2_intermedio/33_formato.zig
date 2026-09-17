// =========================================================================
// MASTERCLASS: FORMATEO AVANZADO (std.fmt) - ZIG 0.16.0 (ASCII 7-BIT)
// =========================================================================
//
// Filosofia del Formateo en Zig:
// "El formateo en Zig no es una macro magica ni una interpretacion dinamica.
//  Es un sistema de tipado estricto evaluado 100% en tiempo de compilacion
//  (comptime). Si escribes un especificador invalido para un tipo, la
//  compilacion fallara inmediatamente. El sistema fluye directamente a un
//  Writer generico, garantizando Cero Asignaciones en el Heap (Zero-Heap)."
//
// CONCEPTOS AVANZADOS CUBIERTOS (LA GUIA DEFINITIVA):
// 1. Sintaxis Base: El sistema de Tuplas, Orden Posicional y Escapado.
// 2. Gramatica Visual: Alineacion, Relleno, Ancho y Precision.
// 3. Parametros Dinamicos en Runtime (El por que de las limitaciones).
// 4. Especificadores Nativos (Slices Hex con x, tamanos con B/Bi, Durations con f).
// 5. Formateadores Personalizados: Implementando 'pub fn format' (Zig 0.16.0 API).
// 6. Seguridad y Redaccion: Ocultar contrasenas y secrets en logs.
// 7. Formateo sin Heap (Zero-Allocation): Writer.fixed y buffers de pila.
// 8. Formateo en Tiempo de Compilacion: std.fmt.comptimePrint.
// =========================================================================

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);

    try modulo_1_SintaxisYEscapado(stdout);
    try modulo_2_GramaticaVisual(stdout);
    try modulo_3_DinamismoEnRuntime(stdout);
    try stdout.print("\n", .{}); // Separador visual
    try modulo_4_EspecificadoresDeZig(stdout);
    try modulo_5_FormateadoresPersonalizados(stdout);
    try modulo_6_RedaccionYSeguridad(stdout);
    try modulo_7_ZeroAllocationBuffers(stdout);
    try modulo_8_FormateoEnComptime(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================
// MODULO 1: SINTAXIS BASE Y ESCAPADO
// =========================================================================
fn modulo_1_SintaxisYEscapado(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 1: Sintaxis Base, Tuplas y Escapado\n", .{});

    const usuario = "Alice";
    const id: u32 = 42;

    // 1. Clasico (Basado en Tuplas directas)
    // En Zig, los argumentos siempre se pasan en una tupla anonima: .{arg1, arg2}
    try stdout.print("  [Clasico] Usuario {s} con ID {d}.\n", .{ usuario, id });

    // 2. Ausencia de indices y captura de variables locales:
    // A diferencia de Rust (que tiene indices {0} y capturas implicitas {user}),
    // Zig prefiere la simplicidad radical: el formateador lee la tupla secuencialmente.
    // Esto mantiene el parser del compilador extremadamente veloz y legible.

    // 3. Escapado de Llaves (Doble llave {{ o }})
    // Crucial para generar JSON, CSS o estructuras de datos.
    try stdout.print("  [JSON Gen] {{ \"user\": \"{s}\", \"id\": {d} }}\n\n", .{ usuario, id });
}

// =========================================================================
// MODULO 2: GRAMATICA VISUAL (ALINEACION, RELLENO, ANCHO Y PRECISION)
// =========================================================================
// Sintaxis en Zig: `{[argumento][specifier]:[fill][alignment][width].[precision]}`
fn modulo_2_GramaticaVisual(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 2: Alineacion, Relleno, Ancho y Precision\n", .{});

    // ALINEACION (< izquierda, ^ centro, > derecha) Y RELLENO
    try stdout.print("  Centro exacto   : |{s:^12}|\n", .{"Core"}); // |    Core    |
    try stdout.print("  Relleno custom  : |{s:_^12}|\n", .{"OK"}); // |_____OK_____|
    try stdout.print("  Ceros a la izq  : |{d:0>6}|\n", .{42}); // |000042|

    // PRECISION (Solo valido para flotantes con .N)
    const pi: f64 = 3.14159265;
    try stdout.print("  Float (3 dec)   : {d:.3}\n", .{pi}); // 3.142

    // TRUNCADO DE CADENAS (IMPORTANTE: Zig no trunca strings con el formateador)
    // De acuerdo con la especificacion oficial de std.fmt:
    // - El parametro .precision solo aplica para formateo numerico.
    // - El especificador {s} ignorara la precision. El formateador no recortara el texto.
    //
    // La forma correcta e idiomatica de truncar strings en Zig es mediante slices
    // seguros utilizando @min para evitar desbordamientos de indice (out of bounds).
    const texto_largo = "Zig es God Tier";
    const truncado = texto_largo[0..@min(texto_largo.len, 3)];
    try stdout.print("  Truncar String  : |{s}|\n", .{truncado}); // |Zig|

    // COMBINACION: Truncado manual y posterior formateo de alineacion y relleno:
    try stdout.print("  Combo           : |{s:_<10}|\n\n", .{truncado}); // |Zig_______|
}

// =========================================================================
// MODULO 3: PARAMETROS DINAMICOS EN RUNTIME
// =========================================================================
fn modulo_3_DinamismoEnRuntime(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 3: Parametros Dinamicos en Runtime\n", .{});

    // FILOSOFIA DE SEGURIDAD DE ZIG:
    // En Rust puedes usar variables dinamicas en el compilador para el ancho `{:width$}`.
    // En Zig, el string de formato DEBE ser conocido en tiempo de compilacion (comptime).
    // Esto previene fallos de inyeccion de formato y garantiza seguridad total.
    //
    // Para manejar el ancho dinamico en Zig, interactuamos directamente con el Writer:

    const texto = "Hola";
    const ancho_dinamico: usize = 10;

    try stdout.print("  [Dinamico] ", .{});
    try stdout.print("{s}", .{texto});

    if (ancho_dinamico > texto.len) {
        const diff = ancho_dinamico - texto.len;
        var i: usize = 0;
        while (i < diff) : (i += 1) {
            try stdout.writeAll(" ");
        }
    }
    try stdout.print("|\n", .{});
}

// =========================================================================
// MODULO 4: ESPECIFICADORES NATIVOS Y BUILT-INS DE ZIG 0.16.0
// =========================================================================
fn modulo_4_EspecificadoresDeZig(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 4: Especificadores Basicos e Introspeccion de Zig 0.16.0\n", .{});

    const num: u32 = 255;

    try stdout.print("  Decimal          : {d}\n", .{num});
    try stdout.print("  Hexadecimal      : {x}\n", .{num}); // ff
    try stdout.print("  Hex Upper        : {X}\n", .{num}); // FF
    try stdout.print("  Binario          : {b}\n", .{num}); // 11111111
    try stdout.print("  Octal            : {o}\n", .{num}); // 377
    try stdout.print("  Cientifico       : {e}\n", .{@as(f32, 100000)}); // 1e5
    try stdout.print("  Puntero RAM      : {*}\n", .{&num}); // Direccion RAM

    // ESPECIFICADORES DE ZIG 0.16.0:
    // 1. Slices de Bytes a Hexadecimal Directo (Reemplaza std.fmt.fmtSliceHexLower)
    const array_bytes = [_]u8{ 0xDE, 0xAD, 0xBE, 0xEF };
    try stdout.print("  Slice Hex Nativo : {x}\n", .{&array_bytes}); // deadbeef

    // 2. Tamanos de Memoria Legibles de Forma Nativa
    const bytes: u64 = 1024 * 1024 * 5;
    try stdout.print("  Memoria Decimal  : {B}\n", .{bytes}); // 5.2MB (Base-10)
    try stdout.print("  Memoria Binaria  : {Bi}\n", .{bytes}); // 5.0MiB (Base-2)

    // 3. Duracion de Tiempo de Forma Segura (std.Io.Duration + {f})
    const nanosegundos: u64 = 123456789;
    const duracion = std.Io.Duration.fromNanoseconds(nanosegundos);
    try stdout.print("  Duracion Tiempo  : {f}\n", .{duracion});

    // 4. Reflexion con 'any':
    const matriz = [_]u8{ 1, 2, 3 };
    try stdout.print("  Auto-Reflexion   : {any}\n\n", .{matriz}); // { 1, 2, 3 }
}

// =========================================================================
// MODULO 5: FORMATEADORES PERSONALIZADOS (METODO FORMAT - ZIG 0.16.0 API)
// =========================================================================
// En Zig 0.16.0, para crear un formateador personalizado para tu struct,
// simplemente defines una funcion publica 'format' que recibe un puntero a
// la interfaz de salida '*std.Io.Writer'.

const DireccionIP = struct {
    a: u8,
    b: u8,
    c: u8,
    d: u8,

    // Firma estandarizada en Zig 0.16.0
    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("{d}.{d}.{d}.{d}", .{ self.a, self.b, self.c, self.d });
    }
};

fn modulo_5_FormateadoresPersonalizados(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 5: Custom Formatting a nivel de Struct\n", .{});

    const ip = DireccionIP{ .a = 192, .b = 168, .c = 1, .d = 1 };

    // En Zig 0.16.0, el especificador {f} es obligatorio para delegar
    // la operacion al metodo format de una estructura.
    try stdout.print("  [Custom Format] IP detectada: {f}\n\n", .{ip});
}

// =========================================================================
// MODULO 6: SEGURIDAD Y REDACCION DE DATOS SENSIBLES
// =========================================================================
// Al implementar tu propio formateador, puedes censurar datos sensibles como
// contrasenas, impidiendo que caigan en logs de produccion.

const BaseDeDatosConfig = struct {
    host: []const u8,
    puerto: u16,
    password_super_secreta: []const u8,

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("DatabaseConfig(host: {s}, puerto: {d}, password: <REDACTADO_POR_SEGURIDAD>)", .{
            self.host,
            self.puerto,
        });
    }
};

fn modulo_6_RedaccionYSeguridad(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 6: Redaccion y Seguridad de Datos en Logs\n", .{});

    const db = BaseDeDatosConfig{
        .host = "rds-postgres-production",
        .puerto = 5432,
        .password_super_secreta = "Admin123_MasterKey!",
    };

    try stdout.print("  [Log Seguro] {f}\n\n", .{db});
}

// =========================================================================
// MODULO 7: ZERO-ALLOCATION EN BUFFERS (ZIG 0.16.0 FIXED WRITERS)
// =========================================================================
// SOLUCION DE ZIG: Formatear directamente en buffers estaticos sobre la pila (Stack).
// En Zig 0.16.0, 'FixedBufferStream' ha sido removido. Ahora inicializamos un
// escritor directamente sobre la pila usando 'std.Io.Writer.fixed'.

fn modulo_7_ZeroAllocationBuffers(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 7: Writer.fixed (Formateo Seguro en el Stack)\n", .{});

    const valores = [_]u32{ 10, 20, 30 };

    // 1. Reservamos un buffer estatico en la pila (Stack)
    var stack_buffer: [128]u8 = undefined;

    // 2. Inicializamos el escritor de buffer fijo nativo
    var writer = std.Io.Writer.fixed(&stack_buffer);

    // 3. Escribimos directamente en la pila
    for (valores) |val| {
        try writer.print("[{d}] ", .{val});
    }

    // 4. Obtenemos el slice exacto con los bytes escritos
    const string_final = writer.buffered();

    try stdout.print("  String formateado en el Stack sin usar malloc: {s}\n", .{string_final});
    try stdout.print("  Bytes escritos en memoria de la pila: {d} bytes\n\n", .{string_final.len});
}

// =========================================================================
// MODULO 8: FORMATEO EN TIEMPO DE COMPILACION (std.fmt.comptimePrint)
// =========================================================================
// Ademas del formateo dinamico en runtime, Zig permite generar cadenas
// constantes pre-formateadas durante la fase de compilacion.

fn modulo_8_FormateoEnComptime(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 8: Formateo en Tiempo de Compilacion (comptimePrint)\n", .{});

    // std.fmt.comptimePrint genera un string literal definitivo en el ejecutable,
    // eliminando por completo el procesamiento en tiempo de ejecucion.
    const compilacion_meta = std.fmt.comptimePrint("Compilado en: {s}, Version: {d}", .{ "Zig", @as(f32, 0.16) });

    try stdout.print("  [Comptime Print] {s}\n\n", .{compilacion_meta});
}

// =========================================================================
// UTILIDADES DE IMPRESION (ASCII PURO)
// =========================================================================
fn imprimirCabecera(stdout: *std.Io.Writer) !void {
    try stdout.print(
        \\====================================================================
        \\     ___ _   _ ___ _  _____ ___ _  _ ___ 
        \\    | _ ) | | |_ _| |__   _|_ _| \| / __|
        \\    | _ \ |_| || || |__| |  | || .` \__ \
        \\    |___/\___/|___|____|_| |___|_|\_|___/
        \\                                                            
        \\    MASTERCLASS 17: ADVANCED FORMATTING (ZIG 0.16.0)
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: *std.Io.Writer) !void {
    try stdout.print(
        \\====================================================================
        \\ RESUMEN DE RENDIMIENTO DE FORMATEO:
        \\ - Zig no tiene sobrecostos ocultos, toda la sintaxis se valida en comptime.
        \\ - Con la API de Zig 0.16.0, las interfaces de I/O son mas eficientes.
        \\ - El uso de Writer.fixed erradica la fragmentacion de memoria.
        \\====================================================================
        \\
    , .{});
}
