// =========================================================================
// MASTERCLASS 5: ESTRUCTURAS, TUPLAS Y CONTROL DE BITS (EDICION ZIG 0.16)
// =========================================================================

// En Zig, el "struct" es la base de toda abstraccion. No hay "class", no
// hay herencia. Solo hay datos, metodos asociados (namespacing) y un control
// milimetrico sobre la memoria.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Structs Basicos, Metodos y Structs Vacios.
// 2. Valores por Defecto y Prevencion de Invariantes Rotos.
// 3. Tipos Genericos: Funciones que retornan Structs en Comptime.
// 4. Tuplas y Literales Anonimos: Coercion, Destructuracion y anytype.
// 5. El Poder del Packed Struct: Control a nivel de bit y Casting directo.
// 6. Magia de Punteros: @fieldParentPtr, @offsetOf y campos desalineados.
// 7. Seguridad en Hardware (MMIO) con Packed Structs.

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [8192]u8 = undefined; // Buffer mas grande para tanta informacion
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE STRUCTS EN ZIG ---\n\n", .{});

    try modulo1StructsBasicosYMetodos(stdout);
    try modulo2ValoresPorDefecto(stdout);
    try modulo3GenericosYComptime(stdout);
    try modulo4TuplasYAnonimos(stdout);
    try modulo5PackedStructs(stdout);
    try modulo6MagiaDePunterosAvanzada(stdout);
    try modulo7HardwareMMIO(stdout);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE STRUCTS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: STRUCTS BASICOS, METODOS Y STRUCTS VACIOS
// -------------------------------------------------------------------------
// Un struct simple. Zig no garantiza el orden de los campos en memoria
// por defecto, pero si garantiza que estan alineados segun la ABI.
const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    // Una funcion dentro del namespace del struct hace las veces de "Constructor"
    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z }; // Literal anonimo deducido
    }

    // Si el primer parametro es del tipo del struct, se puede llamar con sintaxis de punto
    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
};

// Los Structs pueden no tener campos y solo servir como contenedores de constantes (Namespaces)
const Matematicas = struct {
    pub const PI = 3.14159;
};

fn modulo1StructsBasicosYMetodos(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Structs Basicos y Metodos\n", .{});

    const v1 = Vec3.init(1.0, 2.0, 3.0);
    const v2 = Vec3.init(4.0, 5.0, 6.0);

    // Llamada via "metodo" (sintaxis de punto)
    const resultado = v1.dot(v2);
    // Llamada directa via namespace (exactamente lo mismo)
    const resultado2 = Vec3.dot(v1, v2);

    try stdout.print("  Producto punto v1.v2: {d:.2} (Metodo) | {d:.2} (Namespace)\n", .{ resultado, resultado2 });
    try stdout.print("  Struct vacio Matematicas. PI: {d:.5}, Tamano en memoria: {d} bytes\n\n", .{ Matematicas.PI, @sizeOf(Matematicas) });
}

// -------------------------------------------------------------------------
// MODULO 2: VALORES POR DEFECTO Y EL PATRON "DEFAULT"
// -------------------------------------------------------------------------
const ConfiguracionSegura = struct {
    // Valores por defecto evaluados en comptime
    reintentos: u32 = 5,
    timeout_ms: u32 = 1000,
    host: []const u8, // Sin valor por defecto, es obligatorio

    // Patron Zig para evitar "Data Invariants Rotos":
    // En lugar de poner valores por defecto en los campos si estos
    // dependen de una logica estricta, proveemos una constante "default" completa.
    pub const default: ConfiguracionSegura = .{
        .reintentos = 3,
        .timeout_ms = 500,
        .host = "localhost",
    };
};

fn modulo2ValoresPorDefecto(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Valores por Defecto e Inicializacion\n", .{});

    // Se pueden omitir los campos que tienen default
    const conf_parcial = ConfiguracionSegura{ .host = "192.168.1.1" };

    // Usar el patron de la constante default
    const conf_base = ConfiguracionSegura.default;

    try stdout.print("  Config Parcial -> Host: {s}, Reintentos: {d}\n", .{ conf_parcial.host, conf_parcial.reintentos });
    try stdout.print("  Config Base    -> Host: {s}, Reintentos: {d}\n\n", .{ conf_base.host, conf_base.reintentos });
}

