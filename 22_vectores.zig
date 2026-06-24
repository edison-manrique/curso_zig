// =========================================================================
// MASTERCLASS: VECTORES Y HARDWARE SIMD (EDICION ZIG 0.16.0)
// =========================================================================
// En Zig, un Vector no es un arreglo dinamico (como std::vector en C++).
// Un Vector en Zig es una abstraccion directa para hardware SIMD
// (Single Instruction, Multiple Data). Permite operar grupos de booleanos,
// enteros, flotantes o punteros EN PARALELO usando una sola instruccion de CPU.
//
// Todo el codigo e instrucciones estan disenados en ASCII puro (7-bit)
// para maxima compatibilidad con cualquier consola y editor del mundo.
//
// CONTENIDO DE LA MASTERCLASS:
// Modulo 1: Creacion basica y Operaciones Matematicas (Element-wise).
// Modulo 2: Escalares vs Vectores: Conversiones con @splat y @reduce.
// Modulo 3: Conversiones e Interoperabilidad (Vectores, Arrays y Slices).
// Modulo 4: Destructuracion de Vectores (Extraccion rapida de elementos).
// =========================================================================

const std = @import("std");

// ZIG 0.16.0 JUICY MAIN: El nuevo estandar de entrada con inyeccion de dependencias
pub fn main(init: std.process.Init) !void {
    // Obtenemos el subsistema de I/O inyectado por el entorno
    const io = init.io;

    // Inicializamos un buffer de escritura de alto rendimiento para stdout
    var buffer: [16384]u8 = undefined;

    // Usamos el nuevo std.Io (Notar la 'I' mayuscula del nuevo subsistema 0.16.0)
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Aseguramos que la consola reciba todo el contenido al finalizar
    defer stdout.flush() catch {};

    try stdout.print("====================================================\n", .{});
    try stdout.print("     MASTERCLASS: VECTORES (SIMD) EN ZIG 0.16.0     \n", .{});
    try stdout.print("====================================================\n\n", .{});

    try modulo1CreacionYOperaciones(stdout);
    try modulo2SplatYReduce(stdout);
    try modulo3ArraysSlicesYMemoria(stdout);
    try modulo4DestructuracionYExtraccion(stdout);

    try stdout.print("\n====================================================\n", .{});
    try stdout.print("     FIN DE LA MASTERCLASS - COMPILADO CON EXITO     \n", .{});
    try stdout.print("====================================================\n", .{});
}

// =========================================================================
// MODULO 1: CREACION Y OPERACIONES ELEMENT-WISE
// =========================================================================
fn modulo1CreacionYOperaciones(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Uso Basico y Matematicas Paralelas\n", .{});

    // Los vectores se crean con la funcion builtin @Vector(longitud, Tipo)
    const a = @Vector(4, i32){ 1, 2, 3, 4 };
    const b = @Vector(4, i32){ 5, 6, 7, 8 };

    // MAGIA SIMD: Esta suma no ocurre en un bucle for.
    // Si la CPU lo soporta (ej. SSE/AVX), suma los 4 elementos en un solo ciclo de reloj.
    const c = a + b;

    // Se puede acceder a elementos individuales con sintaxis de array
    try stdout.print("  Suma Vectorial: [{d}, {d}, {d}, {d}]\n", .{ c[0], c[1], c[2], c[3] });

    // Operadores logicos retornan un Vector de booleanos
    const d: @Vector(4, bool) = a < b;
    try stdout.print("  Comparacion (a < b): [{any}, {any}, {any}, {any}]\n\n", .{ d[0], d[1], d[2], d[3] });

    // NOTA: Para vectores de bools, los operadores 'and' y 'or' ESTAN PROHIBIDOS
    // porque afectan el flujo de control. Se deben usar operadores bitwise (&, |).
}

// =========================================================================
// MODULO 2: ESCALARES VS VECTORES (@splat y @reduce)
// =========================================================================
fn modulo2SplatYReduce(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Interacciones con Escalares (@splat y @reduce)\n", .{});

    const vec_base = @Vector(4, f32){ 1.0, 2.0, 3.0, 4.0 };

    // ERROR COMUN: vec_base * 10.0 -> Prohibido mezclar escalares y vectores directamente.

    // CORRECTO: Usamos @splat para "esparcir" el escalar en un vector completo
    const multiplicador: @Vector(4, f32) = @splat(10.0);
    const vec_multiplicado = vec_base * multiplicador;

    // @reduce colapsa un vector a un solo escalar aplicando una operacion
    // En este caso, sumamos todos los elementos del vector (.Add)
    const suma_total = @reduce(.Add, vec_multiplicado);

    try stdout.print("  Vector Original: [{d:.1}, {d:.1}, {d:.1}, {d:.1}]\n", .{ vec_base[0], vec_base[1], vec_base[2], vec_base[3] });
    try stdout.print("  Multiplicado x10: [{d:.1}, {d:.1}, {d:.1}, {d:.1}]\n", .{ vec_multiplicado[0], vec_multiplicado[1], vec_multiplicado[2], vec_multiplicado[3] });
    try stdout.print("  Reduccion (Suma total): {d:.1}\n\n", .{suma_total});
}

