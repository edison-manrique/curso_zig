// =========================================================================
// MASTERCLASS 4: PUNTEROS, MEMORIA Y ALINEACION (EDICION ZIG 0.16.0)
// =========================================================================

// En Zig no existen referencias ocultas, todo paso por referencia se hace
// mediante punteros explicitos. A diferencia de C, Zig separa estrictamente
// los punteros que apuntan a un solo elemento de los que apuntan a multiples.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Single-Item Pointers (*T) vs Many-Item Pointers ([*]T).
// 2. Slices ([]T): Fat Pointers y la proteccion de Bounds Checking.
// 3. Aritmetica de Punteros: Solo permitida en Many-Item Pointers.
// 4. Casting y Conversiones: @ptrFromInt, @intFromPtr y std.mem.bytesAsSlice.
// 5. Pointers de C (Sentinel-Terminated [*:0]T) para interop nativa.
// 6. Atributos avanzados: volatile (MMIO), align (Alineacion) y allowzero.

const std = @import("std");

// ZIG 0.16.0: "Juicy Main" - Entrada explicita
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE PUNTEROS EN ZIG ---\n\n", .{});

    try modulo1PunterosBasicos(stdout);
    try modulo2AritmeticaYSlices(stdout);
    try modulo3CastingYConversiones(stdout);
    try modulo4PunterosCentinelaYC(stdout);
    try modulo5AlineacionYVolatile(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE PUNTEROS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: SINGLE-ITEM (*T) vs MANY-ITEM ([*]T)
// -------------------------------------------------------------------------
fn modulo1PunterosBasicos(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Single-Item y Many-Item Pointers\n", .{});

    // 1. Single-Item Pointer (*T)
    // Apunta exactamente a 1 elemento. NO soporta aritmetica (no puedes hacer ptr + 1)
    var valor: i32 = 1234;
    const ptr_unico: *i32 = &valor;

    // Para leer o escribir a traves del puntero, desreferenciamos con .*
    ptr_unico.* += 1;
    try stdout.print("  [Single-Item] Valor modificado via *T: {d}\n", .{ptr_unico.*});

    // 2. Many-Item Pointer ([*]T)
    // Apunta a un numero desconocido de elementos (como los punteros crudos de C).
    // Soporta indexacion (ptr[i]) y aritmetica (ptr + i).
    var arreglo = [_]u8{ 10, 20, 30, 40 };

    // Convertimos un puntero a arreglo (*[4]u8) a un Many-Item Pointer ([*]u8)
    const ptr_multiple: [*]u8 = &arreglo;

    try stdout.print("  [Many-Item] Elemento en indice 2: {d}\n\n", .{ptr_multiple[2]});
}

// -------------------------------------------------------------------------
// MODULO 2: SLICES (FAT POINTERS) Y ARITMETICA
// -------------------------------------------------------------------------
fn modulo2AritmeticaYSlices(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Slices y Aritmetica de Punteros\n", .{});

    var datos = [_]i32{ 100, 200, 300, 400 };

    // 1. Aritmetica de Punteros
    // SOLO permitida en [*]T.
    var ptr: [*]i32 = &datos;
    ptr += 1; // Avanza al siguiente i32 en memoria (suma 4 bytes reales)
    try stdout.print("  [Aritmetica] ptr avanzo 1 posicion. Valor actual: {d}\n", .{ptr[0]});

    // 2. Slices ([]T) - "Fat Pointers"
    // Un slice contiene 2 cosas (ocupa 16 bytes en 64-bits):
    // - Un puntero many-item subyacente ([*]T)
    // - Un campo de longitud (usize)
    const slice: []i32 = datos[1..4];

    try stdout.print("  [Slice] Longitud: {d}, Primer valor: {d}\n", .{ slice.len, slice[0] });

    // LOS SLICES SON SEGUROS: Tienen Bounds Checking!
    // Si hicieramos slice[5], Zig haria Panic y detendria el programa para evitar un exploit.
    try stdout.print("  (Nota: Slices son preferidos sobre [*]T por la proteccion de limites)\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 3: CASTING Y CONVERSIONES INT <-> PTR
// -------------------------------------------------------------------------
fn modulo3CastingYConversiones(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Casting y Direcciones Crudas\n", .{});

    // 1. Direcciones crudas (@ptrFromInt y @intFromPtr)
    // Utiles para drivers, sistemas operativos o interactuar con hardware.
    const direccion_fisica: usize = 0xDEADBEE0;

    // Convertir un numero a puntero (No lo desreferenciamos porque crashearia aqui)
    const ptr_hardware: *i32 = @ptrFromInt(direccion_fisica);

    // Convertir de puntero a numero
    const dir_recuperada = @intFromPtr(ptr_hardware);
    try stdout.print("  [Int<->Ptr] Memoria apuntada: 0x{X}\n", .{dir_recuperada});

    // 2. Pointer Casting (@ptrCast) vs Casting Seguro
    // Imagina que recibes 4 bytes por red y quieres leerlos como un u32
    // Debemos declarar el array explicitly aligned (alineado) para que el casting sea seguro.
    const bytes align(@alignOf(u32)) = [_]u8{ 0xAA, 0xBB, 0xCC, 0xDD };

    // METODO SEGURO: Usar std.mem en lugar de @ptrCast
    // std.mem.bytesAsSlice reinterpreta el slice de u8 a un slice de u32
    const slice_u32 = std.mem.bytesAsSlice(u32, bytes[0..]);

    try stdout.print("  [Casting Seguro] 4 bytes leidos como u32: 0x{X}\n\n", .{slice_u32[0]});
}

// -------------------------------------------------------------------------
// MODULO 4: PUNTEROS CENTINELA (C-STRINGS) Y ALLOWZERO
// -------------------------------------------------------------------------
fn modulo4PunterosCentinelaYC(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Sentinel-Terminated Pointers y allowzero\n", .{});

    // 1. Punteros Terminados por Centinela ([*:X]T)
    // En C, los strings no tienen longitud, terminan en un byte 0 (Null-terminated).
    // Zig representa esto nativamente con [*:0]u8, protegiendo contra Buffer Overflows.
    const c_string: [*:0]const u8 = "Hola Mundo C"; // Zig anade el \0 implicitamente

    var idx: usize = 0;
    while (c_string[idx] != 0) : (idx += 1) {} // Contar hasta el centinela

    try stdout.print("  [Centinela] C-String iterado manualmente. Longitud calculada: {d}\n", .{idx});

    // 2. Allowzero (*allowzero T)
    // En Sistemas Operativos (Freestanding), la direccion 0x0 de RAM puede existir y ser valida.
    // Para punteros nulos normales usamos Opcionales (?*T).
    // Pero si realmente queremos apuntar a la direccion cero, usamos allowzero.
    const cero: usize = 0;
    const ptr_cero: *allowzero i32 = @ptrFromInt(cero);
    try stdout.print("  [Allowzero] Puntero apuntando a la direccion absoluta: 0x{X}\n\n", .{@intFromPtr(ptr_cero)});
}

// -------------------------------------------------------------------------
// MODULO 5: ALINEACION Y VOLATILE (HARDWARE LEVEL)
// -------------------------------------------------------------------------
fn modulo5AlineacionYVolatile(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Alineacion de Memoria y Volatile\n", .{});

    // 1. Alineacion (Alignment)
    // La CPU es mas rapida (o solo funciona) si los datos se alinean en multiplos de bytes.
    // Un i32 por ejemplo, requiere alineacion de 4 bytes (@alignOf(i32) == 4).
    var x: i32 = 42;
    const direccion = @intFromPtr(&x);
    const alineacion = @alignOf(@TypeOf(x));

    try stdout.print("  [Align] Direccion de x: 0x{X}. Es multiplo de {d}? {s}\n", .{ direccion, alineacion, if (direccion % alineacion == 0) "SI" else "NO" });

    // @alignCast permite convertir un puntero poco alineado a uno muy alineado
    // (Asegurate de que realmente este alineado, o dara un Panic en runtime).
    var buffer_alineado align(8) = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 };
    const slice_u8 = buffer_alineado[0..];
    const slice_forzado_u64 = @as([]align(8) u8, @alignCast(slice_u8));
    _ = slice_forzado_u64; // Lo ignoramos, solo para demostrar validacion de tipos

    // 2. Volatile (*volatile T)
    // Usado EXCLUSIVAMENTE para Memory Mapped I/O (MMIO) al escribir Drivers.
    // Le dice al compilador: "NO optimices esta variable, el hardware externo puede cambiarla".
    const hardware_register: *volatile u8 = @ptrFromInt(0x4000_0000);
    _ = hardware_register;

    try stdout.print("  [Volatile] Puntero a registro de hardware listo (Evita optimizaciones del compilador).\n", .{});
}
