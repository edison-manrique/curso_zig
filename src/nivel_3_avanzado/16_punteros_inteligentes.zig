// =========================================================================
//           MASTERCLASS: GESTION DE MEMORIA Y PUNTEROS INTELIGENTES
//                         EDICION ZIG 0.16.0
// =========================================================================
// Este documento ha sido disenado como una guia definitiva escrita por
// expertos en sistemas para dominar el control explicito de memoria en Zig.
//
// NOTA DE COMPATIBILIDAD: Todo el codigo, graficos ASCII y explicaciones
// estan limitados estrictamente a la codificacion ASCII de 7 bits (rango 0-127)
// para prevenir errores de compilacion y renderizado en consolas legadas.

// =========================================================================
// TABLA DE CONTENIDOS (TEMARIO)
// =========================================================================
// 1. INTRODUCCION: LA FILOSOFIA DE ZIG SOBRE LA MEMORIA
//    1.1 Por que Zig no tiene destructores automaticos (RAII)
//    1.2 El costo oculto del flujo de control invisible
//    1.3 El papel de "defer" y "errdefer" como primitivas de limpieza
//
// 2. DISENO DE "BOX" (PROPIEDAD UNICA EN EL HEAP)
//    2.1 Definicion de propiedad unica
//    2.2 Implementacion de un contenedor Unique(T) con seguridad estricta
//
// 3. REFLEXION COMPTIME PARA PREVENIR FUGAS ANIDADAS (DEEP LEAKS)
//    3.1 Que es una fuga anidada y por que ocurre
//    3.2 Metaprogramacion con @hasDecl para detectar destructores deinit()
//
// 4. CONCURRENCIA Y OPERACIONES ATOMICAS (EL EQUIVALENTE A ARC<T>)
//    4.1 Por que el incremento basico (ref_count += 1) falla en multihilo
//    4.2 Instrucciones atomicas de CPU en Zig: @atomicRmw and @atomicLoad
//
// 5. IMPLEMENTACION DEL CONTENEDOR SHARED(T) (THREAD-SAFE & LEAK-FREE)
//    5.1 Analisis linea por linea del codigo fuente
//    5.2 Mecanismo de nulidad y prevencion de Use-After-Free
//
// 6. CASOS DE ESTUDIO DEL MUNDO REAL
//    6.1 Caso 1: Sistema de Cache de Configuracion de Red Compartida
//    6.2 Caso 2: Manejo de Conexiones de Base de Datos con Buffers Dinamicos
//
// 7. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG

const std = @import("std");

// =========================================================================
// 1. INTRODUCCION: LA FILOSOFIA DE ZIG SOBRE LA MEMORIA
// =========================================================================
// En lenguajes como C++, Rust o Swift, los "punteros inteligentes" son
// automatizados por el compilador. Cuando una variable sale de su ambito de
// visibilidad (scope), el compilador inserta de forma invisible llamadas
// a destructores (como el trait 'Drop' en Rust).
//
// Zig rechaza esta filosofia basandose en un principio fundamental:
// "No debe haber flujo de control oculto ni asignaciones de memoria ocultas."
//
// Si una linea de codigo no muestra una llamada a una funcion de limpieza,
// esa limpieza no ocurre. Esto otorga al programador control absoluto sobre
// la latencia del sistema, el diseno de la pila (stack) y las llamadas al
// sistema operativo, algo crucial en sistemas embebidos, videojuegos y kernels.
//
// Para gestionar recursos, Zig introduce dos herramientas principales:
// - defer: Ejecuta una declaracion al salir del bloque actual de forma garantizada.
// - errdefer: Ejecuta una declaracion solo si la funcion retorna un error.

// =========================================================================
// 2. DISENO DE "BOX" (PROPIEDAD UNICA EN EL HEAP)
// =========================================================================
// El concepto de "Box" representa un valor que reside en la memoria dinamica
// (heap) pero que tiene un unico propietario. Al transferir este puntero,
// transferimos la obligacion de liberar la memoria.
//
// En Zig, implementamos esto mediante un struct "Unique(T)" que toma control
// exclusivo de un puntero y expone metodos explicitos de destruccion.

