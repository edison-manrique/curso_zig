// =========================================================================
//       MASTERCLASS: IDENTIFICADORES Y IDENTIFICADORES DE CADENA
//                         EDICION ZIG 0.16.0
// =========================================================================
// Este documento ha sido disenado como la guia definitiva escrita por
// expertos en sistemas para dominar las reglas de nomenclatura, enlaces de
// funciones externas (C ABI) y la sintaxis avanzada de identificadores de
// cadena en Zig.
//
// NOTA DE COMPATIBILIDAD: Todo el codigo, graficos ASCII y explicaciones
// estan limitados estrictamente a la codificacion ASCII de 7 bits (rango 0-127)
// para prevenir errores de compilacion y renderizado en consolas legadas.

// =========================================================================
// TABLA DE CONTENIDOS (TEMARIO)
// =========================================================================
// 1. INTRODUCCION: ¿QUE ES UN IDENTIFICADOR EN ZIG?
//    1.1 Definicion formal y analisis lexico (Lexical Analysis)
//    1.2 El mapa de caracteres permitidos en identificadores estandar
//    1.3 La colision inevitable con palabras reservadas (Keywords)
//
// 2. SINTAXIS DE IDENTIFICADORES DE CADENA (@"")
//    2.1 El constructor literal de identificador: @""
//    2.2 Por que Zig no usa prefijos de escape como otros lenguajes
//    2.3 Reglas de escape dentro de la cadena del identificador
//
// 3. CASOS DE USO CRITICOS (DEL MUNDO REAL)
//    3.1 Caso 1: Enlace con librerias en C (C ABI Interoperability)
//    3.2 Caso 2: Serializacion y Mapeo directo de JSON/YAML a Structs
//    3.3 Caso 3: Enums altamente descriptivos para protocolos de red
//
// 4. REFLEXION COMPTIME E IDENTIFICADORES DINAMICOS
//    4.1 Acceso reflexivo usando @field con identificadores especiales
//    4.2 El Caso Maestro de @typeInfo y el campo info.@"struct"
//
// 5. ERRORES COMUNES EN TIEMPO DE COMPILACION (COMPILE ERRORS)
//    5.1 Error: Keyword Overlap (Colision con palabras reservadas)
//    5.2 Error: Invalid Start Character (Caracter de inicio no numerico)
//
// 6. PROYECTO COMPLETO DE DEMOSTRACION (SISTEMA DE PARSING DE CABECERAS HTTP)
//    6.1 Implementacion de un parseador que mapea cabeceras HTTP con guiones
//    6.2 Analisis de campos en tiempo de ejecucion y comptime
//
// 7. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG

// =========================================================================
// 1. INTRODUCCION: ¿QUE ES UN IDENTIFICADOR EN ZIG?
// =========================================================================
// Un identificador es un nombre asignado por el programador para reconocer
// una variable, constante, funcion, estructura, enumerado, union o modulo.
//
// El compilador de Zig realiza un paso inicial llamado Tokenizacion (Lexing)
// donde convierte el texto plano del codigo en tokens estructurados.
//
// REGLAS ESTANDAR DE UN IDENTIFICADOR:
// 1. Debe comenzar con una letra alfabetica (a-z, A-Z) o un guion bajo `_`.
// 2. Puede ser seguido por cualquier cantidad de caracteres alfanumericos
//    (letras, numeros) o guiones bajos.
// 3. No puede contener espacios, guiones medios, caracteres especiales (#, $, @)
//    ni comenzar con numeros (0-9).
// 4. No puede coincidir exactamente con ninguna de las palabras reservadas del
//    lenguaje (como `const`, `var`, `fn`, `error`, `struct`, `enum`, etc.).
//
// Grafico ASCII de Tokenizacion de Identificadores:
//
//   Codigo Fuente:     const mi_variable_99 = 10;
//                      ^---^ ^------------^
//   Tokens:           [KEYWORD] [IDENTIFIER]
//
//   Codigo Invalido:   const 99_variable = 10;  <-- ERROR: Comienza con numero
//   Codigo Invalido:   const const = 10;        <-- ERROR: Coincide con Keyword

