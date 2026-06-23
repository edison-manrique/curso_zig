// =========================================================================
// MASTERCLASS: GESTION DE ERRORES EN ZIG (EDICION 0.16.0)
// =========================================================================
// Esta guia cubre desde los fundamentos de bajo nivel hasta los patrones
// avanzados de recuperacion y control de flujo de errores en Zig 0.16.0.
// Todo el codigo e instrucciones estan disenados en ASCII puro (7-bit)
// para maxima compatibilidad con cualquier consola y editor del mundo.
//
// CONTENIDO DE LA MASTERCLASS:
// Modulo 1: Concepto de Error Set (Subconjuntos y Coercion)
// Modulo 2: Error Unions y Desempaquetado (try & catch con bloques)
// Modulo 3: Control de Flujo Avanzado (if / switch con capturas)
// Modulo 4: Libera Recursos de Forma Segura (errdefer y captura de errores)
// Modulo 5: Operador de Mezcla (||) y Error Sets Inferidos
// Modulo 6: Anatomia de un Error Return Trace (Como funciona la magia)
// Modulo 7: Proyecto Practico: Sistema de Procesamiento de Pagos
// =========================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Inicializamos un buffer de escritura de alto rendimiento para stdout
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Aseguramos que la consola reciba todo el contenido al finalizar
    defer stdout.flush() catch {};

    try stdout.print("====================================================\n", .{});
    try stdout.print("         MASTERCLASS: ERRORES EN ZIG 0.16.0         \n", .{});
    try stdout.print("====================================================\n\n", .{});

    try modulo1ErrorSets(stdout);
    try modulo2ErrorUnions(stdout);
    try modulo3FlujoAvanzado(stdout);
    try modulo4Errdefer(stdout);
    try modulo5MezclaEInferencia(stdout);
    try modulo6BajoNivel(stdout);
    try modulo7ProyectoPagos(stdout);

    try stdout.print("\n====================================================\n", .{});
    try stdout.print("     FIN DE LA MASTERCLASS - COMPILADO CON EXITO     \n", .{});
    try stdout.print("====================================================\n", .{});
}

// =========================================================================
// MODULO 1: CONCEPTOS DE ERROR SET (SUBCONJUNTOS Y COERCION)
// =========================================================================
// Un Error Set en Zig es similar a una enumeracion (enum). Sin embargo,
// cada nombre de error en todo el binario recibe un identificador entero
// unico global mayor a 0 (de tipo u16 por defecto).
//
// Regla de Coercion: Puedes convertir implicitamente un subconjunto de error
// en un superconjunto, pero NO al reves.

const ErroresDeRed = error{
    Timeout,
    ServidorCaido,
    SinConexion,
};

const ErroresDeFalloCritico = error{
    ServidorCaido, // Comparte el mismo identificador entero global
    OutOfMemory,
};

fn modulo1ErrorSets(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Error Sets y Coercion\n", .{});

    // Ejemplo de Coercion Valida (Subconjunto a Superconjunto):
    // Como ErroresDeRed.ServidorCaido pertenece tambien al set de fallos
    // criticos (u otros mas grandes), podemos enviarlo directamente.
    const err_origen = ErroresDeRed.ServidorCaido;
    const err_destino: anyerror = err_origen; // anyerror es el superconjunto global

    try stdout.print("  [OK] Coercion implicita a anyerror de forma exitosa.\n", .{});
    try stdout.print("  Valor numerico interno de ServidorCaido: {d}\n", .{@intFromError(err_destino)});

    // El atajo de declaracion de un solo valor:
    const error_rapido = error.AccesoDenegado; // Equivale a (error{AccesoDenegado}).AccesoDenegado
    try stdout.print("  [OK] Atajo para error simple: {any}\n\n", .{error_rapido});
}

// =========================================================================
// MODULO 2: ERROR UNIONS Y DESEMPAQUETADO (TRY & CATCH)
// =========================================================================
// El operador binario '!' combina un Error Set con un Tipo normal para crear
// un "Error Union Type" (ejemplo: Error!i32).
// Para desenvolver este tipo, usamos los operadores 'try' y 'catch'.

const ErroresDeMatematicas = error{
    DivisionPorCero,
    ResultadoNegativo,
};

fn dividir(numerador: i32, denominador: i32) ErroresDeMatematicas!i32 {
    if (denominador == 0) return error.DivisionPorCero;
    if (numerador < 0 or denominador < 0) return error.ResultadoNegativo;
    return @divTrunc(numerador, denominador);
}