fn Unique(comptime T: type) type {
    return struct {
        ptr: *T,
        allocator: std.mem.Allocator,

        const Self = @This();

        /// Inicializa el valor en el Heap y toma su propiedad unica.
        pub fn init(allocator: std.mem.Allocator, value: T) !Self {
            const ptr = try allocator.create(T);
            errdefer allocator.destroy(ptr);
            ptr.* = value;
            return Self{
                .ptr = ptr,
                .allocator = allocator,
            };
        }

        /// Devuelve un puntero constante al valor.
        pub fn get(self: Self) *const T {
            return self.ptr;
        }

        /// Devuelve un puntero mutable al valor.
        pub fn getMut(self: Self) *T {
            return self.ptr;
        }

        /// Destruye el objeto y libera la memoria del Heap de forma explicita.
        pub fn deinit(self: *Self) void {
            // CORRECCION COMPTIME: Validamos si el tipo T es un tipo de contenedor
            // antes de utilizar la macro @hasDecl, evitando errores de compilacion en tipos primitivos.
            const info = @typeInfo(T);
            const can_have_deinit = switch (info) {
                .@"struct", .@"union", .@"enum", .@"opaque" => @hasDecl(T, "deinit"),
                else => false,
            };

            if (can_have_deinit) {
                self.ptr.deinit();
            }
            self.allocator.destroy(self.ptr);
            // Prevenimos accesos accidentales posteriores (Use-After-Free)
            self.ptr = undefined;
        }
    };
}

// =========================================================================
// 3. REFLEXION COMPTIME PARA PREVENIR FUGAS ANIDADAS (DEEP LEAKS)
// =========================================================================
// Imagine que guarda una estructura compleja dentro de un puntero inteligente,
// por ejemplo, un struct que contiene un arreglo dinamico de strings:
//
// const RecursoComplejo = struct {
//     nombres: [][]u8,
//     allocator: std.mem.Allocator,
// };
//
// Si simplemente liberamos la memoria de 'RecursoComplejo' usando
// allocator.destroy(ptr), el arreglo 'nombres' y sus strings individuales
// quedaran huerfanos en el heap, causando una fuga de memoria grave.
//
// Zig resuelve esto en tiempo de compilacion (comptime). Mediante la funcion
// integrada `@hasDecl(T, "deinit")`, inspeccionamos si el tipo de datos 'T'
// tiene un metodo de desinicializacion. Si existe, lo ejecutamos primero de
// forma automatica antes de destruir el nodo principal.

// =========================================================================
// 4. CONCURRENCIA Y OPERACIONES ATOMICAS (EL EQUIVALENTE A ARC<T>)
// =========================================================================
// Cuando multiples hilos de ejecucion (threads) comparten el mismo puntero,
// no podemos usar una simple adicion (`count += 1`) para rastrear las copias.
// Si dos hilos modifican el contador al mismo tiempo, se produce una
// condicion de carrera (Race Condition) que corrompe el conteo.
//
// Para evitar esto, utilizamos instrucciones atomicas del procesador.
// Estas instrucciones garantizan que la operacion de lectura-modificacion-escritura
// se realice en un solo ciclo ininterrumpido a nivel de hardware.
//
// En Zig 0.16.0, esto se logra mediante:
// - `@atomicRmw(T, ptr, op, val, ordering)`: Realiza una modificacion atomica.
// - `@atomicLoad(T, ptr, ordering)`: Lee un valor de forma sincronizada.
//
// El ordenamiento de memoria `.seq_cst` (Consistencia Secuencial) garantiza
// que todas las operaciones atomicas se observen en el mismo orden por todos
// los hilos, evitando optimizaciones peligrosas del compilador o de la CPU.

// =========================================================================
// 5. IMPLEMENTACION DEL CONTENEDOR SHARED(T) (THREAD-SAFE & LEAK-FREE)
// =========================================================================
// Esta es la implementacion robusta, profesional y segura para entornos de
// produccion concurrentes de un Shared Pointer en Zig 0.16.0.

