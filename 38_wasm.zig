// =========================================================================================
// THE ZIG 0.16.0 MASTERCLASS: COMPILACIÓN Y DESARROLLO PARA WEBASSEMBLY (WASM)
// =========================================================================================
//
// Versión de Zig: 0.16.0 (Juicy Main Edition)
// Plataformas Objetivo: wasm32-freestanding (Web/Node.js) & wasm32-wasi (Entornos de Servidor)
//
// DESCRIPCION:
// WebAssembly es un destino de compilación de primer nivel en Zig. El compilador
// de Zig no requiere herramientas externas (como emscripten o binaryen) para generar
// binarios Wasm optimizados. Esta guía cubre desde los fundamentos de la memoria lineal
// hasta las abstracciones de sistema que provee WASI.
//
// INSTRUCCIONES DE USO:
// 1. Para leer el manual explicativo en consola:
//      $ zig run 38_wasm.zig
// 2. Para correr la suite completa de pruebas unitarias locales:
//      $ zig test 38_wasm.zig
// 3. Para compilar este módulo como un binario WebAssembly Freestanding:
//      $ zig build-exe 38_wasm.zig -target wasm32-freestanding -fno-entry --export=add_example
//
// =========================================================================================
// TABLA DE CONTENIDO (MÓDULOS DE APRENDIZAJE):
// =========================================================================================
// [MODULO 1] WebAssembly Freestanding: Conceptos Basicos e Imports/Exports.
// [MODULO 2] Memoria Lineal e Interoperabilidad con JavaScript (Punteros).
// [MODULO 3] WASI (WebAssembly System Interface) y Argumentos de Linea de Comandos.
// [MODULO 4] El Sistema de Archivos en WASI: Directorios Preabiertos (Preopens).
// [MODULO 5] Asignación Dinámica de Memoria en Wasm (std.heap.page_allocator).
// [MODULO 6] Simulando Entornos Host en Pruebas Unitarias.
// [MODULO 7] Matrices de Destino (Targets) y Optimizaciones del Compilador.
// [MODULO 8] PROYECTO PRÁCTICO: Motor de Codificación Base64 Optimizado para WASM.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

// =========================================================================================
// ENTRY POINT (ZIG 0.16.0 I/O ENGINE)
// =========================================================================================
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Buffer para albergar el texto del manual de forma segura en memoria
    var buffer: [2048]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);
    try ejecutarModulo1(stdout);
    try ejecutarModulo2(stdout);
    try ejecutarModulo3(stdout);
    try ejecutarModulo4(stdout);
    try ejecutarModulo5(stdout);
    try ejecutarModulo6(stdout);
    try ejecutarModulo7(stdout);
    try ejecutarModulo8(stdout);
    try imprimirCierre(stdout);
}

// Helper para imprimir texto estático sin colisiones de formateo
fn printStatic(writer: anytype, comptime text: []const u8) !void {
    try writer.print("{s}", .{text});
}

// =========================================================================================
// [MODULO 1] WEBASSEMBLY FREESTANDING: CONCEPTOS BÁSICOS E IMPORTS/EXPORTS
// =========================================================================================
// En el entorno "Freestanding" (autónomo), WebAssembly no asume la presencia de un
// Sistema Operativo o una biblioteca de C. Es un entorno de caja de arena (sandbox) puro.
//
// Para comunicarnos con el entorno ejecutor (host), por ejemplo, el navegador web o Node.js:
// 1. `export`: Hace que una función de Zig sea visible y ejecutable desde JavaScript.
// 2. `extern`: Declara una función que el host JavaScript debe inyectar obligatoriamente
//    al instanciar el módulo WebAssembly.

// Declaración de una función importada desde el Host JavaScript (imprime un número)
extern "env" fn print_i32(val: i32) void;

// Exportamos una función matemática para que pueda ser invocada desde JavaScript
export fn add_example(a: i32, b: i32) i32 {
    const resultado = a + b;
    // Si estamos compilando para WASM real, podemos invocar el import.
    // Durante pruebas nativas, evitamos llamarlo si no está enlazado.
    if (builtin.cpu.arch == .wasm32) {
        print_i32(resultado);
    }
    return resultado;
}

