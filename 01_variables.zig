// =========================================================================
// MASTERCLASS: VARIABLES, CICLO DE VIDA, MEMORIA Y TIPOS (EDICION ZIG 0.16.0)
// =========================================================================
// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.
//
// En Zig, las variables son vinculos estrictos a posiciones de memoria,
// con un tamano exacto conocido en tiempo de compilacion. No hay recolector
// de basura ni flujo de control oculto.
//
// CONCEPTOS AVANZADOS CUBIERTOS EN ESTA MASTERCLASS:
// 1. Mutabilidad (const vs var) y prohibicion estricta de Shadowing.
// 2. Container Level Variables (Estaticas, de analisis perezoso y orden libre).
// 3. Namespaced Container Variables (Estructuras de datos con variables internas).
// 4. Static Local Variables (Retener estado local con contenedores de funcion).
// 5. Thread Local Variables (TLS con la palabra clave threadlocal).
// 6. Local Variables y Comptime Variables (Evaluacion estatica de variables).
// 7. Tipos Enteros Flexibles y Control de Desbordamientos (Wrapping y Checked).
// 8. Flotantes (IEEE 754), Booleans y Chars (Integers en Zig).
// 9. Tuplas (Anonymous Structs) y Void (Zero Sized Types).
// 10. Punteros (*T), Slices ([]T) y Fat Pointers.
// 11. Casting Moderno en Zig 0.16.0 (Inferencia con @intCast y @floatFromInt).
// 12. Semantica de Memoria: Paso por Valor vs Paso por Referencia.
// 13. El Tipo de Retorno Imposible: noreturn.
// 14. Proyecto Final: Procesador de Telemetria de Hardware Multi-hilo.

const std = @import("std");

// --- CONFIGURACION GLOBAL (CONTAINER LEVEL VARIABLES) ---
// Las variables a nivel de contenedor tienen un ciclo de vida estatico,
// son independientes del orden en que se escriben y se analizan bajo demanda.
// Su valor de inicializacion es implicitamente 'comptime'.
var y_global: i32 = sumar_global(10, x_global);
const x_global: i32 = sumar_global(12, 34);

fn sumar_global(a: i32, b: i32) i32 {
    return a + b;
}

// Variable a nivel de contenedor para pruebas de Thread Local Storage (TLS)
// threadlocal var no puede declararse como 'const'
threadlocal var tls_variable: i32 = 1234;

// Entrada del Sistema compatible con la edicion Zig 0.16.0 ("Juicy Main")
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Buffer de escritura optimizado para la terminal
    var buffer: [8192]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Asegurar que la consola vuelque los datos al finalizar el programa
    defer stdout.flush() catch {};

    try stdout.print(
        \\============================================================
        \\     INICIO DE LA MASTERCLASS DE VARIABLES Y MEMORIA IN ZIG
        \\============================================================
        \\
    , .{});

    // Despacho de modulos teorico-practicos
    try modulo1MutabilidadYShadowing(stdout);
    try modulo2ContainerLevelVariables(stdout);
    try modulo3StaticLocalVariables(stdout);
    try modulo4ThreadLocalVariables(stdout);
    try modulo5ComptimeVariables(stdout);
    try modulo6EnterosYOverflows(stdout);
    try modulo7FlotantesBooleanosChars(stdout);
    try modulo8CompuestosYZeroSizedTypes(stdout);
    try modulo9SlicesYPointers(stdout);
    try modulo10ConversionesSeguras(stdout);
    try modulo11SemanticaCopia(stdout);
    try modulo12ElTipoNoreturn(stdout);
    try modulo13ProyectoFinal(stdout);

    try stdout.print(
        \\============================================================
        \\       FIN DE LA MASTERCLASS DE VARIABLES Y MEMORIA
        \\============================================================
        \\
    , .{});
}

// -------------------------------------------------------------------------
// MODULO 1: MUTABILIDAD Y LA PROHIBICION DE SHADOWING
// -------------------------------------------------------------------------
// Zig prohibe estrictamente el sombreado (shadowing) de variables en el
// mismo scope y scopes aninados inmediatamente visibles.
fn modulo1MutabilidadYShadowing(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 1: Mutabilidad y Shadowing\n", .{});

    const inmutable: i32 = 100;
    _ = inmutable; // Evitar advertencia de variable no utilizada

    var mutable: i32 = 50;
    mutable += 10;

    // En Zig, transformar variables requiere nombres unicos y explicitos
    // para evitar colisiones logicas silenciosas en el codigo.
    const entrada_usuario_sucia = "  42  ";
    const entrada_usuario_limpia = std.mem.trim(u8, entrada_usuario_sucia, " \t\r\n");
    const valor_numerico = try std.fmt.parseInt(i32, entrada_usuario_limpia, 10);

    try stdout.print("  [Mutabilidad] Original: '{s}', Procesado: {d}\n", .{ entrada_usuario_sucia, valor_numerico });
}

