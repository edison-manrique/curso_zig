// =========================================================================
//           MASTERCLASS: OPERADORES Y PRECEDENCIA EN ZIG
//                         EDICION ZIG 0.16.0
// =========================================================================
// Este documento ha sido disenado como la guia de referencia definitiva
// para dominar los operadores matematicos, de bits, de desempaquetado,
// de punteros y de fusion de errores en Zig.
//
// NOTA DE COMPATIBILIDAD: Todo el codigo, graficos ASCII y explicaciones
// estan limitados estrictamente a la codificacion ASCII de 7 bits (rango 0-127)
// para prevenir errores de compilacion y renderizado en consolas legadas.

// =========================================================================
// TABLA DE CONTENIDOS (TEMARIO)
// =========================================================================
// 1. FILOSOFIA: POR QUE ZIG RECHAZA LA SOBREGARGA DE OPERADORES
//    1.1 Legibilidad pura y prevencion de flujo de control oculto
//    1.2 Lo que ves en el codigo es exactamente lo que se ejecuta
//
// 2. MODULO 1: ARITMETICA ESTANDAR, DE ENVOLVIMIENTO Y DE SATURACION
//    2.1 Aritmetica Estandar (+, -, *, /, %): El peligro del desbordamiento
//    2.2 Aritmetica de Envolvimiento o Wrapping (+%, -%, *%): Twos-Complement
//    2.3 Aritmetica de Saturacion (+|, -|, *|): Limites fisicos del hardware
//
// 3. MODULO 2: OPERADORES DE BITS Y DESPLAZAMIENTOS
//    3.1 Desplazamiento Izquierda y Derecha (<<, >>, <<|)
//    3.2 Operaciones Booleanas de Bits (&, |, ^, ~)
//
// 4. MODULO 3: OPERADORES DE DESEMPAQUETADO SEGURO (UNWRAP)
//    4.1 Defaulting Optional Unwrap (orelse)
//    4.2 Optional Assert Unwrap (.?)
//    4.3 Defaulting Error Unwrap (catch)
//
// 5. MODULO 4: LOGICA, COMPARACION Y RESOLUCION DE TIPOS CONCURRENTES
//    5.1 Operadores Logicos Cortocircuitados (and, or, !)
//    5.2 Comparaciones (==, !=, <, >, <=, >=)
//    5.3 Peer Type Resolution (Resolucion Homogenea de Tipos)
//
// 6. MODULO 5: OPERADORES DE ARREGLOS Y PUNTEROS
//    6.1 Concatenacion (++) y Multiplicacion (**) en tiempo de compilacion
//    6.2 Direccionamiento (&) y Desreferenciacion (.*)
//
// 7. MODULO 6: FUSION DE SETS DE ERRORES (||)
//
// 8. TABLA OFICIAL DE PRECEDENCIA DE OPERADORES
//
// 9. PROYECTO COMPLETO: CALCULADORA CRITICA PARA SISTEMAS EMBEBIDOS
//
// 10. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG

// =========================================================================
// 1. FILOSOFIA: POR QUE ZIG RECHAZA LA SOBREGARGA DE OPERADORES
// =========================================================================
// En lenguajes como C++, Rust o C#, puedes "sobrecargar" operadores.
// Esto significa que si ves `a + b`, no puedes estar seguro de que hace
// esa linea sin conocer los tipos de `a` y `b`. Podria estar sumando enteros,
// concatenando strings, realizando una consulta a la base de datos o enviando
// un paquete por red de forma oculta.
//
// Zig rechaza esto tajantemente basandose en un principio fundamental:
// "No debe haber flujo de control oculto ni costes ocultos."
//
// Cuando ves un operador en Zig, sabes que esta realizando una operacion
// basica de la CPU descrita en este documento, y absolutamente nada mas.
// Si necesitas sumar dos vectores estructurados en Zig, debes llamar a una
// funcion explicita (ej. `v1.add(v2)`).