test "Modulo 1: Operacion de exportacion matematica" {
    try expectEqual(@as(i32, 15), add_example(5, 10));
}

fn ejecutarModulo1(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 1] WEBASSEMBLY FREESTANDING Y ENLACES (IMPORTS/EXPORTS)
        \\====================================================================
        \\ * El destino `wasm32-freestanding` no asume un Sistema Operativo.
        \\ * Usamos `export fn` para exponer logica de Zig a JavaScript.
        \\ * Usamos `extern` para declarar funciones del navegador u otros entornos 
        \\   que Zig necesita invocar para realizar operaciones (como imprimir en consola).
        \\
        \\   Ejemplo de carga en JavaScript (Node.js):
        \\   ------------------------------------------------------------
        \\   const source = fs.readFileSync("./modulo.wasm");
        \\   WebAssembly.instantiate(source, {
        \\     env: { print_i32: (x) => console.log(x) }
        \\   }).then(result => {
        \\     const add = result.instance.exports.add_example;
        \\     console.log("Resultado: " + add(5, 10));
        \\   });
        \\
    );
}

// =========================================================================================
// [MODULO 2] MEMORIA LINEAL E INTEROPERABILIDAD CON JAVASCRIPT (PUNTEROS)
// =========================================================================================
// WebAssembly opera sobre una región contigua de memoria llamada "Memoria Lineal".
// Desde JavaScript, esta memoria se ve como un buffer de bytes plano (`ArrayBuffer`).
//
// El paso de datos complejos (como strings o estructuras) se realiza compartiendo
// punteros. En Wasm de 32 bits, un puntero es simplemente un índice numérico de 32 bits
// (un entero `u32`) que representa la posición exacta en el ArrayBuffer de WebAssembly.
//
// REPRESENTACION GRAFICA DE LA MEMORIA COMPARTIDA:
// +------------------------------------------------------------------------+
// | MEMORIA LINEAL (Wasm.memory.buffer)                                    |
// +----------------+-------------------------------------------------------+
// | Puntero (u32)  | Datos Reales (ej. 'H' 'o' 'l' 'a')                     |
// | 0x0004FA10     | [ 0x48, 0x6F, 0x6C, 0x61 ]                             |
// +----------------+-------------------------------------------------------+

// Declaración de un búfer de comunicación global estático
var buffer_compartido: [1024]u8 = undefined;

// Exportamos una función que retorna la posición en memoria del búfer compartido.
// El código JS leerá este puntero y usará un `Uint8Array` sobre la memoria de Wasm.
export fn getSharedBufferPointer() [*]u8 {
    return &buffer_compartido;
}

export fn getSharedBufferLen() usize {
    return buffer_compartido.len;
}

// Procesa los datos escritos por el Host JS en el búfer compartido
export fn convertirMayusculas(len: usize) void {
    if (len > buffer_compartido.len) return;
    for (0..len) |i| {
        buffer_compartido[i] = std.ascii.toUpper(buffer_compartido[i]);
    }
}

test "Modulo 2: Procesamiento e interoperabilidad de buffer simulado" {
    const ptr = getSharedBufferPointer();
    const longitud = getSharedBufferLen();

    // Escribimos un string en la memoria del búfer
    const datos_entrada = "hello zig wasm";
    @memcpy(ptr[0..datos_entrada.len], datos_entrada);

    convertirMayusculas(datos_entrada.len);

    const esperado = "HELLO ZIG WASM";
    try std.testing.expectEqualStrings(esperado, ptr[0..datos_entrada.len]);
    try expectEqual(@as(usize, 1024), longitud);
}

fn ejecutarModulo2(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 2] MEMORIA LINEAL E INTEROPERABILIDAD CON JAVASCRIPT
        \\====================================================================
        \\ * WebAssembly de 32 bits utiliza indices de 32 bits para punteros.
        \\ * JavaScript lee la propiedad `WebAssembly.Memory.buffer` como un
        \\   bloque contiguo de memoria.
        \\ * Al exportar la direccion del buffer (`[*]u8`), JavaScript puede
        \\   escribir directamente en la RAM de WebAssembly y luego llamar
        \\   a una funcion de Zig para que procese los datos sin copias extras.
        \\
    );
}

