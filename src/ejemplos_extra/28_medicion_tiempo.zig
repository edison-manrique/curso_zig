// Zig Release Version: 0.16.0
// Tema: Medición de Tiempo y Nuevas APIs de I/O
// Nivel: Intermedio/Avanzado

const std = @import("std");

/// Función auxiliar para crear un writer con buffer explícito (Patrón Zig 0.16.0)
pub fn generateStdOut(init: std.process.Init) std.Io.Writer {
    // 1. Tú declaras el tamaño del buffer de memoria (ej. 4 KB)
    var buffer: [4096]u8 = undefined;
    
    // 2. Creas el "escritor" vinculando el archivo stdout, el contexto (io) y tu buffer
    var stdout_impl = std.Io.File.stdout().writer(init.io, &buffer);
    
    // 3. Extraes la interfaz genérica para poder usar la función .print()
    const stdout = &stdout_impl.interface;
    
    return stdout;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // ==========================================
    // MAGIA DE ZIG 0.16: I/O Explícito
    // En versiones anteriores, std.io.getStdOut() era implícito.
    // Ahora tú tienes el control total sobre la memoria del buffer.
    // ==========================================

    // 1. Declaración explícita del buffer en la pila (stack)
    var buffer: [4096]u8 = undefined;

    // 2. Creación del writer vinculado a stdout y nuestro buffer
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);

    // 3. Obtención de la interfaz genérica para usar .print()
    const stdout = &stdout_impl.interface;

    // IMPORTANTE: Como la consola ahora espera a que tu buffer se llene,
    // debes obligarla a "vaciar" o "escupir" (flush) el texto manualmente.
    // Usamos 'defer' para asegurar que se limpie al salir de la función.
    defer stdout.flush() catch {};

    // Configuración del benchmark: Cálculo de PI por método Montecarlo
    const iteraciones: usize = 100_000_000;
    var dentro_del_circulo: usize = 0;

    // Imprimir mensaje inicial
    try stdout.print("Calculando PI con {d} millones de iteraciones...\n", .{iteraciones / 1_000_000});
    
    // Forzamos a imprimir esto ANTES de que empiece a calcular el bucle
    // para que el usuario vea progreso inmediato.
    try stdout.flush(); 

    // ==========================================
    // MEDICIÓN DE TIEMPO
    // ==========================================
    
    // Capturamos el tiempo de inicio usando el reloj "awake" (tiempo real despierto)
    const start = std.Io.Clock.awake.now(io);
    
    const f_iteraciones: f64 = @floatFromInt(iteraciones);

    // Bucle intensivo para demostrar la medición
    for (0..iteraciones) |i| {
        // Generación de pseudo-aleatorios simples para el ejemplo
        const x = @as(f64, @floatFromInt(i)) / f_iteraciones;
        const y = @as(f64, @floatFromInt((i * i) % iteraciones)) / f_iteraciones;

        // Verificación si el punto está dentro del círculo unitario
        if (x * x + y * y <= 1.0) {
            dentro_del_circulo += 1;
        }
    }

    // Cálculo final de PI
    const pi_estimado = 4.0 * @as(f64, @floatFromInt(dentro_del_circulo)) / f_iteraciones;
    
    // Calculamos la duración transcurrida
    const duracion = start.untilNow(io, .awake);

    // ==========================================
    // RESULTADOS
    // ==========================================
    
    try stdout.print("---\n", .{});
    try stdout.print("Resultado de PI: {d:.6}\n", .{pi_estimado});

    // Conversión de nanosegundos a milisegundos (f64)
    const ms_float = @as(f64, @floatFromInt(duracion.toNanoseconds())) / 1_000_000.0;
    
    try stdout.print("Tiempo de ejecución: {d:.2}ms\n", .{ms_float});
    try stdout.print("¡Velocidad alcanzada!\n", .{});

    // Al salir de la función, el 'defer' de arriba se encargará 
    // del último flush automáticamente para mostrar los resultados finales.
}
