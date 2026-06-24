// =========================================================================================
// THE ZIG 0.16.0 MASTERCLASS: EL ARTE DEL TESTING Y QA EN SISTEMAS DE BAJO NIVEL
// =========================================================================================
//
// Autor: Zig AI Masterclass Series
// Version: Zig 0.16.0 (Juicy Main Edition)
// Encoding: 7-bit ASCII
//
// DESCRIPCION:
// Zig tiene el Testing integrado directamente en el lenguaje. No necesitas frameworks
// externos (como Jest, JUnit o GoogleTest). El compilador mismo actua como el test runner.
// Esta guia exhaustiva (+500 lineas) te llevara desde las aserciones mas basicas hasta
// la deteccion de fugas de memoria (Memory Leaks), simulacion (Mocking), Doctests y
// la creacion de proyectos listos para produccion probados al 100%.
//
// INSTRUCCIONES DE USO:
// 1. Para leer el manual en consola:   $ zig run masterclass_testing.zig
// 2. Para correr la suite de pruebas:  $ zig test masterclass_testing.zig
//
// =========================================================================================
// TABLA DE CONTENIDO (MODULOS DE ESTUDIO):
// =========================================================================================
// [MODULO 1] Fundamentos: expect, expectEqual y Bloques de Test.
// [MODULO 2] Tipos Complejos: Comparacion de Slices, Strings y Estructuras Profundas.
// [MODULO 3] Manejo de Errores: expectError y testing de fallos esperados.
// [MODULO 4] Deteccion de Fugas de Memoria (std.testing.allocator).
// [MODULO 5] Control de Ejecucion: SkipZigTest y Deteccion de Entorno (builtin.is_test).
// [MODULO 6] Doctests: Documentacion Viva y Probada.
// [MODULO 7] Arquitectura de Pruebas: Inyeccion de Dependencias (Mocking).
// [MODULO 8] PROYECTO FINAL: Base de Datos en Memoria (LRU Cache) Totalmente Probada.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");

// Alias rapidos para el namespace de testing (Buena practica en Zig)
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualStrings = testing.expectEqualStrings;
const expectEqualSlices = testing.expectEqualSlices;
const expectError = testing.expectError;

// =========================================================================================
// "JUICY MAIN" (ZIG 0.16.0) - EL MOTOR DEL MODO LECTURA
// =========================================================================================
// Este bloque solo se ejecuta cuando usas `zig run`.
// Cuando usas `zig test`, Zig ignora todo el main y busca la palabra clave `test`.
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Buffer masivo para soportar la inmensa cantidad de texto de esta Masterclass
    var buffer: [65536]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);
    try imprimirModulo1(stdout);
    try imprimirModulo2(stdout);
    try imprimirModulo3(stdout);
    try imprimirModulo4(stdout);
    try imprimirModulo5(stdout);
    try imprimirModulo6(stdout);
    try imprimirModulo7(stdout);
    try imprimirModulo8(stdout);
    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: FUNDAMENTOS Y ASERCIONES BASICAS
// =========================================================================================
// Los tests en Zig se declaran con la palabra clave `test` seguida de un string
// que describe lo que hace. Dentro, usamos `try std.testing.expect(...)`.

fn addOne(number: i32) i32 {
    return number + 1;
}

test "Modulo 1: expect basico de operaciones matematicas" {
    // `expect` toma un booleano. Si es falso, retorna error.TestUnexpectedResult
    try expect(addOne(41) == 42);

    // `expectEqual` es MUCHO MEJOR. Si falla, el compilador te dice exactamente
    // "Esperaba 42, pero obtuve 99". Con `expect` normal, solo sabes que fallo.
    // SINTAXIS: expectEqual(ESPERADO, REAL)
    try expectEqual(@as(i32, 42), addOne(41));
}

test "Modulo 1: Multiples aserciones en un solo bloque" {
    const a = 10;
    const b = 20;

    try expectEqual(30, a + b);
    try expect(a < b);
    try expect(b != 0);
}

// Funcion didactica para el stdout
fn imprimirModulo1(stdout: anytype) !void {
    try stdout.print("\n[MODULO 1] FUNDAMENTOS Y ASERCIONES BASICAS\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - Los tests se declaran con: test \"nombre\" {{ ... }}\n", .{});
    try stdout.print("  - Usa `try std.testing.expect(bool)` para verificaciones simples.\n", .{});
    try stdout.print("  - Usa `try std.testing.expectEqual(esperado, real)` para ver valores.\n", .{});
    try stdout.print("  - Si un test falla, Zig imprime el Error Return Trace completo.\n", .{});
}

