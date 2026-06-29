// =========================================================================
// GUIA DE APRENDIZAJE: MODOS DE COMPILACION (EDICION ZIG 0.16.0)
// =========================================================================
// En Zig, la forma en que se compila el codigo determina el balance entre:
// 1. Velocidad de ejecucion (Runtime performance)
// 2. Seguridad en ejecucion (Safety checks)
// 3. Velocidad de compilacion (Compile-time speed)
// 4. Tamano del ejecutable final (Binary size)
//
// Todo el codigo e instrucciones estan disenados en ASCII puro (7-bit)
// para maxima compatibilidad con cualquier consola y editor del mundo.
//
// CONTENIDO DE LA GUIA:
// Modulo 1: Analisis Comparativo de los 4 Modos de Optimizacion
// Modulo 2: Configuracion del Archivo 'build.zig'
// Modulo 3: Deteccion del Modo Activo en Tiempo de Compilacion
// Modulo 4: Comportamiento Práctico de los Chequeos de Seguridad
// =========================================================================

const std = @import("std");
const builtin = @import("builtin");

// ZIG 0.16.0 MAIN: Estructura estandar de entrada con inyeccion de dependencias
pub fn main(init: std.process.Init) !void {
    // Obtenemos el subsistema de I/O inyectado por el entorno
    const io = init.io;

    // Inicializamos un buffer de escritura de alto rendimiento para stdout
    var buffer: [16384]u8 = undefined;

    // Usamos el nuevo std.Io (Notar la 'I' mayuscula del subsistema 0.16.0)
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Aseguramos que la consola reciba todo el contenido al finalizar
    defer stdout.flush() catch {};

    try stdout.print("====================================================\n", .{});
    try stdout.print("     GUIA DE APRENDIZAJE: MODOS DE COMPILACION      \n", .{});
    try stdout.print("====================================================\n\n", .{});

    try modulo1ExplicacionTeorica(stdout);
    try modulo2ConfiguracionBuild(stdout);
    try modulo3DeteccionCompilacion(stdout);
    try modulo4DemostracionSeguridad(stdout);

    try stdout.print("\n====================================================\n", .{});
    try stdout.print("     FIN DE LA GUIA - COMPILADO CON EXITO           \n", .{});
    try stdout.print("====================================================\n", .{});
}

// =========================================================================
// MODULO 1: ANALISIS COMPARATIVO DE LOS 4 MODOS DE OPTIMIZACION
// =========================================================================
fn modulo1ExplicacionTeorica(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Los Cuatro Modos de Optimizacion\n\n", .{});

    try stdout.print("  1. Debug (Predeterminado)\n", .{});
    try stdout.print("     - Comando: zig build-exe archivo.zig\n", .{});
    try stdout.print("     - Velocidad de compilacion: Muy rapida\n", .{});
    try stdout.print("     - Chequeos de seguridad: Activados (Safety ON)\n", .{});
    try stdout.print("     - Velocidad de ejecucion: Lenta\n", .{});
    try stdout.print("     - Tamano del binario: Grande (con simbolos de depuracion)\n", .{});
    try stdout.print("     - Requisito de build reproducible: No obligatorio\n\n", .{});

    try stdout.print("  2. ReleaseFast\n", .{});
    try stdout.print("     - Comando: zig build-exe archivo.zig -O ReleaseFast\n", .{});
    try stdout.print("     - Velocidad de compilacion: Lenta (optimizaciones agresivas)\n", .{});
    try stdout.print("     - Chequeos de seguridad: Desactivados (Safety OFF)\n", .{});
    try stdout.print("     - Velocidad de ejecucion: Alta\n", .{});
    try stdout.print("     - Tamano del binario: Grande\n", .{});
    try stdout.print("     - Requisito de build reproducible: Si\n\n", .{});

    try stdout.print("  3. ReleaseSafe\n", .{});
    try stdout.print("     - Comando: zig build-exe archivo.zig -O ReleaseSafe\n", .{});
    try stdout.print("     - Velocidad de compilacion: Lenta\n", .{});
    try stdout.print("     - Chequeos de seguridad: Activados (Safety ON)\n", .{});
    try stdout.print("     - Velocidad de ejecucion: Media-Alta\n", .{});
    try stdout.print("     - Tamano del binario: Grande\n", .{});
    try stdout.print("     - Requisito de build reproducible: Si\n\n", .{});

    try stdout.print("  4. ReleaseSmall\n", .{});
    try stdout.print("     - Comando: zig build-exe archivo.zig -O ReleaseSmall\n", .{});
    try stdout.print("     - Velocidad de compilacion: Lenta (optimizaciones de espacio)\n", .{});
    try stdout.print("     - Chequeos de seguridad: Desactivados (Safety OFF)\n", .{});
    try stdout.print("     - Velocidad de ejecucion: Media\n", .{});
    try stdout.print("     - Tamano del binario: Muy pequeno (optimo para sistemas embebidos)\n", .{});
    try stdout.print("     - Requisito de build reproducible: Si\n\n", .{});
}

