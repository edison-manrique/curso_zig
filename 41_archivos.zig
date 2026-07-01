// =========================================================================
// MASTERCLASS 8: TRABAJO CON ARCHIVOS Y EL NUEVO std.Io (EDICION ZIG 0.16)
// =========================================================================

// En Zig 0.16, todo el sistema de entrada/salida (I/O) fue completamente 
// redisenado para alinearse con la filosofia explicita de los Allocators.
// Se elimino el antiguo 'std.fs' global para dar paso al modulo 'std.Io'.
//
// Ahora, cualquier operacion de I/O requiere pasar explicitamente una
// instancia de 'std.Io' (proporcionada comunmente por Juicy Main en init.io).
// Esto permite que el mismo codigo se ejecute de manera sincrona, asincrona
// o multihilo simplemente cambiando el backend de I/O.

// CONCEPTOS CLAVE CUBIERTOS:
// 1. Creacion y Escritura de Archivos (Metodo de Escritura Streaming).
// 2. Lectura Completa (Metodo Posicional con Memoria Dinamica GPA).
// 3. Manejo Seguro de Errores al abrir recursos inexistentes.
// 4. Creacion, Iteracion Lazy y Lectura de Directorios.
// 5. Eliminacion y Limpieza del Sistema de Archivos de forma segura.

// Todo el codigo, comentarios y diagramas estan escritos en ASCII puro
// (7-bit, rango 0-127) para compatibilidad universal con terminales.

const std = @import("std");