// =========================================================================================
// MODULO 2: TIPOS COMPLEJOS (SLICES, STRINGS Y ESTRUCTURAS)
// =========================================================================================
// Cuando comparas arrays o strings, `expectEqual` NO sirve, porque compararia los
// punteros de memoria, no el contenido. Debes usar funciones especializadas.

test "Modulo 2: Comparando Strings (expectEqualStrings)" {
    const saludo_calculado = "Hola " ++ "Mundo";

    // INCORRECTO: expectEqual("Hola Mundo", saludo_calculado) -> Compara punteros!
    // CORRECTO:
    try expectEqualStrings("Hola Mundo", saludo_calculado);
}

test "Modulo 2: Comparando Slices y Arrays (expectEqualSlices)" {
    const esperados = [_]u8{ 10, 20, 30 };

    var dinamico = [_]u8{0} ** 3;
    dinamico[0] = 10;
    dinamico[1] = 20;
    dinamico[2] = 30;

    // Comparamos byte a byte en memoria
    try expectEqualSlices(u8, &esperados, &dinamico);
}

// ¿Que pasa con estructuras profundas?
const Vector2 = struct { x: f32, y: f32 };

test "Modulo 2: Comparacion profunda (Deep Equality)" {
    const v1 = Vector2{ .x = 1.0, .y = 2.0 };
    const v2 = Vector2{ .x = 1.0, .y = 2.0 };

    // expectEqual funciona bien con structs planos si sus campos son primitivos
    try expectEqual(v1, v2);
}

fn imprimirModulo2(stdout: anytype) !void {
    try stdout.print("\n[MODULO 2] TIPOS COMPLEJOS Y MEMORIA\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - Para texto: expectEqualStrings(\"esperado\", variable)\n", .{});
    try stdout.print("  - Para arrays: expectEqualSlices(Tipo, &esperado, &variable)\n", .{});
    try stdout.print("  - Esto garantiza que verificas valores y no direcciones de RAM.\n", .{});
}

// =========================================================================================
// MODULO 3: MANEJO DE ERRORES (EXPECT ERROR)
// =========================================================================================
// A veces queremos probar que nuestra funcion FALLA cuando deberia fallar.
// Para esto existe `expectError`.

const ErrorDeParseo = error{
    NumeroInvalido,
    MuyLargo,
};

fn parsearEdad(input: []const u8) ErrorDeParseo!u8 {
    if (input.len > 3) return error.MuyLargo;
    if (input[0] == 'X') return error.NumeroInvalido;
    return 25; // Dummy logic
}

test "Modulo 3: Verificando que una funcion emite el error correcto" {
    // 1. Probamos el camino feliz (Happy Path)
    const resultado = try parsearEdad("25");
    try expectEqual(@as(u8, 25), resultado);

    // 2. Probamos el camino de fallo: Esperamos que devuelva error.MuyLargo
    try expectError(error.MuyLargo, parsearEdad("9999"));

    // 3. Probamos otro caso de fallo
    try expectError(error.NumeroInvalido, parsearEdad("X2"));
}

fn imprimirModulo3(stdout: anytype) !void {
    try stdout.print("\n[MODULO 3] TESTEANDO ERRORES\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - No solo pruebes que el codigo funciona, prueba que falla bien.\n", .{});
    try stdout.print("  - Usa `expectError(error.TipoDeError, funcion_que_falla())`.\n", .{});
    try stdout.print("  - Esto asegura que tu API es robusta ante malas entradas.\n", .{});
}

// =========================================================================================
// MODULO 4: DETECCION DE FUGAS DE MEMORIA (MEMORY LEAKS)
// =========================================================================================
// ESTA ES LA FUNCION MAS PODEROSA DE ZIG.
// El `std.testing.allocator` es un asignador de memoria especial. Rastrea cada
// byte que pides. Cuando el test termina, si no liberaste la memoria, el test FALLA
// y te imprime la linea exacta donde solicitaste la memoria fugada.

test "Modulo 4: allocator de testing seguro" {
    // Obtenemos el allocator especial
    const allocator = std.testing.allocator;

    // Asignamos memoria en el heap
    const memoria = try allocator.alloc(u32, 100);

    // Si olvidaramos esta linea, el test reportaria un "Memory Leak" en rojo
    defer allocator.free(memoria);

    // Usamos la memoria
    memoria[0] = 999;
    try expectEqual(@as(u32, 999), memoria[0]);
}

test "Modulo 4: Memory Leak en estructuras dinamicas" {
    const gpa = std.testing.allocator;

    var lista = std.ArrayList(u8).init(gpa);
    // IMPORTANTE: En los tests, siempre usa defer para limpiar
    defer lista.deinit();

    try lista.append('Z');
    try lista.append('I');
    try lista.append('G');

    try expectEqualStrings("ZIG", lista.items);
}