// =========================================================================
// MODULO 2: CONFIGURACION DEL ARCHIVO 'build.zig'
// =========================================================================
fn modulo2ConfiguracionBuild(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Integracion en el Sistema de Construccion (build.zig)\n\n", .{});
    try stdout.print("  Para permitir que el usuario elija el modo usando parametros como\n", .{});
    try stdout.print("  '-Doptimize=ReleaseFast', se utiliza la API 'std.Build'.\n\n", .{});

    const codigo_ejemplo =
        \\  // Ejemplo de estructura tipica para build.zig en Zig 0.16.0:
        \\  const std = @import("std");
        \\
        \\  pub fn build(b: *std.Build) void {
        \\      // Obtiene la opcion de optimizacion seleccionada por consola
        \\      // Por defecto sera 'Debug' si no se especifica -Doptimize
        \\      const optimize = b.standardOptimizeOption(.{});
        \\
        \\      const exe = b.addExecutable(.{
        \\          .name = "mi-programa",
        \\          .root_module = b.createModule(.{
        \\              .root_source_file = b.path("main.zig"),
        \\              .optimize = optimize,
        \\          }),
        \\      });
        \\
        \\      b.default_step.dependOn(&exe.step);
        \\  }
    ;

    try stdout.print("{s}\n\n", .{codigo_ejemplo});
}

// =========================================================================
// MODULO 3: DETECCION DEL MODO EN TIEMPO DE COMPILACION
// =========================================================================
fn modulo3DeteccionCompilacion(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Consultando el modo actual con '@import(\"builtin\")'\n", .{});

    // La estructura 'builtin' expone metadatos de la compilacion actual
    const modo_actual = builtin.mode;

    try stdout.print("  El programa actual ha sido compilado en modo: ", .{});

    // Al evaluar 'builtin.mode' en un bloque 'switch', el compilador
    // puede realizar optimizaciones de codigo muerto (Dead Code Elimination)
    switch (modo_actual) {
        .Debug => {
            try stdout.print("DEBUG\n", .{});
            try stdout.print("  -> Comportamiento: Depuracion activa, ejecucion mas lenta.\n", .{});
        },
        .ReleaseSafe => {
            try stdout.print("RELEASE SAFE\n", .{});
            try stdout.print("  -> Comportamiento: Optimizacion media, con proteccion ante fallos.\n", .{});
        },
        .ReleaseFast => {
            try stdout.print("RELEASE FAST\n", .{});
            try stdout.print("  -> Comportamiento: Velocidad extrema, sin red de seguridad.\n", .{});
        },
        .ReleaseSmall => {
            try stdout.print("RELEASE SMALL\n", .{});
            try stdout.print("  -> Comportamiento: Busqueda del menor tamano de ejecutable posible.\n", .{});
        },
    }
    try stdout.print("\n", .{});
}

// =========================================================================
// MODULO 4: COMPORTAMIENTO PRACTICO DE LOS CHEQUEOS DE SEGURIDAD
// =========================================================================
// Esta funcion demuestra la diferencia de comportamiento entre modos seguros
// (Debug, ReleaseSafe) y modos no seguros (ReleaseFast, ReleaseSmall).
// Se utiliza una variable mutable oculta para evitar optimizaciones tempranas
// del compilador en tiempo de compilacion.
fn modulo4DemostracionSeguridad(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Demostracion de Chequeos de Seguridad\n", .{});

    try stdout.print("  Que sucede si provocamos un desbordamiento de entero (Overflow)?\n", .{});

    // Usamos punteros volatiles para asegurar que el calculo ocurra en runtime
    var x: u8 = 255;
    const ptr_volatil = @as(*volatile u8, &x);

    try stdout.print("  Valor actual: {d}\n", .{ptr_volatil.*});
    try stdout.print("  Intentando sumar 1 a un u8 con valor de 255...\n", .{});

    // Evaluacion del comportamiento esperado segun el modo de optimizacion
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        try stdout.print("  Resultado esperado: El ejecutable detectara el desbordamiento\n", .{});
        try stdout.print("  y detendra la ejecucion inmediatamente con un Panic (Safety Check).\n", .{});
        try stdout.print("  [Ejecucion de la prueba de overflow omitida para evitar crash programado]\n", .{});
    } else {
        // En ReleaseFast o ReleaseSmall, esto provoca comportamiento indefinido (Undefined Behavior).
        // En muchas plataformas/CPUs puede simplemente retornar 0 por truncamiento de registros,
        // pero no existe garantia alguna por parte del lenguaje.
        try stdout.print("  Resultado esperado: El compilador asume que esto nunca pasara.\n", .{});
        try stdout.print("  No habra alertas y podria dar resultados inesperados o corrupcion.\n", .{});

        // Advertencia: Ejecutar la siguiente linea en ReleaseFast/Small dependera del comportamiento
        // del hardware, pero no hara colapsar la aplicacion con un mensaje de error controlado de Zig.
        const resultado_inseguro = ptr_volatil.* +% 1; // Usamos +% (wrapping) aqui para fines demostrativos seguros
        try stdout.print("  Suma con wrapping explicito (+%): {d}\n", .{resultado_inseguro});
    }
}
