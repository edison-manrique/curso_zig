// =========================================================================================
// THE ZIG 0.16.0 MASTERCLASS: ENSAMBLADOR x86_64 PARA WINDOWS Y LINUX (EDICION ULTRA)
// =========================================================================================
//
// Versión de Zig: 0.16.0 (Juicy Main Edition)
// Arquitectura Objetivo: x86_64 (Intel / AMD)
// Sistemas Operativos: Windows (Microsoft x64 ABI) & Linux (System V AMD64 ABI)
// Sintaxis utilizada por el backend: AT&T (vía LLVM)
//
// INSTRUCCIONES DE USO:
// 1. Para leer el manual explicativo en consola:
//      $ zig run masterclass_assembly_v2.zig
// 2. Para correr la suite completa de pruebas de CPU:
//      $ zig test masterclass_assembly_v2.zig
//
// =========================================================================================
// TABLA DE CONTENIDO (MÓDULOS DE APRENDIZAJE):
// =========================================================================================
// [MODULO 1] Anatomía de la Arquitectura x86_64 y Sintaxis AT&T.
// [MODULO 2] Restricciones de Entrada, Salida y Enlaces de Registro (Constraints).
// [MODULO 3] Clobbers, Efectos Secundarios y Barreras de Memoria.
// [MODULO 4] Acceso Directo al Hardware: Lectura de CPUID y RDTSC (Multiplataforma).
// [MODULO 5] La Gran Batalla de ABIs: Windows x64 vs. System V (Linux).
// [MODULO 6] Ensamblador Global Condicional (comptime asm).
// [MODULO 7] Instrucciones Vectoriales (SIMD / SSE) en Ensamblador Inline.
// [MODULO 8] PROYECTO PRÁCTICO: Memset optimizado a nivel de CPU.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

// =========================================================================================
// ENTRY POINT (ZIG 0.16.0 "JUICY MAIN" I/O ENGINE)
// =========================================================================================
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Buffer de gran tamaño para albergar el curso de forma segura en memoria
    var buffer: [131072]u8 = undefined;
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

// Helper para imprimir texto estático sin colisiones con los corchetes de formato de Zig
fn printStatic(writer: anytype, comptime text: []const u8) !void {
    try writer.print("{s}", .{text});
}

// =========================================================================================
// [MODULO 1] ANATOMÍA DE LA ARQUITECTURA x86_64 Y SINTAXIS AT&T
// =========================================================================================
// El procesador x86_64 posee 16 registros de propósito general de 64 bits:
// RAX, RBX, RCX, RDX, RSI, RDI, RBP, RSP, R8, R9, R10, R11, R12, R13, R14, R15.
//
// Podemos acceder a porciones más pequeñas de estos registros:
// +-----------------------------------------------------------------------+
// | RAX (64 bits)                                                         |
// +-----------------------------------+-----------------------------------+
//                                     | EAX (32 bits)                     |
//                                     +-----------------+-----------------+
//                                                       | AX (16 bits)    |
//                                                       +--------+--------+
//                                                       | AH (8) | AL (8) |
//                                                       +--------+--------+
//
// SINTAXIS AT&T VS INTEL:
// 1. Prefijos de Registros:
//    - AT&T: Requiere el símbolo '%' antes de cada registro (ej. %rax). En Zig, como
//      el caracter '%' se usa para sustituir variables en los templates de asm, debemos
//      escaparlo escribiendo '%%' (ej. %%rax).
//    - Intel: No usa prefijos para registros (ej. rax).
//
// 2. Operandos Inmediatos (Literales):
//    - AT&T: Requiere el símbolo '$' antes del número (ej. $42, $0x10).
//    - Intel: Escribe el número crudo (ej. 42, 10h).
//
// 3. Dirección de Operandos:
//    - AT&T: OP ORIGEN, DESTINO.
//      Ejemplo: `movq $42, %%rax` -> Mueve el número 42 al registro RAX.
//    - Intel: OP DESTINO, ORIGEN.
//      Ejemplo: `mov rax, 42` -> Mueve el número 42 al registro RAX.
//
// 4. Sufijos de tamaño:
//    En AT&T, las instrucciones llevan sufijos que indican el ancho del operando:
//    - 'q' (Quadword) -> 64 bits (ej. movq, addq)
//    - 'l' (Longword) -> 32 bits (ej. movl, addl)
//    - 'w' (Word)     -> 16 bits (ej. movw, addw)
//    - 'b' (Byte)     -> 8 bits  (ej. movb, addb)