fn modulo2ErrorUnions(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Error Unions, try y catch\n", .{});

    // Uso de 'try': Si la funcion retorna un error, se propaga inmediatamente
    // hacia afuera del bloque actual. Si tiene exito, devuelve el payload.
    const valor1 = try dividir(10, 2);
    try stdout.print("  [try] 10 / 2 es: {d}\n", .{valor1});

    // Uso de 'catch' con valor por defecto:
    // Si la operacion falla, se asigna el valor por defecto provisto (999).
    const valor_seguro = dividir(10, 0) catch 999;
    try stdout.print("  [catch] 10 / 0 provoco un error, valor por defecto: {d}\n", .{valor_seguro});

    // Para retornar un valor desde un bloque 'catch' multilineal, el bloque
    // DEBE ser etiquetado formalmente (ej. 'blk:'). Posteriormente, usamos
    // 'break :blk' para retornar el valor de forma segura.
    const valor_complejo = dividir(-5, 1) catch |err| blk: {
        try stdout.print("    [Info] Capturado error '{any}' dentro del bloque catch\n", .{err});
        // Realizamos logica personalizada y proveemos un valor de recuperacion
        break :blk -1;
    };
    try stdout.print("  [catch Block] Resultado de la recuperacion: {d}\n\n", .{valor_complejo});
}

// =========================================================================
// MODULO 3: CONTROL DE FLUJO AVANZADO (IF / SWITCH CON CAPTURAS)
// =========================================================================
// En entornos robustos, necesitas reaccionar de manera especifica a cada
// tipo de error. Para ello, combinamos 'if' con bloques de captura y 'switch'.

const ErroresDeParser = error{
    TokenInvalido,
    FinDeArchivoInesperado,
    DesbordamientoDeEntero,
};

fn parsearNumero(texto: []const u8) ErroresDeParser!u32 {
    if (texto.len == 0) return error.FinDeArchivoInesperado;

    var acumulado: u32 = 0;
    for (texto) |caracter| {
        if (caracter < '0' or caracter > '9') return error.TokenInvalido;

        // Verificamos desbordamiento usando built-ins seguros de Zig
        const ov = @mulWithOverflow(acumulado, 10);
        if (ov[1] != 0) return error.DesbordamientoDeEntero;

        const digito = caracter - '0';
        const ov_suma = @addWithOverflow(ov[0], digito);
        if (ov_suma[1] != 0) return error.DesbordamientoDeEntero;

        acumulado = ov_suma[0];
    }
    return acumulado;
}

fn modulo3FlujoAvanzado(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Control de Flujo con Capturas (if/switch)\n", .{});

    const muestras = [_][]const u8{ "12345", "999999999999", "abc" };

    for (muestras) |muestra| {
        // La sintaxis 'if (expresion) |payload|' extrae el valor exitoso.
        // El bloque 'else |err|' captura el error para su analisis detallado.
        if (parsearNumero(muestra)) |numero| {
            try stdout.print("  Muestra '{s}' parseada correctamente: {d}\n", .{ muestra, numero });
        } else |err| switch (err) {
            error.FinDeArchivoInesperado => {
                try stdout.print("  Fallo '{s}': El string de entrada estaba vacio.\n", .{muestra});
            },
            error.DesbordamientoDeEntero => {
                try stdout.print("  Fallo '{s}': El numero es demasiado grande para un u32.\n", .{muestra});
            },
            error.TokenInvalido => {
                try stdout.print("  Fallo '{s}': Contiene caracteres no numericos.\n", .{muestra});
            },
        }
    }
    try stdout.print("\n", .{});
}

// =========================================================================
// MODULO 4: LIBERA RECURSOS DE FORMA SEGURA (ERRDEFER Y CAPTURA)
// =========================================================================
// Mientras que 'defer' se ejecuta SIEMPRE al salir del scope del bloque actual,
// 'errdefer' se ejecuta UNICAMENTE si la funcion sale retornando un error.
// Esto es indispensable para revertir asignaciones parciales de memoria o sockets.

const ErroresDeRecurso = error{
    FalloDeAsignacion,
    PermisoDenegado,
};

var base_de_datos_mock_conectada: bool = false;