const std = @import("std");

// =========================================================================
// 2. SINTAXIS DE IDENTIFICADORES DE CADENA (@"")
// =========================================================================
// Zig provee un mecanismo elegante y poderoso para romper las limitaciones
// de los identificadores estandar sin comprometer el rendimiento ni la
// seguridad del compilador: La Sintaxis de Identificadores de Cadena.
//
// Al encerrar cualquier secuencia de caracteres dentro de `@""`, le indicamos
// al compilador que trate el contenido de la cadena literal como un unico
// identificador valido para el AST (Arbol de Sintaxis Abstracta).
//
// CARACTERISTICAS CLAVE:
// - Permite espacios en blanco, caracteres especiales, simbolos y numeros iniciales.
// - Permite usar palabras reservadas (Keywords) como identificadores legitimos.
// - No introduce sobrecarga en tiempo de ejecucion; el compilador resuelve el
//   nombre de forma estatica en tiempo de compilacion.

// Variables declaradas con identificadores de cadena:
const @"identifier with spaces in it" = 0xff;
const @"1SmallStep4Man" = 112358;

// =========================================================================
// 3. CASOS DE USO CRITICOS (DEL MUNDO REAL)
// =========================================================================

// -------------------------------------------------------------------------
// 3.1 CASO 1: ENLACE CON LIBRERIAS EN C (C ABI INTEROPERABILITY)
// -------------------------------------------------------------------------
// Cuando te enlazas con librerias escritas en C, no puedes controlar los
// nombres que los desarrolladores de C eligieron.
//
// Por ejemplo, una libreria de C podria exportar una funcion llamada `error()`
// o una funcion para Mac/iOS que use caracteres especiales como `fstat$INODE64`.
// En Zig puro, no podrias declarar estas funciones porque `error` es una palabra
// reservada muy importante y `$` es un caracter ilegal.
//
// La sintaxis `@""` resuelve esto de forma directa y limpia:

// Simulamos tipos basicos de C para compilar el ejemplo de forma autonoma
const c_fd_t = i32;
const Stat = struct {
    size: u64,
};

// Declaramos funciones externas exportadas por una libreria de C ficticia.
// El compilador de Zig enlazara correctamente estos nombres exoticos en el binario.
pub extern "c" fn @"error"() void;
pub extern "c" fn @"fstat$INODE64"(fd: c_fd_t, buf: *Stat) i32;

// -------------------------------------------------------------------------
// 3.2 CASO 2: SERIALIZACION Y MAPEO DIRECTO DE FORMATOS EXTERNOS (JSON/YAML)
// -------------------------------------------------------------------------
// Imagina que estas consumiendo un API JSON externa que te entrega el siguiente
// objeto de usuario:
// {
//   "user-id": 10293,
//   "first name": "John",
//   "class": "admin"
// }
//
// En otros lenguajes, tendrias que definir una estructura con nombres como
// `user_id` y usar tags/decoradores pesados para indicarle al deserializador
// como mapear los campos. En Zig, puedes mapear los campos 1:1 declarando
// la estructura exactamente con los mismos nombres del payload:

const PayloadUsuario = struct {
    @"user-id": u32,
    @"first name": []const u8,
    // "class" es palabra reservada en Zig, pero valida mediante identificador de cadena
    class: []const u8,
};

// -------------------------------------------------------------------------
// 3.3 CASO 3: ENUMS ALTAMENTE DESCRIPTIVOS PARA PROTOCOLOS DE RED
// -------------------------------------------------------------------------
// Los enums en Zig pueden utilizar identificadores de cadena para representar
// estados de protocolos o cadenas con espacios que se transmiten directamente
// por la red sin requerir funciones complejas de mapeo de texto:

