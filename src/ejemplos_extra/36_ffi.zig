// =========================================================================
//           MASTERCLASS: INTEROPERABILIDAD CON C Y FFI (C-CALLS)
//                         EDICION ZIG 0.16.0
// =========================================================================
// Este documento ha sido disenado como la guia de referencia definitiva
// para dominar el uso de librerias de C, gestion de memoria cruzada,
// punteros de C (*c), strings terminados en null y exportacion binaria.
//
// NOTA DE COMPATIBILIDAD: Todo el codigo, graficos ASCII y explicaciones
// estan limitados estrictamente a la codificacion ASCII de 7 bits (rango 0-127).

// =========================================================================
// !!! INSTRUCCION CRITICA DE COMPILACION !!!
// Para compilar y ejecutar este archivo, DEBES enlazar la libreria C (libc).
// Ejecuta exactamente este comando en tu terminal:
//
//      zig run 36_ffi.zig -lc
//
// =========================================================================

const std = @import("std");
const builtin = @import("builtin");
const print = std.debug.print;

// -------------------------------------------------------------------------
// VALIDACION DE SEGURIDAD EN TIEMPO DE COMPILACION (Novedad Zig 0.16)
// -------------------------------------------------------------------------
comptime {
    if (!builtin.link_libc) {
        @compileError("\n" ++
            "==========================================================\n" ++
            "[ERROR FATAL] La libreria estandar de C (libc) no esta enlazada.\n" ++
            "Zig se niega a importar cabeceras de C sin ella.\n" ++
            "Por favor, ejecuta el programa asi:\n" ++
            "    zig run <este_archivo.zig> -lc\n" ++
            "==========================================================");
    }
}

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("string.h");
    @cInclude("ctype.h");
});

// =========================================================================
// 1. IMPORTACION DE CABECERAS Y TIPOS PRIMITIVOS
// =========================================================================
fn modulo1TiposC() void {
    print(">> MODULO 1: Tipos de C mapeados nativamente\n", .{});

    const numero_entero: c_int = 42;
    const caracter: c_char = 'Z';
    const char_seguro = @as(u8, @bitCast(caracter));

    print("  c_int (int)   : {d}\n", .{numero_entero});
    print("  c_char (char) : {c}\n\n", .{char_seguro});
}

// =========================================================================
// 2. PUNTEROS, ALINEACION DE MEMORIA Y @alignCast (EL ERROR DE MALLOC)
// =========================================================================
// ¿POR QUE ZIG DIO ERROR CON MALLOC? (Concepto para Principiantes)
// Imagina que la memoria es un estacionamiento.
// - Un byte de datos es como una bicicleta: cabe en cualquier espacio (Alineacion 1).
// - Un `c_int` (entero de 32 bits) es como un autobus: requiere 4 espacios
//   especificos perfectamente alineados (Alineacion 4).
//
// La funcion `c.malloc` devuelve un puntero generico (void* en C, o ?*anyopaque
// en Zig). Como Zig no sabe que vas a guardar ahi, le asigna preventivamente
// "Alineacion 1" (espacio de bicicleta).
//
// Si intentamos forzar ese espacio para que guarde un autobus (`c_int`) usando
// solo @ptrCast, Zig dice: "¡ALTO! No puedo garantizar que este espacio este
// alineado en bloques de 4. Podria causar un error de CPU".
//
// LA SOLUCION:
// 1. Usar `@alignCast`: Para decirle a Zig "Confia en mi, se que malloc
//    devuelve memoria correctamente alineada para cualquier tipo en C".
// 2. Usar `@ptrCast`: Para cambiar el tipo visual (de void* a int*).

fn modulo2PunterosC() void {
    print(">> MODULO 2: Punteros de C y Alineacion de Memoria\n", .{});

    // PASO 1: Pedimos memoria a C. Esto devuelve un puntero opcional generico
    // Tipo: `?*anyopaque` (Alineacion 1)
    const raw_malloc_ptr = c.malloc(@sizeOf(c_int) * 5);

    if (raw_malloc_ptr == null) {
        print("  [Error] Malloc devolvio NULL (Sin memoria)\n", .{});
        return;
    }

    // PASO 2: Extraemos el valor seguro garantizando que no es null usando `.?`
    // Tipo: `*anyopaque` (Sigue siendo Alineacion 1)
    const valid_void_ptr = raw_malloc_ptr.?;

    // PASO 3: MAGIA ZIG.
    // Primero, `@alignCast` aumenta la alineacion (de 1 a 4 bytes).
    // Segundo, `@ptrCast` transforma el "anyopaque" a un Puntero Múltiple de Zig `[*]c_int`.
    const puntero_zig_seguro: [*]c_int = @ptrCast(@alignCast(valid_void_ptr));

    // NUNCA olvides liberar memoria asignada por C usando la funcion de C
    defer c.free(valid_void_ptr);

    // PASO 4: Ya podemos usar el puntero de forma nativa como si fuera un Array!
    puntero_zig_seguro[0] = 100;
    puntero_zig_seguro[1] = 200;
    puntero_zig_seguro[2] = 300;

    print("  Direccion cruda en RAM  : {*}\n", .{valid_void_ptr});
    print("  Alineacion confirmada, valor[1] : {d}\n\n", .{puntero_zig_seguro[1]});
}

