// =========================================================================
//           MASTERCLASS: CONCURRENCIA, HILOS Y SINCRONIZACION
//                         EDICION ZIG 0.16.0
// =========================================================================
// Este documento ha sido disenado como la guia definitiva escrita por
// expertos en sistemas para dominar la ejecucion multihilo en el nuevo
// ecosistema de Zig 0.16.0 (La revolucion del asincronismo y std.Io).
//
// NOTA DE COMPATIBILIDAD: Todo el codigo, graficos ASCII y explicaciones
// estan limitados estrictamente a la codificacion ASCII de 7 bits (rango 0-127)
// para prevenir errores de compilacion y renderizado en consolas legadas.

// =========================================================================
// TABLA DE CONTENIDOS (TEMARIO)
// =========================================================================
// 1. INTRODUCCION: EL EVENTO "WRITERGATE" Y STD.IO
//    1.1 La muerte de std.fs.File y el nacimiento de std.Io.File
//    1.2 Por que los candados ahora piden el contexto "io"
//    1.3 La muerte de std.time.sleep (El nuevo io.sleep)
//
// 2. MODULO 1: EL NUEVO "JUICY MAIN" Y EL ENTORNO I/O
//    2.1 Obtencion del contexto std.Io
//    2.2 Lanzamiento de hilos nativos con std.Thread.spawn
//
// 3. MODULO 2: EXCLUSION MUTUA CON STD.IO.MUTEX
//    3.1 Creacion de un ThreadSafePrinter evadiendo el antiguo Writer
//    3.2 Prevencion de Data Races (Simulador Bancario)
//
// 4. MODULO 3: SPINLOCKS ARTESANALES (CONCURRENCIA BARE-METAL)
//    4.1 Creacion de un candado puro evadiendo el framework std.Io
//    4.2 Operaciones atomicas y Busy-Waiting
//
// 5. MODULO 4: PATRON SCATTER-GATHER (DISPERSAR Y REUNIR)
//    5.1 Lanzamiento en lotes con arreglos de Hilos (Join Multiple)
//
// 6. MODULO 5: THREAD LOCAL STORAGE (TLS)
//    6.1 Memoria global aislada de forma nativa por el compilador
//
// 7. MODULO 6: RENDIMIENTO LOCK-FREE (ATOMICS)
//    7.1 Contadores masivos sin bloqueos de contexto (@atomicRmw)
//
// 8. MODULO 7: HILOS DEMONIOS (FIRE-AND-FORGET)
//    8.1 Sustitucion de Thread Pools usando spawn + detach
//
// 9. CONCLUSIONES Y REGLAS DE ORO EN ZIG 0.16

const std = @import("std");

// =========================================================================
// 1. INTRODUCCION: LA REVOLUCION "STD.IO" EN ZIG 0.16
// =========================================================================
// En versiones antiguas, escribiamos `std.Thread.Mutex` y
// imprimiamos con `std.fs.File`. Tambien dormiamos con `std.time.sleep`.
//
// En Zig 0.16.0, el nucleo de Zig sufrio un refactor masivo arquitectonico.
// Se abstraen los candados, la interaccion de la consola y EL TIEMPO del
// Sistema Operativo directo. Ahora, dormir es una operacion controlada por
// el multiplexor de entrada/salida (`io`). De esta forma, `io.sleep` puede
// pausar un hilo, o puede pausar una Fibra/Corrutina sin bloquear la CPU.

// -------------------------------------------------------------------------
// HERRAMIENTA UTILIDAD: THREAD-SAFE PRINTER (ESTILO 0.16.0)
// -------------------------------------------------------------------------
// Escribir a la consola (stdout) desde multiples hilos al mismo tiempo
// corrompera la salida. Creamos un envoltorio seguro usando el nuevo Mutex.
const ThreadSafePrinter = struct {
    // En Zig 0.16 usamos el inicializador constante oficial del struct
    mutex: std.Io.Mutex = std.Io.Mutex.init,

    pub fn print(self: *@This(), io: std.Io, comptime format: []const u8, args: anytype) void {
        // `lockUncancelable` bloquea el hilo asegurando que ninguna operacion
        // de red o senal OS cancele nuestro candado de forma imprevista.
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        // Nuevo API de Impresion Zig 0.16.0: std.Io.File.stdout().writer()
        // Requiere inyectar el contexto global `io` y un buffer temporal.
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        const stdout = &stdout_writer.interface;

        stdout.print(format, args) catch {};
        stdout.flush() catch {};
    }
};

