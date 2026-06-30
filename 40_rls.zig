// =========================================================================
// MASTERCLASS 40: RESULT LOCATION SEMANTICS (EDICION ZIG 0.16)
// =========================================================================

// En Zig, la inferencia de tipos y la asignacion de memoria no son detalles
// de implementacion, son parte fundamental de la especificacion del lenguaje.
// A este sistema se le conoce como "Result Location Semantics" (Semantica
// de Ubicacion de Resultados).

// Durante la compilacion, a cada expresion se le asigna opcionalmente:
// 1. Result Type: Que tipo deberia tener la expresion.
// 2. Result Location: En que direccion de memoria exacta debe escribirse.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Result Types y su propagacion recursiva.
// 2. Uso de builtins dependientes del contexto (@intCast, @as).
// 3. Result Locations y la eliminacion de copias intermedias.
// 4. El "Desugaring" de constructores de structs/arrays.
// 5. El peligro de hacer Swap (intercambio) con inicializadores.

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

    try stdout.print("--- MASTERCLASS: RESULT LOCATION SEMANTICS ---\n\n", .{});

    try modulo1ResultTypes(stdout);
    try modulo2BuiltinsYPropagacion(stdout);
    try modulo3ResultLocationsYOptimizacion(stdout);
    try modulo4ElPeligroDelSwap(stdout);
    try modulo5ReglasDePropagacion(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: RESULT TYPES Y PROPAGACION RECURSIVA
// -------------------------------------------------------------------------
fn modulo1ResultTypes(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Result Types y Propagacion\n", .{});

    // En esta simple linea ocurren varias cosas invisibles:
    // El tipo 'u32' (Result Type) se propaga hacia la derecha.
    // El literal '42' (inicialmente comptime_int) sabe que debe ser u32.
    const x: u32 = 42;

    const S = struct { valor: u32 };
    const val_grande: u64 = 123;

    // AQUI OCURRE LA MAGIA DE LA PROPAGACION RECURSIVA:
    // 1. .{ ... } recibe el Result Type 'S' por la anotacion de la variable.
    // 2. @intCast(val_grande) recibe el Result Type 'u32' porque el campo
    //    S.valor es de tipo u32.
    // 3. 'val_grande' en si no tiene Result Type asignado aqui (puede ser
    //    cualquier entero para @intCast).
    const s: S = .{ .valor = @intCast(val_grande) };

    try stdout.print("  Valor x: {d}\n", .{x});
    try stdout.print("  Struct propagado s.valor: {d}\n\n", .{s.valor});
}

// -------------------------------------------------------------------------
// MODULO 2: BUILTINS DEPENDIENTES DEL CONTEXTO
// -------------------------------------------------------------------------
fn modulo2BuiltinsYPropagacion(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Builtins y el uso de @as\n", .{});

    const valor_original: u16 = 500;

    // @intCast no recibe un tipo como argumento. Sabe a que tipo castear
    // gracias al Result Type que le impone la variable (u32).
    const valor_casteado: u32 = @intCast(valor_original);

    // Que pasa si no hay un Result Type desde el contexto?
    // Usamos @as() para inyectar manualmente un Result Type hacia adentro.
    // Aqui @as inyecta 'u8' hacia @intCast.
    const valor_explicito = @as(u8, @intCast(valor_original / 10));

    try stdout.print("  Casteo implicito (por contexto): {d}\n", .{valor_casteado});
    try stdout.print("  Casteo explicito (via @as): {d}\n\n", .{valor_explicito});
}

// -------------------------------------------------------------------------
// MODULO 3: RESULT LOCATIONS Y OPTIMIZACION DE MEMORIA
// -------------------------------------------------------------------------
const Coordenada = struct { x: i32, y: i32 };

fn modulo3ResultLocationsYOptimizacion(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Result Locations y Cero Copias\n", .{});

    var destino: Coordenada = undefined;

    // En otros lenguajes, esto crearia un struct temporal en la pila (stack)
    // y luego lo copiaria bit a bit dentro de 'destino'.
    //
    // EN ZIG: 'destino' provee su direccion de memoria (&destino) como
    // "Result Location". La expresion de la derecha escribe DIRECTAMENTE ahi.
    destino = .{ .x = 10, .y = 20 };

    // Literalmente el compilador lo "desugara" (transforma) a esto:
    // destino.x = 10;
    // destino.y = 20;

    try stdout.print("  Destino modificado in-place: X={d}, Y={d}\n", .{ destino.x, destino.y });
    try stdout.print("  (Cero copias temporales en memoria!)\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 4: EL PELIGRO DEL SWAP Y EL DESUGARING
// -------------------------------------------------------------------------
fn modulo4ElPeligroDelSwap(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: El Peligro de Swap por Result Locations\n", .{});

    var arr: [2]u32 = .{ 1, 2 };

    try stdout.print("  Arreglo original: [{d}, {d}]\n", .{ arr[0], arr[1] });

    // CUIDADO: La intuicion nos dice que esto invertira los elementos.
    arr = .{ arr[1], arr[0] };

    // PERO por las reglas de Result Location, esto no crea un array temporal.
    // Se desugara directamente a:
    // arr[0] = arr[1]; // arr[0] ahora vale 2
    // arr[1] = arr[0]; // arr[1] copia el NUEVO valor de arr[0] (que es 2!)

    try stdout.print("  Arreglo tras intento de Swap: [{d}, {d}]  <-- SORPRESA!\n", .{ arr[0], arr[1] });
    try stdout.print("  (Esto falla logica pero es correcto segun la semantica)\n\n", .{});

    // NOTA: Para hacer un swap real sin errores, usa una variable temporal
    // o std.mem.swap(&arr[0], &arr[1]);
}

// -------------------------------------------------------------------------
// MODULO 5: REGLAS DE PROPAGACION (SINTAXIS)
// -------------------------------------------------------------------------
fn modulo5ReglasDePropagacion(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Como se propagan las Locations\n", .{});

    var ptr_ejemplo: Coordenada = undefined;

    // EXPRESION         | RESULT LOCATION de 'sub_exp'
    // -----------------------------------------------------------
    // var val = x       | x tiene location &val
    // &x                | x NO tiene location (se toma su ref real)
    // .{x}              | x tiene location &ptr[0]
    // T{x} (Tipado)     | x NO tiene location (rompe la cadena)

    // Ejemplo de inicializador tipado (Coordenada{...}) vs no tipado (.{...}):

    // NO TIPADO: Propaga el Result Location (&ptr_ejemplo).
    // Escribe directo.
    ptr_ejemplo = .{ .x = 1, .y = 2 };

    // TIPADO: NO propaga el Result Location hacia adentro.
    // Obliga a construir en temporal y luego copiar.
    ptr_ejemplo = Coordenada{ .x = 3, .y = 4 };

    try stdout.print("  Las inicializaciones no tipadas ( .{{}} ) son mas\n", .{});
    try stdout.print("  eficientes al anidarse porque no rompen la cadena\n", .{});
    try stdout.print("  de Result Locations.\n\n", .{});
}
