// =========================================================================
// MASTERCLASS: ITERADORES PERSONALIZADOS (EDICION ZIG 0.16.0)
// =========================================================================
// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.

// En Rust, creas iteradores implementando el rasgo 'Iterator' con su metodo 'next()'.

// En Zig, al no haber interfaces formales en el compilador, usamos una convencion
// estandar adoptada por toda la libreria estandar (como 'std.mem.SplitIterator'):
// 1. Definimos una estructura que almacena el estado de la iteracion.
// 2. Implementamos una funcion 'next(self: *Self) ?T' en dicha estructura.
// 3. Si hay mas elementos, retorna el valor envuelto en opcional ('T').
// 4. Si la iteracion termina, retorna 'null'.

// CONCEPTOS CLAVE:
// 1. El patron de diseno de Iteradores en Zig.
// 2. Implementacion de un Iterador de Fibonacci (FibonacciIterator).
// 3. Implementacion de un Iterador de Tokenizacion de Textos (SplitIterator).

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Inicializamos buffer de escritura de alta performance para stdout
    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    // Liberamos el flujo de salida al finalizar el programa
    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE ITERADORES IN ZIG ---\n\n", .{});

    try modulo1FibonacciIterator(stdout);
    try modulo2SplitIterator(stdout);

    try stdout.print("--- FIN DE LA MASTERCLASS DE ITERADORES ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: ITERADOR DE LA SECUENCIA DE FIBONACCI
// -------------------------------------------------------------------------
const FibonacciIterator = struct {
    limite: u32,
    actual: u32 = 0,
    siguiente: u32 = 1,
    contador: u32 = 0,

    const Self = @This();

    pub fn init(limite: u32) Self {
        return .{ .limite = limite };
    }

    // Metodo next que retorna un opcional '?u32'
    pub fn next(self: *Self) ?u32 {
        if (self.contador >= self.limite) return null;

        const resultado = self.actual;
        const nuevo_sig = self.actual + self.siguiente;

        self.actual = self.siguiente;
        self.siguiente = nuevo_sig;
        self.contador += 1;

        return resultado;
    }
};

fn modulo1FibonacciIterator(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Iterador de Fibonacci\n", .{});

    var fib = FibonacciIterator.init(10); // Generara los primeros 10 numeros

    try stdout.print("  Secuencia: ", .{});

    // El control de flujo 'while' en desempaqueta de manera nativa los opcionales '?T'
    while (fib.next()) |num| {
        try stdout.print("{d} ", .{num});
    }
    try stdout.print("\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 2: ITERADOR DE DIVISIONES (SPLIT ITERATOR)
// -------------------------------------------------------------------------
// Implementamos un iterador personalizado que divide una cadena de texto
// por un caracter delimitador (espacio, coma, etc.) sin hacer copias ni usar Heap.
const DelimiterIterator = struct {
    buffer: []const u8,
    index: usize = 0,
    delimitador: u8,

    const Self = @This();

    pub fn init(buffer: []const u8, delimitador: u8) Self {
        return .{
            .buffer = buffer,
            .delimitador = delimitador,
        };
    }

    pub fn next(self: *Self) ?[]const u8 {
        const buf_len = self.buffer.len;
        if (self.index >= buf_len) return null;

        const inicio = self.index;

        // Buscamos la posicion del delimitador
        var fin = inicio;
        while (fin < buf_len) : (fin += 1) {
            if (self.buffer[fin] == self.delimitador) {
                self.index = fin + 1; // Avanzamos el cursor de lectura
                return self.buffer[inicio..fin]; // Retorna el sub-slice sin copias en Heap
            }
        }

        self.index = buf_len; // Llegamos al final de la cadena
        return self.buffer[inicio..buf_len];
    }
};

fn modulo2SplitIterator(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Delimiter Iterator (Tokenizador sin allocations)\n", .{});

    const texto = "Zig,Rust,C,C++,Assembly";
    var tokens = DelimiterIterator.init(texto, ',');

    // Iteramos e imprimimos directamente consumiendo el escritor de consola
    while (tokens.next()) |token| {
        try stdout.print("  Token extraido: {s}\n", .{token});
    }
    try stdout.print("\n", .{});
}
