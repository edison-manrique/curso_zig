// =========================================================================
// MASTERCLASS 9: STRINGS, UTF-8 Y TEXTO EN MEMORIA (EDICION ZIG 0.16.0)
// =========================================================================

// En Zig, un String Literal es un puntero a un arreglo de bytes constante,
// estatico y terminado en cero: `*const [N:0]u8`.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Anatomia de un String Literal (*const [N:0]u8) y el byte nulo (:0).
// 2. Coercion automatica a Slices ([]const u8) y Punteros C ([*:0]const u8).
// 3. Unicode Code Points como enteros en tiempo de compilacion (comptime_int).
// 4. Indexacion cruda de bytes UTF-8 (Por que un Emoji mide mas de 1 byte).
// 5. Literales Multilinea (Multiline string literals con \\).
// 6. Comparacion segura de strings en memoria (std.mem.eql).
// 7. Proyecto Final: Parser de archivos CSV con Slices (Zero Allocations).

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [8192]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE STRINGS EN ZIG ---\n\n", .{});

    try modulo1AnatomiaString(stdout);
    try modulo2CoercionYTipos(stdout);
    try modulo3UnicodeYBytes(stdout);
    try modulo4Multilinea(stdout);
    try modulo5ComparacionYEscapes(stdout);
    try modulo6ProyectoParserCSV(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE STRINGS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: ANATOMIA DE UN STRING LITERAL
// -------------------------------------------------------------------------
fn modulo1AnatomiaString(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Anatomia de un String Literal\n", .{});

    const texto = "hello";

    // El tipo real contiene el tamano (5) y el centinela de terminacion (:0)
    try stdout.print("  Tipo de 'hello': {s}\n", .{@typeName(@TypeOf(texto))});
    try stdout.print("  Longitud de caracteres: {d}\n", .{texto.len});

    // Al estar terminado en cero, podemos acceder de forma segura al indice [len]
    // Esto es garantizado por el compilador de Zig y no provoca desbordamientos.
    const centinela = texto[texto.len];
    try stdout.print("  Valor del byte centinela al final (indice {d}): {d}\n\n", .{ texto.len, centinela });
}

// -------------------------------------------------------------------------
// MODULO 2: COERCION AUTOMATICA DE TIPOS
// -------------------------------------------------------------------------
fn modulo2CoercionYTipos(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Coercion de Strings (Slices y Punteros C)\n", .{});

    const literal = "ZigLang";

    // 1. Coercion a Slice de solo lectura (El formato mas usado en Zig)
    const slice: []const u8 = literal;

    // 2. Coercion a Puntero terminado en cero compatible con C ([*:0]const u8)
    const ptr_c: [*:0]const u8 = literal;

    try stdout.print("  Convertido a Slice -> Tipo: {s}, Len: {d}\n", .{ @typeName(@TypeOf(slice)), slice.len });
    try stdout.print("  Convertido a C-Pointer -> Tipo: {s}\n\n", .{@typeName(@TypeOf(ptr_c))});
}

// -------------------------------------------------------------------------
// MODULO 3: UNICODE Y BYTES (¿DONDE ESTA EL CARACTER?)
// -------------------------------------------------------------------------
fn modulo3UnicodeYBytes(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Unicode Code Points e Indexacion Cruda de Bytes\n", .{});

    // En Zig, los caracteres individuales (Code Points) se escriben con comillas simples.
    // Su tipo es 'comptime_int' (como los enteros literales).
    const letra_e = 'e';
    const rayo = '⚡';
    const emoji_cien = '💯';

    try stdout.print("  Letra 'e' en decimal: {d}\n", .{letra_e});
    try stdout.print("  Rayo en decimal (Unicode Scalar): {d}\n", .{rayo});
    try stdout.print("  Emoji 100 en decimal (Unicode Scalar): {d}\n", .{emoji_cien});

    // INDEXACION CRUDA:
    // El emoji "💯" ocupa 4 bytes en UTF-8.
    // Si indexamos el string "💯" directamente, obtenemos bytes individuales, NO el emoji completo.
    const cien_string = "💯";
    try stdout.print("  El string de emoji 'Cien' mide {d} bytes de memoria.\n", .{cien_string.len});
    try stdout.print("  Bytes UTF-8 individuales de 'Cien' en hexadecimal: ", .{});
    for (cien_string) |byte| {
        try stdout.print("0x{X} ", .{byte});
    }
    try stdout.print("\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 4: LITERALES MULTILINEA (\\)
// -------------------------------------------------------------------------
// Los strings multilinea no procesan secuencias de escape (como \n o \t).
// Conservan exactamente el espaciado y saltos de linea que dibujes en el codigo.
const SCRIPT_SQL =
    \\SELECT id, nombre, rol
    \\FROM usuarios
    \\WHERE activo = 1;
;

fn modulo4Multilinea(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Literales Multilinea\n", .{});
    try stdout.print("  Script SQL compilado directamente:\n{s}\n\n", .{SCRIPT_SQL});
}

// -------------------------------------------------------------------------
// MODULO 5: COMPARACION SEGURA DE STRINGS EN MEMORIA
// -------------------------------------------------------------------------
fn modulo5ComparacionYEscapes(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Comparacion Segura y Escapes\n", .{});

    // En Zig, como los strings son punteros, hacer `str1 == str2` comparara si apuntan
    // a la misma direccion de memoria, NO si el texto es igual.
    // Para comparar el contenido, debemos usar `std.mem.eql`.
    const texto1 = "hola";
    const texto2 = "h\x65llo"; // \x65 es la letra 'e' en hexadecimal

    const son_iguales = std.mem.eql(u8, texto1, "hola");
    const son_iguales_hex = std.mem.eql(u8, "hello", texto2);

    try stdout.print("  'hola' es igual a 'hola'? {}\n", .{son_iguales});
    try stdout.print("  'hello' es igual a 'h\\x65llo'? {}\n\n", .{son_iguales_hex});
}

// -------------------------------------------------------------------------
// MODULO 6: PROYECTO - PARSER DE ARCHIVOS CSV (ZERO ALLOCATIONS)
// -------------------------------------------------------------------------
// Gracias al poder de los Slices, podemos parsear un texto gigante sin tener
// que copiar palabras ni reservar memoria en el Heap (0 bytes de allocation).
// Solo apuntamos punteros a diferentes secciones del string original.

const CSV_DATA =
    \\101,Alice,Dev
    \\102,Bob,SysOps
    \\103,Charlie,Manager
;

fn modulo6ProyectoParserCSV(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: Proyecto - Parser CSV (Zero Allocations / Pure Slices)\n", .{});

    // std.mem.splitScalar corta un string usando un caracter delimitador
    var lineas = std.mem.splitScalar(u8, CSV_DATA, '\n');

    while (lineas.next()) |linea| {
        if (linea.len == 0) continue;

        // Cortamos cada linea por comas
        var columnas = std.mem.splitScalar(u8, linea, ',');

        const id = columnas.next() orelse "N/A";
        const nombre = columnas.next() orelse "N/A";
        const rol = columnas.next() orelse "N/A";

        try stdout.print("    [Registro] ID: {s: <3} | Nombre: {s: <7} | Rol: {s}\n", .{ id, nombre, rol });
    }
}