const EstadoHttp = enum {
    OK,
    @"Bad Request",
    @"Internal Server Error",
    @"Gateway Timeout",
};

// =========================================================================
// 4. REFLEXION COMPTIME E IDENTIFICADORES DINAMICOS
// =========================================================================
// La metaprogramacion en Zig permite interactuar con identificadores de cadena
// de forma dinamica utilizando la funcion integrada `@field()`.
// `@field` toma una estructura o union y busca un campo cuyo nombre coincida
// con un string determinado en tiempo de compilacion (comptime).

fn obtenerCampoDinamico(instancia: anytype, comptime nombre_campo: []const u8) void {
    const info = @typeInfo(@TypeOf(instancia));

    // CORRECCION ZIG 0.16.0: El compilador exige usar minusculas para reflejar
    // tipos (`struct`, `union`, `enum`). Dado que `struct` es una palabra
    // reservada, la API de Zig se diseno usando la sintaxis de identificador
    // de cadena obligatorio: `info.@"struct"`.
    inline for (info.@"struct".fields) |f| {
        if (std.mem.eql(u8, f.name, nombre_campo)) {
            const valor = @field(instancia, f.name);
            std.debug.print("    [Metaprogramacion] Campo encontrado '{s}' -> Valor: {any}\n", .{ nombre_campo, valor });
            return;
        }
    }
}

// =========================================================================
// 5. ERRORES COMUNES EN TIEMPO DE COMPILACION (COMPILE ERRORS)
// =========================================================================
// Zig previene errores sutiles de nomenclatura aplicando reglas estrictas.

// -------------------------------------------------------------------------
// 5.1 ERROR: KEYWORD OVERLAP (Intento de usar Keyword de forma estandard)
// -------------------------------------------------------------------------
// Si intentas declarar una variable usando una Keyword sin `@""`, el compilador
// fallara inmediatamente indicando que esperaba un identificador.
//
// EJEMPLO DE CODIGO INCORRECTO:
// const fn = 10; // Error: expected identifier, found keyword 'fn'
//
// SOLUCION:
// const @"fn" = 10; // Totalmente valido

// -------------------------------------------------------------------------
// 5.2 ERROR: CARACTER DE INICIO NUMERICO EN IDENTIFICADOR ESTANDAR
// -------------------------------------------------------------------------
// Los identificadores estandar no pueden empezar con numeros por limitaciones
// del analizador lexico del compilador (confunde identificadores con numeros).
//
// EJEMPLO DE CODIGO INCORRECTO:
// const 3d_vector = struct { x: f32 }; // Error: invalid token
//
// SOLUCION:
// const @"3d_vector" = struct { x: f32 }; // Totalmente valido

// =========================================================================
// 6. PROYECTO COMPLETO: PARSEADOR DE CABECERAS HTTP
// =========================================================================
// En este proyecto practico creamos un modulo que simula el procesamiento
// de cabeceras HTTP de red. Las cabeceras HTTP contienen guiones medios (como
// "Content-Type" o "User-Agent") que son ilegales en identificadores estandar.
// Veremos como `@""` nos permite disenar una API limpia y expresiva.

const CabecerasHttp = struct {
    @"Content-Type": []const u8,
    @"Content-Length": u32,
    @"User-Agent": []const u8,
    Authorization: []const u8,
    @"X-Custom-Header": []const u8,

    /// Muestra por pantalla el estado de las cabeceras procesadas
    pub fn imprimirCabeceras(self: *const @This()) void {
        std.debug.print("  [Parser HTTP] Cabecera Content-Type: {s}\n", .{self.@"Content-Type"});
        std.debug.print("  [Parser HTTP] Cabecera Content-Length: {d} bytes\n", .{self.@"Content-Length"});
        std.debug.print("  [Parser HTTP] Cabecera User-Agent: {s}\n", .{self.@"User-Agent"});
        std.debug.print("  [Parser HTTP] Cabecera X-Custom-Header: {s}\n", .{self.@"X-Custom-Header"});
    }
};