fn ejemploBasicoMover() u64 {
    // Retornamos un valor cargado directamente en RAX
    return asm (
        \\ movq $0xABCDE, %[ret]
        : [ret] "={rax}" (-> u64),
    );
}

test "Modulo 1: Verificación de movimiento básico a RAX" {
    try expectEqual(@as(u64, 0xABCDE), ejemploBasicoMover());
}

fn ejecutarModulo1(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 1] ANATOMÍA DE LA ARQUITECTURA x86_64 Y SINTAXIS AT&T
        \\====================================================================
        \\ * x86_64 cuenta con 16 registros de proposito general de 64 bits.
        \\ * Zig utiliza el compilador LLVM, el cual emplea por defecto la 
        \\   sintaxis AT&T para evitar inconsistencias en el parsing.
        \\ * Regla nemotecnica de AT&T: OP ORIGEN, DESTINO.
        \\ * Los registros se direccionan con "%%" para escapar el formateador
        \\   interno de strings de Zig.
        \\
    );
}

// =========================================================================================
// [MODULO 2] RESTRICCIONES DE ENTRADA, SALIDA Y ENLACES (CONSTRAINTS)
// =========================================================================================
// Las restricciones (Constraints) le comunican al compilador qué registros debe
// asignar a nuestras variables de Zig antes y después de ejecutar el bloque de código.
//
// SINTAXIS GENERAL:
// asm ( "instrucciones" : salidas : entradas : clobbers );
//
// Tipos de Constraints de Registro en x86_64:
//   "={rax}" -> El valor de retorno se asignará a RAX (Salida exclusivamente).
//   "{rcx}"  -> La variable de entrada debe copiarse a RCX antes de iniciar.
//   "+{rdi}" -> Operando de Lectura-Escritura (In-Out). El valor inicial entra por RDI
//               y el valor resultante se lee del mismo RDI.
//   "r"      -> Registro General. El compilador escoge libremente un registro.
//   "m"      -> Dirección en memoria. Permite operar directamente en la RAM.
//
// Veamos cómo realizar operaciones matemáticas con LEAQ (Load Effective Address).
// Aunque LEAQ fue diseñada para calcular direcciones de punteros, los desarrolladores
// la utilizan como un truco rápido para hacer multiplicaciones y sumas en un solo ciclo.

fn multiplicarPorCinco(valor: u64) u64 {
    return asm (
    // leaq (base, indice, escala), destino -> calcula direccion efectiva
    // En este caso: destino = base + (indice * escala)
    // Por ende: %[ret] = %[in] + (%[in] * 4) = %[in] * 5
        \\ leaq (%[in], %[in], 4), %[ret]
        : [ret] "={rax}" (-> u64),
        : [in] "{rdi}" (valor),
    );
}

test "Modulo 2: Multiplicación por 5 usando LEAQ" {
    try expectEqual(@as(u64, 50), multiplicarPorCinco(10));
    try expectEqual(@as(u64, 0), multiplicarPorCinco(0));
}

fn ejecutarModulo2(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 2] RESTRICCIONES DE ENTRADA Y SALIDA (CONSTRAINTS)
        \\====================================================================
        \\ * Las restricciones (Constraints) actuan como puente entre los tipos 
        \\   de datos de Zig y los registros fisicos de la CPU.
        \\ * "={rax}" indica que el compilador debe extraer el resultado de RAX.
        \\ * "{rdi}" indica que el compilador debe colocar el argumento en RDI
        \\   antes de que comience a ejecutarse nuestro codigo ensamblador.
        \\ * Tambien podemos delegar la eleccion del registro usando "r".
        \\
    );
}