// =========================================================================
// 3. STRINGS (ARREGLOS VS TERMINADOS EN NULL)
// =========================================================================
fn modulo3StringsC() void {
    print(">> MODULO 3: Traduccion cruzada de Strings\n", .{});

    const string_zig = "Hola C, soy Zig";
    const longitud_c = c.strlen(string_zig);
    print("  c.strlen(\"{s}\") devolvio: {d}\n", .{ string_zig, longitud_c });

    const user_c_ptr = c.getenv("USER") orelse c.getenv("USERNAME");
    if (user_c_ptr != null) {
        const c_str: [*:0]const u8 = @ptrCast(user_c_ptr);
        const string_slice_zig: []const u8 = std.mem.span(c_str);
        print("  std.mem.span reconstruyo String C: '{s}'\n\n", .{string_slice_zig});
    } else {
        print("  Variable de entorno USER/USERNAME no encontrada.\n\n", .{});
    }
}

// =========================================================================
// 4. EXPORTAR ZIG HACIA C (CREANDO LIBRERIAS)
// =========================================================================
const StructCompatibleC = extern struct {
    eje_x: c_int,
    eje_y: c_int,
};

export fn procesarCoordenada(coord: *StructCompatibleC) callconv(.c) c_int {
    return coord.eje_x + coord.eje_y;
}

fn modulo4Exportacion() void {
    print(">> MODULO 4: Exportacion de Funciones a C\n", .{});
    print("  La funcion 'procesarCoordenada' esta expuesta al linker con ABI de C.\n\n", .{});
}

// =========================================================================
// 5. PROYECTO COMPLETO: UTILIZANDO QSORT DE LIBC CON CALLBACK ZIG
// =========================================================================
// Aqui aplicamos lo mismo! `a` y `b` son `?*const anyopaque` (Alineacion 1).
// Debemos usar @alignCast para que Zig confie en que son punteros de `c_int`.
export fn miCallbackOrdenacion(a: ?*const anyopaque, b: ?*const anyopaque) callconv(.c) c_int {
    // 1. Forzamos la alineacion requerida por un entero.
    // 2. Casteamos al tipo nativo.
    const ptr_a: *const c_int = @ptrCast(@alignCast(a.?));
    const ptr_b: *const c_int = @ptrCast(@alignCast(b.?));

    const valor_a = ptr_a.*;
    const valor_b = ptr_b.*;

    if (valor_a < valor_b) return -1;
    if (valor_a > valor_b) return 1;
    return 0;
}

fn ejecucionProyectoQSort() void {
    print(">> PROYECTO INTEGRAL: Ordenacion Hibrida Zig-C (qsort) <<\n", .{});

    var numeros = [_]c_int{ 99, 12, 5, 87, 42, -5, 33 };

    print("  Arreglo Original Zig : ", .{});
    for (numeros) |n| print("{d} ", .{n});
    print("\n", .{});

    c.qsort(
        &numeros[0],
        numeros.len,
        @sizeOf(c_int),
        miCallbackOrdenacion,
    );

    print("  Arreglo Ordenado por C : ", .{});
    for (numeros) |n| print("{d} ", .{n});
    print("\n\n", .{});
}

// =========================================================================
// PUNTO DE ENTRADA PRINCIPAL
// =========================================================================
pub fn main() void {
    print("--- INICIO DE LA MASTERCLASS DE INTEROPERABILIDAD C (FFI) ---\n\n", .{});

    modulo1TiposC();
    modulo2PunterosC();
    modulo3StringsC();
    modulo4Exportacion();
    ejecucionProyectoQSort();

    print("--- FIN DE LA MASTERCLASS DE INTEROPERABILIDAD C (FFI) ---\n", .{});
}
