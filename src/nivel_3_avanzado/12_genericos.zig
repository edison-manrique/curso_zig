// =========================================================================
// MASTERCLASS: GENERICOS Y METAPROGRAMACION (EDICION ZIG 0.16.0)
// =========================================================================
// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.

// Rust implementa genericos utilizando firmas de tipos complejas, rasgos (Traits)
// y monomorfizacion tras bambalinas.

// Zig simplifica esto al extremo usando el super poder de 'comptime':
// 1. En Zig, los tipos son valores de primera clase que se pueden pasar a funciones
//    en tiempo de compilacion.
// 2. Un tipo generico es simplemente una funcion ordinaria que acepta un tipo
//    'comptime T: type' y retorna un nuevo tipo ('type').
// 3. Funciones genericas se definen pidiendo parametros 'comptime T: type'
//    o usando el tipo inferido 'anytype'.

// CONCEPTOS CLAVE:
// 1. Funciones Genericas con Comptime.
// 2. Estructuras Genericas: Creando una estructura 'Pila(T)' (Stack) dinamica.
// 3. Restricciones e Inferencia de tipos con '@TypeOf' y '@typeInfo'.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Inicializamos buffer de escritura de alta performance para stdout
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Liberamos el flujo de salida al finalizar el programa
    defer stdout.flush() catch {};

    // Inicializamos el Arena Allocator para la gestion de memoria del programa
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try stdout.print("--- INICIO DE LA MASTERCLASS DE GENERICOS IN ZIG ---\n\n", .{});

    try modulo1FuncionesGenericas(stdout);
    try modulo2EstructurasGenericas(allocator, stdout);

    try stdout.print("--- FIN DE LA MASTERCLASS DE GENERICOS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: FUNCIONES GENERICAS
// -------------------------------------------------------------------------
// Para definir una funcion generica en Zig, pedimos el tipo en tiempo de
// compilacion y lo usamos en la firma de tipos de ejecucion.
fn duplicarValor(comptime T: type, valor: T) T {
    // El compilador verificara en tiempo de compilacion si el tipo soporta el operador '+'
    return valor + valor;
}

fn modulo1FuncionesGenericas(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Funciones Genericas con Comptime\n", .{});

    const entero_duplicado = duplicarValor(i32, 10);
    const decimal_duplicado = duplicarValor(f64, 3.14);

    try stdout.print("  i32 Duplicado: {d} | f64 Duplicado: {d:.2}\n\n", .{ entero_duplicado, decimal_duplicado });
}

// -------------------------------------------------------------------------
// MODULO 2: ESTRUCTURAS GENERICAS (El patron de fabrica de tipos)
// -------------------------------------------------------------------------
// En Zig 0.16.0, std.ArrayList(T) es una estructura de datos no gestionada
// (unmanaged) que requiere que le proveamos el Allocator en cada operacion.
// Creamos una envoltura "Pila(T)" que almacena el Allocator para simplificar su uso.
fn Pila(comptime T: type) type {
    return struct {
        items: std.ArrayList(T),
        allocator: std.mem.Allocator,

        const Self = @This(); // Retorna el tipo de la estructura instanciada

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                // CORRECCION SINTACTICA ZIG 0.16.0:
                // Al no tener valores por defecto, inicializamos explicitamente la lista vacia.
                .items = .{ .items = &.{}, .capacity = 0 },
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            // Pasamos de forma explicita el allocator para liberar la memoria de la lista
            self.items.deinit(self.allocator);
        }

        pub fn push(self: *Self, item: T) !void {
            // Pasamos el allocator para permitir el crecimiento dinamico del arreglo
            try self.items.append(self.allocator, item);
        }

        pub fn pop(self: *Self) ?T {
            // CORRECCION ZIG 0.16.0:
            // El metodo correcto es '.pop()', el cual devuelve un tipo opcional '?T'
            return self.items.pop();
        }

        pub fn len(self: *const Self) usize {
            return self.items.items.len;
        }
    };
}

fn modulo2EstructurasGenericas(allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Estructuras Genericas (Pila(T))\n", .{});

    // Instanciamos el tipo generico con i32
    var pila_enteros = Pila(i32).init(allocator);
    defer pila_enteros.deinit();

    try pila_enteros.push(100);
    try pila_enteros.push(200);

    // Instanciamos el tipo generico con strings
    var pila_cadenas = Pila([]const u8).init(allocator);
    defer pila_cadenas.deinit();

    try pila_cadenas.push("Hola");
    try pila_cadenas.push("Mundo");

    // Extraemos los valores para presentacion
    const len_enteros_antes = pila_enteros.len();
    const entero_recuperado = pila_enteros.pop();

    const len_cadenas_antes = pila_cadenas.len();
    const cadena_recuperada = pila_cadenas.pop();

    // Mostrar resultados directamente mediante el formateador nativo del escritor
    try stdout.print("  Pila(i32) len: {d} | Pop: {any}\n", .{ len_enteros_antes, entero_recuperado });
    try stdout.print("  Pila([]const u8) len: {d} | Pop: {any}\n\n", .{ len_cadenas_antes, cadena_recuperada });
}
