// =========================================================================
//           MASTERCLASS: MANIPULACION DE BITS Y OPERADORES BINARIOS
//                         EDICION ZIG 0.16.0
// =========================================================================
// Este documento ha sido disenado como la guia de referencia definitiva
// para dominar los operadores de bits (bitwise), desplazamientos seguros,
// enteros de ancho arbitrario y built-ins orientados a hardware en Zig.
//
// NOTA DE COMPATIBILIDAD: Todo el codigo, graficos ASCII y explicaciones
// estan limitados estrictamente a la codificacion ASCII de 7 bits (rango 0-127)
// para prevenir errores de compilacion y renderizado en consolas legadas.

// =========================================================================
// TABLA DE CONTENIDOS (TEMARIO)
// =========================================================================
// 1. FILOSOFIA: POR QUE ZIG REVOLUCIONA LA MANIPULACION DE BITS
//    1.1 Adios a la promocion implicita de enteros de C
//    1.2 Tipado estricto en el tamano de los desplazamientos (Shift sizes)
//
// 2. MODULO 1: ENTEROS DE ANCHO ARBITRARIO (u1, u7, i24, etc.)
//    2.1 El fin del desperdicio de memoria y mascaras manuales
//
// 3. MODULO 2: OPERADORES BOOLEANOS A NIVEL DE BIT (&, |, ^, ~)
//    3.1 Mascaras, seteo, limpieza y alternancia de bits (Toggling)
//
// 4. MODULO 3: DESPLAZAMIENTOS SEGUROS (SHIFTS: <<, >>)
//    4.1 Desplazamiento Logico vs Aritmetico (Unsigned vs Signed)
//    4.2 La regla de oro del "Logaritmo Base 2" en el operando derecho
//
// 5. MODULO 4: FUNCIONES INTEGRADAS (BUILT-INS) DE ALTO RENDIMIENTO
//    5.1 @popCount, @clz, @ctz y @bitReverse
//
// 6. MODULO 5: ESTRUCTURAS EMPAQUETADAS (PACKED STRUCTS)
//    6.1 Reemplazando macros de C con structs estandarizados
//    6.2 @bitCast: Reinterpretacion de memoria a coste cero
//
// 7. PROYECTO COMPLETO: CONTROLADOR Y GESTOR DE MEMORIA POR BITS (BITSET)
//
// 8. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG

// =========================================================================
// 1. FILOSOFIA: POR QUE ZIG REVOLUCIONA LA MANIPULACION DE BITS
// =========================================================================
// En lenguajes como C o C++, operar con bits es un campo minado. Los tipos
// pequeños (como uint8_t) son "promovidos" secretamente a int antes de
// operarse, causando bugs catastroficos por extension de signo (Sign Extension).
// Ademas, desplazar bits mas alla de la capacidad del tipo es Undefined Behavior.
//
// Zig elimina esto de raiz:
// - No hay promocion implicita de tipos. Un u8 sigue siendo un u8.
// - El tamano de un shift se valida estaticamente mediante el sistema de tipos.
// - Tienes control total y predecible del bit de signo.

const std = @import("std");
const print = std.debug.print;

// =========================================================================
// 2. MODULO 1: ENTEROS DE ANCHO ARBITRARIO
// =========================================================================
// En Zig no estas limitado a los clasicos u8, u16, u32 o u64.
// Puedes definir exactamente cuantos bits necesitas en memoria.

fn modulo1EnterosArbitrarios() void {
    print(">> MODULO 1: Enteros de Ancho Arbitrario\n", .{});

    // Un u1 es un verdadero booleano a nivel numerico (0 o 1).
    const bit_flag: u1 = 1;

    // Un u24 es ideal para representar colores RGB sin rellenar memoria inutilmente.
    const color_rgb: u24 = 0xFF00AA;

    // Un i7 permite representar valores con signo en exactamente 7 bits.
    const temperatura: i7 = -50;

    print("  Entero u1 (Bandera) : {d}\n", .{bit_flag});
    print("  Entero u24 (RGB)    : 0x{X:0>6}\n", .{color_rgb});
    print("  Entero i7 (Signo)   : {d}\n\n", .{temperatura});
}

// =========================================================================
// 3. MODULO 2: OPERADORES BOOLEANOS A NIVEL DE BIT
// =========================================================================
// Los pilares de la manipulacion de registros: AND (&), OR (|), XOR (^), NOT (~).

fn modulo2BooleanoDeBits() void {
    print(">> MODULO 2: Operadores Booleanos de Bits\n", .{});

    const estado_inicial: u8 = 0b1010_0000;

    // OR (|) -> SET: Enciende bits sin afectar al resto.
    const encender_bits = estado_inicial | 0b0000_1111;

    // AND (&) junto con NOT (~) -> CLEAR: Apaga bits especificos.
    const mascara_apagar: u8 = 0b1000_0000;
    const apagar_bits = estado_inicial & ~mascara_apagar;

    // XOR (^) -> TOGGLE: Alterna o invierte bits especificos.
    const alternar_bits = estado_inicial ^ 0b1111_1111;

    print("  Original        : 0b{b:0>8}\n", .{estado_inicial});
    print("  OR (Set)        : 0b{b:0>8}\n", .{encender_bits});
    print("  AND+NOT (Clear) : 0b{b:0>8}\n", .{apagar_bits});
    print("  XOR (Toggle)    : 0b{b:0>8}\n\n", .{alternar_bits});
}