fn demostracionHttp() void {
    // Inicializacion de estructura utilizando nombres no estandar de forma nativa
    const cabeceras_recibidas = CabecerasHttp{
        .@"Content-Type" = "application/json",
        .@"Content-Length" = 1024,
        .@"User-Agent" = "Mozilla/5.0 (ZigOS 0.16.0)",
        .Authorization = "Bearer token_secreto_abc123",
        .@"X-Custom-Header" = "Metaprogramacion_Zig_Habilitada",
    };

    cabeceras_recibidas.imprimirCabeceras();

    // Probamos nuestra funcion de metaprogramacion para leer un campo con guiones
    std.debug.print("\n  [Main] Ejecutando lectura dinamica de campos con guiones medios:\n", .{});
    obtenerCampoDinamico(cabeceras_recibidas, "X-Custom-Header");
    obtenerCampoDinamico(cabeceras_recibidas, "Content-Length");
}

// =========================================================================
// PUNTO DE ENTRADA PRINCIPAL
// =========================================================================
pub fn main() void {
    std.debug.print("--- INICIO DE LA MASTERCLASS DE IDENTIFICADORES EN ZIG ---\n\n", .{});

    // 1. Demostracion de identificadores basicos de cadena
    std.debug.print(">> Modulo 1: Identificadores con espacios y numeros iniciales <<\n", .{});
    std.debug.print("  Valor constante con espacios: {d}\n", .{@"identifier with spaces in it"});
    std.debug.print("  Valor constante con numero inicial: {d}\n\n", .{@"1SmallStep4Man"});

    // 2. Demostracion de uso de Enums con espacios
    std.debug.print(">> Modulo 2: Enums con nombres altamente descriptivos <<\n", .{});
    const estado_actual: EstadoHttp = .@"Internal Server Error";

    // Mostramos que el compilador mapea la cadena del identificador de forma estatica
    std.debug.print("  Estado de red actual: {s} (Enum ordinal: {d})\n\n", .{
        @tagName(estado_actual),
        @intFromEnum(estado_actual),
    });

    // 3. Demostracion de Proyecto Practico (HTTP headers)
    std.debug.print(">> Modulo 3: Simulacion de Mapeo de Cabeceras HTTP <<\n", .{});
    demostracionHttp();

    std.debug.print("\n--- FIN DE LA MASTERCLASS DE IDENTIFICADORES ---\n", .{});
}

// =========================================================================
// 7. CONCLUSIONES Y REGLAS DE ORO DEL PROGRAMADOR EN ZIG
// =========================================================================
// 1. USE SINTAXIS DE CADENA SOLO CUANDO SEA NECESARIO: Aunque `@""` te permite
//    escribir codigo extravagante como `const @"mi variable" = 10;`, no abuses
//    de ello para el codigo interno de tu aplicacion. Mantener el estilo
//    estandar (`camelCase` o `snake_case`) mantiene tu codigo legible.
//
// 2. FUNDAMENTAL PARA C ABI: Al escribir bindings para librerias de C,
//    siempre ten a la mano `@""`. Te evitara dolores de cabeza al colisionar
//    con keywords de Zig o simbolos especiales del enlazador.
//
// 3. METAPROGRAMACION EXPRESIVA: Cuando escribas serializadores de JSON,
//    BSON, XML o bases de datos, utiliza `@""` combinado con `@field` para
//    lograr un mapeo directo y de alto rendimiento sin asignaciones de memoria
//    adicionales ni tablas hash de busqueda en tiempo de ejecucion.
//
// 4. CERO COSTO FISICO: Recuerda que los identificadores de cadena son un
//    mecanismo puramente sintactico. Al compilar a codigo maquina, el binario
//    final no contiene cadenas de texto extras ni consume mas RAM por usar `@""`.
// =========================================================================