// =========================================================================================
// [MODULO 3] CLOBBERS, EFECTOS SECUNDARIOS Y BARRERAS DE MEMORIA
// =========================================================================================
// Cuando el compilador optimiza el código de tu programa, asume que él posee el control
// absoluto sobre los registros y el estado de la RAM.
//
// volatile:
//   Fuerza al compilador a ejecutar el código ASM inline tal y como está escrito,
//   impidiendo que lo elimine o lo mueva de posición durante el proceso de optimización.
//
// Clobbers de Registros (Estructuras de Zig):
//   Si modificamos registros dentro del código de ensamblador que no están declarados en
//   las salidas, debemos decírselo al compilador. En Zig esto se hace mediante un
//   STRUCT ANÓNIMO de booleanos:
//   Ejemplo: `: .{ .rax = true, .rbx = true }`
//
// Clobber de Memoria (.{ .memory = true }):
//   Funciona como una barrera de memoria ("Memory Barrier"). Le avisa al compilador:
//   "He modificado la RAM en posiciones arbitrarias de forma directa. Vuelve a cargar las
//   variables que tenías cacheadas en registros desde la memoria física antes de continuar".

fn swapMemoria(a: *u64, b: *u64) void {
    asm volatile (
        \\ movq (%[ptr_a]), %%rax
        \\ movq (%[ptr_b]), %%rbx
        \\ movq %%rax, (%[ptr_b])
        \\ movq %%rbx, (%[ptr_a])
        :
        : [ptr_a] "r" (a),
          [ptr_b] "r" (b),
          // Estructura anonima para indicarle los registros ensuciados (Clobbered) al compilador
        : .{ .rax = true, .rbx = true, .memory = true });
}

test "Modulo 3: Intercambio de memoria (Swap) con clobber nativo" {
    var x: u64 = 1111;
    var y: u64 = 9999;
    swapMemoria(&x, &y);
    try expectEqual(@as(u64, 9999), x);
    try expectEqual(@as(u64, 1111), y);
}

fn ejecutarModulo3(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 3] CLOBBERS, VOLATILE Y BARRERAS DE MEMORIA
        \\====================================================================
        \\ * `volatile` previene que el optimizador elimine tu bloque de ASM.
        \\ * Declarar adecuadamente los registros modificados evita la corrupcion
        \\   silenciosa del estado de la aplicacion.
        \\ * En Zig, los clobbers se declaran mediante un struct anonimo de booleanos,
        \\   por ejemplo: `.{ .rax = true, .memory = true }`.
        \\ * El clobber especial `memory` fuerza una sincronizacion total de RAM.
        \\
    );
}

// =========================================================================================
// [MODULO 4] ACCESO DIRECTO AL HARDWARE: LECTURA DE CPUID Y RDTSC (MULTIPLATAFORMA)
// =========================================================================================
// Una gran ventaja de escribir ensamblador es invocar instrucciones no expuestas en el
// lenguaje.
//
// 1. RDTSC: Retorna el numero de ciclos de reloj desde que se encendio el procesador.
//    - Retorna en EDX:EAX (Parte alta en EDX, parte baja en EAX).
//
// 2. CPUID: Permite interrogar a la CPU sobre sus caracteristicas.
//    - Le pasamos una "hoja" (leaf) en EAX (para ver el fabricante, pasamos un 0).
//    - Retorna la cadena del fabricante distribuida en EBX, EDX y ECX.
//
// Para evitar colisiones de asignación en LLVM, utilizamos operandos de lectura-escritura
// "+{eax}" para pasar la hoja y recibir la salida en el mismo registro RAX.