const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

// =========================================================================
// 2. MODULO 1: ARITMETICA ESTANDAR, DE ENVOLVIMIENTO Y DE SATURACION
// =========================================================================
// Zig divide las operaciones aritmeticas en tres familias semanticas para
// que el desarrollador decida exactamente que hacer en caso de desbordamiento.

fn modulo1Aritmetica() void {
    print(">> MODULO 1: Familias Aritmeticas de Zig\n", .{});

    // -------------------------------------------------------------------------
    // 2.1 ARITMETICA ESTANDAR (+, -, *, /, %)
    // -------------------------------------------------------------------------
    // Estas operaciones asumen que el resultado cabe en el tipo de datos.
    // Si ocurre un desbordamiento (Overflow) en modo Debug o ReleaseSafe,
    // el programa lanzara un Panic de inmediato.
    const a: u8 = 200;
    const b: u8 = 50;
    const suma_estandar = a + b; // Correcto, 250 cabe en u8.
    print("  Aritmetica Estandar: {d} + {d} = {d}\n", .{ a, b, suma_estandar });

    // Si intentamos hacer: `const error_overflow = a + 100;` el programa morira
    // en tiempo de ejecucion para evitar corrupcion de memoria.

    // -------------------------------------------------------------------------
    // 2.2 ARITMETICA DE ENVOLVIMIENTO O WRAPPING (+%, -%, *%)
    // -------------------------------------------------------------------------
    // Utiliza la aritmetica de complemento a dos. Al superar el limite del tipo,
    // el valor "da la vuelta" (envuelve) al valor minimo del rango.
    // Es equivalente a la operacion modulo del limite.
    const max_u8: u8 = 255;
    const wrapping_add = max_u8 +% 1; // 255 + 1 envuelve a 0
    print("  Aritmetica Wrapping (255 +%% 1): {d}\n", .{wrapping_add});

    const wrapping_sub = @as(u8, 0) -% 1; // 0 - 1 envuelve a 255
    print("  Aritmetica Wrapping (0 -%% 1): {d}\n", .{wrapping_sub});

    // -------------------------------------------------------------------------
    // 2.3 ARITMETICA DE SATURACION (+|, -|, *|)
    // -------------------------------------------------------------------------
    // Al superar el limite del tipo, el valor se "pega" (satura) al limite
    // maximo o minimo posible de dicho tipo. No ocurre panic ni envolvimiento.
    const saturating_add = @as(u8, 200) +| 100; // Satura al limite maximo de u8 (255)
    print("  Aritmetica Saturacion (200 +| 100): {d}\n", .{saturating_add});

    const saturating_sub = @as(u32, 10) -| 100; // Satura al limite minimo de u32 (0)
    print("  Aritmetica Saturacion (10 -| 100): {d}\n\n", .{saturating_sub});
}

// =========================================================================
// 3. MODULO 2: OPERADORES DE BITS Y DESPLAZAMIENTOS
// =========================================================================
// Zig provee operadores de bajo nivel optimizados para manipulacion de registros,
// protocolos binarios y mascaras de control.

fn modulo2Bits() void {
    print(">> MODULO 2: Operadores de Bits y Desplazamiento\n", .{});

    const registro_a: u8 = 0b10101111;
    const registro_b: u8 = 0b00001111;

    // AND, OR, XOR y NOT de bits
    const bitwise_and = registro_a & registro_b;
    const bitwise_or = registro_a | registro_b;
    const bitwise_xor = registro_a ^ registro_b;
    const bitwise_not = ~registro_a;

    print("  AND:  0b{b:0>8}\n", .{bitwise_and});
    print("  OR:   0b{b:0>8}\n", .{bitwise_or});
    print("  XOR:  0b{b:0>8}\n", .{bitwise_xor});
    print("  NOT:  0b{b:0>8}\n", .{bitwise_not});

    // Desplazamientos (Shift Left y Shift Right)
    // El operando derecho debe ser conocido en tiempo de compilacion (comptime)
    // o tener un tamano logaritmo en base 2 del operando izquierdo.
    const shift_left = @as(u8, 1) << 3; // Desplaza 1 tres veces a la izquierda (8)
    const shift_right = @as(u8, 16) >> 2; // Desplaza 16 dos veces a la derecha (4)
    print("  Shift Left (1 << 3): {d}\n", .{shift_left});
    print("  Shift Right (16 >> 2): {d}\n\n", .{shift_right});
}