// -------------------------------------------------------------------------
// MODULO 2: CONTAINER LEVEL VARIABLES (VARIABLES DE CONTENEDOR)
// -------------------------------------------------------------------------
// Estas variables se declaran en el nivel superior de un archivo o estructura.
// Tienen ciclo de vida estatico. Si se declaran con 'const', su valor es
// conocido en tiempo de compilacion; de lo contrario, se conocen en ejecucion.
const ContenedorEstatico = struct {
    var estado_global: i32 = 5000;
};

fn modulo2ContainerLevelVariables(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 2: Container Level Variables\n", .{});

    // Demostracion de orden independiente y analisis perezoso de x_global e y_global
    try stdout.print("  Variable global x_global (const): {d}\n", .{x_global});
    try stdout.print("  Variable global y_global (var, calculada con x_global): {d}\n", .{y_global});

    // Modificando una variable dentro de un namespace (struct)
    ContenedorEstatico.estado_global += 250;
    try stdout.print("  Variable estatica de contenedor (ContenedorEstatico.estado_global): {d}\n", .{ContenedorEstatico.estado_global});
}

// -------------------------------------------------------------------------
// MODULO 3: STATIC LOCAL VARIABLES (VARIABLES LOCALES ESTATICAS)
// -------------------------------------------------------------------------
// Zig no tiene una palabra clave 'static' para variables locales como C.
// En su lugar, se obtiene el mismo comportamiento declarando un struct anonimo
// interno en la funcion que contiene variables de tipo 'var'.
fn contadorEstaticoLocal() i32 {
    const Instancia = struct {
        var contador: i32 = 0;
    };
    Instancia.contador += 1;
    return Instancia.contador;
}

fn modulo3StaticLocalVariables(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 3: Static Local Variables\n", .{});

    const valor1 = contadorEstaticoLocal();
    const valor2 = contadorEstaticoLocal();
    const valor3 = contadorEstaticoLocal();

    try stdout.print("  Llamada 1 a contador: {d}\n", .{valor1});
    try stdout.print("  Llamada 2 a contador: {d}\n", .{valor2});
    try stdout.print("  Llamada 3 a contador: {d}\n", .{valor3});
}

// -------------------------------------------------------------------------
// MODULO 4: THREAD LOCAL VARIABLES (TLS)
// -------------------------------------------------------------------------
// Usando la palabra clave 'threadlocal', cada hilo de ejecucion obtiene una
// copia independiente y privada de la variable estatica.
fn ejecutarHiloTls() void {
    // Cada hilo inicia con el valor por defecto: 1234
    if (tls_variable != 1234) @panic("Fallo de aislamiento TLS");
    tls_variable += 100;
}

fn modulo4ThreadLocalVariables(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 4: Thread Local Variables (TLS)\n", .{});

    // Modificamos el valor en el hilo principal
    tls_variable = 9000;

    // Lanzamos hilos independientes para verificar que no interfieren con el principal
    const h1 = try std.Thread.spawn(.{}, ejecutarHiloTls, .{});
    const h2 = try std.Thread.spawn(.{}, ejecutarHiloTls, .{});

    h1.join();
    h2.join();

    // El hilo principal conserva su estado inalterado
    try stdout.print("  TLS en Hilo Principal conserva su valor: {d} (aislado de sub-hilos)\n", .{tls_variable});
}

// -------------------------------------------------------------------------
// MODULO 5: LOCAL VARIABLES Y COMPTIME (EVALUACION DE COMPILACION)
// -------------------------------------------------------------------------
// Una variable local declarada con 'comptime' obliga a que sus operaciones
// y asignaciones se resuelvan por completo en tiempo de compilacion.
fn modulo5ComptimeVariables(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 5: Local Variables y Comptime\n", .{});

    var variable_runtime: i32 = 10;
    comptime var variable_comptime: i32 = 10;

    variable_runtime += 5;
    variable_comptime += 5;

    // Esta condicional de abajo es analizada estaticamente por el compilador,
    // y el bloque interno no se incluye en el binario si la expresion es falsa.
    if (variable_comptime != 15) {
        @compileError("Este error nunca ocurrira porque variable_comptime es 15");
    }

    try stdout.print("  Runtime var: {d} | Comptime var calculada en compilacion: {d}\n", .{ variable_runtime, variable_comptime });
}