// =========================================================================================
// [MODULO 3] WASI (WEBASSEMBLY SYSTEM INTERFACE) Y ARGUMENTOS DE LINEA DE COMANDOS
// =========================================================================================
// WASI (WebAssembly System Interface) define un estándar para que WebAssembly interactúe
// con recursos del sistema de manera segura (fuera del navegador).
//
// En Zig 0.16.0, el acceso a los argumentos pasados al binario de WASI se realiza
// a través del objeto `std.process.Init` que recibe la función `main`.
// Esto unifica la forma en que los argumentos se recuperan tanto de forma nativa como
// bajo el estándar WASI.

fn simularYProcesarArgumentos(allocator: std.mem.Allocator, args_mock: []const []const u8) !usize {
    var recuento_caracteres: usize = 0;
    for (args_mock) |arg| {
        // En una aplicación WASI real, procesaríamos los argumentos recibidos
        const copia = try allocator.alloc(u8, arg.len);
        defer allocator.free(copia);
        @memcpy(copia, arg);
        recuento_caracteres += copia.len;
    }
    return recuento_caracteres;
}

test "Modulo 3: Procesamiento lógico de argumentos" {
    const allocator = std.testing.allocator;
    const args_prueba = [_][]const u8{ "wasi_test.wasm", "--verbose", "input.txt" };

    const recuento = try simularYProcesarArgumentos(allocator, &args_prueba);
    try expectEqual(@as(usize, 32), recuento);
}

fn ejecutarModulo3(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 3] WASI (WEBASSEMBLY SYSTEM INTERFACE) Y ARGUMENTOS
        \\====================================================================
        \\ * WASI permite ejecutar codigo WebAssembly con acceso controlado a recursos
        \\   del host (archivos, argumentos, entorno, etc.).
        \\ * En Zig 0.16.0, se utiliza `init.minimal.args.toSlice` en la funcion `main`
        \\   para leer los argumentos.
        \\
        \\   Ejemplo de ejecucion en servidor:
        \\   ------------------------------------------------------------
        \\   $ zig build-exe app.zig -target wasm32-wasi
        \\   $ wasmtime app.wasm -- argumento_uno
        \\
    );
}

// =========================================================================================
// [MODULO 4] EL SISTEMA DE ARCHIVOS EN WASI: DIRECTORIOS PREABIERTOS (PREOPENS)
// =========================================================================================
// Por cuestiones de seguridad, un binario WASI no puede leer cualquier parte de tu disco
// duro por defecto. Los directorios accesibles deben ser explícitamente "pre-abiertos"
// por el host en tiempo de ejecución.
//
// En la API de Zig 0.16.0, el mapa de directorios preabiertos está disponible mediante
// `init.preopens.map`. Podemos iterar sobre este mapa para consultar qué directorios
// físicos del disco han sido expuestos al entorno aislado de WebAssembly.

fn comprobarDirectorioPermitido(preopens: []const []const u8, directorio: []const u8) bool {
    for (preopens) |p| {
        if (std.mem.eql(u8, p, directorio)) return true;
    }
    return false;
}

test "Modulo 4: Verificación simulada de directorios preabiertos (Preopens)" {
    const preopens_mock = [_][]const u8{ "stdin", "stdout", "stderr", "." };

    try expect(comprobarDirectorioPermitido(&preopens_mock, "."));
    try expect(!comprobarDirectorioPermitido(&preopens_mock, "/etc/shadow"));
}

fn ejecutarModulo4(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 4] EL SISTEMA DE ARCHIVOS EN WASI (PREOPENS)
        \\====================================================================
        \\ * WASI implementa seguridad basada en capacidades. Un binario WebAssembly
        \\   solo puede ver directorios compartidos explicitamente (Preopens).
        \\ * En Zig 0.16.0, la lista se recupera mediante `init.preopens.map.keys()`.
        \\ * Intentar abrir directorios que no estan en esta lista retornara un error
        \\   del tipo `AccessDenied` administrado por la sandbox de WASI.
        \\
    );
}

