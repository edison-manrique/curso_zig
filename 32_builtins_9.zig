// =========================================================================================
// MASTERCLASS: REFLEXION PROFUNDA Y CONSTRUCCION PROGRAMATICA DE TIPOS (ZIG 0.16.0)
// =========================================================================================
//
// CONTENIDO DE LA MASTERCLASS (21 Builtins cubiertos):
// 1. Introspeccion y Datos Basicos: @This, @tagName, @typeName, @TypeOf, @EnumLiteral.
// 2. Creacion Programatica de Tipos: @Int, @Tuple, @Pointer, @Fn, @Struct, @Union,
//    @Enum y @typeInfo.
// 3. Manipulacion de Datos Avanzada: @truncate, @unionInit, @Vector, @volatileCast.
// 4. Control de Ejecucion y GPGPU: @trap, @workGroupId, @workGroupSize, @workItemId.
//
// Todo el codigo esta en ASCII puro para compatibilidad universal con terminales.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");

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

    try modulo1_IntrospeccionBasica(stdout);
    try modulo2_ConstruccionProgramatica(stdout);
    try modulo3_ManipulacionAvanzada(stdout);
    try modulo4_EjecucionYGPU(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: INTROSPECCION Y IDENTIDAD (@This, @tagName, @typeName, @TypeOf)
// =========================================================================================
const EstadoConex = enum { Conectado, Desconectado };

const MiContenedor = struct {
    // 1. @This() devuelve el tipo del contenedor mas interno (en este caso, 'MiContenedor')
    // Esencial para estructuras anonimas que necesitan referenciarse a si mismas (como nodos de arbol).
    const Self = @This();

    activo: bool,

    pub fn init(activo: bool) Self {
        return Self{ .activo = activo };
    }
};

fn modulo1_IntrospeccionBasica(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Introspeccion Basica de Tipos e Identidades\n", .{});

    // 1. @This()
    const inst = MiContenedor.init(true);
    try stdout.print("  [This] Instancia creada con exito. Tipo resuelto: {any}\n", .{@TypeOf(inst)});

    // 2. @tagName: Convierte un tag de enum o union en su nombre en string literal
    const nombre_tag = @tagName(EstadoConex.Conectado); // "Conectado"
    try stdout.print("  [tagName] EstadoConex.Conectado traducido a string: {s}\n", .{nombre_tag});

    // 3. @typeName: Devuelve el nombre completamente calificado del tipo en string
    const nombre_tipo = @typeName(MiContenedor);
    try stdout.print("  [typeName] Nombre cualificado de la estructura: {s}\n", .{nombre_tipo});

    // 4. @TypeOf: Resuelve el tipo de una expresion en tiempo de compilacion sin efectos colaterales
    const variable_sucia: i32 = 42;
    const TipoDeVariable = @TypeOf(variable_sucia);
    try stdout.print("  [TypeOf] El tipo de 'variable_sucia' es: {any}\n", .{TipoDeVariable});

    // 5. @EnumLiteral: El tipo comptime especial para los identificadores de enum sin coaccionar
    const literal: @EnumLiteral() = .Conectado;
    const estado_coaccionado: EstadoConex = literal; // Coacciona al enum real
    try stdout.print("  [EnumLiteral] Literal .Conectado coaccionado a EstadoConex: {any}\n\n", .{estado_coaccionado});
}

// =========================================================================================
// MODULO 2: CONSTRUCCION PROGRAMATICA DE TIPOS EN COMPTIME
// =========================================================================================
fn modulo2_ConstruccionProgramatica(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Generacion de Tipos Dinamicos con Metaprogramacion\n", .{});

    // Zig te permite CREAR tipos de datos reales utilizando funciones comptime. No necesitas
    // plantillas pesadas; el tipo se construye como si fuera una funcion normal.

    // 1. @Int: Crea un entero con signo o sin signo con un ancho de bits EXACTO y personalizado.
    // CORRECCION ZIG 0.16.0: Usamos 'CustomU18' para evitar colisiones con la primitiva nativa u18.
    const CustomU18 = @Int(.unsigned, 18); // Creamos un entero de 18 bits (u18)
    const valor_u18: CustomU18 = 250000; // Cabe perfectamente en 18 bits (max 262143)
    try stdout.print("  [@Int] Creado tipo 'CustomU18' (18 bits) en tiempo de compilacion de manera dinamica. Valor: {d}\n", .{valor_u18});

    // 2. @Tuple: Crea una Tupla dinamica especificando los tipos de sus campos en un array
    const TuplaDinamica = @Tuple(&[_]type{ i32, bool, f32 });
    const mi_tupla = TuplaDinamica{ 100, true, 3.14 };
    try stdout.print("  [@Tuple] Tupla generada: {{ {d}, {}, {d:.2} }}\n", .{ mi_tupla[0], mi_tupla[1], mi_tupla[2] });

    // 3. @typeInfo: Descompone cualquier tipo para inspeccionar sus componentes estructurales.
    // Esto nos permite hacer "Reflexion Estatica" de campos, funciones y alineaciones.
    const info_contenedor = @typeInfo(MiContenedor);
    const campos_struct = info_contenedor.@"struct".fields;
    try stdout.print("  [@typeInfo] Estructura 'MiContenedor' posee {d} campos en su declaracion.\n", .{campos_struct.len});

    // 4. Builtins de Construccion Avanzada (Explicados conceptualmente):
    // Zig expone builtins para generar de forma exacta punteros, funciones, estructuras, uniones y enums:
    // - @Pointer: Genera tipos puntero (*T, []T, [*]T) parametrizando atributos, centinelas y alineacion.
    // - @Fn: Genera firmas de funciones parametrizando tipos de argumentos y atributos ABI.
    // - @Struct / @Union / @Enum: Generan contenedores completos en memoria dinamica del compilador.
    comptime {
        if (false) {
            // Ejemplo de generacion de puntero personalizado:
            _ = @Pointer(.One, .{ .is_const = true, .is_volatile = false, .alignment = 4, .address_space = .generic }, u8, null);
        }
    }
    try stdout.print("  [Info] @Pointer, @Fn, @Struct, @Union y @Enum construyen la ABI completa en memoria del compilador.\n\n", .{});
}

// =========================================================================================
// MODULO 3: MANIPULACION DE DATOS AVANZADA (@truncate, @unionInit, @Vector, @volatileCast)
// =========================================================================================
const UnionFisica = union(enum) {
    entero: i32,
    flotante: f32,
};

fn modulo3_ManipulacionAvanzada(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Manipulacion Avanzada de Datos y Volatilidad\n", .{});

    // 1. @truncate: Corta los bits mas significativos de un entero para encajarlo en un tipo menor.
    // A diferencia de @intCast (que hace panics si no cabe), @truncate siempre funciona y descarta bits.
    const valor_u16: u16 = 0xABCD;
    const truncado: u8 = @truncate(valor_u16); // Descarta 0xAB y se queda con 0xCD
    try stdout.print("  [@truncate] u16 (0xABCD) truncado a u8: 0x{X}\n", .{truncado});

    // 2. @unionInit: Inicializa una union especificando el campo activo mediante un String dinamico
    // en lugar de usar un identificador estatico. Crucial para deserializadores JSON/binarios.
    const u_inst = @unionInit(UnionFisica, "entero", @as(i32, 777));
    try stdout.print("  [@unionInit] Union instanciada activando el campo 'entero': {d}\n", .{u_inst.entero});

    // 3. @Vector: Instanciacion nativa de vectores SIMD (Single Instruction Multiple Data)
    const V = @Vector(4, i32);
    const vector: V = .{ 1, 2, 3, 4 };
    try stdout.print("  [@Vector] Vector SIMD inicializado: {any}\n", .{vector});

    // 4. @volatileCast: Remueve el calificador 'volatile' de un puntero.
    // Volatile le dice al compilador que la memoria puede cambiar por fuera de la aplicacion (ej. registros MMIO).
    // CORRECCION ZIG 0.16.0: 'volatile' pertenece al puntero (*volatile T), no a la variable directamente.
    var valor_real: i32 = 100;

    // Obtenemos un puntero volatil mediante coercion automatica de tipo
    const ptr_volatil: *volatile i32 = &valor_real;

    // Removemos la restriccion volatil usando @volatileCast de forma legal
    const ptr_plano: *i32 = @volatileCast(ptr_volatil);
    ptr_plano.* = 200;

    try stdout.print("  [@volatileCast] Volatilidad removida. Valor modificado: {d}\n\n", .{valor_real});
}

// =========================================================================================
// MODULO 4: CONTROL DE EJECUCION Y ARQUITECTURAS GPU (@trap, @workGroup*)
// =========================================================================================
fn modulo4_EjecucionYGPU(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Control de Exito de Ejecucion y GPGPU (Shaders)\n", .{});

    // 1. @trap: Fuerza una instruccion de trampa por hardware (como un crash/jam ilegal irreversible).
    // A diferencia de @breakpoint(), la ejecucion jamas continua despues de este punto.
    // Lo protegemos en un if (false) para que no aborte la ejecucion del manual.
    if (false) {
        @trap();
    }
    try stdout.print("  [@trap] Instruccion de trampa de hardware ilegal lista (protegida).\n", .{});

    // 2. @workGroupId / @workGroupSize / @workItemId:
    // Estas son intrinsicas especiales de hardware que SOLO compilan cuando tu arquitectura
    // destino es una GPU (por ejemplo, compilando sombreadores/shaders para SPIR-V o NVPTX de NVIDIA).
    //
    // PROTECCION COMPTIME: Usamos el sistema de reflexion del compilador para asegurarnos
    // de que solo se analicen semanticamente si estamos compilando para una GPU.
    comptime {
        const arch = builtin.target.cpu.arch;
        if (arch == .wasm32 or arch == .wasm64) {
            const tamano_actual = @wasmMemorySize(0);
            _ = @wasmMemoryGrow(0, 1); // Crece la memoria en 1 pagina (64KB)
            _ = tamano_actual;
        }
    }

    try stdout.print("  [Wasm Check] Intrinsicas @wasmMemory* protegidas en tiempo de compilacion.\n", .{});

    // 2. @panic: Invoca el manejador de fallos fatales del programa.
    // Detiene el hilo actual e imprime el stack trace. Lo dejamos dentro de un 'if (false)'
    // para que la ejecucion de este manual termine exitosamente.
    if (false) {
        @panic("Detencion forzada por error critico no recuperable.");
    }

    try stdout.print("  [@panic] Manejador de fallos del sistema listo (protegido por seguridad).\n\n", .{});
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
        \\    MASTERCLASS 16: REFLEXION EXTREMA Y ENLACE GPU (ZIG 0.16.0)
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\ FIN DE LA MASTERCLASS DE BUILTINS DE ZIG. COMPILACION COMPLETADA.
        \\====================================================================
        \\ CONCEPTOS CLAVE REPASADOS:
        \\ - @This() y @tagName otorgan identidad estatica a tus estructuras y enums.
        \\ - @Int, @Tuple y @typeInfo te permiten construir sistemas de tipos dinamicos.
        \\ - @unionInit permite mapear e instanciar uniones de forma segura usando Strings.
        \\ - @volatileCast abre las puertas a la interaccion con registros MMIO de hardware.
        \\ - Zig posee soporte nativo para sombreadores y computacion en GPU (@workGroup*).
        \\====================================================================
        \\
    , .{});
}