// -------------------------------------------------------------------------
// MODULO 6: ENTEROS Y CONTROL DE DESBORDAMIENTOS (OVERFLOW)
// -------------------------------------------------------------------------
fn modulo6EnterosYOverflows(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 6: Enteros y Overflows Seguros\n", .{});

    // En Zig se pueden definir enteros con tamaños de bits arbitrarios (u3, i29, u112, etc.)
    const entero_u3: u3 = 7; // Rango: 0 a 7
    try stdout.print("  Entero arbitrario u3: {d} (ocupa {d} bit(s) en semantica)\n", .{ entero_u3, @bitSizeOf(@TypeOf(entero_u3)) });

    // 1. Wrapping Add: Simula desbordamiento natural circular con '+%'
    const max_u8: u8 = 255;
    const resultado_wrap = max_u8 +% 1; // Da la vuelta a 0
    try stdout.print("  Desbordamiento Wrapping (255 +% 1) = {d}\n", .{resultado_wrap});

    // 2. Checked Add: El compilador provee tuplas {resultado, overflow_flag}
    const resultado_seguro = @addWithOverflow(max_u8, 1);
    if (resultado_seguro[1] == 1) {
        try stdout.print("  Checked Add: Overflow detectado con seguridad (operacion prevenida).\n", .{});
    }
}

// -------------------------------------------------------------------------
// MODULO 7: FLOTANTES, BOOLEANOS Y CARACTERES
// -------------------------------------------------------------------------
fn modulo7FlotantesBooleanosChars(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 7: Flotantes, Booleanos y Chars\n", .{});

    const f: f64 = 0.55 + 0.45;
    try stdout.print("  Flotante f64 precision: {d:.4}\n", .{f});

    const activo = true;
    try stdout.print("  Tamano en memoria de un booleano: {d} byte(s)\n", .{@sizeOf(@TypeOf(activo))});

    // En Zig no existe el tipo char dedicado. Son enteros en tiempo de compilacion (comptime_int)
    const char_ascii = 'Z';
    const char_unicode = 'A'; // ASCII compatible literal

    try stdout.print("  Caracter '{c}' es el valor numerico {d} de tipo {s}\n", .{ char_ascii, char_ascii, @typeName(@TypeOf(char_ascii)) });
    try stdout.print("  Caracter Unicode '{c}' es el valor numerico {d}\n", .{ char_unicode, char_unicode });
}

// -------------------------------------------------------------------------
// MODULO 8: TIPOS COMPUESTOS Y ZERO-SIZED TYPES (ZST)
// -------------------------------------------------------------------------
fn modulo8CompuestosYZeroSizedTypes(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 8: Compuestos y Zero-Sized Types\n", .{});

    // Las tuplas en Zig son structs anonimos con campos indexados secuencialmente
    const telemetria_rapida = .{ "Voltaje", 12.4, @as(u16, 120) };
    const label = telemetria_rapida.@"0";
    const valor = telemetria_rapida.@"1";
    const ID = telemetria_rapida.@"2";

    try stdout.print("  Tupla extraida: {s} -> {d:.2}V (ID: {d})\n", .{ label, valor, ID });

    // Zero-Sized Types (ZST): El tipo 'void' ocupa exactamente 0 bytes
    const vacio: void = {};
    try stdout.print("  El tipo void ocupa: {d} bytes de espacio real en memoria\n", .{@sizeOf(@TypeOf(vacio))});
}