fn conectarBaseDeDatos(falla_al_final: bool, stdout: anytype) ErroresDeRecurso!void {
    base_de_datos_mock_conectada = true;

    if (!base_de_datos_mock_conectada) {
        return error.FalloDeAsignacion;
    }

    // Si la transaccion falla mas adelante, debemos desconectarnos para no dejar hilos abiertos
    errdefer {
        base_de_datos_mock_conectada = false;
    }

    // Solucion a error 'error set is discarded': Consumimos el error capturado
    // imprimiendolo en consola en lugar de descartarlo con un identificador vacio.
    errdefer |err| {
        stdout.print("    [errdefer Telemetria] Database rollback activado por error: {any}\n", .{err}) catch {};
    }

    if (falla_al_final) {
        return error.PermisoDenegado;
    }
}

fn modulo4Errdefer(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Uso robusto de errdefer\n", .{});

    // Caso 1: Todo tiene exito. El errdefer no se dispara, mantenemos la conexion.
    try conectarBaseDeDatos(false, stdout);
    try stdout.print("  Conexion 1 (Exito) -> Base de datos conectada: {}\n", .{base_de_datos_mock_conectada});

    // Caso 2: Ocurre un fallo. El errdefer entra en accion y revierte el estado de forma automatica.
    conectarBaseDeDatos(true, stdout) catch {};
    try stdout.print("  Conexion 2 (Fallo) -> Base de datos conectada: {}\n\n", .{base_de_datos_mock_conectada});
}

// =========================================================================
// MODULO 5: OPERADOR DE MEZCLA (||) Y ERROR SETS INFERIDOS
// =========================================================================
// Zig permite fusionar Error Sets usando el operador binario de suma de conjuntos '||'.
// Asimismo, permite omitir la declaracion del Error Set escribiendo simplemente
// '!T' como retorno, haciendo que el compilador infiera todos los errores posibles.

const ErroresDeDisco = error{
    DiscoLleno,
    SectorDanado,
};

const ErroresDeArchivo = error{
    ArchivoNoEncontrado,
};

// Fusionamos los dos sets en un nuevo tipo de error unificado en tiempo de compilacion
const ErroresDeIO = ErroresDeDisco || ErroresDeArchivo;

fn guardarArchivoSimulado(disco_lleno: bool) ErroresDeIO!void {
    if (disco_lleno) return error.DiscoLleno;
    return error.ArchivoNoEncontrado;
}

// Funcion con retorno de error inferido ('!void'). El compilador analiza todo el arbol
// de llamadas estaticas para generar de forma exacta la lista de errores que pueden salir de aqui.
fn operacionInferida(opcion: u2) !void {
    if (opcion == 0) return error.EntradaInvalida;
    if (opcion == 1) return error.DispositivoBloqueado;
}

fn modulo5MezclaEInferencia(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Mezcla de Error Sets (||) y Errores Inferidos\n", .{});

    // Probamos la funcion que mezcla dos conjuntos de errores diferentes
    if (guardarArchivoSimulado(true)) |_| {} else |err| {
        try stdout.print("  [Mezcla] Capturado error mixto: {any}\n", .{err});
    }

    // Probamos la funcion con inferencia de tipos
    if (operacionInferida(1)) |_| {} else |err| {
        try stdout.print("  [Inferencia] Capturado error de firma dinamica: {any}\n\n", .{err});
    }
}

// =========================================================================
// MODULO 6: ANATOMIA DE UN ERROR RETURN TRACE (COMO FUNCIONA LA MAGIA)
// =========================================================================
// Zig no genera excepciones pesadas como C++ o JVM, ni realiza analisis
// dinamico costoso en tiempo de ejecucion en el camino feliz (cuando no hay errores).
//
// COSTO DEL CAMINO FELIZ (Cero Overhead):
// 1. Cuando llamas a una funcion failable, Zig reserva espacio en la pila para la
//    siguiente estructura estatica invisible:
//
//    const StackTrace = struct {
//        index: usize,
//        instruction_addresses: [N]usize,
//    };
//
// 2. N es calculado estaticamente en el grafo de llamadas compilado. No hay reserva dinamica.
// 3. Un puntero a esta estructura se pasa de manera transparente como el primer
//    argumento en los registros de CPU de la funcion.
// 4. Si la ejecucion es exitosa, solo cuesta una escritura basica de inicializacion.
//
// COSTO DE LA RUTA DE ERROR:
// Cuando una funcion ejecuta explicitamente un return de un error, Zig inyecta una
// llamada no enlineable (no-inline) a una subrutina del compilador:
//
//    fn __zig_return_error(stack_trace: *StackTrace) void {
//        stack_trace.instruction_addresses[stack_trace.index] = @returnAddress();
//        stack_trace.index = (stack_trace.index + 1) % N;
//    }
//
// Esto almacena la direccion de retorno exacta en la tabla de ejecucion, logrando
// el rastreo impecable sin la necesidad de desenrollar la pila (stack unwinding).