// =========================================================================
// 4. MODULO 3: DESPLAZAMIENTOS SEGUROS (SHIFTS: <<, >>)
// =========================================================================
// Zig es implacable con los Shifts. El operando de la derecha DEBE caber en
// el "logaritmo base 2" del numero de bits del operando de la izquierda.

fn modulo3Desplazamientos() void {
    print(">> MODULO 3: Desplazamientos Seguros y Fuertemente Tipados\n", .{});

    const valor_base: u8 = 0b0000_0001;

    // REGLA DE ORO: Para un u8 (8 bits), log2(8) = 3.
    // Por tanto, el desplazamiento SOLO puede ser un tipo u3 (rango 0-7).
    // Si intentas `const shift: u8 = 4; valor_base << shift;` => COMPILE ERROR.
    const shift_permitido: u3 = 4;
    const desplazado = valor_base << shift_permitido;
    print("  Shift Left Seguro (1 << 4) : 0b{b:0>8}\n", .{desplazado});

    // SHIFT LOGICO VS ARITMETICO (El comportamiento de >>)
    const base_sin_signo: u8 = 0b1000_0000; // Unsigned (u8)
    const base_con_signo: i8 = @bitCast(base_sin_signo); // Signed (i8, equivalente a -128)

    // En Unsigned (u), '>>' es Logico: Desplaza e inyecta CEROS por la izquierda.
    const shift_logico = base_sin_signo >> 1;

    // En Signed (i), '>>' es Aritmetico: Desplaza y COPIA el bit de signo anterior.
    const shift_aritmetico = base_con_signo >> 1;

    print("  Shift Right Unsigned (>>1) : 0b{b:0>8} (Logico)\n", .{shift_logico});
    print("  Shift Right Signed   (>>1) : 0b{b:0>8} (Aritmetico, preserva signo)\n\n", .{@as(u8, @bitCast(shift_aritmetico))});
}

// =========================================================================
// 5. MODULO 4: FUNCIONES INTEGRADAS (BUILT-INS) DE ALTO RENDIMIENTO
// =========================================================================
// Zig expone instrucciones de hardware nativas directamente al programador
// evitando bucles costosos. Dependiendo de la CPU (x86, ARM), el compilador
// emitira instrucciones de un solo ciclo como POPCNT o TZCNT.

fn modulo4Builtins() void {
    print(">> MODULO 4: Built-ins de Hardware (Funciones Intrinsecas)\n", .{});

    const registro: u8 = 0b0011_0100;

    // @popCount: "Population Count", ¿Cuantos bits estan encendidos (1)?
    const bits_activos = @popCount(registro);

    // @clz: "Count Leading Zeroes", Ceros a la izquierda antes del primer '1'.
    const ceros_lideres = @clz(registro);

    // @ctz: "Count Trailing Zeroes", Ceros a la derecha despues del ultimo '1'.
    const ceros_finales = @ctz(registro);

    // @bitReverse: Invierte todo el orden de los bits en espejo.
    const espejado = @bitReverse(registro);

    print("  Registro Analizado    : 0b{b:0>8}\n", .{registro});
    print("  @popCount (Bits 1)    : {}\n", .{bits_activos});
    print("  @clz (Ceros Izq)      : {}\n", .{ceros_lideres});
    print("  @ctz (Ceros Der)      : {}\n", .{ceros_finales});
    print("  @bitReverse           : 0b{b:0>8}\n\n", .{espejado});
}

// =========================================================================
// 6. MODULO 5: ESTRUCTURAS EMPAQUETADAS (PACKED STRUCTS)
// =========================================================================
// Adiós a escribir mascaras bit a bit en C. En Zig puedes definir exactamente
// cómo se acopla una estructura a la memoria, y usar @bitCast para convertirla
// a enteros nativos sin coste de ejecucion (Coste Cero).

// El mapeo de bits en Zig ocurre desde el LSB (Least Significant Bit) al MSB.
const ConfiguracionUART = packed struct {
    tx_activado: bool, // Bit 0 (LSB)
    rx_activado: bool, // Bit 1
    baud_rate: u2, // Bits 2-3
    modo_paridad: u2, // Bits 4-5
    interrupcion_on: bool, // Bit 6
    _reservado: u1 = 0, // Bit 7 (MSB) - Padding para completar exactamente 8 bits (u8)
};

