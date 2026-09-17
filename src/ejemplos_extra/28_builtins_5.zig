// =========================================================================================
// MASTERCLASS: REFLEXION, CASTS Y PUNTEROS DE BAJO NIVEL (ZIG 0.16.0)
// =========================================================================================
//
// CONTENIDO DE LA MASTERCLASS (19 Builtins cubiertos):
// 1. Metaprogramacion y Reflexion: @field, @FieldType, @hasDecl, @hasField, @inComptime.
// 2. Sistema de Conversiones: @intCast, @floatCast, @floatFromInt, @intFromFloat,
//    @intFromBool, @intFromEnum, @intFromError, @max.
// 3. Punteros y Control de Pila: @fieldParentPtr, @intFromPtr, @frameAddress.
// 4. Sistema de Enlace y Modulos: @import, @export, @extern.
//
// Todo el codigo esta en ASCII puro para compatibilidad universal con terminales.
// =========================================================================================

const std = @import("std"); // Utiliza @import para cargar la Libreria Estandar
const builtin = @import("builtin"); // Carga variables de configuracion del compilador

// =========================================================================================
// SINOPSIS DE ENLACE EXTERNO (@export, @extern)
// =========================================================================================
// @export crea un simbolo visible en el objeto binario de salida (.o, .exe, .dll)
comptime {
    @export(&funcionInterna, .{ .name = "simbolo_exportado_c", .linkage = .strong });
}

fn funcionInterna() callconv(.c) void {}

