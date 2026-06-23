// =========================================================================
// MASTERCLASS: FUNCIONES, EXPRESIONES Y EL PODER DE DEFER (EDICION ZIG 0.16)
// =========================================================================

// En Zig, las funciones son predecibles y no contienen comportamiento oculto.
// A diferencia de Rust (que usa destructores implicitos via RAII), Zig confia
// en palabras clave explicitas del lenguaje como `defer` y `errdefer` para
// la gestion robusta de recursos.

// CONCEPTOS CLAVE:
// 1. Anatomia de Funciones en Zig (Declaracion y Visibilidad).
// 2. Bloques como Expresiones en Zig (Uso de Etiquetas y `break`).
// 3. `defer` y `errdefer`: La alternativa explicita de Zig a RAII en Rust.
// 4. Punteros a Funcion ( callbacks ) como alternativa a Closures.
// 5. Funciones de Orden Superior (Pasar logica como parametros).

const std = @import("std");

// ZIG 0.16.0: "Juicy Main" - Entrada con std.process.Init
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // 1. I/O Explicito y robusto en Zig 0.16.0
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Al salir del programa forzamos el volcado de memoria a la consola
    defer stdout.flush() catch {};

    // 2. Inicializacion del Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Nota: Textos limpios de acentos para evitar basura en la consola de Windows
    try stdout.print("--- INICIO DE LA MASTERCLASS DE FUNCIONES IN ZIG ---\n\n", .{});

    // Pasamos el genérico 'stdout' a nuestras funciones
    try modulo1AnatomiaYRetorno(stdout);
    try modulo2BloquesComoExpresiones(stdout);
    try modulo3ElPoderDeDefer(stdout);
    try modulo4CallbacksYClosures(stdout);
    try modulo5OrdenSuperior(allocator, stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE FUNCIONES ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: ANATOMIA BASICA Y RETORNO
// -------------------------------------------------------------------------
// Las funciones en Zig se definen con `fn` y usan `camelCase` por convencion.
// Todos los parametros son INMUTABLES (de solo lectura) por defecto.
fn modulo1AnatomiaYRetorno(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Anatomia Basica\n", .{});

    // Si una función puede fallar (!void) pero estamos seguros de ignorarlo, usamos `catch {}`
    saludar(stdout, "Desarrollador Zig", 1) catch {};

    const a: i32 = 10;
    const b: i32 = 25;
    const resultado = sumarNumeros(a, b);

    try stdout.print("  Resultado de sumar {d} + {d}: {d}\n\n", .{ a, b, resultado });
}

// Parametros inmutables. Si intentaramos hacer 'nivel = 2', daria error de compilacion.
fn saludar(stdout: anytype, nombre: []const u8, nivel: u32) !void {
    try stdout.print("  Hola {s}! Nivel de usuario: {d}\n", .{ nombre, nivel });
}

fn sumarNumeros(x: i32, y: i32) i32 {
    // El retorno en Zig es siempre explicito usando 'return'
    return x + y;
}

// -------------------------------------------------------------------------
// MODULO 2: BLOQUES COMO EXPRESIONES EN ZIG
// -------------------------------------------------------------------------
// Al igual que Rust, los bloques en Zig pueden ser expresiones que devuelven
// valores. En Zig esto se logra etiquetando el bloque y haciendo un `break`.
fn modulo2BloquesComoExpresiones(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Bloques como Expresiones (Labeled Blocks)\n", .{});

    // Bloques con etiqueta para devolver valores
    const bloque_resultado = blk: {
        const x: i32 = 3;
        // break :nombre_etiqueta valor
        break :blk x + 1;
    };

    // 'if' es una expresion en Zig (como los operadores ternarios en otros lenguajes)
    const condicion = true;
    const valor_condicional = if (condicion) @as(i32, 42) else @as(i32, 0);

    try stdout.print("  Bloque evaluado: {d} | Valor de if condicional: {d}\n\n", .{ bloque_resultado, valor_condicional });
}

// -------------------------------------------------------------------------
// MODULO 3: EL PODER DE DEFER Y ERRDEFER (LA GRAN VENTAJA DE ZIG)
// -------------------------------------------------------------------------
// En Rust, la limpieza de recursos ocurre implicitamente cuando una variable
// sale de su ambito (RAII). Esto puede oscurecer cuando ocurre la liberacion.
//
// En Zig, disponemos de:
// - `defer`: Ejecuta el codigo al salir del bloque actual.
// - `errdefer`: Ejecuta el codigo al salir del bloque actual SOLO si la funcion
//   retorna un error. Ideal para liberar memoria si falla la inicializacion.
fn modulo3ElPoderDeDefer(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: El Poder de defer y errdefer\n", .{});

    {
        // defer se ejecuta al final de este bloque local '{}' en orden inverso.
        // Atrapamos posibles errores de I/O en defer porque dentro de un defer no se puede retornar un error.
        defer stdout.print("  [defer 1] Este es el ultimo defer ejecutado.\n", .{}) catch {};
        defer stdout.print("  [defer 2] Este defer se ejecuta primero porque se apilo despues.\n", .{}) catch {};

        try stdout.print("  [Bloque] Ejecutando codigo principal del bloque...\n", .{});
    }

    try stdout.print("  [Bloque] Bloque finalizado.\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 4: PUNTEROS A FUNCION (EL ANALOGO A CLOSURES)
// -------------------------------------------------------------------------
// Zig no tiene "Closures" implicitos que capturan el entorno magicamente
// como Rust. En Zig usamos punteros a funcion tradicionales de C,
// lo que mantiene el codigo ligero, rapido y sin flujos de control invisibles.
fn modulo4CallbacksYClosures(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Punteros a Funcion (Callbacks)\n", .{});

    // Guardar una funcion en una variable (puntero a funcion)
    const mi_operacion: *const fn (i32) i32 = duplicar;

    try stdout.print("  Llamando callback 'duplicar' para 5 = {d}\n\n", .{mi_operacion(5)});
}

fn duplicar(x: i32) i32 {
    return x * 2;
}

// -------------------------------------------------------------------------
// MODULO 5: FUNCIONES DE ORDEN SUPERIOR
// -------------------------------------------------------------------------
fn modulo5OrdenSuperior(allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Funciones de Orden Superior\n", .{});

    const numeros = [_]i32{ 1, 2, 3, 4, 5 };

    // Pasamos un puntero de funcion 'duplicar' a aplicarOperacion
    const duplicados = try aplicarOperacion(allocator, &numeros, duplicar);

    // Limpiamos la memoria dinámica de 'duplicados' en cuanto salgamos del scope.
    defer allocator.free(duplicados);

    try stdout.print("  Originales: ", .{});
    for (numeros) |n| {
        try stdout.print("{d} ", .{n});
    }

    try stdout.print("\n  Duplicados: ", .{});
    for (duplicados) |n| {
        try stdout.print("{d} ", .{n});
    }
    try stdout.print("\n", .{});
}

// Recibe un callback de tipo '*const fn(i32) i32'
fn aplicarOperacion(allocator: std.mem.Allocator, slice: []const i32, callback: *const fn (i32) i32) ![]i32 {
    const resultado = try allocator.alloc(i32, slice.len);

    // errdefer: Si por alguna razon esta funcion fallara (por un try mas abajo),
    // limpiara la memoria recien reservada para no generar fugas de memoria.
    errdefer allocator.free(resultado);

    for (slice, 0..) |item, i| {
        resultado[i] = callback(item);
    }

    return resultado;
}