fn obtenerCiclosDeReloj() u64 {
    var baja: u32 = undefined;
    var alta: u32 = undefined;
    asm volatile (
        \\ rdtsc
        : [baja] "={eax}" (baja),
          [alta] "={edx}" (alta),
    );
    return (@as(u64, alta) << 32) | baja;
}

// Estructura para contener el identificador del fabricante de la CPU (12 Bytes de longitud)
const CpuVendor = struct {
    bytes: [12]u8,

    pub fn esIntel(self: CpuVendor) bool {
        return std.mem.eql(u8, &self.bytes, "GenuineIntel");
    }

    pub fn esAMD(self: CpuVendor) bool {
        return std.mem.eql(u8, &self.bytes, "AuthenticAMD");
    }
};

fn obtenerIdentificacionCPU() CpuVendor {
    var r_eax: u32 = 0; // Hoja 0 para consultar el fabricante
    var r_ebx: u32 = undefined;
    var r_edx: u32 = undefined;
    var r_ecx: u32 = undefined;

    asm volatile (
        \\ cpuid
        // r_eax se define como in-out ("+") para entrar y salir por EAX de forma limpia
        : [r_eax] "+{eax}" (r_eax),
          [r_ebx] "={ebx}" (r_ebx),
          [r_edx] "={edx}" (r_edx),
          [r_ecx] "={ecx}" (r_ecx),
    );

    var vendor: CpuVendor = undefined;
    // EBX, EDX y ECX contienen caracteres de 4 bytes cada uno en formato Little Endian
    std.mem.writeInt(u32, vendor.bytes[0..4], r_ebx, .little);
    std.mem.writeInt(u32, vendor.bytes[4..8], r_edx, .little);
    std.mem.writeInt(u32, vendor.bytes[8..12], r_ecx, .little);
    return vendor;
}

test "Modulo 4: Consulta de identificador de fabricante" {
    const vendor = obtenerIdentificacionCPU();
    // La prueba debe correr en procesadores comerciales Intel o AMD
    const es_procesador_valido = vendor.esIntel() or vendor.esAMD();
    try expect(es_procesador_valido);
}

fn ejecutarModulo4(stdout: anytype) !void {
    const vendor = obtenerIdentificacionCPU();
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 4] ACCESO DIRECTO AL HARDWARE (CPUID & RDTSC)
        \\====================================================================
        \\ * Es posible leer registros especificos de control usando ASM inline.
        \\ * La CPU reporta su fabricante directamente mediante la instruccion CPUID.
        \\
    );
    try stdout.print("   -> Fabricante de tu CPU detectado: {s}\n", .{vendor.bytes});
    try stdout.print("   -> Ciclos de reloj transcurridos: {d}\n\n", .{obtenerCiclosDeReloj()});
}

// =========================================================================================
// [MODULO 5] LA GRAN BATALLA DE ABIS: WINDOWS x64 VS. SYSTEM V (LINUX)
// =========================================================================================
// Cuando una funcion es llamada en x86_64, los parametros no se pasan al azar.
// Se rigen por la ABI (Application Binary Interface) del Sistema Operativo.
//
// 1. MICROSOFT x64 CALLING CONVENTION (Windows):
//    - Primeros 4 enteros/punteros van en: RCX, RDX, R8, R9.
//    - El llamador debe reservar obligatoriamente 32 bytes de espacio en la pila
//      llamados "Shadow Space" o "Home Space" justo antes del CALL.
//    - Preservados por el callee: RBX, RBP, RDI, RSI, RSP, R12, R13, R14, R15.
//
// 2. SYSTEM V AMD64 ABI (Linux, macOS, BSD):
//    - Primeros 6 enteros/punteros van en: RDI, RSI, RDX, RCX, R8, R9.
//    - No requiere reservar Shadow Space.
//    - Posee una "Red Zone" de 128 bytes por debajo del puntero de pila (RSP)
//      que las funciones hoja pueden usar sin alterar la pila.
//
// COMPARATIVA DE PASO DE PARAMETROS:
// +-------+-------------+-------------+
// | Arg # | Windows ABI | System V    |
// +-------+-------------+-------------+
// | 1     | RCX         | RDI         |
// | 2     | RDX         | RSI         |
// | 3     | R8          | RDX         |
// | 4     | R9          | RCX         |
// +-------+-------------+-------------+