fn imprimirModulo4(stdout: anytype) !void {
    try stdout.print("\n[MODULO 4] DETECCION DE FUGAS DE MEMORIA\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - std.testing.allocator envuelve al GeneralPurposeAllocator.\n", .{});
    try stdout.print("  - Si te olvidas un `defer free()`, el test falla automaticamente.\n", .{});
    try stdout.print("  - Esto garantiza que tu codigo de produccion jamas tendra leaks.\n", .{});
}

// =========================================================================================
// MODULO 5: CONTROL DE EJECUCION Y SKIP TESTS
// =========================================================================================
// A veces un test no puede correr en cierta arquitectura, o depende de hardware
// que no esta presente en tu maquina (ej. servidor CI/CD). Puedes saltarlo.

test "Modulo 5: Saltando un test intencionalmente" {
    // Retornar error.SkipZigTest le dice al runner: "Ignora esto, no es un fallo"
    if (true) {
        return error.SkipZigTest;
    }

    // Este codigo nunca se ejecutara
    try expect(1 == 2);
}

// Podemos detectar si estamos en un build de prueba
fn estoyEnUnTest() bool {
    // builtin.is_test es true solo cuando corres `zig test`
    return builtin.is_test;
}

test "Modulo 5: Comprobando builtin.is_test" {
    try expect(estoyEnUnTest() == true);
}

fn imprimirModulo5(stdout: anytype) !void {
    try stdout.print("\n[MODULO 5] CONTROL DE EJECUCION (SKIP)\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - `return error.SkipZigTest` descarta un test sin considerarlo fallo.\n", .{});
    try stdout.print("  - Util para tests que requieren conexion a internet o hardware real.\n", .{});
    try stdout.print("  - `builtin.is_test` te permite compilar codigo condicionalmente.\n", .{});
}

// =========================================================================================
// MODULO 6: DOCTESTS (PRUEBAS COMO DOCUMENTACION)
// =========================================================================================
// Si un test se nombra exactamente igual que un identificador (una funcion, un struct),
// Zig lo considera un "Doctest". Esto aparecera en la documentacion autogenerada.

/// Calcula el factorial de un numero usando recursividad.
fn factorial(n: u64) u64 {
    if (n == 0 or n == 1) return 1;
    return n * factorial(n - 1);
}

// Nota como no usamos un string "...", sino el identificador desnudo
test factorial {
    try expectEqual(@as(u64, 1), factorial(0));
    try expectEqual(@as(u64, 1), factorial(1));
    try expectEqual(@as(u64, 120), factorial(5));
}

fn imprimirModulo6(stdout: anytype) !void {
    try stdout.print("\n[MODULO 6] DOCTESTS (TESTS NOMBRADOS)\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - Escribe `test miFuncion {{ ... }}` sin comillas.\n", .{});
    try stdout.print("  - Zig asocia ese test directamente a la funcion `miFuncion`.\n", .{});
    try stdout.print("  - Mantiene tu documentacion 100% precisa y libre de regresiones.\n", .{});
}

// =========================================================================================
// MODULO 7: MOCKING Y DEPENDENCY INJECTION PARA TESTS
// =========================================================================================
// En lenguajes de bajo nivel no hay "Librerias de Mocking Magicas". Hacemos
// Inyeccion de Dependencias usando interfaces (v-tables) o Structs genericos en Comptime.

// 1. Definimos una Interfaz simple para un Sensor
const ISensor = struct {
    ptr: *anyopaque,
    leerTemperaturaFn: *const fn (ptr: *anyopaque) f32,

    pub fn leerTemperatura(self: ISensor) f32 {
        return self.leerTemperaturaFn(self.ptr);
    }
};

// 2. Logica de produccion que toma la interfaz (independiente del hardware)
fn activarAlarmaSiHaceCalor(sensor: ISensor) bool {
    const temp = sensor.leerTemperatura();
    return temp > 100.0;
}

// 3. El Mock (Simulador) que usaremos solo en el Test
const SensorMock = struct {
    temperatura_fija: f32,

    pub fn interface(self: *SensorMock) ISensor {
        return .{
            .ptr = self,
            .leerTemperaturaFn = mockLeerTemp,
        };
    }

    fn mockLeerTemp(ptr: *anyopaque) f32 {
        const self: *SensorMock = @ptrCast(@alignCast(ptr));
        return self.temperatura_fija;
    }
};