// =========================================================================
// PUNTO DE ENTRADA PRINCIPAL: EL NUEVO "JUICY MAIN"
// =========================================================================
// En Zig 0.16.0, la firma de `main` recibe el contexto de inicializacion
// del proceso, el cual contiene la gran maquina `std.Io`.
pub fn main(init: std.process.Init) !void {
    // Extraemos el orquestador global de I/O y concurrencia
    const io = init.io;

    var safe_out = ThreadSafePrinter{};

    safe_out.print(io, "=== INICIO DE LA MASTERCLASS DE CONCURRENCIA ZIG 0.16 ===\n\n", .{});

    try modulo1Basicos(io, &safe_out);
    try modulo2ExclusionMutua(io, &safe_out);
    try modulo3SpinLockArtesanal(io, &safe_out);
    try modulo4ScatterGather(io, &safe_out);
    try modulo5ThreadLocalStorage(io, &safe_out);
    try modulo6OperacionesAtomicas(io, &safe_out);
    try modulo7HilosDemonios(io, &safe_out);

    safe_out.print(io, "=== FIN DE LA MASTERCLASS DE CONCURRENCIA ===\n", .{});
}

// =========================================================================
// 2. MODULO 1: CICLO DE VIDA BASICO DE UN HILO NATIVO
// =========================================================================

fn tareaModulo1(io: std.Io, id: u32, printer: *ThreadSafePrinter) void {
    printer.print(io, "  [Hilo Nativo {d}] Iniciando tarea basica...\n", .{id});

    // CORRECCION ZIG 0.16: Dormir es una operacion I/O asincrona.
    // Usamos el reloj ".awake" (Monotonic) para garantizar precision.
    // Atrapamos cualquier error de cancelacion con `catch {}`.
    io.sleep(.{ .nanoseconds = 100 * std.time.ns_per_ms }, .awake) catch {};

    printer.print(io, "  [Hilo Nativo {d}] Finalizado!\n", .{id});
}

fn modulo1Basicos(io: std.Io, printer: *ThreadSafePrinter) !void {
    printer.print(io, ">> MODULO 1: Lanzamiento de Hilos (Spawn & Join)\n", .{});

    // Lanzamos 3 hilos. `spawn` toma:
    // 1. Configuracion de hilo (.{})
    // 2. Puntero a la funcion.
    // 3. Tupla de argumentos para la funcion (ahora inyectando `io`).
    const t1 = try std.Thread.spawn(.{}, tareaModulo1, .{ io, 1, printer });
    const t2 = try std.Thread.spawn(.{}, tareaModulo1, .{ io, 2, printer });
    const t3 = try std.Thread.spawn(.{}, tareaModulo1, .{ io, 3, printer });

    // IMPORTANTE: Si la funcion principal termina antes que los hilos,
    // el proceso entero muere. Usamos `join()` para bloquear el hilo principal.
    t1.join();
    t2.join();
    t3.join();

    printer.print(io, "  [Main] Todos los hilos se han reincorporado (Join exitoso).\n\n", .{});
}

// =========================================================================
// 3. MODULO 2: EXCLUSION MUTUA CON STD.IO.MUTEX
// =========================================================================
// Simulamos una cuenta bancaria compartida. Mostramos como proteger el
// estado mediante la nueva API de Mutex de Zig 0.16.

