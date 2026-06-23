// =========================================================================
// MASTERCLASS: TIEMPOS DE VIDA Y CICLOS DE MEMORIA (EDICION ZIG 0.16.0)
// =========================================================================
// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.

// Rust confia en anotaciones de tiempos de vida ('a, Lifetimes) para asegurar
// en tiempo de compilacion que no existan referencias colgantes (Dangling Pointers).

// Zig no tiene borrow checker ni anotaciones de ciclo de vida. Toda la seguridad
// recae en el diseno explicito y la disciplina del programador:
// 1. Stack Allocation: Las variables declaradas dentro de una funcion viven
//    mientras el bloque de la funcion este activo. ¡NUNCA retornes un puntero a ellas!
// 2. Heap Allocation: Las variables viven indefinidamente hasta que el programador
//    llame explicitamente a 'allocator.free' o 'allocator.destroy'.

// CONCEPTOS CLAVE:
// 1. El ciclo de vida de la pila (Stack Frame Lifetimes).
// 2. El peligro de retornar punteros locales (Dangling Pointers en Stack).
// 3. El ciclo de vida de objetos en Heap y prevencion de fugas.
// 4. Patrones seguros de retorno de datos.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Inicializamos buffer de escritura de alta performance para stdout
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Liberamos el flujo de salida al finalizar el programa
    defer stdout.flush() catch {};

    // En Zig 0.16.0, DebugAllocator es el estandar para rastreo de memoria en desarrollo
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try stdout.print("--- INICIO DE LA MASTERCLASS DE LIFETIMES IN ZIG ---\n\n", .{});

    try modulo1StackLifetime(stdout);
    try modulo2DanglingHeap(allocator, stdout);
    try modulo3RetornoSeguro(allocator, stdout);

    try stdout.print("--- FIN DE LA MASTERCLASS DE LIFETIMES ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: CICLO DE VIDA DE LA PILA (STACK)
// -------------------------------------------------------------------------
// Cada llamada a una funcion reserva una porcion de memoria llamada Stack Frame.
// Al retornar de la funcion, esa memoria se libera. Retornar un puntero a una
// variable local es un error de compilacion directo detectado por el compilador.

// fn obtenerPunteroInvalido() *const i32 {
//     const numero: i32 = 42;
//     return &numero; // -> ERROR DE COMPILACION: pointer to local variable
// }

// PATRON SEGURO: Down-Passing (Pasar punteros hacia abajo en la pila)
// Es 100% seguro pasar la direccion de una variable local a funciones secundarias,
// ya que el frame de la funcion padre permanece activo en la pila.
fn modificarValorEnPila(ptr: *i32) void {
    ptr.* = 999;
}

fn modulo1StackLifetime(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Ciclo de Vida en la Pila (Stack Frame)\n", .{});

    var valor_local: i32 = 10;
    try stdout.print("  Valor inicial en la pila de main: {d}\n", .{valor_local});

    // Pasamos el puntero hacia abajo de forma segura
    modificarValorEnPila(&valor_local);
    try stdout.print("  Valor modificado de forma segura por funcion hija: {d}\n", .{valor_local});

    try stdout.print("  [OK] El compilador de Zig impide de forma estricta el retorno de punteros locales.\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 2: REFERENCIAS COLGANTES EN EL HEAP (DANGLING POINTERS)
// -------------------------------------------------------------------------
// Si liberamos la memoria de un objeto en el heap y luego intentamos seguir
// usando el puntero que apuntaba a el, creamos una referencia colgante.
fn modulo2DanglingHeap(allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Referencias Colgantes en Heap (Dangling Pointers)\n", .{});

    const ptr = try allocator.create(i32);
    ptr.* = 12345;

    try stdout.print("  Memoria reservada en Heap. Valor asignado: {d}\n", .{ptr.*});

    // Liberamos la memoria del objeto
    allocator.destroy(ptr);

    // ptr.* = 777;
    // ¡ERROR DE USO DESPUES DE LIBERAR (Use-After-Free)!
    // Si descomentas la linea de arriba, DebugAllocator detectara de forma
    // automatica el acceso a memoria liberada y provocara un panic de seguridad.

    try stdout.print("  [OK] Memoria destruida. El puntero ha sido invalidado correctamente.\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 3: PATRONES SEGUROS DE RETORNO DE DATOS
// -------------------------------------------------------------------------
// Al no poseer un recolector de basura, Zig implementa dos patrones de diseno
// seguros para devolver informacion compleja desde funciones:
// 1. Asignar en Heap (el llamante asume de forma explicita la responsabilidad de liberar).
// 2. Pasando un buffer preasignado por el llamante (out-parameter, evita allocs).
fn modulo3RetornoSeguro(allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Patrones Seguros de Retorno de Datos\n", .{});

    // Patron 1: Asignar en Heap (El receptor debe liberar)
    const texto_heap = try crearMensajeHeap(allocator, "Arthur");
    defer allocator.free(texto_heap);

    // Patron 2: Pasar buffer de salida (Out-Parameter, libre de allocations)
    var buffer_salida: [64]u8 = undefined;
    const texto_estatico = try escribirMensajeBuffer(&buffer_salida, "Zaphod");

    // Imprimimos directamente usando el formateador del escritor del sistema
    try stdout.print("  Heap: {s}\n", .{texto_heap});
    try stdout.print("  Buffer Local (Out-Parameter): {s}\n\n", .{texto_estatico});
}

// Retorna un slice en heap que debe ser liberado
fn crearMensajeHeap(allocator: std.mem.Allocator, nombre: []const u8) ![]u8 {
    return try std.fmt.allocPrint(allocator, "Hola {s} desde el Heap!", .{nombre});
}

// Llena un buffer provisto por el llamante (evita allocs)
fn escribirMensajeBuffer(buffer: []u8, nombre: []const u8) ![]const u8 {
    return try std.fmt.bufPrint(buffer, "Hola {s} desde el Buffer local!", .{nombre});
}
