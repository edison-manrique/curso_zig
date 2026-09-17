// =========================================================================
// MASTERCLASS: COMPTIME Y METAPROGRAMACION EN ZIG (EDICION 0.16.0)
// =========================================================================
// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.
//
// TABLA DE CONTENIDO:
// Modulo 1: Concepto de Comptime (Genericos y Duck Typing)
// Modulo 2: Variables Comptime y Lazos Inlined (Evaluacion Parcial)
// Modulo 3: Expresiones Comptime y Seguridad de Recursion (Branch Quota)
// Modulo 4: Evaluacion a Nivel de Contenedor (Static Lookup Tables)
// Modulo 5: Estructuras de Datos Genericas (Monomorfizacion)
// Modulo 6: Caso de Estudio: Motor de Formateo Estatico y Compile Errors
// =========================================================================

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Inicializamos buffer de escritura optimizado para la terminal
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try stdout.print("====================================================\n", .{});
    try stdout.print("       MASTERCLASS: COMPTIME EN ZIG 0.16.0          \n", .{});
    try stdout.print("====================================================\n\n", .{});

    try modulo1Genericos(stdout);
    try modulo2Inlining(stdout);
    try modulo3Recursion(stdout);
    try modulo4ContainerComptime(stdout);
    try modulo5EstructurasGenericas(stdout);
    try modulo6FormatParser(stdout);

    try stdout.print("\n====================================================\n", .{});
    try stdout.print("     FIN DE LA MASTERCLASS - PROCESADO CON EXITO     \n", .{});
    try stdout.print("====================================================\n", .{});
}

// =========================================================================
// MODULO 1: CONCEPTO DE COMPTIME (GENERICOS Y DUCK TYPING)
// =========================================================================
// En Zig, los tipos son ciudadanos de primera clase. Pueden asignarse a
// variables y pasarse como parametros de funcion, siempre y cuando se
// procesen en tiempo de compilacion (comptime).

// Esta funcion recibe un tipo 'T' y dos valores de ese tipo.
// Como 'T' es de tipo 'type', debe marcarse obligatoriamente como 'comptime'.
fn obtenerMayor(comptime T: type, a: T, b: T) T {
    // Si pasamos un tipo que no soporta el operador '>', el compilador
    // arrojara un error estatico al analizar la especializacion de la funcion.
    return if (a > b) a else b;
}

// Sobrecarga condicional en tiempo de compilacion:
// Podemos usar condicionales 'if' evaluados en comptime para alterar la
// firma y comportamiento de la funcion segun el tipo recibido.
fn obtenerMayorSeguro(comptime T: type, a: T, b: T) T {
    if (T == bool) {
        // El operador '>' no aplica para booleanos. Redefinimos la logica:
        return a or b;
    } else {
        return if (a > b) a else b;
    }
}

fn modulo1Genericos(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Genericos y Duck Typing Estatico\n", .{});

    const mayor_entero = obtenerMayor(i32, 15, 42);
    try stdout.print("  Mayor entero (i32): {d}\n", .{mayor_entero});

    const mayor_flotante = obtenerMayor(f32, 3.14, 1.59);
    try stdout.print("  Mayor flotante (f32): {d:.2}\n", .{mayor_flotante});

    // Probamos la sobrecarga condicional comptime para booleanos
    const union_bool = obtenerMayorSeguro(bool, false, true);
    try stdout.print("  Resultado logico condicional (bool): {}\n\n", .{union_bool});
}

// =========================================================================
// MODULO 2: VARIABLES COMPTIME Y LAZOS INLINED (EVALUACION PARCIAL)
// =========================================================================
// Al marcar una variable local como 'comptime var', le garantizamos al
// compilador que cada lectura y escritura sobre ella se realizara en tiempo
// de compilacion.
// Esto, combinado con 'inline while' o 'inline for', desenrolla los bucles y
// pre-calcula los valores en el binario final.

const Comando = struct {
    nombre: []const u8,
    codigo: u8,
};

const LISTA_COMANDOS = [_]Comando{
    Comando{ .nombre = "iniciar", .codigo = 10 },
    Comando{ .nombre = "detener", .codigo = 20 },
    Comando{ .nombre = "pausar", .codigo = 30 },
};