fn sumaCuatroValoresABI(a: u64, b: u64, c: u64, d: u64) u64 {
    if (builtin.os.tag == .windows) {
        // En Windows: a=RCX, b=RDX, c=R8, d=R9
        return asm (
            \\ movq %[arg1], %%rax
            \\ addq %[arg2], %%rax
            \\ addq %[arg3], %%rax
            \\ addq %[arg4], %%rax
            : [ret] "={rax}" (-> u64),
            : [arg1] "{rcx}" (a),
              [arg2] "{rdx}" (b),
              [arg3] "{r8}" (c),
              [arg4] "{r9}" (d),
        );
    } else {
        // En Linux: a=RDI, b=RSI, c=RDX, d=RCX
        return asm (
            \\ movq %[arg1], %%rax
            \\ addq %[arg2], %%rax
            \\ addq %[arg3], %%rax
            \\ addq %[arg4], %%rax
            : [ret] "={rax}" (-> u64),
            : [arg1] "{rdi}" (a),
              [arg2] "{rsi}" (b),
              [arg3] "{rdx}" (c),
              [arg4] "{rcx}" (d),
        );
    }
}

test "Modulo 5: Comprobar el paso de parametros respetando la ABI activa" {
    const res = sumaCuatroValoresABI(10, 20, 30, 40);
    try expectEqual(@as(u64, 100), res);
}

fn ejecutarModulo5(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 5] LA GRAN BATALLA DE ABIS (WINDOWS VS. LINUX)
        \\====================================================================
        \\ * El paso de parametros a nivel fisico cambia segun el sistema operativo.
        \\ * Windows reserva "Shadow Space" de 32 bytes y usa RCX, RDX, R8, R9.
        \\ * Linux/POSIX prescinde del Shadow Space y usa RDI, RSI, RDX, RCX, R8, R9.
        \\ * Ignorar estas diferencias al de-serializar datos o invocar funciones
        \\   de bajo nivel provocara crash de violacion de acceso (Access Violation).
        \\
    );
}

// =========================================================================================
// [MODULO 6] ENSAMBLADOR GLOBAL CONDICIONAL (COMPTIME ASM)
// =========================================================================================
// El ensamblador inline está limitado al cuerpo de funciones. Si deseas declarar
// funciones completas escritas en Assembly puro que puedan ser consumidas por otros
// archivos u otros lenguajes, debes usar `comptime asm` (Ensamblador Global).
//
// Como las ABIs difieren, usaremos bloques `comptime` condicionales para inyectar la
// funcion correcta segun el sistema operativo objetivo al momento de la compilacion.

comptime {
    if (builtin.cpu.arch == .x86_64) {
        if (builtin.os.tag == .windows) {
            // Implementacion para la ABI de Windows (Microsoft x64)
            asm (
                \\.global funcion_global_asm;
                \\funcion_global_asm:
                \\  movq %rcx, %rax       # Mueve primer argumento (RCX) a RAX
                \\  subq %rdx, %rax       # Resta segundo argumento (RDX) de RAX
                \\  retq                  # Retorna a la funcion llamadora
            );
        } else {
            // Implementacion para la ABI System V (Linux / macOS / BSD)
            asm (
                \\.global funcion_global_asm;
                \\.type funcion_global_asm, @function;
                \\funcion_global_asm:
                \\  movq %rdi, %rax       # Mueve primer argumento (RDI) a RAX
                \\  subq %rsi, %rax       # Resta segundo argumento (RSI) de RAX
                \\  retq
            );
        }
    }
}

// Enlace externo de la funcion inyectada globalmente
extern fn funcion_global_asm(a: i64, b: i64) i64;

