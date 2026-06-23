// =========================================================================
//         GUIA DEFINITIVA: COMENTARIOS Y AUTODOCUMENTACION EN ZIG
//                         EDICION ZIG 0.16.0
// =========================================================================
// Este documento ha sido disenado como un curso intensivo y de nivel
// produccion para dominar la sintaxis de comentarios, reglas de analisis
// sintactico (parsing) y generacion de documentacion automatica en Zig.
//
// NOTA DE COMPATIBILIDAD: Todo el codigo, graficos ASCII y explicaciones
// estan limitados estrictamente a la codificacion ASCII de 7 bits (rango 0-127)
// para prevenir errores de compilacion y renderizado en consolas legadas.

// =========================================================================
// TABLA DE CONTENIDOS (TEMARIO)
// =========================================================================
// 1. FILOSOFIA DE ZIG: LA AUSENCIA DE COMENTARIOS MULTILINEA (/* */)
//    1.1 El principio de "Context-Free Tokenization" (Analisis sin Contexto)
//    1.2 Beneficios en el rendimiento del compilador
//
// 2. MODULO 1: COMENTARIOS NORMALES o DE CODIGO (//)
//    2.1 Sintaxis basica y limites del byte LF (Line Feed)
//    2.2 Comentarios inline y deshabilitacion temporal de codigo
//
// 3. MODULO 2: DOCUMENTACION DE DECLARACIONES o "DOC COMMENTS" (///)
//    3.1 Reglas estrictas de coincidencia de tres barras
//    3.2 El mecanismo de fusion consecutiva (Multiline Fusion)
//    3.3 Asociacion inmediata con la declaracion siguiente
//
// 4. MODULO 3: DOCUMENTACION DE MODULOS Y CONTENEDORES (//!)
//    4.1 Comentarios de nivel superior y su rol en el empaquetado
//    4.2 Reglas de posicionamiento estricto antes de cualquier expresion
//
// 5. MODULO 4: ERRORES COMUNES EN TIEMPO DE COMPILACION (COMPILE ERRORS)
//    5.1 Error: Unattached Documentation Comment (Comentario huerfano)
//    5.2 Error: Misplaced Doc Comment (Posicionamiento invalido)
//
// 6. MODULO 5: PROYECTO INTEGRAL DE DEMOSTRACION Y COMPILACION DE DOCS
//    6.1 Estructuracion de un modulo documentado para exportar a HTML
//    6.2 El comando `zig test -femit-docs`
//
// 7. CONCLUSIONES Y REGLAS DE ORO DEL DESARROLLADOR EN ZIG

// =========================================================================
// 1. FILOSOFIA DE ZIG: LA AUSENCIA DE COMENTARIOS MULTILINEA
// =========================================================================
// A diferencia de C, C++, Rust, Java o Go, Zig NO soporta comentarios
// multilinea encerrados entre barras y asteriscos (/* ... */).
//
// Esta decision de diseno no es un capricho estético; responde a una
// de las propiedades de ingenieria mas buscadas por el compilador de Zig:
//
// ---> "CONTEXT-FREE TOKENIZATION" (Tokenizacion Libre de Contexto) <---
//
// En lenguajes tradicionales, para saber si una linea de codigo es ejecutable
// o es simplemente un comentario pasivo, el analizador lexico (lexer)
// requiere saber el estado de las lineas anteriores. Si abriste un `/*` en
// la linea 5, la linea 500 sigue siendo un comentario hasta que encuentre `*/`.
//
// En Zig, cada linea individual puede ser tokenizada de forma aislada sin
// importar el resto del archivo. Si una linea empieza con `//`, es un comentario.
// Si no, es codigo ejecutable (o esta vacia).
//
// Beneficios tecnicos:
// 1. Paralelizacion extrema: El lexer puede analizar multiples partes de un
//    archivo en hilos separados sin preocuparse por estados de comentarios globales.
// 2. Simplicidad de herramientas: Editores de texto, formateadores (`zig fmt`)
//    y analizadores estaticos pueden procesar el codigo de forma ultra veloz.
// 3. Robustez ante errores: Se elimina la posibilidad de "comentar accidentalmente"
//    miles de lineas de codigo debido a un cierre de bloque `*/` omitido.

// Visualizacion del Arbol de Sintaxis Abstracta (AST) de Zig ante comentarios:
//
// Source Code                       Zig Compiler / Lexer
// +--------------------------+      +-------------------------------------+
// | //! Modulo Principal     | ---> | Guarda en AST: Documentacion de File|
// | const std = @import(...);|      |                                     |
// |                          |      |                                     |
// | // Comentario normal     | ---> | IGNORADO por completo (Descartado)  |
// |                          |      |                                     |
// | /// Estructura           | ---> | Guarda en AST: Vinculado a Node S   |
// | const S = struct {};     |      |                                     |
// +--------------------------+      +-------------------------------------+

const std = @import("std");

// =========================================================================
// 2. MODULO 1: COMENTARIOS NORMALES O DE CODIGO (//)
// =========================================================================
// Los comentarios normales comienzan con dos barras inclinadas `//` y se
// extienden hasta el final de la linea, definido especificamente por el
// byte LF (Line Feed, '\n' o byte 10 en la tabla ASCII).

