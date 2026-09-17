// =========================================================================================
// MASTERCLASS: FUNCIONES BUILTIN (PARTE 3) - C-INTEROP, ATOMICAS Y COMPTIME
// =========================================================================================
//
// CONTENIDO DE LA MASTERCLASS (11 Builtins cubiertos):
// 1. Memoria y Punteros: @offsetOf y @constCast.
// 2. Control de Llamadas (Optimizador): @call.
// 3. Interoperabilidad con C (Directa): @cImport, @cInclude, @cDefine.
// 4. Conteo de Bits por Hardware: @clz (Count Leading Zeroes).
// 5. Concurrencia Extrema (CAS): @cmpxchgStrong y @cmpxchgWeak.
// 6. Depuracion en Tiempo de Compilacion: @compileError y @compileLog.
//
// Todo el codigo esta en ASCII puro para compatibilidad universal con terminales.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");

// =========================================================================================
// ZIG 0.16.0 "JUICY MAIN" - ENTRY POINT
// =========================================================================================
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);

    try modulo1_MemoriaYPunteros(stdout);
    try modulo2_ControlDeLlamadas(stdout);
    try modulo3_InteroperabilidadConC(stdout);
    try modulo4_ConteoDeBits(stdout);
    try modulo5_ConcurrenciaCAS(stdout);
    try modulo6_DepuracionComptime(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: MEMORIA Y PUNTEROS (@offsetOf, @constCast)
// =========================================================================================
const PaqueteDeDatos = struct {
    activo: bool,
    identificador: u32,
};

fn modulo1_MemoriaYPunteros(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: @offsetOf y @constCast\n", .{});

    // 1. @offsetOf(Tipo, "campo"): Devuelve el offset en BYTES del campo en la estructura.
    // Util para serializacion manual o interactuar con APIs de C que esperan offsets.
    const offset_id = @offsetOf(PaqueteDeDatos, "identificador");
    try stdout.print("  El 'identificador' inicia en el byte {d} de la estructura.\n", .{offset_id});

    // 2. @constCast: Quita el calificador 'const' de un puntero.
    // PELIGRO: Mutar una variable declarada originalmente como 'const' es Comportamiento Indefinido (UB).
    // Uso correcto: Cuando recibes un parametro *const T (por una API estricta)
    // pero SABES que la memoria subyacente es mutable.

    var variable_real: i32 = 100; // Memoria original MUTABLE
    const ptr_solo_lectura: *const i32 = &variable_real;

    // Le quitamos el candado al puntero
    const ptr_mutable: *i32 = @constCast(ptr_solo_lectura);
    ptr_mutable.* = 999;

    try stdout.print("  Mutacion via @constCast exitosa: {d}\n\n", .{variable_real});
}

// =========================================================================================
// MODULO 2: CONTROL DEL OPTIMIZADOR Y LLAMADAS (@call)
// =========================================================================================
fn multiplicar(a: i32, b: i32) i32 {
    return a * b;
}

fn modulo2_ControlDeLlamadas(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Modificadores de Invocacion (@call)\n", .{});

    // @call te permite invocar una funcion dictandole reglas estrictas al compilador (LLVM).
    // Si la regla no se puede cumplir, el programa NO compila.

    // .always_inline: Obliga a incrustar el codigo de la funcion aqui mismo, eliminando
    // el salto de memoria. Si la funcion es muy grande o recursiva, dara error.
    const resultado = @call(.always_inline, multiplicar, .{ 10, 5 });

    // Otros modificadores interesantes (std.builtin.CallModifier):
    // .never_inline -> Previene crecimiento excesivo del binario.
    // .always_tail  -> Fuerza Tail-Call Optimization (util en recursividad profunda).

    try stdout.print("  Resultado con .always_inline: {d}\n\n", .{resultado});
}

// =========================================================================================
// MODULO 3: INTEROPERABILIDAD DIRECTA CON C (@cImport, @cInclude, @cDefine)
// =========================================================================================
fn modulo3_InteroperabilidadConC(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Compilacion C Integrada (@cImport)\n", .{});

    // @cImport y @cDefine nos permiten escribir codigo y macros de C directamente.
    // Para que sea 100% funcional sin requerir cabeceras de sistema (como stdio.h)
    // ni enlazar a libc con '-lc', definimos un macro de C que actua como funcion (MULTIPLICAR_C)
    // y un macro que actua como constante (VERSION_C).
    //
    // Zig compilara esto de manera nativa e instantanea en cualquier sistema operativo.
    const c = @cImport({
        @cDefine("MULTIPLICAR_C(x, y)", "((x) * (y))");
        @cDefine("VERSION_C", "42");
        // @cInclude("stdio.h");
    });

    // Zig automágicamente traduce las macros de C a funciones seguras de Zig.
    const calculo_c = c.MULTIPLICAR_C(10, 5);
    const constante_c = c.VERSION_C;

    try stdout.print("  [Exito] @cImport compilo macros C sin depender de archivos de cabecera externos.\n", .{});
    try stdout.print("  Calculo ejecutado en la macro C: {d}\n", .{calculo_c});
    try stdout.print("  Constante C parseada por Zig: {d}\n\n", .{constante_c});
}

// =========================================================================================
// MODULO 4: CONTEO DE BITS POR HARDWARE (@clz)
// =========================================================================================
fn modulo4_ConteoDeBits(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Count Leading Zeroes (@clz)\n", .{});

    // @clz cuenta cuantos "0" existen a la izquierda del primer "1" en binario.
    // Es CRITICO en la implementacion de Tablas Hash, Arboles Radix y de redes.
    // Modernas CPUs tienen instrucciones de silicio dedicadas para resolver esto en 1 ciclo.

    // Representacion de 12: 0b0000_1100 (en un u8)
    // Tiene exactamente 4 ceros a la izquierda.
    const numero: u8 = 12;
    const ceros_lideres = @clz(numero);

    try stdout.print("  Numero: {d} (0b00001100)\n", .{numero});
    try stdout.print("  Ceros a la izquierda (@clz): {d}\n\n", .{ceros_lideres});
}

// =========================================================================================
// MODULO 5: CONCURRENCIA ATOMICA CAS (@cmpxchgStrong, @cmpxchgWeak)
// =========================================================================================
fn modulo5_ConcurrenciaCAS(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Compare-And-Swap (CAS)\n", .{});

    // "Compare And Swap" es el corazon de los Mutexes, Spinlocks y Semaphores de tu SO.
    // Revisa si una variable tiene el 'valor esperado', y si es asi, la cambia por
    // el 'nuevo valor', de forma totalmente indivisible.

    var estado_hilo: u32 = 0; // 0 = Libre, 1 = Ocupado

    // @cmpxchgStrong
    // Retorna 'null' si tuvo EXITO. Si falla, retorna el valor actual que entorpecio la operacion.
    const intento1 = @cmpxchgStrong(u32, &estado_hilo, 0, 1, .seq_cst, .seq_cst);

    // @cmpxchgWeak
    // Hace lo mismo, pero en arquitecturas ARM (Load-Link / Store-Conditional),
    // Weak puede fallar esporadicamente aunque el valor esperado sea correcto.
    // Se usa dentro de bucles "while", ya que genera codigo maquina mas rapido.
    const intento2 = @cmpxchgWeak(u32, &estado_hilo, 0, 1, .seq_cst, .seq_cst);

    try stdout.print("  Intento 1 (Strong): Exito? {s}\n", .{if (intento1 == null) "SI" else "NO"});
    // intento2 fallara, porque estado_hilo ahora es 1, y esperaba 0.
    try stdout.print("  Intento 2 (Weak): Exito? {s} (Estaba en {d})\n\n", .{ if (intento2 == null) "SI" else "NO", intento2.? });
}

// =========================================================================================
// MODULO 6: DEPURACION EN COMPILACION (@compileError, @compileLog)
// =========================================================================================
fn modulo6_DepuracionComptime(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: Herramientas Comptime\n", .{});

    // Zig ejecuta codigo en tiempo de compilacion con la palabra clave 'comptime'.
    // A veces, mientras programas logica generica, necesitas imprimir el valor
    // de una variable antes de que el programa se convierta en un binario.

    comptime {
        const SO_Soportado = true;

        if (!SO_Soportado) {
            // Aborta la compilacion con un mensaje humano
            // @compileError("Este Sistema Operativo no esta soportado!");
        }

        // @compileLog("Evaluando compatibilidad...", SO_Soportado);

        // IMPORTANTE: @compileLog IMPRIME el valor durante el `zig build`, pero ADEMAS
        // INYECTA UN ERROR de compilacion. Esto se hace intencionalmente para que
        // jamas dejes un "console.log" olvidado en tu codigo de produccion.
    }

    try stdout.print("  [Info] @compileError aborta la creacion del binario.\n", .{});
    try stdout.print("  [Info] @compileLog imprime en la consola del compilador, pero\n", .{});
    try stdout.print("         rompe la compilacion a proposito para que no lo olvides.\n", .{});
    try stdout.print("  (Ambas instrucciones estan comentadas para permitir esta ejecucion).\n\n", .{});
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
        \\    MASTERCLASS 10: C-INTEROP, ATOMICAS Y COMPTIME (ZIG 0.16.0)
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\ FIN DE LA MASTERCLASS.
        \\====================================================================
        \\ RESUMEN AVANZADO:
        \\ - @constCast abre candados de memoria (cuidado con UB).
        \\ - @call permite exprimir a LLVM forzando Inline o Tail-Calls.
        \\ - @cImport demuestra que Zig *posee* un compilador de C interno.
        \\ - @cmpxchg es la base de programacion asincrona y concurrente.
        \\ - @compileLog previene "basura" en produccion matando el build.
        \\====================================================================
        \\
    , .{});
}