// =========================================================================================
// ENTRY POINT JUICY MAIN
// =========================================================================================
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);

    try modulo1_MetaprogramacionYReflexion(stdout);
    try modulo2_ConversionesSeguras(stdout);
    try modulo3_PunterosYFisicaDeMemoria(stdout);
    try modulo4_EnlaceYModulos(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: METAPROGRAMACION Y REFLEXION
// =========================================================================================
const Persona = struct {
    nombre: []const u8,
    edad: u32,

    pub const especie = "Homo Sapiens";
    pub var contador_instancias: u32 = 0;
};

fn calcularEnComptime() bool {
    // @inComptime devuelve true si la funcion se esta evaluando en tiempo de compilacion
    return @inComptime();
}

fn modulo1_MetaprogramacionYReflexion(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Reflexion en Tiempo de Compilacion\n", .{});

    var p = Persona{ .nombre = "Alice", .edad = 30 };

    // 1. @field: Permite acceder a un campo de un Struct/Union usando un String dinamico
    @field(p, "edad") = 31; // Equivalente a: p.edad = 31
    const nombre_leido = @field(p, "nombre");

    try stdout.print("  Accesso @field dinamico: {s} tiene {d} anos.\n", .{ nombre_leido, p.edad });

    // Tambien funciona para acceder a declaraciones constantes o variables estaticas:
    @field(Persona, "contador_instancias") += 1;
    const especie_leida = @field(Persona, "especie");

    try stdout.print("  Acceso @field estatico -> Especie: {s}, Instancias: {d}\n", .{ especie_leida, Persona.contador_instancias });

    // 2. @FieldType: Obtiene el tipo exacto de un campo por su nombre en String
    const TipoDeEdad = @FieldType(Persona, "edad");
    try stdout.print("  Tipo de campo 'edad' resuelto por @FieldType: {any}\n", .{TipoDeEdad});

    // 3. @hasField / @hasDecl: Evaluan existencia de campos o variables globales
    const tiene_nombre = @hasField(Persona, "nombre");
    const tiene_especie = @hasDecl(Persona, "especie");
    const tiene_falso = @hasField(Persona, "apellido");

    try stdout.print("  @hasField nombre? {s} | @hasDecl especie? {s} | @hasField apellido? {s}\n", .{ if (tiene_nombre) "SI" else "NO", if (tiene_especie) "SI" else "NO", if (tiene_falso) "SI" else "NO" });

    // 4. @inComptime: Comportamiento dinamico basado en el contexto de ejecucion
    const evaluado_runtime = calcularEnComptime();
    comptime {
        const evaluado_comptime = calcularEnComptime();
        // Comprobacion estatica
        if (!evaluado_comptime) @compileError("Debio ser evaluado en comptime!");
    }

    try stdout.print("  @inComptime invocado en tiempo de ejecucion: {s}\n\n", .{if (evaluado_runtime) "SI" else "NO"});
}

// =========================================================================================
// MODULO 2: CONVERSIONES NUMERICAS SEGURAS Y UTILERIA
// =========================================================================================
const TipoColor = enum(u4) { Rojo = 1, Verde = 2, Azul = 3 };
const FalloCritico = error{ Timeout, DiscoLleno };

fn modulo2_ConversionesSeguras(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Conversiones Integradas de Precision\n", .{});

    // 1. @intCast / @floatCast: Conversiones entre tipos enteros/flotantes.
    // Si el valor no cabe en el tipo destino, Zig lanza un Panic controlado por seguridad.
    const a_u32: u32 = 100;
    const b_u8: u8 = @intCast(a_u32);

    const f64_valor: f64 = 1.23456789;
    const f32_valor: f32 = @floatCast(f64_valor);

    try stdout.print("  @intCast (u32 a u8): {d} | @floatCast (f64 a f32): {d:.5}\n", .{ b_u8, f32_valor });

    // 2. @floatFromInt / @intFromFloat: Transiciones entre entero y coma flotante
    const entero_original: i32 = -500;
    const flotante_cercano: f32 = @floatFromInt(entero_original);
    const entero_truncado: i32 = @intFromFloat(flotante_cercano);

    try stdout.print("  @floatFromInt: {d:.1} | @intFromFloat: {d}\n", .{ flotante_cercano, entero_truncado });

    // 3. @intFromBool: Mapea booleano a entero directo (true -> 1, false -> 0)
    const bandera_activa = true;
    const entero_bool = @intFromBool(bandera_activa);
    try stdout.print("  @intFromBool de true: {d}\n", .{entero_bool});

    // 4. @intFromEnum / @intFromError: Obtencion de la representacion numerica tag
    const enum_valor = TipoColor.Azul;
    const tag_enum = @intFromEnum(enum_valor);

    const err_valor = FalloCritico.DiscoLleno;
    const tag_error = @intFromError(err_valor);

    try stdout.print("  @intFromEnum (Azul): {d} | @intFromError (DiscoLleno): {d}\n", .{ tag_enum, tag_error });

    // 5. @max: Compara multiples elementos de manera eficiente
    const numero_maximo = @max(10, 50, 5, 100, 2);
    try stdout.print("  @max de un set de enteros: {d}\n\n", .{numero_maximo});
}

// =========================================================================================
// MODULO 3: PUNTEROS Y FISICA DE MEMORIA
// =========================================================================================
const NodoConector = struct {
    datos: [128]u8,
    puerto_activo: u16,
};

fn modulo3_PunterosYFisicaDeMemoria(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Fisica de Memoria y Punteros\n", .{});

    // 1. @fieldParentPtr: SUPER PODER DE ZIG.
    // Dado un puntero a un CAMPO de un Struct, calcula matematicamente la direccion
    // base del Struct contenedor ("Padre") y nos devuelve un puntero a este.
    // Clave para Listas Intrusivas, OOP basada en C e Implementacion de Interfaces.

    var conexion = NodoConector{ .datos = [_]u8{0} ** 128, .puerto_activo = 443 };

    // Obtenemos un puntero al campo 'puerto_activo'
    const ptr_al_campo = &conexion.puerto_activo;

    // Recuperamos el puntero al Struct 'NodoConector' completo
    const ptr_al_padre: *NodoConector = @fieldParentPtr("puerto_activo", ptr_al_campo);

    // Verificamos que el puerto_activo sea modificable desde el puntero recuperado
    ptr_al_padre.puerto_activo = 80;

    try stdout.print("  [fieldParentPtr] Puerto modificado via puntero base recuperado: {d}\n", .{conexion.puerto_activo});

    // 2. @intFromPtr: Obtiene la direccion fisica en memoria (como un entero usize)
    const direccion_fisica = @intFromPtr(&conexion);
    try stdout.print("  Direccion fisica de RAM del Struct: 0x{X}\n", .{direccion_fisica});

    // 3. @frameAddress: Devuelve el puntero base (Base Pointer/Frame Pointer) del stack frame actual.
    // Util para depuradores, diagnosticos y unwinding manual.
    const ptr_stack_frame = @frameAddress();
    try stdout.print("  Puntero base del Stack Frame actual: 0x{X}\n\n", .{ptr_stack_frame});
}

// =========================================================================================
// MODULO 4: ENLACE EXTERNO Y IMPORTACION
// =========================================================================================
fn modulo4_EnlaceYModulos(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Sistema de Enlace y Modulos\n", .{});

    // @import ya fue utilizado arriba para cargar "std" y "builtin".
    // Mapea y compila archivos o librerias.

    // @extern: Declara la existencia de una variable o funcion que sera enlazada
    // por el linker final en tiempo de compilacion, resolviendo el simbolo.
    // Para evitar errores si no compilas con libc, lo demostramos de forma segura:
    comptime {
        if (false) {
            // Buscara un entero externo llamado 'errno' que provee libc
            const errno_ptr = @extern(*c_int, .{ .name = "errno" });
            _ = errno_ptr;
        }
    }

    try stdout.print("  [Info] @export hace visible un simbolo Zig a APIs de C u otros linkers.\n", .{});
    try stdout.print("  [Info] @extern declara la intencion de usar un simbolo de otra libreria binaria.\n", .{});
    try stdout.print("  [Info] Ambos son esenciales para construir interfaces robustas de FFI.\n", .{});
}

// =========================================================================================
// UTILIDADES DE IMPRESION
// =========================================================================================
fn imprimirCabecera(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\     ___ _   _ ___ _  _____ ___ _  _ ___ 
        \\    | _ ) | | |_ _| |__   _|_ _| \| / __|
        \\    | _ \ |_| || || |__| |  | || .` \__ \
        \\    |___/\___/|___|____|_| |___|_|\_|___/
        \\                                                            
        \\    MASTERCLASS 12: REFLEXION, CASTS Y BAJO NIVEL (ZIG 0.16.0)
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\ FIN DE LA MASTERCLASS.
        \\====================================================================
        \\ CONCEPTOS CLAVE REPASADOS:
        \\ - @field y @FieldType otorgan un sistema de reflexion potente y estatico.
        \\ - @intCast y @floatCast previenen desbordamientos silenciosos.
        \\ - @fieldParentPtr permite estructurar arquitecturas OOP de manera nativa.
        \\ - @export y @extern son los bloques fundamentales de interoperabilidad FFI.
        \\====================================================================
        \\
    , .{});
}
