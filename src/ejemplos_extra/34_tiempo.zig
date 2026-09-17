// =========================================================================
// MASTERCLASS: MANEJO DEL TIEMPO Y RENDIMIENTO (std.Io) - ZIG 0.16.0
// =========================================================================
//
// FILOSOFÍA DEL TIEMPO EN ZIG 0.16.0 (Zero-Hidden-Control-Flow):
// "El tiempo ya no es mágico ni global. Es una interfaz de Entrada/Salida
//  explícita. Todas las mediciones dependen del contexto `io`. Esto te da
//  poder absoluto para inyectar relojes falsos en tests, o ejecutar tu código
//  en hardware puro sin sistema operativo (Bare-Metal)."
//
// CONCEPTOS AVANZADOS CUBIERTOS (LA GUÍA DEFINITIVA):
// 1. I/O Explícito: Configurando tu búfer estático y gestionando .flush().
// 2. Tipos de Relojes en std.Io.Clock:
//    - .awake : Reloj monotónico de CPU activa (Perfecto para Benchmarks).
//    - .boot  : Reloj de uptime continuo (Incluso si el sistema duerme).
//    - .real  : Reloj de calendario/mundo real (Sujeto a cambios NTP).
// 3. Tipado Estricto de Tiempo: `std.Io.Timestamp` vs `std.Io.Duration`.
// 4. Benchmarking Intensivo: Midiendo ráfagas de CPU.
// 5. Formateo Nativo: El nuevo especificador `{f}` para Duraciones.
// =========================================================================

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // ==========================================
    // MAGIA DE ZIG 0.16: I/O Estricto y Explicito
    // ==========================================
    // 1. Declaramos el tamaño del buffer en la pila (Ej. 8 KB)
    var buffer: [8192]u8 = undefined;

    // 2. Creamos el "escritor" vinculando el archivo stdout, el contexto (io) y el buffer
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);

    // 3. Extraemos la interfaz genérica fuertemente tipada
    const stdout = &stdout_impl.interface;

    // IMPORTANTE: Como la consola ahora espera a que tu buffer se llene,
    // debes obligarla a "escupir" (flush) el texto residual antes de salir.
    defer stdout.flush() catch {};
    // ==========================================

    try imprimirCabecera(stdout);

    try modulo_1_relojes(stdout, io);
    try stdout.print("\n", .{}); // Separador

    try modulo_2_benchmarking(stdout, io);
    try stdout.print("\n", .{});

    try modulo_3_duraciones(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================
// MODULO 1: LA TRINIDAD DE LOS RELOJES DE ZIG (std.Io.Clock)
// =========================================================================
fn modulo_1_relojes(stdout: *std.Io.Writer, io: anytype) !void {
    try stdout.print(">> Modulo 1: Obtencion de Timestamps (std.Io.Clock) \n", .{});

    // 1. RELOJ AWAKE (CPU Activa)
    // El mejor para medir rendimiento (Benchmarking). Se pausa si la PC se suspende.
    const t_awake = std.Io.Clock.awake.now(io);

    // 2. RELOJ REAL (Wall-Clock)
    // El mejor para fechas y logs. En Zig 0.16, se garantiza la entrega de un Timestamp
    // (ya no es un Error Union, el compilador maneja las fallas del SO internamente).
    const t_real = std.Io.Clock.real.now(io);

    // Extraemos los nanosegundos crudos (u64)
    try stdout.print("  [Reloj Awake] Timestamp base (Nanosegundos crudos) : {d}\n", .{t_awake.toNanoseconds()});
    try stdout.print("  [Reloj Real]  Timestamp base (Nanosegundos crudos) : {d}\n", .{t_real.toNanoseconds()});

    try stdout.print("  NOTA: En Zig 0.16.0, un Timestamp es solo una marca estatica inmutable.\n", .{});
}

// =========================================================================
// MODULO 2: BENCHMARKING INTENSIVO CON start.untilNow
// =========================================================================
fn modulo_2_benchmarking(stdout: *std.Io.Writer, io: anytype) !void {
    try stdout.print(">> Modulo 2: Midiendo Carga Intensiva de CPU (Monte Carlo PI)\n", .{});

    // Ajustado a 5 millones para no trancar terminales modestas, pero puedes subirlo
    const iteraciones: usize = 5_000_000;
    var dentro_del_circulo: usize = 0;

    try stdout.print("  Calculando PI de forma determinista ({d} millones de loops)...\n", .{iteraciones / 1_000_000});

    // FORZAR SALIDA VISUAL:
    // Puesto que usamos buffers de memoria, la línea de arriba no se imprimirá
    // hasta que el buffer se llene. Llamamos a flush() para verla DE INMEDIATO.
    try stdout.flush();

    // --- INICIO DEL CRONOMETRO ---
    const start = std.Io.Clock.awake.now(io);
    const f_iteraciones: f64 = @floatFromInt(iteraciones);

    for (0..iteraciones) |i| {
        const x = @as(f64, @floatFromInt(i)) / f_iteraciones;
        const y = @as(f64, @floatFromInt((i * i) % iteraciones)) / f_iteraciones;

        if (x * x + y * y <= 1.0) {
            dentro_del_circulo += 1;
        }
    }

    const pi_estimado = 4.0 * @as(f64, @floatFromInt(dentro_del_circulo)) / f_iteraciones;

    // --- FIN DEL CRONOMETRO ---
    // En lugar de restar variables a mano, Zig de forma nativa provee .untilNow(io, reloj),
    // lo que retorna un objeto fuertemente tipado: std.Io.Duration
    const duracion = start.untilNow(io, .awake);

    try stdout.print("\n", .{});
    try stdout.print("  Resultado de PI: {d:.6}\n", .{pi_estimado});

    // CÁLCULO TRADICIONAL (Float):
    // Convertimos los nanosegundos (u64) a f64 para dividir con precisión
    const ms_float = @as(f64, @floatFromInt(duracion.toNanoseconds())) / 1_000_000.0;
    try stdout.print("  Tiempo de CPU (Mates crudas) : {d:.2} ms\n", .{ms_float});
}

// =========================================================================
// MODULO 3: FORMATEO NATIVO Y MATEMÁTICAS DE TIEMPO (std.Io.Duration)
// =========================================================================
fn modulo_3_duraciones(stdout: *std.Io.Writer) !void {
    try stdout.print(">> Modulo 3: El Poder de std.Io.Duration (Formateo Cero-Asignacion) \n", .{});

    // Las duraciones pueden construirse libremente y pasarse entre funciones
    const nanosegundos: u64 = 1_543_210_000;
    const dur_ejemplo = std.Io.Duration.fromNanoseconds(nanosegundos);

    // MAGIA VISUAL: El antiguo formato {D} murió. Ahora, todas las duraciones
    // implementan la interfaz nativa `format` invocable con {f}.
    // Esto detecta automáticamente si imprimir en 's', 'ms', 'us', o 'ns'.
    try stdout.print("  [Auto Formateo] 1.5 billones de ns se leen como : {f}\n", .{dur_ejemplo});

    // MATEMÁTICA DE TIEMPO (Cero ambigüedad):
    // Sumar y restar tiempo sin miedo a mezclar unidades diferentes.
    const extra_ms = std.Io.Duration.fromMilliseconds(500); // 0.5 segundos

    // La suma se normaliza a nanosegundos para evitar pérdida de precisión
    const total_ns = dur_ejemplo.toNanoseconds() + extra_ms.toNanoseconds();
    const dur_total = std.Io.Duration.fromNanoseconds(total_ns);

    try stdout.print("  [Suma de Tiempos] {f} + {f} = {f} \n\n", .{ dur_ejemplo, extra_ms, dur_total });
}

// =========================================================================
// UTILIDADES VISUALES Y DE IMPRESIÓN UTF-8
// =========================================================================
fn imprimirCabecera(stdout: *std.Io.Writer) !void {
    try stdout.print(
        \\====================================================================
        \\  MASTERCLASS: MANEJO DEL TIEMPO (ZIG 0.16.0)
        \\====================================================================
        \\
        \\
    , .{});
}

fn imprimirCierre(stdout: *std.Io.Writer) !void {
    // CORRECCIÓN: Se escapan las llaves de '{f}' como '{{f}}' para evitar que std.fmt
    // intente parsear y requiera argumentos adicionales de la tupla.
    try stdout.print(
        \\====================================================================
        \\ RESUMEN DE RENDIMIENTO DE TIEMPO EN ZIG 0.16:
        \\ - No existen "Timers" magicos globales. Todo fluye por tu contexto 'io'.
        \\ - Usar siempre .awake para benchmarking y .real para timestamps de BBDD.
        \\ - El compilador ahora garantiza la entrega segura de Timestamps.
        \\ - Imprime siempre usando '{{f}}' sobre un `std.Io.Duration`.
        \\ - No olvides el try stdout.flush() si mides tareas muy largas!
        \\====================================================================
        \\
    , .{});
}