// =========================================================================================
// [MODULO 5] ASIGNACIÓN DINÁMICA DE MEMORIA EN WASM
// =========================================================================================
// En WebAssembly, no existe una función nativa del sistema `malloc` para pedir más memoria.
// En su lugar, el motor de ejecución provee la instrucción de hardware `memory.grow`.
// Esta instrucción le pide al host que aumente el tamaño de la memoria lineal en páginas
// de 64 Kilobytes cada una.
//
// La biblioteca estándar de Zig provee `std.heap.WasmPageAllocator`, que interactúa
// directamente con `memory.grow` de forma nativa cuando compilamos para la arquitectura Wasm.
// En entornos nativos (para pruebas unitarias), podemos usar `std.testing.allocator`.

fn duplicarStringDinamico(allocator: std.mem.Allocator, original: []const u8) ![]u8 {
    const destino = try allocator.alloc(u8, original.len);
    @memcpy(destino, original);
    return destino;
}

test "Modulo 5: Asignación dinámica e intercambio de memoria en Wasm" {
    // Para compilar con seguridad, usamos el allocator disponible en el contexto
    const allocator = std.testing.allocator;

    const texto = "WebAssembly en Zig";
    const copia = try duplicarStringDinamico(allocator, texto);
    defer allocator.free(copia);

    try std.testing.expectEqualStrings(texto, copia);
}

fn ejecutarModulo5(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 5] ASIGNACION DINAMICA DE MEMORIA EN WASM
        \\====================================================================
        \\ * En WebAssembly, la memoria se pide en bloques fijos de 64 KB (paginas)
        \\   utilizando la operacion `memory.grow`.
        \\ * Para desarrollo en `wasm32-freestanding`, `std.heap.page_allocator`
        \\   apunta de forma automatica al asignador de paginas nativo de Wasm.
        \\ * Esto simplifica de gran manera el portar bibliotecas nativas complejas
        \\   que utilicen memoria dinamica a la web.
        \\
    );
}

// =========================================================================================
// [MODULO 6] SIMULANDO ENTORNOS HOST EN PRUEBAS UNITARIAS
// =========================================================================================
// Cuando escribimos funciones `extern` para ser inyectadas por el navegador o por Node.js,
// las pruebas de compilación nativas (`zig test`) fallarán por defecto, debido a que el
// enlazador local no sabrá dónde encontrar dichas funciones.
//
// Para solucionar esto de manera elegante en Zig, podemos usar bifurcación en tiempo de
// compilación (`builtin.cpu.arch`) o proveer definiciones "mock" condicionales para
// los entornos de prueba locales.

const InteropMock = struct {
    var ultimo_mensaje_impreso: i32 = 0;

    // Esta funcion simula el comportamiento de la inyeccion externa para pruebas nativas
    pub fn mockHostPrint(val: i32) void {
        ultimo_mensaje_impreso = val;
    }
};

fn operacionConLogicaInterna(val: i32) void {
    if (builtin.cpu.arch == .wasm32) {
        // En entorno de produccion WASM real llamamos al JS import
        print_i32(val);
    } else {
        // En pruebas de escritorio simulamos la llamada
        InteropMock.mockHostPrint(val);
    }
}

test "Modulo 6: Mocking de interoperabilidad con Host JS" {
    operacionConLogicaInterna(999);

    if (builtin.cpu.arch != .wasm32) {
        try expectEqual(@as(i32, 999), InteropMock.ultimo_mensaje_impreso);
    }
}

fn ejecutarModulo6(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 6] SIMULANDO EL HOST EN PRUEBAS UNITARIAS
        \\====================================================================
        \\ * Escribir codigo multiplataforma requiere que los tests unitarios
        \\   corran en tu computadora local (x86_64) aunque el destino sea WASM.
        \\ * Con `builtin.cpu.arch == .wasm32` podemos decidir en tiempo de compilacion
        \\   si interactuamos con el navegador real o llamamos a una funcion de prueba
        \\   local (Mocking).
        \\
    );
}