// -------------------------------------------------------------------------
// MODULO 3: GENERICOS (COMPTIME TYPES)
// -------------------------------------------------------------------------
// Zig NO tiene una sintaxis especial para genericos como <T>.
// En su lugar, usas funciones que reciben un tipo en tiempo de compilacion
// y devuelven un nuevo struct generado a la medida.
fn NodoGenerico(comptime T: type) type {
    return struct {
        dato: T,
        siguiente: ?*const @This() = null, // @This() hace referencia al struct anonimo actual
    };
}

fn modulo3GenericosYComptime(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Genericos via Comptime\n", .{});

    // En tiempo de compilacion, Zig memoriza (cachea) los tipos.
    const NodoInt = NodoGenerico(i32);
    const NodoFloat = NodoGenerico(f32);

    const nodo1 = NodoInt{ .dato = 42 };
    const nodo2 = NodoFloat{ .dato = 3.14 };

    try stdout.print("  Nodo Int contiene: {d}\n", .{nodo1.dato});
    try stdout.print("  Nodo Float contiene: {d:.2}\n", .{nodo2.dato});
    try stdout.print("  Los tipos son unicos y cacheados? {s}\n\n", .{if (NodoGenerico(i32) == NodoInt) "SI" else "NO"});
}

// -------------------------------------------------------------------------
// MODULO 4: TUPLAS, LITERALES ANONIMOS Y DESTRUCTURACION
// -------------------------------------------------------------------------
fn procesarAnonimo(stdout: anytype, args: anytype) !void {
    try stdout.print("    => Extraido: Int: {d}, Bool: {}, Texto: {s}\n", .{ args.numero, args.estado, args.mensaje });
}

fn retornarVariosValores() struct { i32, f64 } {
    return .{ 99, 8.5 }; // Retorna una tupla (struct anonimo enumerado)
}

fn modulo4TuplasYAnonimos(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Tuplas y Structs Anonimos\n", .{});

    // 1. Struct Anonimo como argumento (Duck Typing)
    try stdout.print("  [Struct Anonimo pasado a anytype]:\n", .{});
    try procesarAnonimo(stdout, .{ .numero = 10, .estado = true, .mensaje = "Hola" });

    // 2. Tuplas (Structs anonimos sin nombre de campo, indexados con 0, 1, 2...)
    // Soportan operadores de arreglos como ++ (concatenar) y ** (repetir)
    const mi_tupla = .{ @as(u32, 100), true } ++ .{"Zig"} ** 2;

    try stdout.print("  [Tupla Generada]: Longitud {d}, Elemento 0: {d}, Elemento 2: {s}\n", .{ mi_tupla.len, mi_tupla[0], mi_tupla.@"2" });

    // 3. Destructuracion de Tuplas
    // Excelente para multiples retornos. Se declara con `const val1, const val2 = ...`
    const enterito, const flotantito = retornarVariosValores();
    try stdout.print("  [Destructuracion]: Valor 1: {d}, Valor 2: {d:.1}\n\n", .{ enterito, flotantito });
}

// -------------------------------------------------------------------------
// MODULO 5: PACKED STRUCTS Y CONTROL A NIVEL DE BITS
// -------------------------------------------------------------------------
// Un `packed struct` fuerza a que la memoria coincida EXACTAMENTE con un entero
// subyacente. Los campos se agrupan a nivel de bits.
const CabeceraRed = packed struct(u16) { // Forzamos que mida exactamente 16 bits
    version: u4, // 4 bits
    tipo_trafico: u4, // 4 bits
    longitud: u8, // 8 bits
};

fn modulo5PackedStructs(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Packed Structs (@bitCast y Memoria Exacta)\n", .{});

    const cabecera = CabeceraRed{
        .version = 4, // 0100
        .tipo_trafico = 1, // 0001
        .longitud = 255, // 11111111
    };

    // Como es un packed struct, podemos "Castear" magicamente sus bits a un entero real (u16)
    // El orden de bits dependera del Endianness del procesador (Little/Big Endian)
    const bits_crudos: u16 = @bitCast(cabecera);

    try stdout.print("  Size of CabeceraRed: {d} bytes\n", .{@sizeOf(CabeceraRed)});
    try stdout.print("  Paquete convertido a u16 crudo: 0x{X}\n", .{bits_crudos});

    // Comparacion directa: Los packed structs se comparan directamente por su entero subyacente
    const cabecera2 = CabeceraRed{ .version = 4, .tipo_trafico = 1, .longitud = 255 };
    try stdout.print("  cabecera == cabecera2 ? {s}\n\n", .{if (cabecera == cabecera2) "SI" else "NO"});
}