// =========================================================================
// 4. MODULO 3: OPERADORES DE DESEMPAQUETADO SEGURO (UNWRAP)
// =========================================================================
// Los tipos de datos avanzados de Zig (Optionals y Error Unions) se gestionan
// mediante operadores dedicados de flujo de control explicito.

fn modulo3Desempaquetado() void {
    print(">> MODULO 3: Operadores de Desempaquetado (Optionals y Errors)\n", .{});

    // 1. DEFAULTING OPTIONAL UNWRAP (orelse)
    // Evalua si un opcional es null. Si lo es, retorna un valor por defecto.
    const puerto_opcional: ?u16 = null;
    const puerto_defecto = puerto_opcional orelse 8080;
    print("  Orelse fallback (null orelse 8080): {d}\n", .{puerto_defecto});

    // 2. OPTIONAL ASSERT UNWRAP (.?)
    // Es equivalente a: `opcional orelse unreachable`.
    // Indica al compilador: "Estoy 100% seguro de que no es null, extrae el valor".
    // Si resulta ser null en Debug/ReleaseSafe, el programa lanza un Panic.
    const host_opcional: ?[]const u8 = "localhost";
    const host_real = host_opcional.?;
    print("  Assert Unwrap (.?): '{s}'\n", .{host_real});

    // 3. DEFAULTING ERROR UNWRAP (catch)
    // Captura un error de una Error Union y retorna un valor alternativo.
    const resultado_error: anyerror!u32 = error.ConexionPerdida;
    const bypass_error = resultado_error catch 500;
    print("  Catch fallback (error catch 500): {d}\n\n", .{bypass_error});
}

// =========================================================================
// 5. MODULO 4: LOGICA, COMPARACION Y RESOLUCION DE TIPOS CONCURRENTES
// =========================================================================
// Los operadores logicos booleanos en Zig tienen un comportamiento muy util:
// son cortocircuitados (Short-Circuiting).

fn funcionConEfectoSecundario() bool {
    print("    [ALERTA] Esta funcion jamas debio ejecutarse!\n", .{});
    return true;
}

fn modulo4Logica() void {
    print(">> MODULO 4: Operadores Logicos Cortocircuitados\n", .{});

    // Si el operando izquierdo determina el resultado de la operacion entera,
    // el operando derecho NI SIQUIERA es evaluado.
    const condicion_izquierda = false;

    // Al ser condicion_izquierda 'false', la expresion entera 'and' es imposible
    // que sea 'true'. El compilador omite llamar a la funcion.
    const resultado_logico = condicion_izquierda and funcionConEfectoSecundario();
    _ = resultado_logico;
    print("  Logical AND cortocircuitado exitosamente.\n", .{});

    // PEER TYPE RESOLUTION (Resolucion Homogenea de Tipos)
    // Los operadores de comparacion y operadores condicionales analizan los tipos
    // de ambos operandos para encontrar un tipo comun seguro en tiempo de compilacion.
    const num_i8: i8 = 10;
    const num_i16: i16 = 20;
    const comparacion = num_i8 < num_i16; // i8 es promovido a i16 para comparar de forma segura
    print("  Comparacion cruzada (i8 < i16): {}\n\n", .{comparacion});
}

// =========================================================================
// 6. MODULO 5: OPERADORES DE ARREGLOS Y PUNTEROS
// =========================================================================
// Los operadores especiales `++` y `**` permiten concatenar y multiplicar
// estructuras de datos agregadas en tiempo de compilacion.