// =========================================================================
// MODULO 3: VECTORES, ARRAYS Y SLICES (CONVERSIONES)
// =========================================================================
fn modulo3ArraysSlicesYMemoria(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Conversiones (Arrays, Slices y Memoria)\n", .{});

    // 1. Arrays y Vectores pueden coercionarse mutuamente de forma implicita
    const arreglo: [4]f32 = [_]f32{ 1.1, 3.2, 4.5, 5.6 };
    const vector_desde_array: @Vector(4, f32) = arreglo;
    const array_desde_vector: [4]f32 = vector_desde_array;

    try stdout.print("  Coercion directa Array <-> Vector exitosa. Elemento 0: {d:.1}\n", .{array_desde_vector[0]});

    // 2. Extraer vectores desde un Slice de memoria
    const slice: []const f32 = &arreglo;

    // offset_dinamico simula un valor que no se conoce hasta tiempo de ejecucion
    var offset_dinamico: u32 = 1;
    _ = &offset_dinamico; // Suprimimos el warning de 'var nunca mutada'

    // MAGIA: Para sacar un vector de un slice dinamico, primero extraemos
    // un sub-slice desde el offset, lo limitamos a una longitud comptime [0..2]
    // y aplicamos desreferencia .* para copiar la memoria al Vector.
    const vector_desde_slice: @Vector(2, f32) = slice[offset_dinamico..][0..2].*;

    try stdout.print("  Vector extraido dinamicamente: [{d:.1}, {d:.1}]\n", .{ vector_desde_slice[0], vector_desde_slice[1] });

    // REGLAS CRITICAS DE MEMORIA EN ZIG:
    // - Los Arrays tienen una disposicion de BYTES garantizada en memoria.
    // - Los Vectores NO (dependen del hardware SIMD subyacente).
    // -> Usar @ptrCast entre Arrays y Vectores es COMPORTAMIENTO ILEGAL (Illegal Behavior).
    // -> Usar @bitCast SI ES VALIDO y seguro (la coercion lo hace implicitamente).
    try stdout.print("  Regla de oro: NUNCA usar @ptrCast entre Arrays y Vectores.\n\n", .{});
}

// =========================================================================
// MODULO 4: DESTRUCTURACION DE VECTORES
// =========================================================================
// Ejemplo de swizzling avanzado emulando la instruccion 'punpckldq'
fn desempacar(x: @Vector(4, f32), y: @Vector(4, f32)) @Vector(4, f32) {
    // Al igual que los arrays, los vectores soportan destructuracion.
    // Usamos '_' para descartar los valores que no nos interesan.
    const a, const c, _, _ = x;
    const b, const d, _, _ = y;

    // Retornamos un nuevo vector intercalando los elementos extraidos
    return .{ a, b, c, d };
}

fn modulo4DestructuracionYExtraccion(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Destructuracion de Vectores\n", .{});

    const v1: @Vector(4, f32) = .{ 1.0, 2.0, 3.0, 4.0 };
    const v2: @Vector(4, f32) = .{ 5.0, 6.0, 7.0, 8.0 };

    const resultado = desempacar(v1, v2);

    try stdout.print("  Vector 1: [{d:.1}, {d:.1}, {d:.1}, {d:.1}]\n", .{ v1[0], v1[1], v1[2], v1[3] });
    try stdout.print("  Vector 2: [{d:.1}, {d:.1}, {d:.1}, {d:.1}]\n", .{ v2[0], v2[1], v2[2], v2[3] });

    // El resultado deberia ser la intercalacion de los primeros elementos: { 1, 5, 2, 6 }
    try stdout.print("  Desempacado (Destructuracion): [{d:.1}, {d:.1}, {d:.1}, {d:.1}]\n\n", .{ resultado[0], resultado[1], resultado[2], resultado[3] });

    try stdout.print("  (Otras builtins avanzadas de Vectores incluyen @shuffle y @select)\n", .{});
}