const CuentaBancaria = struct {
    balance: u64 = 0,
    // Primitiva global centralizada en std.Io
    mutex: std.Io.Mutex = std.Io.Mutex.init,

    pub fn depositar(self: *@This(), io: std.Io, cantidad: u64) void {
        self.mutex.lockUncancelable(io);
        // `defer` garantiza la liberacion del candado previniendo Deadlocks.
        defer self.mutex.unlock(io);

        // SECCION CRITICA: Solo un hilo puede ejecutar esto a la vez
        const balance_actual = self.balance;

        // Latencia artificial forzada para demostrar colisiones potenciales
        io.sleep(.{ .nanoseconds = 100 * std.time.ns_per_us }, .awake) catch {};

        self.balance = balance_actual + cantidad;
    }
};

fn trabajadorBancario(io: std.Io, cuenta: *CuentaBancaria, depositos: usize) void {
    var i: usize = 0;
    while (i < depositos) : (i += 1) {
        cuenta.depositar(io, 10);
    }
}

fn modulo2ExclusionMutua(io: std.Io, printer: *ThreadSafePrinter) !void {
    printer.print(io, ">> MODULO 2: Sincronizacion Explicita (std.Io.Mutex)\n", .{});

    var cuenta = CuentaBancaria{};
    const depositos_por_hilo = 500;

    // Desplegamos 4 hilos apuntando a la MISMA ubicacion de memoria
    const h1 = try std.Thread.spawn(.{}, trabajadorBancario, .{ io, &cuenta, depositos_por_hilo });
    const h2 = try std.Thread.spawn(.{}, trabajadorBancario, .{ io, &cuenta, depositos_por_hilo });
    const h3 = try std.Thread.spawn(.{}, trabajadorBancario, .{ io, &cuenta, depositos_por_hilo });
    const h4 = try std.Thread.spawn(.{}, trabajadorBancario, .{ io, &cuenta, depositos_por_hilo });

    h1.join();
    h2.join();
    h3.join();
    h4.join();

    const esperado = depositos_por_hilo * 4 * 10;
    printer.print(io, "  [Banco] Balance Esperado: ${d}\n", .{esperado});
    printer.print(io, "  [Banco] Balance Obtenido: ${d} (Seguridad LockUncancelable garantizada)\n\n", .{cuenta.balance});
}

// =========================================================================
// 4. MODULO 3: SPINLOCKS ARTESANALES (CONCURRENCIA BARE-METAL)
// =========================================================================
// Si estas escribiendo codigo de ultra-baja latencia para un Motor de Audio,
// un Kernel custom, o no quieres inyectar `std.Io` en tu capa logica baja,
// puedes construir tus propios candados ("SpinLocks") utilizando hardware puro.

const CustomSpinLock = struct {
    // 0 = Desbloqueado | 1 = Bloqueado
    flag: u8 = 0,

    pub fn lock(self: *@This()) void {
        // AtomicRmw (.Xchg) intenta cambiar el flag a 1 de golpe en el silicio.
        // Si el valor devuelto ya era 1, significa que otro hilo nos gano, por
        // lo que entramos en el bucle ("Busy Wait / Spin").
        while (@atomicRmw(u8, &self.flag, .Xchg, 1, .acquire) == 1) {}
    }

    pub fn unlock(self: *@This()) void {
        // Para liberar, simplemente escribimos un 0 de forma atomica con
        // la barrera de memoria `.release` para notificar al procesador.
        @atomicStore(u8, &self.flag, 0, .release);
    }
};

const RecursoCritico = struct {
    datos_procesados: u64 = 0,
    spinlock: CustomSpinLock = .{},
};

fn tareaSpinLock(recurso: *RecursoCritico) void {
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        recurso.spinlock.lock();
        defer recurso.spinlock.unlock();
        recurso.datos_procesados += 1;
    }
}

fn modulo3SpinLockArtesanal(io: std.Io, printer: *ThreadSafePrinter) !void {
    printer.print(io, ">> MODULO 3: SpinLocks Artesanales (Sin dependencia std.Io)\n", .{});

    var recurso = RecursoCritico{};

    // Notese que esta funcion nativa NO requiere inyectar `io` para bloquearse
    const h1 = try std.Thread.spawn(.{}, tareaSpinLock, .{&recurso});
    const h2 = try std.Thread.spawn(.{}, tareaSpinLock, .{&recurso});

    h1.join();
    h2.join();

    printer.print(io, "  [SpinLock] Bloqueo nativo exitoso. Valor: {d} (Esperado 2000)\n\n", .{recurso.datos_procesados});
}