// -------------------------------------------------------------------------
// MODULO 6: MAGIA DE PUNTEROS (@fieldParentPtr y Desalineacion)
// -------------------------------------------------------------------------
const Enemigo = struct {
    salud: i32,
    posicion: f32,
};

fn curarDesdeSalud(puntero_salud: *i32) *Enemigo {
    // SUPER PODER DE ZIG/C:
    // Si tenemos un puntero al campo 'salud', podemos retroceder en memoria
    // para obtener un puntero a la estructura 'Enemigo' completa que lo contiene.
    // Esto es vital para sistemas OOP basados en C y para "Listas Intrusivas".
    return @fieldParentPtr("salud", puntero_salud);
}

// Campos desalineados
const BanderasBits = packed struct {
    a: u3,
    b: u3,
    c: u2, // Total 8 bits (1 byte)
};

fn modulo6MagiaDePunterosAvanzada(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: @fieldParentPtr y Punteros a Bits\n", .{});

    // 1. Demostracion de @fieldParentPtr
    var orco = Enemigo{ .salud = 50, .posicion = 100.5 };
    const puntero_a_salud = &orco.salud;

    const orco_recuperado = curarDesdeSalud(puntero_a_salud);
    orco_recuperado.posicion = 999.0; // Modificamos el struct original

    try stdout.print("  [fieldParentPtr]: Posicion del Orco modificada a: {d:.1}\n", .{orco.posicion});

    // 2. Punteros a Campos Sub-byte (Desalineados)
    var banderas = BanderasBits{ .a = 1, .b = 2, .c = 3 };

    // Zig permite sacar punteros a campos de 3 bits!
    // PERO no son punteros normales. Contienen el "bit offset" internamente.
    const ptr_b = &banderas.b;

    try stdout.print("  [Bit Pointers]: Valor de 'b' via puntero sub-byte: {d}\n", .{ptr_b.*});

    // Observa el offset real de los bits dentro del byte usando built-ins
    try stdout.print("  Offset del campo 'a': {d} bits\n", .{@bitOffsetOf(BanderasBits, "a")});
    try stdout.print("  Offset del campo 'c': {d} bits\n\n", .{@bitOffsetOf(BanderasBits, "c")});
}

// -------------------------------------------------------------------------
// MODULO 7: HARDWARE MMIO (MEMORY MAPPED I/O) Y SEGURIDAD
// -------------------------------------------------------------------------
// Cuando programas microcontroladores, un registro de memoria se mapea
// a pines fisicos.
pub const RegistroHardware = packed struct(u8) {
    pin_led1: bool,
    pin_led2: bool,
    pin_motor: bool,
    alarma: bool,
    reservado: u4 = 0,
};

fn modulo7HardwareMMIO(stdout: anytype) !void {
    try stdout.print(">> Modulo 7: Hardware MMIO y Packed Structs\n", .{});

    // Simulamos una direccion de memoria volatil de un microcontrolador
    var simulador_ram: u8 = 0;
    const registro_volatil: *volatile RegistroHardware = @ptrCast(&simulador_ram);

    // REGLA DE ORO EN ZIG PARA HARDWARE:
    // Nunca hagas `registro_volatil.pin_led1 = true;`
    // Como es un packed struct, Zig tendria que hacer lectura, mascara de bits,
    // y escritura. Eso no es atomico y en memoria volatil causara bugs de hardware terribles.

    // LA FORMA CORRECTA: Construir el struct entero en la pila (stack) local
    // y hacer una unica escritura completa.
    const nuevos_estados = RegistroHardware{
        .pin_led1 = true,
        .pin_led2 = false,
        .pin_motor = true,
        .alarma = false,
    };

    // Escritura unica garantizada
    registro_volatil.* = nuevos_estados;

    try stdout.print("  [MMIO Seguro] Valor binario escrito en registro fisico simulado: 0b{b:0>8}\n", .{simulador_ram});
}