pub fn Shared(comptime T: type) type {
    return struct {
        const Inner = struct {
            value: T,
            ref_count: usize,
            allocator: std.mem.Allocator,
        };

        // Puntero opcional al contenedor interno. Es opcional para permitir
        // su nulidad tras ejecutar la operacion de liberacion (release).
        inner: ?*Inner,

        const Self = @This();

        /// Inicializa el valor y establece el conteo de referencias inicial en 1.
        pub fn init(allocator: std.mem.Allocator, value: T) !Self {
            const inner = try allocator.create(Inner);
            errdefer allocator.destroy(inner);

            inner.* = .{
                .value = value,
                .ref_count = 1,
                .allocator = allocator,
            };

            return Self{ .inner = inner };
        }

        /// Incrementa el contador de referencias de forma atomica y segura.
        /// Devuelve un nuevo manejador del Shared Pointer.
        pub fn retain(self: Self) Self {
            const inner = self.inner orelse @panic("Intento de retener un Shared Pointer nulo");

            // Incrementamos de forma atomica el contador de referencias
            _ = @atomicRmw(usize, &inner.ref_count, .Add, 1, .seq_cst);

            return Self{ .inner = inner };
        }

        /// Decrementa de forma atomica el contador de referencias.
        /// Si el contador llega a cero, destruye los recursos anidados mediante
        //  comptime deinit, libera el nodo de control e invalida la referencia.
        pub fn release(self: *Self) void {
            const inner = self.inner orelse return; // Retorno inmediato si ya fue liberado

            // Decrementamos el contador y capturamos su valor previo
            const prev_count = @atomicRmw(usize, &inner.ref_count, .Sub, 1, .seq_cst);

            // Si el valor previo era 1, significa que ahora ha llegado a 0
            if (prev_count == 1) {
                const allocator = inner.allocator;

                // CORRECCION COMPTIME: Validamos si el tipo T es un tipo contenedor
                // antes de llamar a @hasDecl, evitando errores de compilacion con tipos basicos.
                const info = @typeInfo(T);
                const can_have_deinit = switch (info) {
                    .@"struct", .@"union", .@"enum", .@"opaque" => @hasDecl(T, "deinit"),
                    else => false,
                };

                if (can_have_deinit) {
                    inner.value.deinit();
                }

                // Destruye el contenedor principal en el heap
                allocator.destroy(inner);
            }

            // Mitigacion de Use-After-Free: Forzamos la nulidad del puntero local
            self.inner = null;
        }

        /// Acceso de solo lectura al valor interno.
        pub fn get(self: Self) *const T {
            const inner = self.inner orelse @panic("Intento de acceso a un Shared Pointer nulo");
            return &inner.value;
        }

        /// Acceso mutable al valor interno.
        pub fn getMut(self: Self) *T {
            const inner = self.inner orelse @panic("Intento de acceso a un Shared Pointer nulo");
            return &inner.value;
        }

        /// Devuelve el estado actual de referencias de forma atomica.
        pub fn getRefCount(self: Self) usize {
            const inner = self.inner orelse return 0;
            return @atomicLoad(usize, &inner.ref_count, .seq_cst);
        }
    };
}

// =========================================================================
// 6. CASOS DE ESTUDIO DEL MUNDO REAL
// =========================================================================

// -------------------------------------------------------------------------
// 6.1 CASO 1: SISTEMA DE CONFIGURACION DE RED COMPARTIDA
// -------------------------------------------------------------------------
// Un struct de configuracion que almacena parametros criticos del sistema.
// Varios modulos de red necesitan leer estos datos de forma concurrente sin
// duplicar la informacion en memoria.

const ConfiguracionRed = struct {
    ip_servidor: []const u8,
    puerto: u16,
    max_conexiones: u32,
    modo_seguro: bool,

    pub fn mostrar(self: *const @This(), name: []const u8, stdout: anytype) !void {
        try stdout.print("  [{s}] Conectando a {s}:{d} (Max: {d}, Seguro: {any})\n", .{
            name,
            self.ip_servidor,
            self.puerto,
            self.max_conexiones,
            self.modo_seguro,
        });
    }
};