// =========================================================================
// 5. MODULO 4: PATRON SCATTER-GATHER (DISPERSAR Y REUNIR)
// =========================================================================
// En Zig 0.16.0, el patron nativo Multi-Hilo mas limpio para tareas de SO es
// crear un arreglo estatico de hilos, lanzarlos ("Scatter") y reunirlos
// individualmente mediante un bucle ("Gather").

fn tareaDescarga(io: std.Io, id: u32, printer: *ThreadSafePrinter) void {
    printer.print(io, "    [Descarga {d}] Iniciando peticion HTTP de 50ms...\n", .{id});
    io.sleep(.{ .nanoseconds = 50 * std.time.ns_per_ms }, .awake) catch {};
}

fn modulo4ScatterGather(io: std.Io, printer: *ThreadSafePrinter) !void {
    printer.print(io, ">> MODULO 4: Patron Scatter-Gather (Join Arrays)\n", .{});

    var hilos: [5]std.Thread = undefined;

    // SCATTER: Lanzamos las 5 tareas en paralelo iterando sobre punteros
    for (&hilos, 0..) |*h, i| {
        h.* = try std.Thread.spawn(.{}, tareaDescarga, .{ io, @as(u32, @intCast(i + 1)), printer });
    }

    printer.print(io, "  [Main] 5 hilos de red disparados. El nucleo principal espera...\n", .{});

    // GATHER: Nos bloqueamos hasta que cada uno de los hilos finalice.
    for (&hilos) |*h| {
        h.join();
    }

    printer.print(io, "  [Main] Todas las piezas reunidas. Continua la ejecucion.\n\n", .{});
}

// =========================================================================
// 6. MODULO 5: THREAD LOCAL STORAGE (TLS)
// =========================================================================
// A veces, no quieres compartir variables. Quieres que cada hilo tenga
// su propia copia "privada" de una variable global. El compilador y el
// SO aislaran este segmento de memoria por cada hilo invocado.

threadlocal var memoria_privada: u32 = 0;

fn tareaTls(io: std.Io, id: u32, printer: *ThreadSafePrinter) void {
    // Esta escritura SOLO afecta a la copia de 'memoria_privada'
    // perteneciente al hilo actual. No hay condicion de carrera posible.
    memoria_privada = id * 100;

    io.sleep(.{ .nanoseconds = 20 * std.time.ns_per_ms }, .awake) catch {};

    printer.print(io, "    [TLS] Hilo {d} procesa y lee su variable privada: {d}\n", .{ id, memoria_privada });
}

fn modulo5ThreadLocalStorage(io: std.Io, printer: *ThreadSafePrinter) !void {
    printer.print(io, ">> MODULO 5: Thread Local Storage (threadlocal var)\n", .{});

    // El hilo principal establece su propio valor maestro
    memoria_privada = 999;

    const t1 = try std.Thread.spawn(.{}, tareaTls, .{ io, 1, printer });
    const t2 = try std.Thread.spawn(.{}, tareaTls, .{ io, 2, printer });

    t1.join();
    t2.join();

    // El valor del hilo principal debe permanecer intocable
    printer.print(io, "  [Main] La memoria TLS del hilo maestro permanecio intacta: {d}\n\n", .{memoria_privada});
}

// =========================================================================
// 7. MODULO 6: RENDIMIENTO LOCK-FREE (OPERACIONES ATOMICAS)
// =========================================================================
// Incluso con Spinlocks, la contencion frena tu programa.
// Usando primitivas `@atomicRmw`, la CPU resuelve adiciones o restas en
// 1 solo ciclo de reloj de silicio ininterrumpible, evadiendo totalmente
// bloqueos por software o SO.

