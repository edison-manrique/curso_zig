// =========================================================================
// MASTERCLASS 3: BUCLES Y ESTRUCTURAS DE REPETICION (EDICION ZIG 0.16)
// =========================================================================

// En Zig, los bucles son potentes y flexibles. Introducen conceptos unicos
// como las "expresiones de continuacion" de `while`, el desempaquetado de
// opcionales, y la posibilidad de usar bucles como expresiones con `else`.

// CONCEPTOS CLAVE AÑADIDOS Y CUBIERTOS:
// 1. `while` Basico, Continuacion y Desempaquetado de Opcionales (while-let).
// 2. `for` Moderno: Rangos puros (0..N), Iteracion paralela, y modificacion in-place.
// 3. Bucles Anidados: Labeled `break` y Labeled `continue`.
// 4. Bucles como Expresiones: `for...else` y `while...else`.
// 5. Bucles `inline`: Desenrollado de tuplas heterogeneas en tiempo de compilacion.

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Inicializacion del escritor directo a consola (sin basura ni allocations)
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE BUCLES EN ZIG ---\n\n", .{});

    try modulo1BucleWhile(stdout);
    try modulo2BucleFor(stdout);
    try modulo3BuclesAnidados(stdout);
    try modulo4BuclesComoExpresiones(stdout);
    try modulo5BuclesInline(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE BUCLES ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: EL BUCLE `while` (CONTINUACION Y OPCIONALES)
// -------------------------------------------------------------------------
fn modulo1BucleWhile(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: while (Continuacion y Opcionales)\n", .{});

    // 1. while clasico con expresion de continuacion
    // Sintaxis: while (condicion) : (paso) { ... }
    var i: usize = 0;
    try stdout.print("  [while clasico]: ", .{});
    while (i < 5) : (i += 1) {
        try stdout.print("{d} ", .{i});
    }
    try stdout.print("\n", .{});

    // 2. while con Desempaquetado de Opcionales (?T)
    // El bucle se ejecuta mientras el valor NO sea nulo.
    // Capturamos el valor real dentro de los pipes |valor|
    var cuenta_atras: ?u32 = 3;
    try stdout.print("  [while opcionales]: ", .{});
    while (cuenta_atras) |valor| {
        try stdout.print("{d} ", .{valor});

        if (valor == 0) {
            cuenta_atras = null; // Asignar null rompe el bucle naturalmente
        } else {
            cuenta_atras = valor - 1;
        }
    }
    try stdout.print("\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 2: EL NUEVO BUCLE `for` DE ZIG 0.16.0
// -------------------------------------------------------------------------
fn modulo2BucleFor(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: for Moderno (Rangos, Multiples y Referencias)\n", .{});

    // 1. Iterar sobre un rango puro (muy usado en Zig 0.16 en lugar de while)
    try stdout.print("  [for con rangos puros 0..3]: ", .{});
    for (0..3) |idx| {
        try stdout.print("{d} ", .{idx});
    }
    try stdout.print("\n", .{});

    // 2. Iteracion paralela de multiples arrays + Indice
    const nombres = [_][]const u8{ "Alice", "Bob" };
    const edades = [_]u8{ 25, 30 };

    try stdout.print("  [for paralelo]:\n", .{});
    for (nombres, edades, 0..) |nombre, edad, idx| {
        try stdout.print("    - ID:{d} -> {s} tiene {d} anos.\n", .{ idx, nombre, edad });
    }

    // 3. Modificacion in-place (Pasar por referencia)
    // En lugar de iterar por valor, usamos `*item` para obtener un puntero
    var datos = [_]i32{ 1, 2, 3 };
    for (&datos) |*item| {
        item.* *= 10; // Desreferenciamos para modificar el valor subyacente
    }

    // El formateador {any} es un truco magico para imprimir slices enteros facilmente
    try stdout.print("  [for por referencia - datos multiplicados]: {any}\n\n", .{datos});
}

// -------------------------------------------------------------------------
// MODULO 3: BUCLES ANIDADOS (LABELS, BREAK Y CONTINUE)
// -------------------------------------------------------------------------
fn modulo3BuclesAnidados(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Bucles Anidados con Etiquetas\n", .{});

    var fila: usize = 0;

    // Etiquetamos el bucle exterior
    matriz_loop: while (fila < 3) : (fila += 1) {
        for (0..3) |col| {
            // continue :etiqueta => Cancela el ciclo actual y salta al (fila += 1) exterior
            if (fila == 0 and col == 1) {
                try stdout.print("    [Continue] Saltando fila 0, col 1...\n", .{});
                continue :matriz_loop;
            }

            // break :etiqueta => Mata el bucle exterior por completo
            if (fila == 2) {
                try stdout.print("    [Break] Rompiendo todo desde la fila 2!\n", .{});
                break :matriz_loop;
            }

            try stdout.print("  Procesando Fila:{d} Col:{d}\n", .{ fila, col });
        }
    }
    try stdout.print("\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 4: BUCLES COMO EXPRESIONES CON `else`
// -------------------------------------------------------------------------
fn modulo4BuclesComoExpresiones(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Bucles con else como Expresiones\n", .{});

    const lista = [_]i32{ 15, 23, 42, 8, 90 };
    const objetivo: i32 = 42;

    // 1. for...else
    // Si encuentra el 42, hace 'break true'.
    // Si el bucle termina sin encontrarlo, evalua el 'else' y devuelve 'false'.
    const encontrado = for (lista) |item| {
        if (item == objetivo) break true;
    } else false;

    try stdout.print("  Numero {d} encontrado en la lista? {s}\n", .{ objetivo, if (encontrado) "SI" else "NO" });

    // 2. while...else
    // Funciona igual, excelente para busquedas y validaciones rapidas.
    const condicion = false;
    const codigo_estado = while (condicion) {
        break @as(u32, 200);
    } else @as(u32, 404); // Como condicion es falsa, ni entra y devuelve 404

    try stdout.print("  Codigo resultante del while...else: {d}\n\n", .{codigo_estado});
}

// -------------------------------------------------------------------------
// MODULO 5: BUCLES INLINE (DESENROLLADOS POR EL COMPILADOR)
// -------------------------------------------------------------------------
fn modulo5BuclesInline(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: inline for (Reflexion y Tuplas)\n", .{});

    // Una tupla mezcla varios tipos (i32, f64, bool, array de bytes)
    const tupla_heterogenea = .{ @as(i32, 10), @as(f64, 3.14), true, "Texto" };

    // Un bucle normal fallaria porque un iterador comun solo soporta 1 tipo fijo.
    // 'inline for' ordena al compilador que escriba 4 veces el cuerpo del bucle,
    // uno para cada tipo detectado. Es metaprogramacion pura.
    inline for (tupla_heterogenea) |item| {
        try stdout.print("  Valor: {any:<6} | Tipo real en Zig: {s}\n", .{ item, @typeName(@TypeOf(item)) });
    }
}