fn modulo1ComentariosNormales() void {
    // Esto es un comentario estandar.
    // El compilador ignorara por completo estas lineas en tiempo de analisis.

    const x: u32 = 42; // Los comentarios pueden comenzar despues de una expresion

    // El siguiente codigo ha sido desactivado (comentado) temporalmente:
    // const y = x + 10;
    // std.debug.print("Valor omitido: {d}\n", .{y});

    _ = x; // Silenciamos variable para evitar warnings
}

// =========================================================================
// 3. MODULO 2: DOCUMENTACION DE DECLARACIONES O "DOC COMMENTS" (///)
// =========================================================================
// Los comentarios de documentacion de declaraciones deben comenzar con
// EXACTAMENTE tres barras diagonales `///`. Si colocas cuatro barras o mas
// (`////`), el compilador lo tratara como un comentario normal y no generara
// documentacion automatica.
//
// Un "Doc Comment" tiene la obligacion estricta de documentar lo que viene
// inmediatamente despues de el en el codigo fuente.

/// Representa una ubicacion geografica en formato de coordenadas terrestres.
/// Este comentario multilinea se fusionara de forma automatica en el HTML final
/// de documentacion porque son lineas continuas de tres barras.
const Coordenada = struct {
    /// La posicion angular Norte-Sur medida en grados decimales (doc comment).
    latitud: f64,

    /// La posicion angular Este-Oeste medida en grados decimales.
    longitud: f64, // Tambien podemos agregar comentarios normales aqui a la derecha

    /// Inicializa una Coordenada validando que los rangos geograficos sean logicos.
    /// Retorna un error si las coordenadas estan fuera de los limites fisicos de la Tierra.
    pub fn init(lat: f64, lon: f64) !@This() {
        if (lat < -90.0 or lat > 90.0) return error.LatitudInvalida;
        if (lon < -180.0 or lon > 180.0) return error.LongitudInvalida;

        return @This(){
            .latitud = lat,
            .longitud = lon,
        };
    }
};

// -------------------------------------------------------------------------
// REGLA DE INTERCALADO (INTERLEAVING)
// -------------------------------------------------------------------------
// Los comentarios de documentacion (///) pueden estar intercalados con
// comentarios normales (//). Los comentarios normales seran descartados
// y no afectaran la fusion de las lineas de documentacion continua.

/// Esta estructura simula una conexion de base de datos activa.
// NOTA DE DESARROLLO: Esta implementacion es temporal para la version 0.16.0
/// Permite enviar cadenas de texto simulando consultas complejas.
const DBConnection = struct {
    id: u32,
};

// El resultado documentado de 'DBConnection' sera:
// "Esta estructura simula una conexion de base de datos activa. Permite enviar cadenas de texto simulando consultas complejas."

// =========================================================================
// 4. MODULO 3: DOCUMENTACION DE MODULOS Y CONTENEDORES (//!)
// =========================================================================
// Un comentario de nivel superior (Top-Level Doc Comment) comienza con dos
// barras y un signo de exclamacion `//!`. Se utiliza para documentar el modulo
// (archivo) actual o un contenedor completo (como una estructura interna).
//
// REGLA DE ORO DE POSICIONAMIENTO:
// Un comentario `//!` debe colocarse obligatoriamente en la parte superior
// del contenedor, antes de cualquier expresion de codigo, imports o variables.
// Incumplir esto causara un error de compilacion inmediato.

const ContenedorPrueba = struct {
    //! Este comentario de nivel superior documenta el comportamiento interno
    //! de este struct especifico. Aunque es valido, su uso principal se da
    //! en el inicio de archivos de modulo (como la primera linea de este archivo).

    val: u32,
};

// =========================================================================
// 5. MODULO 4: ERRORES COMUNES EN TIEMPO DE COMPILACION (COMPILE ERRORS)
// =========================================================================
// A diferencia de otros lenguajes donde los comentarios son ignorados de
// forma laxa por el compilador, Zig es extremadamente estricto. Los comentarios
// de documentacion (///) y modulo (//!) forman parte del Arbol de Sintaxis
// Abstracta (AST) y deben cumplir reglas semanticas de ubicacion.

// -------------------------------------------------------------------------
// 5.1 ERROR: UNATTACHED DOCUMENTATION COMMENT (Doc comment huerfano)
// -------------------------------------------------------------------------
// Un comentario `///` debe tener una declaracion valida inmediatamente debajo.
// Si pones un `///` al final de un bloque, o antes de cerrar un struct,
// el compilador fallara con "unattached documentation comment".
//
// EJEMPLO DE CODIGO INCORRECTO (Causa error de compilacion si se descomenta):
//
// pub fn funcionInutil() void {
//     const x = 10;
//     _ = x;
//     /// Esto causara error porque no hay ninguna variable o funcion abajo.
// }

// -------------------------------------------------------------------------
// 5.2 ERROR: MISPLACED DOC COMMENT (Posicionamiento invalido)
// -------------------------------------------------------------------------
// Los comentarios `///` no pueden insertarse en medio de una expresion o
// declaracion parcial.
//
// EJEMPLO DE CODIGO INCORRECTO:
//
// const valor = 10 +
// /// Explicacion invalida en medio de una suma
// 20;