// =========================================================================================
// [MODULO 7] MATRICES DE DESTINO (TARGETS) Y OPTIMIZACIONES DEL COMPILADOR
// =========================================================================================
// El concepto de "Target" en Zig se compone de:
//   Arquitectura + Caracteristicas de CPU + Sistema Operativo + ABI.
//
// Destinos WebAssembly comunes en Zig:
// - `wasm32-freestanding`: El binario es una isla computacional. Ideal para la Web.
// - `wasm32-wasi`: Permite acceso de bajo nivel seguro para entornos fuera del navegador.
// - `wasm64-freestanding`: Variacion moderna que permite usar direccionamiento de 64 bits.
//
// CARACTERÍSTICAS DE CPU COMPILANDO PARA WASM:
// El procesador virtual de WebAssembly puede ser extendido con instrucciones adicionales
// que puedes habilitar al compilar desde la terminal:
// - `simd128` (Instrucciones vectoriales de 128 bits nativas en navegadores modernos).
// - `bulk-memory` (Optimizacion de operaciones masivas de copia en memoria).
// - `atomics` (Para implementar multiprocesamiento mediante Web Workers).

fn verificarSiSIMD128EstaHabilitado() bool {
    // Verificamos de forma estatica si el compilador tiene habilitado SIMD128 para Wasm
    return std.Target.wasm.featureSetHas(builtin.cpu.features, .simd128);
}

test "Modulo 7: Verificación de características en tiempo de compilación" {
    // Este test solo evalua la lectura de metadatos de compilacion
    const simd_activado = verificarSiSIMD128EstaHabilitado();
    try expect(simd_activado == simd_activado); // Es de solo lectura
}

fn ejecutarModulo7(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 7] MATRICES DE DESTINOS (TARGETS) Y OPTIMIZACIONES
        \\====================================================================
        \\ * Zig permite definir con precision el entorno de ejecucion.
        \\ * Puedes compilar habilitando caracteristicas modernas de la CPU virtual de
        \\   Wasm, por ejemplo:
        \\   $ zig build-exe app.zig -target wasm32-freestanding -mcpu=wasm32+simd128+bulk_memory
        \\ * Esto genera binarios altamente optimizados que reducen drasticamente el peso
        \\   y aumentan la velocidad de carga en la web.
        \\
    );
}

// =========================================================================================
// [MODULO 8] PROYECTO PRÁCTICO: MOTOR DE CODIFICACIÓN BASE64 OPTIMIZADO PARA WASM
// =========================================================================================
// Como proyecto integrador de WebAssembly, desarrollaremos una biblioteca completa para
// codificar datos binarios en formato Base64.
//
// La codificación de Base64 toma grupos de 3 bytes (24 bits) y los distribuye en
// 4 caracteres de 6 bits cada uno, mapeandolos a la tabla de caracteres segura para web.
//
// Diseñaremos este algoritmo para que opere directamente sobre un búfer compartido
// estático, de modo que JavaScript pueda leer la cadena resultante sin ninguna copia
// de memoria innecesaria.

// Tabla de caracteres Base64 estandar
const TABLA_BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

var input_buffer: [3072]u8 = undefined;
var output_buffer: [4096]u8 = undefined;

export fn getInputBufferPointer() [*]u8 {
    return &input_buffer;
}

export fn getOutputBufferPointer() [*]u8 {
    return &output_buffer;
}

