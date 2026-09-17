// =========================================================================
// MASTERCLASS 7: UNIONES Y VARIANTES (EDICION ZIG 0.16)
// =========================================================================

// Las Uniones permiten que diferentes tipos de datos compartan el mismo
// espacio de memoria, ahorrando RAM. En Zig, las uniones son seguras por
// defecto y evitan la corrupcion de datos clasica de C.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Bare Unions (Uniones Desnudas) y la Proteccion de Seguridad de Zig.
// 2. Tagged Unions (Uniones Etiquetadas): El equivalente a los Enums de Rust.
// 3. Modificacion in-place con Punteros en un Switch (|*valor|).
// 4. Inferencia de Etiquetas y Uniones con Metodos.
// 5. Valores Ordinales Magicos en Uniones (Control a nivel de ABI).
// 6. Packed Unions (Bits exactos) y Extern Unions (C-ABI).
// 7. Proyecto Final: Evaluador Dinamico de Tipos (Interprete JSON simple).

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [8192]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE UNIONES EN ZIG ---\n\n", .{});

    try modulo1UnionesDesnudas(stdout);
    try modulo2UnionesEtiquetadas(stdout);
    try modulo3ModificacionYMetodos(stdout);
    try modulo4OrdinalesYReflection(stdout);
    try modulo5PackedYExtern(stdout);
    try modulo6ProyectoVariante(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE UNIONES ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: BARE UNIONS (UNIONES DESNUDAS) Y SEGURIDAD
// -------------------------------------------------------------------------
// Una Bare Union solo guarda un dato a la vez. Ocupa el tamano del campo mas grande.
const CargaUtil = union {
    entero: i64,
    flotante: f64,
    booleano: bool,
};

fn modulo1UnionesDesnudas(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Uniones Desnudas y Seguridad\n", .{});

    var paquete = CargaUtil{ .entero = 1234 };
    try stdout.print("  Paquete inicial (entero): {d}\n", .{paquete.entero});

    // REGLA DE ZIG: No puedes asignar un campo inactivo directamente.
    // Hacer `paquete.flotante = 12.34;` causaria un PANIC (Illegal Behavior).
    // Para cambiar el tipo activo, DEBES reasignar la union completa:
    paquete = .{ .flotante = 12.34 }; // Literal anonimo de union

    try stdout.print("  Paquete reasignado (flotante): {d:.2}\n\n", .{paquete.flotante});
}

// -------------------------------------------------------------------------
// MODULO 2: TAGGED UNIONS (UNIONES ETIQUETADAS / RUST ENUMS)
// -------------------------------------------------------------------------
// Al agregar `(enum)` a la union, Zig automaticamente crea un enum oculto
// para rastrear que campo esta activo. Esto permite usar `switch`.
const Variante = union(enum) {
    numero: i32,
    texto: []const u8,
    vacio, // Si no tiene tipo, equivale a 'void' (ocupa 0 bytes)
};

fn modulo2UnionesEtiquetadas(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Tagged Unions y Switch\n", .{});

    const dato1 = Variante{ .numero = 42 };
    const dato2 = Variante{ .texto = "Hola Zig" };

    try imprimirVariante(dato1, stdout);
    try imprimirVariante(dato2, stdout);
    try stdout.print("\n", .{});
}

fn imprimirVariante(v: Variante, stdout: anytype) !void {
    // switch sobre Tagged Unions permite "Capturar" el valor del payload usando |var|
    switch (v) {
        .numero => |n| try stdout.print("  Es un numero: {d}\n", .{n}),
        .texto => |t| try stdout.print("  Es un texto: {s}\n", .{t}),
        .vacio => try stdout.print("  Esta vacio\n", .{}),
    }
}

// -------------------------------------------------------------------------
// MODULO 3: MODIFICACION CON PUNTEROS Y METODOS DE UNION
// -------------------------------------------------------------------------
const Entidad = union(enum) {
    jugador: u32, // nivel del jugador
    enemigo: f32, // salud del enemigo

    // Las uniones pueden tener metodos al igual que los structs
    pub fn curar(self: *Entidad) void {
        switch (self.*) {
            // Usamos |*ptr| para capturar un PUNTERO al payload y modificarlo in-place
            .enemigo => |*salud| salud.* = 100.0,

            // Si es un jugador, no hacemos nada
            .jugador => {},
        }
    }
};

fn modulo3ModificacionYMetodos(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Switch con Punteros y Metodos\n", .{});

    var orco = Entidad{ .enemigo = 15.5 };

    // Al pasar por switch con puntero original:
    orco.curar();

    try stdout.print("  El enemigo fue curado usando metodos de union: {d:.1}\n\n", .{orco.enemigo});
}

// -------------------------------------------------------------------------
// MODULO 4: VALORES ORDINALES EN ETIQUETAS Y REFLECTION
// -------------------------------------------------------------------------
// SUPER PODER DE ZIG: Puedes definir el Enum subyacente explicitamente
// y asignarle un valor entero A LA ETIQUETA usando la sintaxis `= X`.
const ComandoRed = union(enum(u8)) {
    // 0x10 y 0x20 NO son el valor por defecto del payload, son el valor
    // numerico del Enum que identifica al campo!
    iniciar_sesion: u32 = 0x10,
    enviar_mensaje: []const u8 = 0x20,
};

fn modulo4OrdinalesYReflection(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Ordinales de Etiqueta y Metadatos\n", .{});

    const cmd = ComandoRed{ .iniciar_sesion = 9999 };

    // @intFromEnum extrae el numero de la etiqueta (0x10) de la union
    const id_etiqueta = @intFromEnum(cmd);

    try stdout.print("  El ID de la etiqueta de red es: 0x{X}\n", .{id_etiqueta});
    try stdout.print("  El nombre del campo activo (@tagName) es: '{s}'\n\n", .{@tagName(cmd)});
}

// -------------------------------------------------------------------------
// MODULO 5: PACKED UNIONS Y EXTERN UNIONS
// -------------------------------------------------------------------------
fn modulo5PackedYExtern(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Packed y Extern Unions\n", .{});

    // 1. Packed Union
    // Garantiza el layout de bits y exige que TODOS los campos tengan
    // exactamente el mismo tamano en bits.
    const UnionEmpaquetada = packed union {
        flotante: f32, // 32 bits
        entero: u32, // 32 bits
        // Si pusieramos un u16 aqui, no compilaria.
    };

    const bits_graficos = UnionEmpaquetada{ .flotante = 1.0 };
    // Los packed unions soportan comparacion directa con == (compara el entero subyacente)
    const otro = UnionEmpaquetada{ .entero = 0x3F800000 };

    try stdout.print("  Son iguales a nivel de bits? {s}\n", .{if (bits_graficos == otro) "SI" else "NO"});

    // 2. Extern Union
    // Garantiza que el tamano y alineacion sean 100% compatibles con la ABI de C.
    // Vital si llamas a funciones de una DLL de C que usan `union`.
    const UnionC = extern union {
        a: i32,
        b: f64,
    };
    try stdout.print("  Tamano de una extern union para C: {d} bytes\n\n", .{@sizeOf(UnionC)});
}

// -------------------------------------------------------------------------
// MODULO 6: PROYECTO - EVALUADOR DE TIPOS DINAMICOS (JSON SIMULADO)
// -------------------------------------------------------------------------
const TipoJson = union(enum) {
    nulo,
    booleano: bool,
    entero: i64,
    texto: []const u8,
};

fn serializarSimulado(nodo: TipoJson, stdout: anytype) !void {
    try stdout.print("    [AST] Nodo procesado: ", .{});
    switch (nodo) {
        .nulo => try stdout.print("null\n", .{}),
        .booleano => |b| try stdout.print("{s}\n", .{if (b) "true" else "false"}),
        .entero => |n| try stdout.print("{d}\n", .{n}),
        .texto => |s| try stdout.print("\"{s}\"\n", .{s}),
    }
}

fn modulo6ProyectoVariante(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: Proyecto - Interprete AST de JSON\n", .{});

    // Podemos declarar un arreglo de diferentes tipos gracias al Tagged Union!
    const documento_json = [_]TipoJson{
        .{ .texto = "servidor_db" },
        .{ .entero = 5432 },
        .{ .booleano = true },
        .nulo, // Literales anonimos funcionan perfecto aqui
    };

    for (documento_json) |nodo| {
        try serializarSimulado(nodo, stdout);
    }
}
