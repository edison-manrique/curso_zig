// =========================================================================
// MASTERCLASS 6: ENUMERACIONES, SEGURIDAD Y REFLEXION (EDICION ZIG 0.16)
// =========================================================================

// En Zig, los Enums son conjuntos de constantes enteras fuertemente tipadas.
// Aunque no almacenan datos internos como en Rust (para eso Zig usa Unions),
// ofrecen seguridad estricta, metodos, exhaustividad en switches y reflexion.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Enums Basicos, Literales Anonimos y Metodos de Enum.
// 2. Control de Ordinales (Valores Base) e Inferencia.
// 3. Tipado Fuerte y Castings (@intFromEnum y @enumFromInt).
// 4. El Poder del Switch Exhaustivo en Zig.
// 5. Enums NO Exhaustivos (Non-exhaustive) y el operador `_`.
// 6. Reflexion de Tipos (@typeInfo) y @tagName para Metaprogramacion.
// 7. Compatibilidad ABI con C (c_int).
// 8. Proyecto Final: Maquina de Estados Finitos (FSM) de un Servidor TCP.

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Usamos un buffer grande para toda la salida de esta enorme Masterclass
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Forzamos la limpieza del buffer al finalizar el programa
    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE ENUMS EN ZIG ---\n\n", .{});

    try modulo1BasicosYLiterales(stdout);
    try modulo2OrdinalesYCastings(stdout);
    try modulo3SwitchesExhaustivos(stdout);
    try modulo4EnumsNoExhaustivos(stdout);
    try modulo5ReflexionYMetaprogramacion(stdout);
    try modulo6CompatibilidadC(stdout);
    try modulo7ProyectoFSM(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE ENUMS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: BASICOS, LITERALES Y METODOS
// -------------------------------------------------------------------------
// Declaracion basica. El tipo base subyacente es inferido por el compilador.
const Direccion = enum {
    norte,
    sur,
    este,
    oeste,

    // Los enums (al igual que los structs) actuan como namespaces para funciones.
    pub fn esVertical(self: Direccion) bool {
        return self == .norte or self == .sur;
    }

    pub fn invertir(self: Direccion) Direccion {
        return switch (self) {
            .norte => .sur,
            .sur => .norte,
            .este => .oeste,
            .oeste => .este,
        };
    }
};

fn modulo1BasicosYLiterales(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Basicos, Literales Anonimos y Metodos\n", .{});

    // Zig permite omitir el nombre del Enum si el tipo ya se espera (Literales)
    const mi_ruta: Direccion = .norte;

    // Llamamos al metodo directamente
    const vertical = mi_ruta.esVertical();
    const regreso = mi_ruta.invertir();

    try stdout.print("  La direccion {s} es vertical? {s}\n", .{ @tagName(mi_ruta), if (vertical) "SI" else "NO" });
    try stdout.print("  La ruta de regreso desde {s} es {s}\n\n", .{ @tagName(mi_ruta), @tagName(regreso) });
}

// -------------------------------------------------------------------------
// MODULO 2: ORDINALES, CONTROL DE TIPOS Y CASTINGS
// -------------------------------------------------------------------------
// Podemos forzar que un Enum ocupe un tamano de memoria especifico.
// Excelente para optimizar RAM o mapear protocolos de red.
const CodigoHTTP = enum(u16) {
    ok = 200,
    creado = 201,
    // Si no especificas, Zig suma 1 al anterior (aqui seria 202)
    aceptado,
    no_encontrado = 404,
    error_servidor = 500,
};

fn modulo2OrdinalesYCastings(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Ordinales y Castings Seguros\n", .{});

    const respuesta = CodigoHTTP.no_encontrado;

    // 1. Convertir Enum a Entero: @intFromEnum
    const codigo_entero = @intFromEnum(respuesta);
    const codigo_aceptado = @intFromEnum(CodigoHTTP.aceptado);

    try stdout.print("  Codigo HTTP extraido: {d}\n", .{codigo_entero});
    try stdout.print("  El codigo autocalculado de 'aceptado' es: {d}\n", .{codigo_aceptado});

    // 2. Convertir Entero a Enum: @enumFromInt
    // ATENCION: Esto aplica Bounds Checking. Si pasamos un 999 aqui en modo Debug,
    // Zig lanzara un Panic porque 999 no existe en el enum.
    const numero_red: u16 = 500;
    const enum_recuperado: CodigoHTTP = @enumFromInt(numero_red);

    try stdout.print("  El numero 500 fue casteado a: {s}\n\n", .{@tagName(enum_recuperado)});
}

// -------------------------------------------------------------------------
// MODULO 3: SWITCH EXHAUSTIVO
// -------------------------------------------------------------------------
// En C, si te olvidas un caso en un switch, el programa falla en silencio.
// En Zig, el compilador TE OBLIGA a cubrir todos los casos del enum.
const NivelLog = enum { info, advertencia, error_fatal };

fn procesarLog(nivel: NivelLog, stdout: anytype) !void {
    // Si borramos un caso de este switch, no compilara.
    const prefijo = switch (nivel) {
        .info => "[INFO]",
        .advertencia => "[WARN]",
        .error_fatal => "[CRIT]",
    };

    try stdout.print("  Escribiendo log con prefijo: {s}\n", .{prefijo});
}

fn modulo3SwitchesExhaustivos(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Compilacion y Switch Exhaustivo\n", .{});
    try procesarLog(.advertencia, stdout);
    try stdout.print("\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 4: ENUMS NO EXHAUSTIVOS (NON-EXHAUSTIVE)
// -------------------------------------------------------------------------
// Utilizados tipicamente al parsear binarios, formatos de red o bindings de C.
// Permiten recibir valores que aun no conocemos o no estandarizados.
// Se define agregando `_` al final. ES OBLIGATORIO INDICAR EL TIPO (ej. u8).
const OpCode = enum(u8) {
    saltar = 0x01,
    mover = 0x02,
    atacar = 0x03,
    _, // Indica que podria haber OpCodes de otros mods o expansiones que valen mas de 0x03
};

fn modulo4EnumsNoExhaustivos(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Enums No Exhaustivos (_)\n", .{});

    // Podemos hacer un cast seguro de un OpCode desconocido (0x99)
    // porque el enum es de tipo u8 y esta marcado como No Exhaustivo.
    const codigo_desconocido: OpCode = @enumFromInt(0x99);

    const descripcion = switch (codigo_desconocido) {
        .saltar => "Saltando",
        .mover => "Moviendose",
        .atacar => "Atacando",
        // En los No Exhaustivos, debes manejar los casos desconocidos:
        // `_ =>` se usa en lugar de `else =>` para capturar cualquier otro entero valido en u8.
        _ => "Comando Desconocido o Expansion DLC",
    };

    try stdout.print("  El OpCode 0x99 resulto ser: {s}\n\n", .{descripcion});
}

// -------------------------------------------------------------------------
// MODULO 5: METAPROGRAMACION CON @typeInfo y @tagName
// -------------------------------------------------------------------------
// Zig te permite "reflexionar" (analizar tipos) en tiempo de compilacion
// de forma gratuita y sin costo en rendimiento.
const Planeta = enum { mercurio, venus, tierra, marte };

fn modulo5ReflexionYMetaprogramacion(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Reflexion y Metaprogramacion (@typeInfo)\n", .{});

    // @tagName convierte una instancia del Enum en un slice de caracteres (string)
    const mi_planeta = Planeta.tierra;
    try stdout.print("  @tagName dice que tu planeta es: '{s}'\n", .{@tagName(mi_planeta)});

    // @typeInfo nos permite inspeccionar todo el struct/enum a nivel del compilador
    const info = @typeInfo(Planeta).@"enum"; // @"enum" porque 'enum' es palabra reservada

    try stdout.print("  El enum Planeta tiene {d} campos. Son:\n", .{info.fields.len});

    // Iteramos los campos del enum en TIEMPO DE COMPILACION (inline for)
    // Esto es magia negra: el compilador escribira 4 lineas de 'try stdout.print' por ti.
    inline for (info.fields, 0..) |campo, idx| {
        try stdout.print("    {d}: {s} (Valor entero subyacente: {d})\n", .{ idx, campo.name, campo.value });
    }
    try stdout.print("\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 6: COMPATIBILIDAD CON C (EXTERN ENUM)
// -------------------------------------------------------------------------
fn modulo6CompatibilidadC(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: Compatibilidad con C\n", .{});

    // Por defecto, Zig optimiza el tamaño de los enums segun el numero de campos.
    // Si necesitas exportar esto a C (C-ABI), el tamaño es indefinido.
    // Para interactuar con librerias dinamicas (.dll, .so), fuerza el uso de c_int.
    const EnumSeguroC = enum(c_int) {
        valor_a,
        valor_b,
    };

    try stdout.print("  Tamaño de un Enum para C (c_int): {d} bytes.\n\n", .{@sizeOf(EnumSeguroC)});
}

// -------------------------------------------------------------------------
// MODULO 7: PROYECTO - MAQUINA DE ESTADOS FINITOS (FSM)
// -------------------------------------------------------------------------
const EstadoTCP = enum {
    cerrado,
    escuchando,
    conectado,
    desconectando,
};

const EventoTCP = enum {
    iniciar_servidor,
    conexion_entrante,
    solicitud_cierre,
    timeout,
};

fn procesarEvento(estado_actual: EstadoTCP, evento: EventoTCP, stdout: anytype) !EstadoTCP {
    try stdout.print("    [FSM] Estado: {s: <13} | Evento: {s}\n", .{ @tagName(estado_actual), @tagName(evento) });

    return switch (estado_actual) {
        .cerrado => switch (evento) {
            .iniciar_servidor => .escuchando,
            else => .cerrado,
        },
        .escuchando => switch (evento) {
            .conexion_entrante => .conectado,
            .timeout => .cerrado,
            else => .escuchando,
        },
        .conectado => switch (evento) {
            .solicitud_cierre => .desconectando,
            .timeout => .desconectando,
            else => .conectado,
        },
        .desconectando => switch (evento) {
            .timeout => .cerrado,
            else => .cerrado, // Cualquier evento en desconectando finaliza cerrando
        },
    };
}

fn modulo7ProyectoFSM(stdout: anytype) !void {
    try stdout.print(">> Modulo 7: Proyecto - Maquina de Estados FSM\n", .{});

    var estado = EstadoTCP.cerrado;

    // Simulamos un flujo de ciclo de vida de un servidor
    const simulacion = [_]EventoTCP{
        .iniciar_servidor, // Pasa a escuchando
        .conexion_entrante, // Pasa a conectado
        .solicitud_cierre, // Pasa a desconectando
        .timeout, // Pasa a cerrado
    };

    for (simulacion) |evento| {
        estado = try procesarEvento(estado, evento, stdout);
    }

    try stdout.print("    [FSM] Estado Final: {s}\n", .{@tagName(estado)});
}
