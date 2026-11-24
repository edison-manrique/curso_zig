# Curso Completo de Zig 0.17.0

Un curso completo, modular y práctico para aprender **Zig 0.17.0** desde cero hasta temas avanzados de programación de sistemas, metaprogramación, concurrencia y bajo nivel.

## Requisitos Previos

- **Zig**: Versión `0.17.0` (verificable con `zig version`)
- **Git**: Para clonar el repositorio

```bash
git clone https://github.com/edison-manrique/curso_zig.git
cd curso_zig
zig version
# Debe mostrar: 0.17.0
```

---

## Novedades clave de Zig 0.17.0 aplicadas en este curso

- **`std.process.Init` y `std.Io`**: Punto de entrada explícito `main(init: std.process.Init)` con `init.io`, `init.gpa`, `init.arena` e `init.minimal.args`.
- **Build System (`build.zig`)**: Uso de `run_cmd.addPassthruArgs()` en lugar de `b.args` para pasar argumentos con `zig build run -- ...`.
- **Repetición con `@splat`**: El operador `**` fue eliminado; ahora se usa `@splat(valor)` para arrays, matrices y vectores.
- **Interoperabilidad C (`FFI`)**: `@cImport` fue eliminado del compilador; se usan declaraciones `extern "c"` directas (o el paquete `translate-c`).
- **`errdefer` sin captura**: `errdefer |err|` fue eliminado; ahora se usa `errdefer { ... }`.
- **Reflexión en `comptime` (`std.lang.Type`)**: `info.@"struct".field_names` e `info.@"enum".field_names` / `field_values` reemplazan a `.fields`.
- **`std.ArrayList` no gestionado**: Inicialización con `.empty` y paso explícito del allocator en cada operación (`append(gpa, ...)`, `deinit(gpa)`).
- **`std.lang.Optimize`**: Los modos de optimización usan variantes en minúsculas (`.debug`, `.safe`, `.fast`, `.small`).

---

## Estructura del Proyecto

```text
curso_zig/
├── build.zig                       # Sistema de build con pasos run_1..run_60, run y all
├── README.md                       # Guía principal del curso
└── src/
    ├── nivel_1_basico/             # Variables, funciones, bucles, punteros, operadores
    ├── nivel_2_intermedio/         # Structs, enums, unions, strings, arreglos, vectores, formato
    ├── nivel_3_avanzado/           # Memoria, errores, comptime, genéricos, lifetimes, concurrencia, tests
    └── ejemplos_extra/             # FFI, ASM x86_64, WASM, build modes, RLS, archivos, tiempo, arena
        └── builtins/               # Builtins matemáticos, bitwise, memoria, atómicos y sistema
```

---

## Cómo Usar el Curso

### Ejecutar todos los módulos (verificación completa)

```bash
zig build all
```

### Ejecutar un módulo específico por número (`1` a `60`)

```bash
zig build run_1
zig build run_17
```

Puedes ver la lista completa de pasos con:

```bash
zig build --help
```

### Compilar y ejecutar un archivo específico con `-Dsrc`

```bash
zig build -Dsrc=src/nivel_1_basico/01_variables.zig run
```

### Ejecutar pruebas unitarias (`zig test`)

```bash
zig test src/nivel_3_avanzado/23_test.zig
zig test src/ejemplos_extra/37_asm.zig
zig test src/ejemplos_extra/36_ffi.zig -lc
```

---

## Índice de Módulos y Guías

### 1. [Nivel 1 — Básico](./src/nivel_1_basico/README.md)
- [01_variables.zig](./src/nivel_1_basico/01_variables.zig) — Variables, ciclo de vida, memoria y tipos
- [02_funciones.zig](./src/nivel_1_basico/02_funciones.zig) — Funciones, bloques etiquetados, callbacks y `defer`
- [03_bucles.zig](./src/nivel_1_basico/03_bucles.zig) — `while`, `for`, rangos e iteración
- [04_punteros.zig](./src/nivel_1_basico/04_punteros.zig) — Punteros simples, múltiples, opcionales y alineación
- [18_comentarios.zig](./src/nivel_1_basico/18_comentarios.zig) — Comentarios y documentación (`///`, `//!`)
- [19_identificadores.zig](./src/nivel_1_basico/19_identificadores.zig) — Identificadores, `@"..."` y reflexión básica
- [20_operadores.zig](./src/nivel_1_basico/20_operadores.zig) — Operadores aritméticos (`+%`, `+|`), bits y `@splat`