test "Modulo 6: Evaluando Ensamblador Global de baja latencia" {
    const res = funcion_global_asm(100, 30);
    try expectEqual(@as(i64, 70), res);
}

fn ejecutarModulo6(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 6] ENSAMBLADOR GLOBAL CONDICIONAL (COMPTIME ASM)
        \\====================================================================
        \\ * El bloque `comptime { asm(...); }` permite inyectar instrucciones 
        \\   fuera del flujo tipico del compilador.
        \\ * El enlazador (Linker) conecta estas etiquetas directamente como
        \\   funciones nativas.
        \\ * Permite optimizar algoritmos matematicos o criptograficos de manera
        \\   independiente y aislada de las decisiones del compilador.
        \\
    );
}

// =========================================================================================
// [MODULO 7] INSTRUCCIONES VECTORIALES (SIMD / SSE) EN ENSAMBLADOR INLINE
// =========================================================================================
// x86_64 cuenta con registros adicionales de 128 bits llamados XMM0 a XMM15.
// Las instrucciones SIMD (Single Instruction, Multiple Data) permiten procesar
// multiples elementos de datos de coma flotante o enteros en un solo ciclo de CPU.
//
// Usaremos "movups" (Move Unaligned Packed Single-Precision) y "addps" (Add Packed Singles)
// para sumar 4 flotantes de precisión simple (f32) de forma simultánea.

fn sumarVectoresSSE(a: *const [4]f32, b: *const [4]f32) [4]f32 {
    var resultado: [4]f32 = undefined;

    asm volatile (
    // Cargamos 4 elementos (128 bits) de 'a' y 'b' en los registros vectoriales XMM0 y XMM1
        \\ movups (%[p_a]), %%xmm0
        \\ movups (%[p_b]), %%xmm1
        // Sumamos los 4 elementos en paralelo: xmm0 = xmm0 + xmm1
        \\ addps %%xmm1, %%xmm0
        // Almacenamos el resultado de vuelta en memoria RAM
        \\ movups %%xmm0, (%[p_res])
        :
        : [p_a] "r" (a),
          [p_b] "r" (b),
          [p_res] "r" (&resultado),
        : .{ .xmm0 = true, .xmm1 = true, .memory = true });

    return resultado;
}

test "Modulo 7: Suma vectorial paralela de 4 elementos f32" {
    const vec_a = [4]f32{ 1.0, 2.0, 3.0, 4.0 };
    const vec_b = [4]f32{ 10.0, 20.0, 30.0, 40.0 };

    const res = sumarVectoresSSE(&vec_a, &vec_b);

    try expectEqual(@as(f32, 11.0), res[0]);
    try expectEqual(@as(f32, 22.0), res[1]);
    try expectEqual(@as(f32, 33.0), res[2]);
    try expectEqual(@as(f32, 44.0), res[3]);
}

fn ejecutarModulo7(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 7] INSTRUCCIONES VECTORIALES (SIMD / SSE)
        \\====================================================================
        \\ * Los procesadores x86_64 exponen unidades de calculo vectorial XMM.
        \\ * Con instrucciones como `addps`, se procesan multiples datos flotantes
        \\   en paralelo mediante hardware especifico de aceleracion de la CPU.
        \\ * Esta tecnica es ampliamente utilizada en motores graficos, procesadores
        \\   de audio y simulaciones de inteligencia artificial.
        \\
    );
}