fn modulo5ArreglosYPunteros() void {
    print(">> MODULO 5: Operadores de Arreglos y Punteros\n", .{});

    // 1. CONCATENACION DE ARREGLOS (++)
    // Solo disponible si las longitudes son conocidas en tiempo de compilacion.
    const arr1 = [_]u32{ 1, 2 };
    const arr2 = [_]u32{ 3, 4 };
    const fusionado = arr1 ++ arr2;
    print("  Concatenacion (arr1 ++ arr2): {any}\n", .{fusionado});

    // 2. MULTIPLICACION DE ARREGLOS (**)
    const patron = "Hi! " ** 3;
    print("  Multiplicacion de String ('Hi! ' ** 3): '{s}'\n", .{patron});

    // 3. DIRECCIONAMIENTO (&) Y DESREFERENCIACION (.*)
    const numero: u32 = 999;
    const puntero = &numero; // & extrae la direccion de memoria del numero
    const valor_recuperado = puntero.*; // .* desreferencia el puntero para leer el valor
    print("  Puntero direccion: {*} | Valor desreferenciado: {d}\n\n", .{ puntero, valor_recuperado });
}

// =========================================================================
// 7. MODULO 6: FUSION DE SETS DE ERRORES (||)
// =========================================================================
// El operador de barra doble `||` tiene un uso especial para los tipos en Zig.
// Permite combinar de forma estatica dos conjuntos de errores independientes
// para crear una nueva union homogenea de errores.

const ErroresBaseDeDatos = error{
    TablaInexistente,
    QueryCorrupto,
};

const ErroresDeRed = error{
    Timeout,
    ServidorInalcanzable,
};

// Fusionamos ambos sets en un unico tipo en tiempo de compilacion
const ErroresGlobales = ErroresBaseDeDatos || ErroresDeRed;

fn modulo6FusionErrores() void {
    print(">> MODULO 6: Fusion de Set de Errores (||)\n", .{});

    const err_db: ErroresGlobales = ErroresGlobales.TablaInexistente;
    const err_red: ErroresGlobales = ErroresGlobales.Timeout;

    print("  Error DB fusionado: {}\n", .{err_db});
    print("  Error Red fusionado: {}\n\n", .{err_red});
}

// =========================================================================
// 8. TABLA OFICIAL DE PRECEDENCIA DE OPERADORES
// =========================================================================
// La precedencia define que operador se evalua antes que otro en expresiones
// complejas sin parentesis. Esta es la jerarquia de mayor a menor prioridad:
//
//  1. Llamadas, Indexados, Acceso a campos, Desreferenciacion, unwraps:
//     x()  x[]  x.y  x.*  x.?
//  2. Desempaquetado de Union de Errores:
//     a!b
//  3. Inicializacion de Estructuras:
//     x{}
//  4. Operadores Unarios Prefijo:
//     !x  -x  -%x  ~x  &x  ?x
//  5. Multiplicativos, Concatenacion, Desbordamientos de multiplicacion:
//     *  /  %  **  *%  *|  ||
//  6. Aditivos, Concatenacion de Slices:
//     +  -  ++  +%  -%  +|  -|
//  7. Desplazamientos de bit:
//     <<  >>  <<|
//  8. Bitwise, Desempaquetados de Fallback:
//     &  ^  |  orelse  catch
//  9. Comparaciones y de Igualdad:
//     ==  !=  <  >  <=  >=
//  10. Logicos Y:
//      and
//  11. Logicos O:
//      or
//  12. Asignaciones y Modificadores de Asignacion:
//      =  *=  *%=  *|=  /=  %=  +=  +%=  +|=  -=  -%=  -|=  <<=  >>=  &=  ^=  |=