fn modulo5PackedStructs() void {
    print(">> MODULO 5: Packed Structs y @bitCast\n", .{});

    const hardware_cfg = ConfiguracionUART{
        .tx_activado = true, // 1
        .rx_activado = false, // 0
        .baud_rate = 0b11, // 3
        .modo_paridad = 0b00, // 0
        .interrupcion_on = true, // 1
        ._reservado = 0, // 0
    };

    // Convertimos la logica humana en un byte crudo listo para hardware I/O
    const byte_exportable: u8 = @bitCast(hardware_cfg);

    print("  Struct Hardware mapeado automaticamente a byte crudo:\n", .{});
    print("  Exportado a CPU: 0b{b:0>8} (En hexadecimal: 0x{X:0>2})\n\n", .{ byte_exportable, byte_exportable });
}

// =========================================================================
// 7. PROYECTO COMPLETO: CONTROLADOR Y GESTOR DE MEMORIA (BITSET)
// =========================================================================
// Crearemos un sistema critico de "Banderas de Estado" (Bitset) de 64 pines
// para un SoC embebido usando unicamente una variable u64 y operadores nativos.
// Utilizaremos la combinacion perfecta de <<, |, &, ~, @popCount y @ctz.

const RegistroSoC64 = struct {
    memoria: u64 = 0, // 64 flags empaquetadas en apenas 8 bytes

    // 1. SET: Enciende el pin deseado
    pub fn habilitarPin(self: *@This(), indice: u6) void {
        const mascara: u64 = @as(u64, 1) << indice;
        self.memoria = self.memoria | mascara;
    }

    // 2. CLEAR: Apaga el pin de forma quirurgica
    pub fn deshabilitarPin(self: *@This(), indice: u6) void {
        const mascara: u64 = ~(@as(u64, 1) << indice);
        self.memoria = self.memoria & mascara;
    }

    // 3. LECTURA ASISTIDA POR HARDWARE: Busca un slot vacio en O(1)
    pub fn buscarPrimerPinLibre(self: *@This()) ?u6 {
        if (self.memoria == std.math.maxInt(u64)) return null; // Todo encendido

        // Invertimos la memoria, de modo que los 0s (libres) se vuelven 1s.
        // @ctz nos dira exactamente la posicion del primer 1 disponible.
        const ceros_finales = @ctz(~self.memoria);

        return @as(u6, @intCast(ceros_finales));
    }
};

fn ejecucionProyectoBitset() void {
    print(">> PROYECTO INTEGRAL: Controlador SoC de 64 Pines de Alta Velocidad <<\n", .{});

    var controlador = RegistroSoC64{};

    // Habilitamos los pines 0, 1, 2, y el pin 5.
    controlador.habilitarPin(0);
    controlador.habilitarPin(1);
    controlador.habilitarPin(2);
    controlador.habilitarPin(5);

    print("  Estado del SoC despues de inicializar 4 pines:\n", .{});
    print("  0b{b:0>64}\n", .{controlador.memoria});

    const pines_usados = @popCount(controlador.memoria);
    print("  Consumo actual reportado por @popCount : {d} pines activos.\n", .{pines_usados});

    // Apagamos el pin 1 para demostrar el Clear.
    controlador.deshabilitarPin(1);

    if (controlador.buscarPrimerPinLibre()) |pin_libre| {
        print("  El sistema busco con @ctz el primer pin libre y encontro el indice: {d}\n\n", .{pin_libre});
    }
}

// =========================================================================
// PUNTO DE ENTRADA PRINCIPAL
// =========================================================================
pub fn main() void {
    print("--- INICIO DE LA MASTERCLASS DE MANIPULACION DE BITS ---\n\n", .{});

    modulo1EnterosArbitrarios();
    modulo2BooleanoDeBits();
    modulo3Desplazamientos();
    modulo4Builtins();
    modulo5PackedStructs();
    ejecucionProyectoBitset();

    print("--- FIN DE LA MASTERCLASS DE MANIPULACION DE BITS ---\n", .{});
}

// =========================================================================
// 8. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG
// =========================================================================
// 1. EVITE INVENTAR LA RUEDA (MASCARAS): Si necesita modelar un registro
//    de hardware, un protocolo de red o una cabecera de datos, utilice un
//    `packed struct`. Es matematicamente superior y libre de errores humanos
//    comparado con hacer shifts y ANDs (<<, &) de forma manual.
//
// 2. RESPETE LOS LIMITES DE SHIFT (LOG2): Zig no compilara si intenta
//    desplazar un `u32` pasandole un entero normal. Tiene que utilizar
//    estrictamente un `u5` (ya que 2^5 = 32). Esta regla salva vidas al
//    prevenir silenciosos desbordamientos y undefined behaviors en runtime.
//
// 3. EL SIGNO DEFINE SU DESPLAZAMIENTO: El operador `>>` toma decisiones
//    basadas en el sistema de tipos. Uselo sobre tipos `u` (unsigned) si
//    quiere limpiar con ceros, y sobre tipos `i` (signed) si quiere
//    preservar el bit negativo. Ante la duda, use @bitCast.
//
// 4. APROVECHE EL HARDWARE (BUILT-INS): Nunca programe un bucle `while` para
//    contar los bits en '1' de un entero. Utilice `@popCount`, `@clz` y
//    `@ctz`. Zig transformara estas llamadas magicas en la instruccion
//    optimizada de un solo ciclo mas rapida de su arquitectura de CPU.
// =========================================================================
