// =========================================================================
// MASTERCLASS: MODULARIDAD Y SISTEMA DE IMPORTACION (EDICION ZIG 0.16.0)
// =========================================================================
// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.

// En Rust, el sistema de modulos utiliza 'mod', 'use', 'pub(crate)' y la
// estructura 'src/lib.rs' o 'src/main.rs', que anade complejidad visual.

// En Zig, la modularidad es intencionadamente simple e intuitiva:
// 1. Cada archivo '.zig' es implicitamente un struct (un namespace).
// 2. No existen declaraciones de modulos 'mod'. Si deseas importar un archivo,
//    usas la funcion incorporada '@import("ruta_del_archivo.zig")'.
// 3. Todo es privado por defecto. Se requiere la palabra 'pub' para exportar.
// 4. No existen importaciones ciclicas ocultas o flujos de carga complejos.

// CONCEPTOS CLAVE:
// 1. Importacion de la libreria estandar (std).
// 2. Importacion de modulos locales relativos (@import("_15_helper.zig")).
// 3. Control de visibilidad de namespaces (pub vs privado).
// 4. Alias de estructuras en tiempo de compilacion.

const std = @import("std");

// Importacion del archivo local. 'helper' actua como una constante de namespace.
const helper = @import("_15_helper.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Inicializamos buffer de escritura de alta performance para stdout
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Liberamos el flujo de salida al finalizar la ejecucion
    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE MODULOS IN ZIG ---\n\n", .{});

    try modulo1ImportarLocales(stdout);
    try modulo2AliasYNamespaces(stdout);

    try stdout.print("--- FIN DE LA MASTERCLASS DE MODULOS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: IMPORTAR MÓDULOS LOCALES
// -------------------------------------------------------------------------
fn modulo1ImportarLocales(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Importar Modulos Locales y Visibilidad\n", .{});

    // Accedemos a las constantes y metodos publicos del modulo helper
    const version = helper.VERSION;
    const suma = helper.Calculadora.sumar(20, 30);
    const resta = helper.Calculadora.restar(50, 15);

    // NOTA DE SEGURIDAD DE COMPILACION:
    // Si descomentas la siguiente linea, el compilador arrojara un error inmediato:
    // helper.funcionPrivada(); // error: 'funcionPrivada' is private

    try stdout.print("  Modulo Helper version: {s}\n", .{version});
    try stdout.print("  Calculo del modulo helper -> 20 + 30 = {d} | 50 - 15 = {d}\n\n", .{ suma, resta });
}

// -------------------------------------------------------------------------
// MODULO 2: ALIAS Y NAMESPACES
// -------------------------------------------------------------------------
// Dado que las importaciones devuelven estructuras semanticas estaticas,
// podemos crear alias cortos en tiempo de compilacion utilizando constantes 'const'.
const Calc = helper.Calculadora;

fn modulo2AliasYNamespaces(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Creacion de Alias para Namespaces\n", .{});

    // Usamos el alias simplificado 'Calc' en lugar de escribir la ruta de namespace larga
    const res = Calc.sumar(100, 200);

    try stdout.print("  Resultado obtenido utilizando alias 'Calc': {d}\n\n", .{res});
}