fn tareaAtomica(contador: *usize) void {
    var i: usize = 0;
    while (i < 50_000) : (i += 1) {
        // @atomicRmw = Atomic Read-Modify-Write.
        // .Add es la operacion de suma.
        // .seq_cst (Sequential Consistency) asegura la mas estricta seguridad
        // en el orden de ejecucion visible a traves de todos los nucleos CPU.
        _ = @atomicRmw(usize, contador, .Add, 1, .seq_cst);
    }
}

fn modulo6OperacionesAtomicas(io: std.Io, printer: *ThreadSafePrinter) !void {
    printer.print(io, ">> MODULO 6: Concurrencia de Hardware (@atomicRmw)\n", .{});

    var contador_global: usize = 0;

    const t1 = try std.Thread.spawn(.{}, tareaAtomica, .{&contador_global});
    const t2 = try std.Thread.spawn(.{}, tareaAtomica, .{&contador_global});
    const t3 = try std.Thread.spawn(.{}, tareaAtomica, .{&contador_global});

    t1.join();
    t2.join();
    t3.join();

    // Lectura atomica totalmente segura sin ningun Mutex de por medio
    const valor_final = @atomicLoad(usize, &contador_global, .seq_cst);
    printer.print(io, "  [Atomicos] Suma masiva completada (Esperado 150000): {d}\n", .{valor_final});
    printer.print(io, "  [Atomicos] Cero sobrecarga del OS o contexto IO.\n\n", .{});
}

// =========================================================================
// 8. MODULO 7: HILOS DEMONIOS (FIRE AND FORGET)
// =========================================================================
// Si envias telemetria en segundo plano, no necesitas retener el hilo para
// hacer un `.join()`. Puedes usar el metodo `.detach()` para que el SO asuma
// la responsabilidad de limpiar su memoria al finalizar su ejecucion.

fn tareaDemonio(io: std.Io, id: u32, printer: *ThreadSafePrinter) void {
    io.sleep(.{ .nanoseconds = 15 * std.time.ns_per_ms }, .awake) catch {};
    printer.print(io, "    [Demonio {d}] Tarea en segundo plano concluida.\n", .{id});
}

fn modulo7HilosDemonios(io: std.Io, printer: *ThreadSafePrinter) !void {
    printer.print(io, ">> MODULO 7: Hilos Desconectados (.detach)\n", .{});

    var i: u32 = 1;
    while (i <= 3) : (i += 1) {
        const hilo = try std.Thread.spawn(.{}, tareaDemonio, .{ io, i, printer });

        // Cortamos el vinculo. El hilo es ahora autonomo y el Hilo Main
        // no podra hacer `join()` para esperarlo.
        hilo.detach();
    }

    // El hilo principal descansa un momento para permitir a los demonios imprimir.
    // Si quitaramos este sleep, el programa terminaria instantaneamente matandolos.
    io.sleep(.{ .nanoseconds = 30 * std.time.ns_per_ms }, .awake) catch {};
    printer.print(io, "  [Main] Demostracion de desvinculacion asincrona completada.\n\n", .{});
}

// =========================================================================
// 9. CONCLUSIONES Y REGLAS DE ORO EN ZIG 0.16.0
// =========================================================================
// 1. ABRACE STD.IO: "Writergate" acabo con `std.fs.File`. El 100% de la
//    interaccion con consolas o archivos requiere instanciar constructos
//    como `std.Io.File.stdout().writer(io, &buffer)` y pasar el orquestador
//    central `io` inyectado desde `main(init: std.process.Init)`.
//
// 2. LA MUERTE DEL SLEEP NATIVO: El acto de dormir ahora es una operacion
//    I/O. Utilice siempre `io.sleep(.{ .nanoseconds = X }, .awake) catch {}`
//    para que el sistema decida si pausar el hilo OS real o solo una Fibra.
//
// 3. EVITE LOS DATA RACES: Pasar variables compartidas en Zig a multiples
//    hilos es facilisimo gracias a las tuplas, pero Zig no tiene un "Borrow
//    Checker" como Rust. Si no sincroniza la escritura mediante `std.Io.Mutex`
//    o `SpinLocks`, corrompera silenciosamente la memoria dinamica.
// =========================================================================