// ZIG 0.16.0: "Juicy Main"
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var buffer: [8192]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    defer stdout.flush() catch {};

    try stdout.print("--- MASTERCLASS: GESTION DE ARCHIVOS EN ZIG 0.16 ---\n\n", .{});

    // Pasamos tanto la interfaz stdout como init.io y init.gpa para el trabajo
    try modulo1CreacionYEscritura(stdout, io);
    try modulo2LecturaCompleta(stdout, io, gpa);
    try modulo3GestionDeErrores(stdout, io);
    try modulo4DirectoriosEIteracion(stdout, io);
    try modulo5Limpieza(stdout, io);

    try stdout.print("\n--- FIN DE LA MASTERCLASS DE ARCHIVOS ---\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 1: CREACION Y ESCRITURA DE ARCHIVOS
// -------------------------------------------------------------------------
fn modulo1CreacionYEscritura(stdout: anytype, io: std.Io) !void {
    try stdout.print(">> Modulo 1: Creacion y Escritura de Archivos\n", .{});

    // En Zig 0.16, se usa std.Io.Dir para representar directorios.
    // .cwd() nos devuelve un manejador del directorio de trabajo actual.
    const cwd = std.Io.Dir.cwd();

    // createFile requiere el backend 'io', la ruta y opciones adicionales.
    const file = try cwd.createFile(io, "temp_masterclass.txt", .{});
    
    // Es indispensable cerrar el archivo al finalizar el bloque para liberar descriptores.
    // En el nuevo std.Io, el metodo close() tambien requiere el parametro 'io'.
    defer file.close(io);

    // Escribimos de forma secuencial (Streaming) sin necesidad de indicar offsets.
    // Esto es ideal para escrituras lineales rapidas y eficientes.
    try file.writeStreamingAll(io, "Linea 1: Hola desde la Masterclass de Archivos!\n");
    try file.writeStreamingAll(io, "Linea 2: Zig 0.16 unifica todo el I/O en std.Io.\n");
    try file.writeStreamingAll(io, "Linea 3: Sin magia oculta detras del compilador.\n");

    try stdout.print("  Archivo 'temp_masterclass.txt' creado y escrito exitosamente.\n\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 2: LECTURA ENTERA EN MEMORIA (HEAP ALLOCATION)
// -------------------------------------------------------------------------
fn modulo2LecturaCompleta(stdout: anytype, io: std.Io, gpa: std.mem.Allocator) !void {
    try stdout.print(">> Modulo 2: Lectura Completa (Heap Allocation)\n", .{});

    const cwd = std.Io.Dir.cwd();
    
    // Abrimos el archivo en modo de solo lectura (comportamiento por defecto).
    const file = try cwd.openFile(io, "temp_masterclass.txt", .{});
    defer file.close(io);

    // Consultamos los metadatos del archivo usando el backend de I/O.
    const stat = try file.stat(io);
    try stdout.print("  Tamano del archivo en disco: {d} bytes\n", .{stat.size});

    // Asignamos memoria de manera dinamica en el heap basandonos en el tamano exacto.
    // Esto es sumamente seguro y previene desbordamientos de bufer en pila.
    const buffer = try gpa.alloc(u8, stat.size);
    defer gpa.free(buffer);

    // Leemos todo el contenido de forma posicional desde el offset 0.
    // readPositionalAll asegura que se lean exactamente los bytes solicitados.
    _ = try file.readPositionalAll(io, buffer, 0);

    try stdout.print("  Contenido leido del archivo:\n  ---\n", .{});
    // Mostramos el contenido convirtiendo el bufer de bytes en texto legible
    try stdout.print("{s}  ---\n\n", .{buffer});
}

// -------------------------------------------------------------------------
// MODULO 3: GESTION EXPLICITA DE ERRORES AL ABRIR ARCHIVOS
// -------------------------------------------------------------------------
fn modulo3GestionDeErrores(stdout: anytype, io: std.Io) !void {
    try stdout.print(">> Modulo 3: Gestion de Errores (FileNotFound)\n", .{});

    const cwd = std.Io.Dir.cwd();
    
    // Zig fomenta que los errores sean tratados como valores normales del sistema.
    // Aqui intentamos abrir un archivo que no existe de forma controlada.
    const intento = cwd.openFile(io, "archivo_que_no_existe.txt", .{});
    
    if (intento) |file| {
        defer file.close(io);
        try stdout.print("  Inesperado: Se abrio el archivo.\n", .{});
    } else |err| {
        try stdout.print("  Exito: Error capturado correctamente -> {s}\n", .{@errorName(err)});
        
        // Podemos ramificar nuestra logica dependiendo del error especifico devuelto por el S.O.
        if (err == error.FileNotFound) {
            try stdout.print("  (El sistema identifico con precision la ausencia del recurso)\n", .{});
        }
    }
    try stdout.print("\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 4: TRABAJO CON DIRECTORIOS E ITERACION LAZY
// -------------------------------------------------------------------------
fn modulo4DirectoriosEIteracion(stdout: anytype, io: std.Io) !void {
    try stdout.print(">> Modulo 4: Creacion e Iteracion de Directorios\n", .{});

    const cwd = std.Io.Dir.cwd();

    // Creamos un directorio temporal usando las banderas estandar del sistema.
    try cwd.createDir(io, "temp_dir_masterclass", .default_dir);
    
    // Abrimos el directorio recien creado.
    // IMPORTANTE: .iterate = true es requerido si planeamos listar sus elementos internos.
    const dir_ref = try cwd.openDir(io, "temp_dir_masterclass", .{ .iterate = true });
    defer dir_ref.close(io);

    // Creamos algunos archivos vacios de prueba dentro de esta carpeta temporal.
    const archivo_a = try dir_ref.createFile(io, "archivo_a.log", .{});
    archivo_a.close(io);
    const archivo_b = try dir_ref.createFile(io, "archivo_b.log", .{});
    archivo_b.close(io);

    // Obtenemos un iterador optimizado.
    // El iterador de Zig lee de forma perezosa (lazy) sin reservar memoria dinamica.
    var iterador = dir_ref.iterate();
    
    try stdout.print("  Listando elementos dentro de 'temp_dir_masterclass':\n", .{});
    while (try iterador.next(io)) |entrada| {
        // entrada.name contiene el slice con el nombre del elemento.
        // entrada.kind contiene el enum del tipo de elemento (.file, .directory, etc).
        try stdout.print("    - Nombre: {s:<15} | Tipo: {any}\n", .{ entrada.name, entrada.kind });
    }
    try stdout.print("\n", .{});
}

// -------------------------------------------------------------------------
// MODULO 5: LIMPIEZA Y ELIMINACION DE RECURSOS
// -------------------------------------------------------------------------
fn modulo5Limpieza(stdout: anytype, io: std.Io) !void {
    try stdout.print(">> Modulo 5: Limpieza del Sistema de Archivos\n", .{});

    const cwd = std.Io.Dir.cwd();

    // 1. Borramos el archivo creado originalmente en el Modulo 1.
    cwd.deleteFile(io, "temp_masterclass.txt") catch |err| {
        try stdout.print("  Fallo al borrar archivo principal: {s}\n", .{@errorName(err)});
    };

    // 2. Para borrar un directorio, primero debemos limpiar su contenido interno.
    // Los sistemas operativos no permiten remover carpetas que no esten vacias.
    const dir_ref = try cwd.openDir(io, "temp_dir_masterclass", .{});
    
    dir_ref.deleteFile(io, "archivo_a.log") catch {};
    dir_ref.deleteFile(io, "archivo_b.log") catch {};
    
    // Cerramos el handler de la carpeta para que el S.O. no la bloquee durante el borrado.
    dir_ref.close(io);

    // 3. Borramos el directorio vacio usando deleteDir.
    cwd.deleteDir(io, "temp_dir_masterclass") catch |err| {
        try stdout.print("  Fallo al borrar el directorio: {s}\n", .{@errorName(err)});
    };

    try stdout.print("  Sistema de archivos limpio. Recursos temporales destruidos.\n", .{});
}