// -------------------------------------------------------------------------
// 5.3 ERROR: MISPLACED TOP-LEVEL COMMENT (Comentario de nivel superior tardio)
// -------------------------------------------------------------------------
// Si declaras un modulo `//!` despues de un import o de una variable,
// el compilador abortara la operacion.
//
// EJEMPLO DE CODIGO INCORRECTO:
//
// const x = 42;
// //! Error grave: Este comentario superior debio estar antes de 'const x'

// =========================================================================
// 6. MODULO 5: PROYECTO INTEGRAL DE DEMOSTRACION
// =========================================================================
// A continuacion, se muestra una biblioteca matematica simulada con un alto
// nivel de documentacion para ser procesada por el generador de HTML de Zig.

/// Provee funciones matematicas para calculos vectoriales bidimensionales.
/// Disenado especificamente para motores graficos de baja latencia.
pub const Vector2 = struct {
    /// Componente de coordenadas horizontal (eje X).
    x: f32,
    /// Componente de coordenadas vertical (eje Y).
    y: f32,

    /// Crea un nuevo Vector2 a partir de sus valores escalares.
    pub fn init(x: f32, y: f32) @This() {
        return @This(){
            .x = x,
            .y = y,
        };
    }

    /// Calcula la magnitud euclidiana (longitud del vector).
    /// Utiliza la aproximacion estandar por raiz cuadrada.
    pub fn magnitud(self: @This()) f32 {
        return @sqrt((self.x * self.x) + (self.y * self.y));
    }

    /// Multiplica el vector por un valor escalar constante.
    /// Retorna un nuevo Vector2 con los componentes escalados.
    pub fn escalar(self: @This(), factor: f32) @This() {
        return @This(){
            .x = self.x * factor,
            .y = self.y * factor,
        };
    }
};

// =========================================================================
// PUNTO DE ENTRADA DE DEMOSTRACION
// =========================================================================
pub fn main() void {
    // 1. Demostracion de uso del modulo documentado
    const v1 = Vector2.init(3.0, 4.0);
    const mag = v1.magnitud();
    const v_escalado = v1.escalar(2.0);

    // 2. Impresion por consola (salida estandar de diagnostico)
    std.debug.print("--- MASTERCLASS COMENTARIOS ZIG ---\n", .{});
    std.debug.print("Vector Original: ({d:.1}, {d:.1})\n", .{ v1.x, v1.y });
    std.debug.print("Magnitud Calculada: {d:.2}\n", .{mag});
    std.debug.print("Vector Escalado x2: ({d:.1}, {d:.1})\n", .{ v_escalado.x, v_escalado.y });

    // Ejecucion interna del modulo 1 para verificar que corre sin problemas
    modulo1ComentariosNormales();
}

// =========================================================================
// 6.2 COMO GENERAR LA DOCUMENTACION HTML AUTOMATICA
// =========================================================================
// Zig cuenta con un generador de documentacion integrado y ultra veloz
// que analiza directamente estos tokens del AST (/// y //!) y genera un sitio
// web estatico interactivo y autonomo en HTML/CSS/JS.
//
// Para generar los archivos de documentacion en tu directorio de proyecto,
// ejecuta el siguiente comando en tu consola de comandos (Shell):
//
// -------------------------------------------------------------------------
// $ zig test -femit-docs 17_concurrencia.zig
// -------------------------------------------------------------------------
//
// Esto creara una carpeta llamada "docs" (o dentro del cache de Zig) que
// contiene un archivo index.html. Al abrirlo en cualquier navegador web,
// podras visualizar toda la biblioteca Vector2, sus metodos (init, magnitud,
// escalar) y sus variables explicadas de forma profesional, estructurada y
// limpia, navegable de forma interactiva.

// =========================================================================
// 7. CONCLUSIONES Y REGLAS DE ORO DEL DESARROLLADOR EN ZIG
// =========================================================================
// 1. COMENTARIOS DE DOCUMENTACION COMPILAN: No trates a `///` o `//!` como texto
//    pasivo. Si colocas un comentario de documentacion en un lugar invalido o
//    sin asignacion fisica, el compilador detendra el proceso arrojando error.
//
// 2. MANTENGA LA COHERENCIA: Usa `///` exclusivamente para documentar la API
//    que sera expuesta para otros programadores. Usa `//` para notas internas
//    de desarrollo o para deshabilitar lineas de codigo temporalmente.
//
// 3. EVITE EL DESORDEN: No es necesario abusar de los comentarios. La filosofia
//    de Zig dicta que el codigo debe ser lo mas claro y explicito posible.
//    Documenta intenciones complejas, asunciones de memoria o formulas fisicas,
//    pero evita documentar lo evidente.
//
// 4. GENERACION CONTINUA: Integra `zig test -femit-docs` en tus servidores de
//    Integracion Continua (CI) para asegurar que la documentacion de tus APIs
//    nunca quede desactualizada con respecto al codigo fuente real.
// =========================================================================