// =========================================================================
// 9. PROYECTO COMPLETO: CALCULADORA CRITICA PARA SISTEMAS EMBEBIDOS
// =========================================================================
// Este modulo simula una centralita electronica de un vehiculo que debe
// calcular la velocidad final basada en la aceleracion. Al tratarse de un
// sistema embebido crítico, bajo ninguna circunstancia se debe permitir un
// desbordamiento (Overflow), por lo que usaremos operaciones saturadas.

const ModoAritmetico = enum {
    Saturado,
    Wrapping,
};

const CentralitaControl = struct {
    velocidad_actual: u8 = 0,
    modo: ModoAritmetico,

    pub fn acelerar(self: *@This(), incremento: u8) void {
        switch (self.modo) {
            .Saturado => {
                // Al usar aceleracion saturada, si la velocidad supera el maximo
                // de un entero u8 (255 km/h), el coche simplemente se mantendra
                // a velocidad maxima de forma segura.
                self.velocidad_actual = self.velocidad_actual +| incremento;
            },
            .Wrapping => {
                // Al usar wrapping, si superamos 255, la velocidad daria la
                // vuelta bruscamente a 0 o valores muy bajos, causando un
                // accidente catastrofico. Demostramos el comportamiento:
                self.velocidad_actual = self.velocidad_actual +% incremento;
            },
        }
    }
};

fn ejecucionProyectoCalculadora() void {
    print(">> PROYECTO INTEGRAL: Calculadora de Centralita Critica <<\n", .{});

    var coche_seguro = CentralitaControl{ .modo = .Saturado, .velocidad_actual = 240 };
    var coche_peligroso = CentralitaControl{ .modo = .Wrapping, .velocidad_actual = 240 };

    print("  Velocidad Inicial Comun: 240 km/h\n", .{});
    print("  [Control] Incrementando velocidad en +30 km/h...\n", .{});

    coche_seguro.acelerar(30);
    coche_peligroso.acelerar(30);

    print("    [Coche Seguro] Velocidad final: {d} km/h (Saturado al limite de seguridad)\n", .{coche_seguro.velocidad_actual});
    print("    [Coche Peligroso] Velocidad final: {d} km/h (Wrapping de desbordamiento!)\n\n", .{coche_peligroso.velocidad_actual});
}

// =========================================================================
// PUNTO DE ENTRADA PRINCIPAL
// =========================================================================
pub fn main() void {
    print("--- INICIO DE LA MASTERCLASS DE OPERADORES Y PRECEDENCIA ---\n\n", .{});

    modulo1Aritmetica();
    modulo2Bits();
    modulo3Desempaquetado();
    modulo4Logica();
    modulo5ArreglosYPunteros();
    modulo6FusionErrores();
    ejecucionProyectoCalculadora();

    print("--- FIN DE LA MASTERCLASS DE OPERADORES Y PRECEDENCIA ---\n", .{});
}

// =========================================================================
// 10. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG
// =========================================================================
// 1. COMPRENDA LA SEMANTICA DE DESBORDAMIENTO: Utilice aritmetica estandar
//    como `+` o `-` solo cuando garantice matematicamente que el valor no
//    superara los limites de memoria. Para sistemas criticos, prefiera
//    saturacion `+|` para evitar panics catastroficos.
//
// 2. BENEFICIESE DEL CORTOCIRCUITO: Coloque siempre la validacion mas rapida
//    y barata en el lado izquierdo del operador `and` u `or`. Esto evitara
//    llamadas costosas o desreferencias de punteros nulos de forma automatica.
//
// 3. FUSION DE ERRORES EXPLICITA: Utilice el operador `||` para acoplar sets
//    de errores de librerias independientes de forma estatica en lugar de
//    crear mapas de traduccion manuales en tiempo de ejecucion.
//
// 4. EVITE CODIGO ILEGIBLE: Debido a la falta de parentesis forzados en algunas
//    operaciones, mantenga la claridad de precedencia. Si una expresion es
//    dificil de leer, dividala en multiples constantes con nombres claros.
// =========================================================================