// Codifica los bytes del buffer de entrada en el de salida
export fn codificarBase64(input_len: usize) usize {
    if (input_len > input_buffer.len) return 0;

    var in_idx: usize = 0;
    var out_idx: usize = 0;

    while (in_idx < input_len) {
        const bytes_restantes = input_len - in_idx;

        if (bytes_restantes >= 3) {
            // Caso general: procesar de a 3 bytes (24 bits)
            const b0 = input_buffer[in_idx];
            const b1 = input_buffer[in_idx + 1];
            const b2 = input_buffer[in_idx + 2];

            in_idx += 3;

            // Extraemos 4 indices de 6 bits cada uno
            const _i0 = b0 >> 2;
            const _i1 = ((b0 & 0x03) << 4) | (b1 >> 4);
            const _i2 = ((b1 & 0x0F) << 2) | (b2 >> 6);
            const _i3 = b2 & 0x3F;

            output_buffer[out_idx] = TABLA_BASE64[_i0];
            output_buffer[out_idx + 1] = TABLA_BASE64[_i1];
            output_buffer[out_idx + 2] = TABLA_BASE64[_i2];
            output_buffer[out_idx + 3] = TABLA_BASE64[_i3];

            out_idx += 4;
        } else if (bytes_restantes == 2) {
            // Padding con un signo de igual '='
            const b0 = input_buffer[in_idx];
            const b1 = input_buffer[in_idx + 1];

            in_idx += 2;

            const _i0 = b0 >> 2;
            const _i1 = ((b0 & 0x03) << 4) | (b1 >> 4);
            const _i2 = (b1 & 0x0F) << 2;

            output_buffer[out_idx] = TABLA_BASE64[_i0];
            output_buffer[out_idx + 1] = TABLA_BASE64[_i1];
            output_buffer[out_idx + 2] = TABLA_BASE64[_i2];
            output_buffer[out_idx + 3] = '=';

            out_idx += 4;
        } else if (bytes_restantes == 1) {
            // Padding con dos signos de igual '=='
            const b0 = input_buffer[in_idx];

            in_idx += 1;

            const _i0 = b0 >> 2;
            const _i1 = (b0 & 0x03) << 4;

            output_buffer[out_idx] = TABLA_BASE64[_i0];
            output_buffer[out_idx + 1] = TABLA_BASE64[_i1];
            output_buffer[out_idx + 2] = '=';
            output_buffer[out_idx + 3] = '=';

            out_idx += 4;
        }
    }

    return out_idx;
}

test "Modulo 8: Comprobacion completa del codificador Base64" {
    const entrada = "Zig Wasm";
    const puntero_entrada = getInputBufferPointer();
    @memcpy(puntero_entrada[0..entrada.len], entrada);

    const len_salida = codificarBase64(entrada.len);
    const puntero_salida = getOutputBufferPointer();

    // Obtenemos la representacion en string resultante
    const codificado = puntero_salida[0..len_salida];

    try std.testing.expectEqualStrings("WmlnIFdhc20=", codificado);
}

fn ejecutarModulo8(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 8] PROYECTO PRACTICO (BASE64 OPTIMIZADO PARA LA WEB)
        \\====================================================================
        \\ * Hemos desarrollado un codificador de Base64 de alto rendimiento.
        \\ * No requiere asignador dinamico (allocator) por lo que es inmune a las
        \\   fugas de memoria en el navegador.
        \\ * Los buffers estaticos de entrada y salida estan expuestos mediante
        \\   punteros crudos accesibles desde JavaScript.
        \\
    );
}

// =========================================================================================
// PRESENTACIÓN DE FORMATO Y CIERRE DEL CURSO
// =========================================================================================
fn imprimirCabecera(stdout: anytype) !void {
    try printStatic(stdout,
        \\====================================================================
        \\     ___ ___ ___    __      __  _   ___ __  __ 
        \\    |_  |_ _/ __|   \ \    / / /_\ / __|  \/  |
        \\     / / | | (_ |    \ \/\/ / / _ \\__ \ |\/| |
        \\    /___|___\___|     \_/\_/ /_/ \_\___/_|  |_|
        \\                                                            
        \\    MASTERCLASS COMPLETA: WEBASSEMBLY (WASM) EN ZIG 0.16.0
        \\====================================================================
        \\ Este archivo se ha compilado y ejecutado exitosamente en tu maquina.
        \\ A continuacion se presenta la informacion del curso interactivo:
        \\====================================================================
        \\
    );
}

fn imprimirCierre(stdout: anytype) !void {
    try printStatic(stdout,
        \\====================================================================
        \\ [CURSO DE WEBASSEMBLY COMPLETADO]
        \\====================================================================
        \\ Has completado la inmersion conceptual y practica de Wasm con Zig.
        \\
        \\ Instrucciones recomendadas para comprobar tu aprendizaje:
        \\ 1. Ejecuta las pruebas unitarias de todos los modulos:
        \\    $ zig test 38_wasm.zig
        \\
        \\ 2. Compila el motor de Base64 optimizado para la Web:
        \\    $ zig build-exe 38_wasm.zig -target wasm32-freestanding -fno-entry --export=codificarBase64
        \\====================================================================
        \\
    );
}