// -------------------------------------------------------------------------
// MODULO 9: PUNTEROS, SLICES Y FAT POINTERS
// -------------------------------------------------------------------------
fn modulo9SlicesYPointers(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 9: Punteros y Slices\n", .{});

    var buffer_datos = [6]u32{ 110, 120, 130, 140, 150, 160 };

    // 1. Puntero a elemento individual (*T)
    const ptr_individual: *u32 = &buffer_datos[3];
    ptr_individual.* = 999; // Desreferenciacion explicita con '.*'

    // 2. Slice ([]T): Contiene la direccion del segmento y su longitud (Fat Pointer)
    const mi_slice: []u32 = buffer_datos[1..5];

    try stdout.print("  Dato editado mediante puntero directo: {d}\n", .{buffer_datos[3]});
    try stdout.print("  Slice apunta a {d} elementos (Tamano Fat Pointer: {d} bytes)\n", .{ mi_slice.len, @sizeOf(@TypeOf(mi_slice)) });

    try stdout.print("  Elementos del Slice: ", .{});
    for (mi_slice) |item| {
        try stdout.print("{d} ", .{item});
    }
    try stdout.print("\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 10: CASTING EN ZIG 0.16.0
// -------------------------------------------------------------------------
fn modulo10ConversionesSeguras(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 10: Casting Moderno e Inferencia\n", .{});

    // EXPLICACION DEL ERROR RESUELTO:
    // Si numero_64 vale 1024 (comptime), castarlo a 'u8' (maximo 255) arroja error
    // de compilacion inmediato porque el compilador detecta de antemano el overflow.
    // Cambiamos el valor a '42' para permitir una conversion segura.
    const numero_64: u64 = 42;
    const numero_8: u8 = @intCast(numero_64); // @intCast infiere el tipo destino 'u8'

    const entero_base: i32 = 45000;
    const decimal_destino: f64 = @floatFromInt(entero_base);

    try stdout.print("  @intCast exitoso (u64 -> u8): {d}\n", .{numero_8});
    try stdout.print("  @floatFromInt exitoso (i32 -> f64): {d:.1}\n", .{decimal_destino});
}

// -------------------------------------------------------------------------
// MODULO 11: SEMANTICA DE COPIA (MEMORIA PLANA)
// -------------------------------------------------------------------------
fn modulo11SemanticaCopia(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 11: Semantica de Copia sin Motor de Ownership\n", .{});

    const Coordenada = struct { x: i32, y: i32 };

    const c1 = Coordenada{ .x = 55, .y = 90 };
    var c2 = c1; // Copia binaria (bit-a-bit) de la estructura
    c2.x = 9999;

    try stdout.print("  Estructura Original c1.x: {d} | Copia Independiente c2.x: {d}\n", .{ c1.x, c2.x });
}

// -------------------------------------------------------------------------
// MODULO 12: EL TIPO NORETURN (COMPORTAMIENTO TERMINAL)
// -------------------------------------------------------------------------
// 'noreturn' es un tipo de dato que indica que el flujo de control nunca
// regresara a la llamada superior (como bucles infinitos o terminaciones abruptas).
fn bucleInfinitoTerminator() noreturn {
    while (true) {}
}

fn modulo12ElTipoNoreturn(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 12: El Tipo noreturn\n", .{});
    try stdout.print("  'noreturn' es util para aserciones, abortos y manejadores de fallos criticos.\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 13: PROYECTO FINAL - PROCESADOR DE TELEMETRIA MULTI-HILO
// -------------------------------------------------------------------------
// Proyecto integrador utilizando variables a nivel de contenedor, paso de referencias
// y decodificacion de datos binarios utilizando estandares seguros de Zig.

const PaqueteTelemetria = struct {
    id_dispositivo: u8,
    temperatura_cruda: u32,

    pub fn obtenerTemperaturaC(self: *const PaqueteTelemetria) f64 {
        const temp_f: f64 = @floatFromInt(self.temperatura_cruda);
        return temp_f / 100.0;
    }
};

fn procesarFlujoTelemetria(comptime ID: u8, buffer: *const [5]u8, stdout: anytype) !void {
    // Variable local estatica para contar cuantas lecturas procesa este contexto
    const ContadorInterno = struct {
        var lecturas_procesadas: u32 = 0;
    };

    if (buffer[0] != ID) return;

    // Deserializacion segura Big Endian
    const lectura = std.mem.readInt(u32, buffer[1..5], .big);

    const paquete = PaqueteTelemetria{
        .id_dispositivo = ID,
        .temperatura_cruda = lectura,
    };

    ContadorInterno.lecturas_procesadas += 1;

    try stdout.print("  [Procesador ID {d}] Lectura Num: {d} | Temperatura: {d:.2} C\n", .{
        paquete.id_dispositivo,
        ContadorInterno.lecturas_procesadas,
        paquete.obtenerTemperaturaC(),
    });
}

fn modulo13ProyectoFinal(stdout: anytype) !void {
    try stdout.print("\n>> MODULO 13: Proyecto Final - Procesador de Telemetria de Hardware\n", .{});

    // Datos simulados de sensores: [ID, Byte1, Byte2, Byte3, Byte4]
    const stream_sensor1 = [5]u8{ 0x01, 0x00, 0x00, 0x0B, 0xB8 }; // 3000 -> 30.00 C
    const stream_sensor2 = [5]u8{ 0x02, 0x00, 0x00, 0x11, 0x94 }; // 4500 -> 45.00 C

    // Procesamos llamadas de forma secuencial y segura
    try procesarFlujoTelemetria(0x01, &stream_sensor1, stdout);
    try procesarFlujoTelemetria(0x01, &stream_sensor1, stdout); // Incrementa el contador local estatico
    try procesarFlujoTelemetria(0x02, &stream_sensor2, stdout);
}