// Esta funcion realiza una busqueda inlined. El bucle se expande en tiempo de
// compilacion, generando llamadas directas y optimizadas segun el parametro.
fn buscarCodigoComando(comptime nombre: []const u8) u8 {
    comptime var i: usize = 0;
    // 'inline while' obliga al compilador a expandir el lazo estaticamente
    inline while (i < LISTA_COMANDOS.len) : (i += 1) {
        if (std.mem.eql(u8, LISTA_COMANDOS[i].nombre, nombre)) {
            return LISTA_COMANDOS[i].codigo;
        }
    }
    return 0;
}

fn modulo2Inlining(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Variables Comptime e Inlining de Lazos\n", .{});

    // En el binario final generado por LLVM, no habra bucle 'while'.
    // La funcion 'buscarCodigoComando(\"detener\")' se optimiza y se reduce
    // directamente al retorno constante del valor '20'.
    const codigo = buscarCodigoComando("detener");
    try stdout.print("  Codigo de comando 'detener' (pre-calculado): {d}\n\n", .{codigo});
}

// =========================================================================
// MODULO 3: EXPRESIONES COMPTIME Y SEGURIDAD DE RECURSION (BRANCH QUOTA)
// =========================================================================
// Un bloque 'comptime { ... }' fuerza la evaluacion estatica de todo su
// contenido. Si alguna operacion posee efectos secundarios en tiempo de ejecucion
// (como llamar funciones del sistema operativo o funciones externas 'extern'),
// el compilador genera un error inmediatamente.

fn calcularFibonacci(index: u32) u32 {
    if (index < 2) return index;
    return calcularFibonacci(index - 1) + calcularFibonacci(index - 2);
}

fn modulo3Recursion(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Bloques Comptime y Branch Quota\n", .{});

    // El compilador posee un limite interno (por defecto 1000 iteraciones)
    // para evitar que bucles infinitos congelen la compilacion.
    // Con '@setEvalBranchQuota' incrementamos este limite para algoritmos pesados.
    comptime {
        @setEvalBranchQuota(5000);
    }

    // Calculamos Fibonacci en tiempo de compilacion
    const fib_estatico = comptime calcularFibonacci(12);

    // Calculamos Fibonacci en tiempo de ejecucion (mismo codigo de funcion)
    const fib_dinamico = calcularFibonacci(12);

    try stdout.print("  Fibonacci(12) calculado en Comptime: {d}\n", .{fib_estatico});
    try stdout.print("  Fibonacci(12) calculado en Runtime : {d}\n\n", .{fib_dinamico});
}

// =========================================================================
// MODULO 4: EVALUACION A NIVEL DE CONTENEDOR (STATIC LOOKUP TABLES)
// =========================================================================
// Todas las variables globales (a nivel de contenedor/modulo) que son inicializadas
// mediante llamadas a funciones se evaluan implicitamente en tiempo de compilacion.
// Esto es ideal para generar tablas de busqueda de alta performance (Lookup Tables).

// Generamos un arreglo estatico de los primeros 10 numeros impares en tiempo de compilacion
const TABLA_IMPARES = generarNumerosImpares(10);

fn generarNumerosImpares(comptime limite: usize) [limite]u32 {
    var resultado: [limite]u32 = undefined;
    var index: usize = 0;
    var numero: u32 = 1;
    while (index < limite) {
        resultado[index] = numero;
        numero += 2;
        index += 1;
    }
    return resultado;
}

fn modulo4ContainerComptime(stdout: anytype) !void {
    try stdout.print(">> Modulo 4: Evaluacion Estatica a Nivel de Contenedor\n", .{});
    try stdout.print("  Tabla de impares pre-computada en el binario: ", .{});

    for (TABLA_IMPARES) |valor| {
        try stdout.print("{d} ", .{valor});
    }
    try stdout.print("\n\n", .{});
}

// =========================================================================
// MODULO 5: ESTRUCTURAS DE DATOS GENERICAS (MONOMORFIZACION)
// =========================================================================
// Zig no necesita sintaxis especial para plantillas/genericos. Una estructura
// generica es simplemente una funcion evaluada en comptime que retorna un
// nuevo tipo de estructura anonima.

