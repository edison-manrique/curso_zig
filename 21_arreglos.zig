// =========================================================================
// MASTERCLASS 6: ARREGLOS, MATRICES Y DESTRUCTURACION (EDICION ZIG 0.16)
// =========================================================================

// En Zig, los Arrays (arreglos) son secuencias de longitud fija que se
// conocen en tiempo de compilacion (comptime). Son la estructura base
// para el manejo de multiples datos de forma continua y predecible.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Inicializacion, Literales y Deduccion de Tamano ([_]).
// 2. Iteracion y Mutabilidad (For loops y Punteros a elementos).
// 3. Operadores en Tiempo de Compilacion (++ Concatenacion y ** Repeticion).
// 4. Bloques Comptime e Inicializacion Avanzada (Funciones/Loops internos).
// 5. Arreglos Multidimensionales (Matrices).
// 6. Arreglos Terminados por Centinela (Sentinel-Terminated Arrays).
// 7. Destructuracion de Arreglos (Swizzling y Extraccion directa).

// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [8192]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE ARRAYS EN ZIG ---\n\n", .{});

    try modulo1InicializacionYLiterales(stdout);
    try modulo2IteracionYMutabilidad(stdout);
    try modulo3OperadoresComptime(stdout);
    try modulo4InicializacionAvanzada(stdout);
    try modulo5Multidimensionales(stdout);
    try modulo6TerminadosPorCentinela(stdout);
    try modulo7Destructuracion(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE ARRAYS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: INICIALIZACION, LITERALES Y TAMAÑO
// -------------------------------------------------------------------------
fn modulo1InicializacionYLiterales(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Inicializacion y Literales\n", .{});

    // Zig puede deducir el tamano del arreglo con [_]
    const mensaje = [_]u8{ 'h', 'o', 'l', 'a' };

    // Inicializacion alternativa declarando el tipo explicito
    const mensaje_alt: [4]u8 = .{ 'h', 'o', 'l', 'a' };

    // Un string literal ("...") no es mas que un puntero a un arreglo subyacente
    const mensaje_string = "hola";

    try stdout.print("  Longitud de 'mensaje': {d} elementos\n", .{mensaje.len});

    // Comprobamos la igualdad de los contenidos en memoria
    const es_igual = std.mem.eql(u8, &mensaje, &mensaje_alt);
    const es_igual_string = std.mem.eql(u8, &mensaje, mensaje_string);

    try stdout.print("  Es mensaje igual a mensaje_alt? {s}\n", .{if (es_igual) "SI" else "NO"});
    try stdout.print("  Es equivalente a un literal de string? {s}\n\n", .{if (es_igual_string) "SI" else "NO"});
}

// -------------------------------------------------------------------------
// MODULO 2: ITERACION Y MUTABILIDAD
// -------------------------------------------------------------------------
fn modulo2IteracionYMutabilidad(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Iteracion y Mutabilidad\n", .{});

    // Usamos 'undefined' cuando vamos a llenar la memoria despues.
    // Esto es muy comun en Zig para evitar sobrecostos de inicializacion.
    var enteros: [5]i32 = undefined;

    // Iteramos usando 0.. para obtener el indice y capturamos por referencia (*item)
    // para poder modificar el arreglo original.
    for (&enteros, 0..) |*item, i| {
        item.* = @intCast(i * 10);
    }

    try stdout.print("  Contenido mutado: ", .{});

    var suma: i32 = 0;
    // Iteramos por valor (solo lectura)
    for (enteros) |num| {
        suma += num;
        try stdout.print("{d} ", .{num});
    }

    try stdout.print("\n  Suma total de los elementos: {d}\n\n", .{suma});
}

// -------------------------------------------------------------------------
// MODULO 3: OPERADORES COMPTIME (++ Y **)
// -------------------------------------------------------------------------
fn modulo3OperadoresComptime(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Operadores Comptime (++ y **)\n", .{});

    // 1. Concatenacion (++)
    // Funciona unicamente si los valores se conocen en tiempo de compilacion
    const parte1 = [_]u32{ 1, 2 };
    const parte2 = [_]u32{ 3, 4 };
    const todos = parte1 ++ parte2;

    // 2. Concatenacion de Strings (ya que son arreglos por debajo)
    const saludo_completo = "Zig" ++ " " ++ "Mola";

    // 3. Repeticion (**)
    const patron = "ab" ** 3;
    const todo_ceros = [_]u8{0} ** 5; // Inicializa un arreglo de 5 elementos en 0

    try stdout.print("  Concatenacion Array (++): {any}\n", .{todos});
    try stdout.print("  Concatenacion String (++): {s}\n", .{saludo_completo});
    try stdout.print("  Repeticion String (**): {s}\n", .{patron});
    try stdout.print("  Todo Ceros (**): {any} (Tamano: {d})\n\n", .{ todo_ceros, todo_ceros.len });
}

// -------------------------------------------------------------------------
// MODULO 4: INICIALIZACION AVANZADA Y BLOQUES COMPTIME
// -------------------------------------------------------------------------
const Punto = struct {
    x: i32,
    y: i32,
};

fn crearPunto(multiplicador: i32) Punto {
    return .{ .x = multiplicador, .y = multiplicador * 2 };
}

fn modulo4InicializacionAvanzada(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Inicializacion Avanzada (Comptime)\n", .{});

    // Podemos usar un bloque de inicializacion para ejecutar logica
    // compleja en tiempo de compilacion y retornar el arreglo final.
    const puntos_calculados = init: {
        var temporal: [3]Punto = undefined;
        for (&temporal, 0..) |*pt, i| {
            pt.* = Punto{
                .x = @intCast(i),
                .y = @intCast(i * 10),
            };
        }
        break :init temporal;
    };

    // Tambien se pueden llamar funciones repetidas con **
    const puntos_repetidos = [_]Punto{crearPunto(5)} ** 2;

    try stdout.print("  Array via bloque 'init' -> Punto 2 (x: {d}, y: {d})\n", .{ puntos_calculados[2].x, puntos_calculados[2].y });

    try stdout.print("  Array via funcion con ** -> Punto 0 (x: {d}, y: {d})\n\n", .{ puntos_repetidos[0].x, puntos_repetidos[0].y });
}

// -------------------------------------------------------------------------
// MODULO 5: ARREGLOS MULTIDIMENSIONALES (MATRICES)
// -------------------------------------------------------------------------
fn modulo5Multidimensionales(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Arreglos Multidimensionales\n", .{});

    // Se crean anidando los tipos de array [filas][columnas]Tipo
    const matriz_2x3 = [2][3]f32{
        [_]f32{ 1.0, 0.5, 0.0 },
        [_]f32{ 0.0, 1.5, 9.9 },
    };

    // Inicializar una matriz a ceros de forma compacta
    const todo_cero: [3][3]u8 = .{.{0} ** 3} ** 3;

    try stdout.print("  matriz_2x3[1][2]: {d:.1}\n", .{matriz_2x3[1][2]});
    try stdout.print("  Matriz 3x3 generada en ceros: {any}\n", .{todo_cero});

    // Iteracion bidimensional
    try stdout.print("  Iterando la matriz: \n", .{});
    for (matriz_2x3, 0..) |fila, i| {
        try stdout.print("    Fila {d}: ", .{i});
        for (fila) |celda| {
            try stdout.print("{d:.1} ", .{celda});
        }
        try stdout.print("\n", .{});
    }
    try stdout.print("\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 6: ARREGLOS TERMINADOS POR CENTINELA
// -------------------------------------------------------------------------
fn modulo6TerminadosPorCentinela(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: Sentinel-Terminated Arrays ([N:x]T)\n", .{});

    // La sintaxis [_:0] indica que el array DEBE terminar en 0.
    // Muy util para interoperar con C-Strings sin perder la seguridad de Zig.
    const array_centinela = [_:0]u8{ 10, 20, 30, 40 };

    try stdout.print("  Tipo exacto: {any}\n", .{@TypeOf(array_centinela)});
    try stdout.print("  Longitud logica (.len): {d}\n", .{array_centinela.len});

    // Podemos acceder al indice 4 que esta fuera del '.len', y SIEMPRE sera el centinela (0)
    try stdout.print("  Valor centinela oculto (Indice 4): {d}\n\n", .{array_centinela[4]});
}

// -------------------------------------------------------------------------
// MODULO 7: DESTRUCTURACION DE ARREGLOS
// -------------------------------------------------------------------------
fn modulo7Destructuracion(stdout: anytype) !void {
    try stdout.print(">> Modulo 7: Destructuracion de Arreglos\n", .{});

    const posicion_2d = [_]i32{ 1920, 1080 };

    // Zig permite asignar los elementos de un array directamente a variables
    const x, const y = posicion_2d;

    try stdout.print("  Coordenadas extraidas: X = {d}, Y = {d}\n", .{ x, y });

    // Esto es muy util para funciones de 'swizzling' de colores o vectores
    const color_rgba: [4]u8 = .{ 255, 128, 64, 255 };
    const r, const g, const b, const a = color_rgba;

    try stdout.print("  Canales separados: R={d}, G={d}, B={d}, A={d}\n", .{ r, g, b, a });
}