### 2. [Nivel 2 — Intermedio](./src/nivel_2_intermedio/README.md)
- [05_structs.zig](./src/nivel_2_intermedio/05_structs.zig) — Structs, métodos, tuplas y `packed struct`
- [06_enums.zig](./src/nivel_2_intermedio/06_enums.zig) — Enums, `switch` exhaustivo y `@typeInfo`
- [07_union.zig](./src/nivel_2_intermedio/07_union.zig) — Uniones, tagged unions y `extern union`
- [09_strings.zig](./src/nivel_2_intermedio/09_strings.zig) — Strings UTF-8, slices y `std.mem`
- [21_arreglos.zig](./src/nivel_2_intermedio/21_arreglos.zig) — Arreglos, matrices multidimensionales y `@splat`
- [22_vectores.zig](./src/nivel_2_intermedio/22_vectores.zig) — Vectores SIMD (`@Vector`)
- [33_formato.zig](./src/nivel_2_intermedio/33_formato.zig) — Formateo de texto y especificadores `std.fmt`

### 3. [Nivel 3 — Avanzado](./src/nivel_3_avanzado/README.md)
- [08_memoria.zig](./src/nivel_3_avanzado/08_memoria.zig) — Gestión de memoria, `DebugAllocator`, `FixedBufferAllocator` y `ArenaAllocator`
- [10_errores.zig](./src/nivel_3_avanzado/10_errores.zig) — Error sets, `try`, `catch`, `defer` y `errdefer`
- [11_comptime.zig](./src/nivel_3_avanzado/11_comptime.zig) — Metaprogramación en tiempo de compilación
- [12_genericos.zig](./src/nivel_3_avanzado/12_genericos.zig) — Estructuras y funciones genéricas
- [13_tiempo_vida.zig](./src/nivel_3_avanzado/13_tiempo_vida.zig) — Lifetimes, stack frames y dangling pointers
- [14_iteradores_personalizados.zig](./src/nivel_3_avanzado/14_iteradores_personalizados.zig) — Diseño de iteradores propios
- [15_modulos.zig](./src/nivel_3_avanzado/15_modulos.zig) y [\_15\_helper.zig](./src/nivel_3_avanzado/_15_helper.zig) — Modularidad e importaciones
- [16_punteros_inteligentes.zig](./src/nivel_3_avanzado/16_punteros_inteligentes.zig) — Patrones `Unique(T)` y `Shared(T)`
- [17_concurrencia.zig](./src/nivel_3_avanzado/17_concurrencia.zig) — Hilos, `std.Io.Mutex`, spinlocks y TLS
- [23_test.zig](./src/nivel_3_avanzado/23_test.zig) — Testing, `std.testing.allocator` y RingBuffer

### 4. [Ejemplos Extra](./src/ejemplos_extra/README.md) y [Builtins](./src/ejemplos_extra/builtins/README.md)
- [28_medicion_tiempo.zig](./src/ejemplos_extra/28_medicion_tiempo.zig) y [34_tiempo.zig](./src/ejemplos_extra/34_tiempo.zig) — `std.Io.Clock` y `std.Io.Duration`
- [35_bitwise.zig](./src/ejemplos_extra/35_bitwise.zig) — Manipulación de bits y controlador SoC
- [36_ffi.zig](./src/ejemplos_extra/36_ffi.zig) — Interoperabilidad con C (`extern "c"`, `qsort`)
- [37_asm.zig](./src/ejemplos_extra/37_asm.zig) — Ensamblador en línea (`x86_64`)
- [38_wasm.zig](./src/ejemplos_extra/38_wasm.zig) — Compilación para WebAssembly / WASI
- [39_build_modes.zig](./src/ejemplos_extra/39_build_modes.zig) — Modos de compilación (`Debug`, `ReleaseFast`, `ReleaseSafe`, `ReleaseSmall`)
- [40_rls.zig](./src/ejemplos_extra/40_rls.zig) — *Result Location Semantics*
- [41_archivos.zig](./src/ejemplos_extra/41_archivos.zig) — Archivos y directorios con `std.Io.Dir`
- [arena.zig](./src/ejemplos_extra/arena.zig) — Benchmark de `ArenaAllocator`
- [builtins/](./src/ejemplos_extra/builtins/README.md) — 27 ejemplos de builtins (`@abs`, `@popCount`, `@memcpy`, `@atomicRmw`, etc.)

---

## Autor

- **Edison Manrique Chocce**
- Email: edison.manrique.chocce@gmail.com
- GitHub: [@edison-manrique](https://github.com/edison-manrique)

## Licencia

Este proyecto está bajo la Licencia MIT.