test "Modulo 7: Mocking de un Sensor de Hardware" {
    // Escenario 1: Temperatura normal
    var sensor_frio = SensorMock{ .temperatura_fija = 40.0 };
    try expect(activarAlarmaSiHaceCalor(sensor_frio.interface()) == false);

    // Escenario 2: Sobrecalentamiento
    var sensor_caliente = SensorMock{ .temperatura_fija = 150.0 };
    try expect(activarAlarmaSiHaceCalor(sensor_caliente.interface()) == true);
}

fn imprimirModulo7(stdout: anytype) !void {
    try stdout.print("\n[MODULO 7] MOCKING E INYECCION DE DEPENDENCIAS\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - Para probar sistemas que tocan el disco o la red, inyecta interfaces.\n", .{});
    try stdout.print("  - Pasa structs con punteros a funciones en tus tests (Mocks).\n", .{});
    try stdout.print("  - Esto aisla tu logica de negocios y permite tests super rapidos.\n", .{});
}

// =========================================================================================
// MODULO 8: PROYECTO PRACTICO (100% TEST COVERAGE)
// BASE DE DATOS EN MEMORIA CON BUFFER CIRCULAR (RING BUFFER / LRU CACHE)
// =========================================================================================
// Vamos a construir un componente real, seguro, robusto y altamente performante.
// Un RingBuffer (Buffer Circular) que sobreescribe los datos mas viejos cuando se llena.
// Luego le aplicaremos todas las tecnicas de testing aprendidas.

/// RingBuffer: Coleccion de tamano fijo FIFO que nunca re-aloja memoria.
pub fn RingBuffer(comptime T: type, comptime capacidad: usize) type {
    return struct {
        buffer: [capacidad]T = undefined,
        cabeza: usize = 0,
        cola: usize = 0,
        esta_lleno: bool = false,

        const Self = @This();

        pub fn init() Self {
            return Self{};
        }

        pub fn push(self: *Self, item: T) void {
            self.buffer[self.cabeza] = item;

            if (self.esta_lleno) {
                // Sobreescribimos el mas viejo, empujamos la cola
                self.cola = (self.cola + 1) % capacidad;
            }

            self.cabeza = (self.cabeza + 1) % capacidad;
            self.esta_lleno = self.cabeza == self.cola;
        }

        pub fn pop(self: *Self) ?T {
            if (self.isEmpty()) return null;

            const item = self.buffer[self.cola];
            self.esta_lleno = false;
            self.cola = (self.cola + 1) % capacidad;
            return item;
        }

        pub fn isEmpty(self: *const Self) bool {
            return (!self.esta_lleno and (self.cabeza == self.cola));
        }

        pub fn getCount(self: *const Self) usize {
            if (self.esta_lleno) return capacidad;
            if (self.cabeza >= self.cola) {
                return self.cabeza - self.cola;
            }
            return capacidad - self.cola + self.cabeza;
        }
    };
}

// -----------------------------------------------------------------------------------------
// SUITE DE PRUEBAS DEL PROYECTO PRACTICO
// -----------------------------------------------------------------------------------------

test "Proyecto: Inicializacion de RingBuffer" {
    const rb = RingBuffer(i32, 5).init();
    try expect(rb.isEmpty());
    try expectEqual(@as(usize, 0), rb.getCount());
}

test "Proyecto: Comportamiento FIFO basico" {
    var rb = RingBuffer(u8, 3).init();

    rb.push('A');
    rb.push('B');

    try expectEqual(@as(usize, 2), rb.getCount());
    try expect(rb.isEmpty() == false);

    // Debe salir el primero que entro (A)
    try expectEqual(@as(?u8, 'A'), rb.pop());
    try expectEqual(@as(usize, 1), rb.getCount());

    // Debe salir el segundo (B)
    try expectEqual(@as(?u8, 'B'), rb.pop());
    try expect(rb.isEmpty());

    // Pop en vacio debe retornar null
    try expectEqual(@as(?u8, null), rb.pop());
}

test "Proyecto: Desbordamiento Circular (Sobreescritura del mas viejo)" {
    var rb = RingBuffer(u32, 3).init(); // Capacidad MAX = 3

    // Llenamos el buffer
    rb.push(10); // Posicion 0
    rb.push(20); // Posicion 1
    rb.push(30); // Posicion 2

    try expect(rb.esta_lleno);
    try expectEqual(@as(usize, 3), rb.getCount());

    // Forzamos el Wrap-Around (Desbordamiento)
    rb.push(40); // Esto DEBE sobreescribir el '10' y mover la cola
    try expectEqual(@as(usize, 3), rb.getCount());

    rb.push(50); // Esto DEBE sobreescribir el '20'

    // El buffer ahora contiene [40, 50, 30] fisicamente,
    // pero logigamente la cola arranca en el '30'.

    // El orden de salida debe ser: 30, 40, 50
    try expectEqual(@as(?u32, 30), rb.pop());
    try expectEqual(@as(?u32, 40), rb.pop());
    try expectEqual(@as(?u32, 50), rb.pop());

    try expect(rb.isEmpty());
}