// -------------------------------------------------------------------------
// 6.2 CASO 2: CONEXION DE BASE DE DATOS CON ALLOCATIONS INTERNAS
// -------------------------------------------------------------------------
// Un objeto complejo que maneja descriptores de archivos o buffers dinamicos.
// Este objeto asigna memoria en el heap en su inicializacion y requiere una
// liberacion explicita de sus recursos internos mediante su metodo 'deinit'.

const DatabaseConnection = struct {
    id_conexion: u32,
    query_buffer: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, id: u32, buffer_size: usize) !DatabaseConnection {
        const buf = try allocator.alloc(u8, buffer_size);
        errdefer allocator.free(buf);

        // Inicializamos el buffer con ceros
        @memset(buf, 0);

        return DatabaseConnection{
            .id_conexion = id,
            .query_buffer = buf,
            .allocator = allocator,
        };
    }

    /// Destructor explicito que sera detectado por la reflexion de Shared(T)
    pub fn deinit(self: *DatabaseConnection) void {
        self.allocator.free(self.query_buffer);
        self.query_buffer = &[_]u8{}; // Seguridad adicional
    }

    pub fn ejecutarQuery(self: *const DatabaseConnection, query: []const u8, stdout: anytype) !void {
        const len = if (query.len > self.query_buffer.len) self.query_buffer.len else query.len;
        @memcpy(self.query_buffer[0..len], query[0..len]);
        try stdout.print("  [DB-Connection-{d}] Query ejecutado: '{s}'\n", .{
            self.id_conexion,
            self.query_buffer[0..len],
        });
    }
};