// =========================================================================================
// [MODULO 8] PROYECTO PRÁCTICO: MEMSET OPTIMIZADO A NIVEL DE CPU
// =========================================================================================
// Como proyecto integrador, implementaremos nuestra propia version ultra-rapida de
// la funcion `memset` (llenar un bloque de memoria con un byte especifico).
//
// Para lograr la maxima velocidad en bloques de memoria continuos, utilizaremos la
// instrucción especializada `rep stosb`.
//
// Funcionamiento de `rep stosb`:
// 1. RAX: Debe contener el valor de byte a escribir (en AL).
// 2. RDI: Debe apuntar a la direccion de memoria destino.
// 3. RCX: Debe contener la cantidad de bytes a reescribir.
//
// Al ejecutar `rep stosb`, la CPU escribe el valor de AL en la direccion apuntada por RDI,
// incrementa RDI de forma automatica y decrementa RCX, repitiendo el proceso en hardware
// hasta que RCX sea 0.
//
// NOTA CLAVE DE OPTIMIZACIÓN EN LLVM:
// Como RDI y RCX cambian su valor en cada iteracion por diseño de la CPU, los vinculamos
// como operandos de lectura-escritura usando el prefijo "+". Así, el compilador sabe
// exactamente qué pasó con sus registros tras terminar el bucle.

fn memsetRapido(destino: []u8, valor: u8) void {
    if (destino.len == 0) return;

    // Duplicamos puntero y tamaño para usarlos como operandos in-out mutables
    var dest_ptr = destino.ptr;
    var dest_len = destino.len;

    asm volatile (
    // cld limpia el "Direction Flag" garantizando que RDI se incremente
    // y no se decremente durante el bucle de escritura
        \\ cld
        \\ rep stosb
        : [dest] "+{rdi}" (dest_ptr),
          [count] "+{rcx}" (dest_len),
        : [val] "{al}" (valor),
        : .{ .memory = true });
}

test "Modulo 8: Validando memset optimizado de hardware" {
    var buffer_prueba = [_]u8{1} ** 256;

    // Llenamos el buffer de prueba con el byte 0xAA (170 en decimal)
    memsetRapido(&buffer_prueba, 0xAA);

    for (buffer_prueba) |byte| {
        try expectEqual(@as(u8, 0xAA), byte);
    }
}

fn ejecutarModulo8(stdout: anytype) !void {
    try printStatic(stdout,
        \\
        \\====================================================================
        \\ [MODULO 8] PROYECTO PRÁCTICO (MEMSET DE HARDWARE)
        \\====================================================================
        \\ * Hemos integrado los conceptos de constraints, clobbers y volatile.
        \\ * La instruccion `rep stosb` de la CPU permite reescribir la memoria RAM
        \\   de forma mas veloz que un bucle manual convencional de alto nivel.
        \\ * Tambien garantizamos que RDI se incremente de forma correcta mediante
        \\   la instruccion inicial `cld` (Clear Direction Flag).
        \\
    );
}

// =========================================================================================
// FORMATO DE PRESENTACION Y CIERRE DEL CURSO
// =========================================================================================
fn imprimirCabecera(stdout: anytype) !void {
    try printStatic(stdout,
        \\====================================================================
        \\     ___ ___ ___      _   ___ __  __ 
        \\    |_  |_ _/ __|    /_\ / __|  \/  |
        \\     / / | | (_ |   / _ \ __ \ |\/| |
        \\    /___|___\___|  /_/ \_\___/_|  |_|
        \\                                                            
        \\    MASTERCLASS COMPLETA: ENSAMBLADOR x86_64 EN ZIG 0.16.0
        \\====================================================================
        \\ Este archivo se ha compilado exitosamente. A continuacion, se presenta
        \\ el analisis interactivo directo de tu procesador fisico actual:
        \\====================================================================
        \\
    );
}

fn imprimirCierre(stdout: anytype) !void {
    try printStatic(stdout,
        \\====================================================================
        \\ [ANALISIS FINALIZADO CON EXITO]
        \\====================================================================
        \\ Has completado la inmersion practica de Ensamblador en Zig 0.16.0.
        \\
        \\ Pasos siguientes recomendados:
        \\ 1. Ejecuta la suite de pruebas nativas:
        \\    $ zig test masterclass_assembly_v2.zig
        \\
        \\ 2. Inspecciona el codigo ensamblador generado directamente por el 
        \\    compilador de Zig ejecutando:
        \\    $ zig build-exe masterclass_assembly_v2.zig --emit asm
        \\====================================================================
        \\
    );
}