fn ContenedorGenerico(comptime T: type) type {
    return struct {
        // CORRECCION SINTACTICA:
        // Los builtins de Zig que retornan tipos deben capitalizarse.
        // Se reemplaza '@this()' por el builtin correcto: '@This()'
        const Self = @This();

        valor: T,

        pub fn inicializar(v: T) Self {
            return Self{ .valor = v };
        }

        pub fn obtenerTipoNombre(self: *const Self) []const u8 {
            _ = self;
            return @typeName(T);
        }
    };
}

fn modulo5EstructurasGenericas(stdout: anytype) !void {
    try stdout.print(">> Modulo 5: Estructuras Genericas Dinamicas\n", .{});

    // Instanciamos el contenedor especializado para enteros de 64 bits
    const ContenedorDeEnteros = ContenedorGenerico(i64);
    const instancia_int = ContenedorDeEnteros.inicializar(-987654321);

    // Instanciamos el contenedor especializado para buffers de bytes de solo lectura
    const ContenedorDeTexto = ContenedorGenerico([]const u8);
    const instancia_txt = ContenedorDeTexto.inicializar("Zig Lang 0.16.0");

    try stdout.print("  Instancia 1 -> Tipo Interno: {s}, Valor: {d}\n", .{
        instancia_int.obtenerTipoNombre(),
        instancia_int.valor,
    });

    try stdout.print("  Instancia 2 -> Tipo Interno: {s}, Valor: {s}\n\n", .{
        instancia_txt.obtenerTipoNombre(),
        instancia_txt.valor,
    });
}

// =========================================================================
// MODULO 6: CASO DE ESTUDIO: MOTOR DE FORMATEO ESTATICO Y COMPILE ERRORS
// =========================================================================
// Implementacion didactica de un analizador de cadenas de formato a bajo nivel.
// Valida en tiempo de compilacion que el numero de argumentos coincida de
// manera exacta con las llaves de formato '{}'. De lo contrario, interrumpe
// la compilacion usando la funcion builtin '@compileError'.

const MiniLogger = struct {
    pub fn logear(comptime formato: []const u8, argumentos: anytype) void {
        comptime {
            var cantidad_llaves: usize = 0;
            var i: usize = 0;

            // Analizamos el formato caracter por caracter
            while (i < formato.len) : (i += 1) {
                if (formato[i] == '{') {
                    if (i + 1 < formato.len and formato[i + 1] == '}') {
                        cantidad_llaves += 1;
                        i += 1; // Saltamos la llave de cierre '}'
                    }
                }
            }

            const tipo_args = @TypeOf(argumentos);
            const info_args = @typeInfo(tipo_args);

            // Al ser 'struct' una palabra clave, es mandatorio escapar el literal
            // de comparacion de la union utilizando la sintaxis de escape: .@"struct"
            if (info_args != .@"struct" or !info_args.@"struct".is_tuple) {
                @compileError("Los argumentos deben ser pasados como una tupla estructurada (usando '.{ ... }')");
            }

            const cantidad_args = info_args.@"struct".fields.len;

            // Validacion de seguridad estatica
            if (cantidad_llaves < cantidad_args) {
                @compileError("Error de Compilacion: Argumentos sobrantes provistos en la tupla de logeo.");
            }
            if (cantidad_llaves > cantidad_args) {
                @compileError("Error de Compilacion: Faltan argumentos para cubrir todas las llaves '{}' de formato.");
            }
        }
    }
};

fn modulo6FormatParser(stdout: anytype) !void {
    try stdout.print(">> Modulo 6: Caso de Estudio - Parser de Formato Estatico\n", .{});

    // El siguiente codigo compila con exito porque la cadena tiene exactamente
    // dos llaves '{}' y la tupla contiene exactamente dos argumentos de entrada.
    MiniLogger.logear("Registro: ID {} - Estado: {}", .{ @as(u32, 501), "Activo" });
    try stdout.print("  [OK] Validacion estatica del formateador exitosa (Sin errores en tiempo de diseno).\n", .{});

    // NOTA DE CONTROL DE CALIDAD:
    // Si descomentas cualquiera de las siguientes lineas de codigo, el programa
    // fallara inmediatamente al intentar compilar:
    //
    // MiniLogger.logear("Registro: ID {} - Estado: {}", .{ 501 }); // Error: Faltan argumentos
    // MiniLogger.logear("Registro: ID {}", .{ 501, "Activo" });    // Error: Argumentos sobrantes
}
