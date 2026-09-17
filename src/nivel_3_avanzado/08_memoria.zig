// =========================================================================
// MASTERCLASS 8: GESTION DE MEMORIA Y ALLOCATORS (EDICION ZIG 0.16)
// =========================================================================

// Zig no tiene Recolector de Basura (Garbage Collector) ni un "malloc" oculto.
// La memoria dinamica siempre es explicita. Si una funcion necesita memoria,
// TU debes proveerle la herramienta (Allocator) para obtenerla.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Donde estan los bytes? (Stack vs Data Section vs Heap).
// 2. Creacion vs Asignacion: create(*T) vs alloc([]T).
// 3. DebugAllocator: El nuevo estandar de Zig 0.16 que reemplaza a GPA.
// 4. FixedBufferAllocator (FBA): Asignacion ultra-rapida sin usar el SO.
// 5. ArenaAllocator: El patron supremo para Videojuegos y Servidores Web.
// 6. El error de memoria obligatorio: error.OutOfMemory.
// 7. Proyecto Final: Simulador de Servidor Web con Arenas.

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [8192]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE MEMORIA EN ZIG ---\n\n", .{});

    try modulo1DondeEstanLosBytes(stdout);
    try modulo2DebugAllocator(stdout);
    try modulo3FixedBufferAllocator(stdout);
    try modulo4ArenaAllocator(stdout);
    try modulo5ProyectoWeb(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE MEMORIA ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: ¿DONDE ESTAN LOS BYTES? (DATA SECTION VS STACK)
// -------------------------------------------------------------------------
fn modulo1DondeEstanLosBytes(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Donde estan los bytes?\n", .{});

    // 1. GLOBAL CONSTANT DATA SECTION
    // Los literales de texto existen en el propio binario compilado (.rodata).
    // Su tamano es conocido al compilar y NUNCA se liberan (viven para siempre).
    const texto_estatico: []const u8 = "Hola Mundo";

    // 2. STACK (LA PILA)
    // Memoria pre-reservada por el hilo. Es ultra-rapida, pero limitada (ej. 8MB).
    // Se limpia automaticamente al salir de la funcion (return).
    var buffer_stack: [100]u8 = undefined;

    // Copiamos datos del binario a nuestra memoria local (Stack)
    @memcpy(buffer_stack[0..texto_estatico.len], texto_estatico);

    try stdout.print("  Texto original (Data Section): {s}\n", .{texto_estatico});
    try stdout.print("  Copia mutable (Stack): {s}\n\n", .{buffer_stack[0..texto_estatico.len]});
}

// -------------------------------------------------------------------------
// MODULO 2: DEBUG ALLOCATOR (HEAP)
// -------------------------------------------------------------------------
// Cuando no sabemos cuanta memoria usaremos en tiempo de ejecucion,
// la pedimos al Sistema Operativo (Heap) usando DebugAllocator.
fn modulo2DebugAllocator(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Debug Allocator (Deteccion de Fugas)\n", .{});

    // En Zig 0.16.0, 'DebugAllocator' reemplaza al antiguo 'GeneralPurposeAllocator'.
    // Al llamar a 'deinit()', este informara automaticamente de cualquier fuga en la consola.
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // A. alloc / free (Para Slices / Multiples elementos)
    // El 'try' es obligatorio porque pedir memoria puede fallar (OutOfMemory)
    const array_dinamico = try allocator.alloc(u32, 5);
    defer allocator.free(array_dinamico); // ¡Regla de oro: Quien reserva, libera!

    for (array_dinamico, 0..) |*item, i| item.* = @as(u32, @intCast(i * 10));

    // B. create / destroy (Para Un Solo elemento)
    const puntero_entero = try allocator.create(i32);
    defer allocator.destroy(puntero_entero);
    puntero_entero.* = 999;

    try stdout.print("  Slice Dinamico allocado: {any}\n", .{array_dinamico});
    try stdout.print("  Puntero Individual creado: {d}\n\n", .{puntero_entero.*});
}

// -------------------------------------------------------------------------
// MODULO 3: FIXED BUFFER ALLOCATOR (FBA)
// -------------------------------------------------------------------------
// Si sabes el limite maximo de memoria que usaras, puedes evitar por completo
// el costoso Heap del Sistema Operativo. FBA envuelve un array en un Allocator.
// IDEAL PARA: Sistemas Embebidos, Arduino, Kernel Dev o mods de juegos.
fn modulo3FixedBufferAllocator(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Fixed Buffer Allocator (Sin Sistema Operativo)\n", .{});

    // 1. Reservamos un bloque de memoria estatico en el Stack (1 Kilobyte)
    var memoria_stack: [1024]u8 = undefined;

    // 2. Le decimos al FBA que administre ese array de 1024 bytes
    var fba = std.heap.FixedBufferAllocator.init(&memoria_stack);
    const allocator = fba.allocator();

    // 3. Ahora podemos usar funciones de "alloc" que en realidad consumen el Stack
    const texto_generado = try std.fmt.allocPrint(allocator, "El valor es: {d}", .{42});

    // No necesitamos llamar a `free()` obligatoriamente aqui, porque `memoria_stack`
    // sera destruida por el compilador al salir de esta funcion.

    try stdout.print("  Texto formateado usando memoria del Stack: '{s}'\n\n", .{texto_generado});
}

// -------------------------------------------------------------------------
// MODULO 4: ARENA ALLOCATOR (LA ARMA SECRETA DE ZIG)
// -------------------------------------------------------------------------
// Una Arena agrupa multiples allocations en un solo bloque, y al final,
// borra TODO el bloque en 1 sola operacion rapida O(1).
fn modulo4ArenaAllocator(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Arena Allocator (Asignacion por Lotes)\n", .{});

    // Usamos el allocator basico de paginas del SO como base para la Arena
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    // MAGIC: Esto destruira TODOS los datos creados dentro de la arena de una sola vez.
    defer arena.deinit();

    const allocator = arena.allocator();

    // Podemos hacer multiples allocs sin requerir escribir un solo defer por cada variable.
    const nodo1 = try allocator.create(u64);
    const nodo2 = try allocator.create(u64);
    const arreglo_temporal = try allocator.alloc(f32, 1000);

    nodo1.* = 10;
    nodo2.* = 20;
    arreglo_temporal[0] = 3.14;

    try stdout.print("  Memoria masiva asignada en Arena sin llamar a 'free'.\n", .{});
    try stdout.print("  (Se liberara instantaneamente al salir de este modulo)\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 5: PROYECTO - SIMULADOR DE SERVIDOR WEB
// -------------------------------------------------------------------------
// Al usar una Arena por Peticion, garantizamos 0% memory leaks y velocidad maxima.

const Peticion = struct {
    id: u32,
    ruta: []const u8,
};

fn procesarPeticionWeb(req: Peticion, base_allocator: std.mem.Allocator, stdout: anytype) !void {
    // 1. Creamos una Arena especifica para esta request individual
    var arena_request = std.heap.ArenaAllocator.init(base_allocator);

    // 2. Liberamos todo el contexto de la Request al terminar
    defer arena_request.deinit();
    const req_allocator = arena_request.allocator();

    // 3. Simulamos generar una respuesta compleja (consultas, strings dinamicos, etc)
    const nombre_usuario = try std.fmt.allocPrint(req_allocator, "User_{d}", .{req.id});
    const respuesta_html = try std.fmt.allocPrint(req_allocator, "<h1>Hola {s}, visitaste {s}</h1>", .{ nombre_usuario, req.ruta });

    try stdout.print("    [Log] Procesada Req {d} -> Respuesta generada ({d} bytes)\n", .{ req.id, respuesta_html.len });
}

fn modulo5ProyectoWeb(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Proyecto - Servidor Web con Request Arenas\n", .{});

    // El servidor principal usa un DebugAllocator para el ciclo de vida del proceso
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const base_allocator = gpa.allocator();

    const trafico = [_]Peticion{
        .{ .id = 1, .ruta = "/inicio" },
        .{ .id = 2, .ruta = "/perfil" },
        .{ .id = 3, .ruta = "/configuracion" },
    };

    // Procesamos cada Request en un bucle
    for (trafico) |req| {
        try procesarPeticionWeb(req, base_allocator, stdout);
    }

    try stdout.print("  Todas las peticiones procesadas y su memoria purgada del sistema.\n", .{});
}