fn modulo6BajoNivel(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: Bajo Nivel (Optimizacion de CPU)\n", .{});
    try stdout.print("  [Info] Los Error Return Traces estan activos en compilaciones de Debug.\n", .{});
    try stdout.print("  [Info] En ReleaseFast/ReleaseSmall se desactivan, eliminando todo overhead.\n", .{});
    try stdout.print("  [Info] Estructura StackTrace mapeada estaticamente en la pila de ejecucion.\n\n", .{});
}

// =========================================================================
// MODULO 7: PROYECTO PRACTICO: SISTEMA DE PROCESAMIENTO DE PAGOS
// =========================================================================
// Implementacion integral de un procesador de transacciones simulado que
// aplica todos los conocimientos aprendidos en la masterclass.

const ErrorDeValidacion = error{
    TarjetaExpirada,
    MontoInvalido,
    FormatoDeMonedaInvalido,
};

const ErrorDePasarela = error{
    FondosInsuficientes,
    FalloDeComunicacion,
    FrailInminente,
};

const ErrorDeProcesamiento = ErrorDeValidacion || ErrorDePasarela;

const Transaccion = struct {
    id: u32,
    monto_usd: f32,
    numero_tarjeta: []const u8,
    es_valida: bool,
};

// Funcion con flujo real de verificacion y emision de errores
fn verificarTarjeta(tarjeta: []const u8) ErrorDeValidacion!void {
    if (tarjeta.len != 16) {
        return error.TarjetaExpirada;
    }

    for (tarjeta) |char| {
        if (char < '0' or char > '9') {
            return error.FormatoDeMonedaInvalido;
        }
    }
}

fn autorizarMonto(monto: f32) ErrorDePasarela!void {
    if (monto <= 0.0) return error.FrailInminente;
    if (monto > 5000.0) return error.FondosInsuficientes;
}

// Coordinador principal del pipeline de pagos
fn procesarTransaccion(tx: Transaccion, stdout: anytype) ErrorDeProcesamiento!void {
    // 1. Iniciamos logica y establecemos reversiones automaticas ante errores
    try verificarTarjeta(tx.numero_tarjeta);

    // Solucion a error 'error set is discarded': Consumimos el error de la
    // pasarela guardando un registro inmediato en las metricas/logs de consola.
    errdefer |err| {
        stdout.print("    [errdefer Telemetria] Fallo de pasarela en transaccion {d}: {any}\n", .{ tx.id, err }) catch {};
    }

    try autorizarMonto(tx.monto_usd);
}

fn modulo7ProyectoPagos(stdout: anytype) !void {
    try stdout.print(">> Modulo 7: Proyecto - Procesador de Pagos Financiero\n", .{});

    const listado_de_transacciones = [_]Transaccion{
        .{ .id = 101, .monto_usd = 250.50, .numero_tarjeta = "4000123456789010", .es_valida = true },
        .{ .id = 102, .monto_usd = 9999.00, .numero_tarjeta = "4000123456789010", .es_valida = false }, // Falla por Fondos
        .{ .id = 103, .monto_usd = 15.00, .numero_tarjeta = "TARJETA_ROTA_999", .es_valida = false }, // Falla por Validacion
    };

    for (listado_de_transacciones) |tx| {
        try stdout.print("    Procesando Transaccion {d}... ", .{tx.id});

        if (procesarTransaccion(tx, stdout)) |_| {
            try stdout.print("[OK] Transaccion procesada y capturada con exito.\n", .{});
        } else |err| switch (err) {
            error.TarjetaExpirada => {
                try stdout.print("[RECHAZADA] Tarjeta Expirada o digitos insuficientes.\n", .{});
            },
            error.FormatoDeMonedaInvalido => {
                try stdout.print("[RECHAZADA] Caracteres no numericos detectados.\n", .{});
            },
            error.FondosInsuficientes => {
                try stdout.print("[RECHAZADA] Fondos Insuficientes para transaccion de alto valor.\n", .{});
            },
            error.MontoInvalido, error.FrailInminente => {
                try stdout.print("[BLOQUEADA] Intento de cargo ilegal o inconsistente.\n", .{});
            },
            error.FalloDeComunicacion => {
                try stdout.print("[REINTENTAR] Error de conexion con el banco central.\n", .{});
            },
        }
    }
}