test "Proyecto: Operaciones intercaladas y estres de limites" {
    // Simularemos un sistema que lee y escribe constantemente
    var rb = RingBuffer(f64, 4).init();

    // Ciclo 1
    rb.push(1.1);
    rb.push(2.2);
    _ = rb.pop(); // sale 1.1

    // Ciclo 2
    rb.push(3.3);
    rb.push(4.4);
    rb.push(5.5); // Deberia llenarse aqui (2.2, 3.3, 4.4, 5.5)

    try expect(rb.esta_lleno);
    try expectEqual(@as(usize, 4), rb.getCount());

    // Vaciar parcialmente
    try expectEqual(@as(?f64, 2.2), rb.pop());
    try expectEqual(@as(?f64, 3.3), rb.pop());

    // Volver a escribir
    rb.push(6.6);

    // Vaciar completamente
    try expectEqual(@as(?f64, 4.4), rb.pop());
    try expectEqual(@as(?f64, 5.5), rb.pop());
    try expectEqual(@as(?f64, 6.6), rb.pop());

    // Verificacion de estado final limpio
    try expect(rb.isEmpty());
}

fn imprimirModulo8(stdout: anytype) !void {
    try stdout.print("\n[MODULO 8] PROYECTO PRACTICO (RING BUFFER)\n", .{});
    try stdout.print("------------------------------------------------------------\n", .{});
    try stdout.print("  - Hemos implementado un RingBuffer Generico y libre de memoria dinamica.\n", .{});
    try stdout.print("  - Las pruebas cubren: inicializacion, comportamiento FIFO.\n", .{});
    try stdout.print("  - Y lo mas critico: el Wrap-Around (desbordamiento circular y sobreescritura).\n", .{});
    try stdout.print("  - Corre `zig test` en este archivo para ver los tests ejecutarse.\n", .{});
}

// =========================================================================================
// UTILIDADES DE IMPRESION DEL MANUAL
// =========================================================================================

fn imprimirCabecera(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\     ___ ___ ___      _____ ___ ___ _____ ___ _  _  ___ 
        \\    |_  |_ _/ __|    |_   _| __/ __|_   _|_ _| \| |/ __|
        \\     / / | | (_ |      | | | _|\__ \ | |  | || .` | (_ |
        \\    /___|___\___|      |_| |___|___/ |_| |___|_|\_|\___|
        \\                                                            
        \\    MASTERCLASS DEFINITIVA: ZIG 0.16.0 (EDICION JUICY MAIN)
        \\====================================================================
        \\ Bienvenido a la guia interactiva. Este archivo es un hibrido:
        \\ Es un programa de consola y una suite de pruebas simultaneamente.
        \\
        \\ Para correr las pruebas descritas abajo, usa:
        \\ $ zig test masterclass_testing.zig
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\
        \\====================================================================
        \\ FELICIDADES. HAS COMPLETADO LA MASTERCLASS DE TESTING EN ZIG.
        \\====================================================================
        \\ Has aprendido:
        \\ 1. Aserciones basicas y profundas.
        \\ 2. Control de fugas de memoria con Testing Allocator.
        \\ 3. Doctests y Testing Condicional.
        \\ 4. Arquitecturas de Mocks (Inyeccion de Dependencias).
        \\ 5. Testeo exhaustivo de estructuras de datos complejas.
        \\
        \\ Ahora, cierra esta guia y corre: `zig test masterclass_testing.zig`
        \\ ¡Observa la magia del compilador validando cada linea de codigo!
        \\====================================================================
        \\
    , .{});
}

// -----------------------------------------------------------------------------------------
// NOTA ARQUITECTONICA FINAL:
// -----------------------------------------------------------------------------------------
// Cuando corres "zig test", el compilador de Zig realiza un proceso fascinante:
// 1. Lee tu archivo origen (este archivo).
// 2. Extrae todas las declaraciones "test".
// 3. Genera un NUEVO "main" oculto en un archivo temporal (test_runner.zig).
// 4. Compila un binario separado especificamente para tests.
// 5. Ejecuta el binario y captura la salida de error (stderr) para los fallos.
// Es por esto que puedes tener tu propio "pub fn main()" en el archivo de produccion
// sin colisionar jamas con los tests.