// =========================================================================
// PUNTO DE ENTRADA: DEMOSTRACION Y COMPROBACION DE FUGAS
// =========================================================================

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try stdout.print("--- INICIO DE LA MASTERCLASS DE PUNTEROS INTELIGENTES ---\n\n", .{});

    // 1. Configuracion del DebugAllocator para desarrollo e integracion continua.
    // Al final del programa, gpa.deinit() analizara el heap y arrojara un error
    // explicito por consola si existe el mas minimo byte fugado.
    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const check_leak = gpa.deinit();
        if (check_leak == .leak) {
            std.debug.print("ERROR GRAVE: Se ha detectado una fuga de memoria dinamica!\n", .{});
        } else {
            std.debug.print("\n>>> AUDITORIA DE SEGURIDAD DE MEMORIA: 0 BYTES FUGADOS (EXITO) <<<\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // -------------------------------------------------------------------------
    // PRUEBA DE MODULO 1: EN ACCION EL CONTENEDOR UNIQUE(T) (BOX)
    // -------------------------------------------------------------------------
    try stdout.print(">> Iniciando Pruebas de Modulo 1: Unique(T) <<\n", .{});
    {
        var box_entero = try Unique(i32).init(allocator, 1024);
        // Garantizamos la desasignacion del entero en el scope local
        defer box_entero.deinit();

        try stdout.print("  [Unique-Box] Valor de entero en el Heap: {d}\n", .{box_entero.get().*});
        box_entero.getMut().* = 2048;
        try stdout.print("  [Unique-Box] Valor modificado en el Heap: {d}\n", .{box_entero.get().*});
    }
    try stdout.print("  [Unique-Box] Ambito cerrado y recursos destruidos de forma segura.\n\n", .{});

    // -------------------------------------------------------------------------
    // PRUEBA DE MODULO 2: CONFIGURACION DE RED COMPARTIDA (SHARED SIN DEINIT)
    // -------------------------------------------------------------------------
    try stdout.print(">> Iniciando Pruebas de Modulo 2: Shared(T) sin Deinit Interno <<\n", .{});
    {
        const config_estatica = ConfiguracionRed{
            .ip_servidor = "192.168.1.100",
            .puerto = 8080,
            .max_conexiones = 5000,
            .modo_seguro = true,
        };

        // Creamos la referencia compartida inicial (RefCount = 1)
        var shared_config = try Shared(ConfiguracionRed).init(allocator, config_estatica);
        defer shared_config.release();

        try stdout.print("  [Red] Shared configuracion creado. Referencias activas: {d}\n", .{shared_config.getRefCount()});

        // Simulamos la retencion de referencias por parte de dos modulos de software independientes
        var modulo_http = shared_config.retain();
        defer modulo_http.release();

        var modulo_websocket = shared_config.retain();
        defer modulo_websocket.release();

        try stdout.print("  [Red] Modulos retenidos. Referencias activas totales: {d}\n", .{shared_config.getRefCount()});

        // Ambos modulos leen el mismo mapa de memoria compartida sin duplicaciones
        try modulo_http.get().mostrar("Modulo-HTTP", stdout);
        try modulo_websocket.get().mostrar("Modulo-Websocket", stdout);
    }
    try stdout.print("  [Red] Todos los modulos salieron de su ambito de ejecucion de forma limpia.\n\n", .{});

    // -------------------------------------------------------------------------
    // PRUEBA DE MODULO 3: BASE DE DATOS COMPARTIDA (SHARED CON DEINIT COMPTIME)
    // -------------------------------------------------------------------------
    // Esta prueba demuestra la verdadera potencia del diseno: la base de datos
    // tiene buffers en el heap que DEBEN ser liberados de forma dinamica.
    try stdout.print(">> Iniciando Pruebas de Modulo 3: Shared(T) con Deinit Interno Comptime <<\n", .{});
    {
        // Creamos la conexion de base de datos que asigna un buffer de 512 bytes
        const conn = try DatabaseConnection.init(allocator, 1, 512);

        // Inicializamos el Shared Pointer que asume el control del recurso (RefCount = 1)
        var db_compartida = try Shared(DatabaseConnection).init(allocator, conn);
        // Garantizamos la liberacion del puntero maestro
        defer db_compartida.release();

        try stdout.print("  [DB] Shared conexion creado. Referencias activas: {d}\n", .{db_compartida.getRefCount()});

        // Simulamos que el modulo de Autenticacion de la API retiene el recurso
        var modulo_auth = db_compartida.retain();
        defer modulo_auth.release();

        // Simulamos que el modulo de Facturacion de la API retiene el recurso
        var modulo_facturas = db_compartida.retain();
        defer modulo_facturas.release();

        try stdout.print("  [DB] Modulo Auth y Modulo Facturas retenidos. Referencias activas: {d}\n", .{db_compartida.getRefCount()});

        // Los modulos ejecutan consultas utilizando el buffer dinamico interno de la conexion
        try modulo_auth.get().ejecutarQuery("SELECT * FROM sesiones WHERE token = 'xyz';", stdout);
        try modulo_facturas.get().ejecutarQuery("UPDATE facturas SET estado = 1 WHERE id = 450;", stdout);

        try stdout.print("  [DB] Finalizando ejecucion de modulos secundarios...\n", .{});
    }
    // Gracias al chequeo de compilacion '@hasDecl(DatabaseConnection, "deinit")',
    // la llamada final a release() detectara el destructor de DatabaseConnection
    // y liberara de forma limpia el buffer de consulta de 512 bytes antes de
    // destruir la estructura de control Shared.
    try stdout.print("  [DB] Ambito de base de datos cerrado. Todos los recursos fueron purgados.\n\n", .{});
}

// =========================================================================
// 7. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG
// =========================================================================
// 1. LA MEMORIA SIEMPRE ES EXPLICITA: Nunca confie en que la memoria se
//    liberara sola en Zig. Siempre defina un flujo claro con 'defer' o 'release'.
//
// 2. ENTIENDA EL COSTO: El uso de operaciones atomicas (.seq_cst) garantiza
//    la seguridad en hilos, pero penaliza levemente el rendimiento de la CPU.
//    Si su aplicacion es puramente monohilo, puede prescindir de las funciones
//    atomicas y utilizar operaciones basicas de asignacion.
//
// 3. REFLEXION COMPTIME ES SU MEJOR ALIADO: Utilice la capacidad de evaluacion
//    en tiempo de compilacion para escribir envolturas genericas seguras de
//    recursos, garantizando que los objetos internos limpien su propia memoria.
//
// 4. INVALIDACION DE PUNTEROS: Al crear destructores, siempre establezca
//    los punteros internos a 'null' o 'undefined'. Esto hara que cualquier
//    intento de uso posterior falle de forma controlada mediante un "Panic"
//    en lugar de corromper silenciosamente la memoria del proceso.
// =========================================================================
