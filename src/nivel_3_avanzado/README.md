# Nivel 3: Programación Avanzada de Sistemas

En este nivel profundizarás en gestión explícita de memoria, metaprogramación en `comptime`, concurrencia con `std.Io` y pruebas automatizadas.

## Contenido

| Archivo | Tema | Comando |
| :--- | :--- | :--- |
| [08_memoria.zig](./08_memoria.zig) | `DebugAllocator`, `FixedBufferAllocator`, `ArenaAllocator` | `zig build run_8` |
| [10_errores.zig](./10_errores.zig) | Error sets, `try`, `catch`, `defer`, `errdefer` | `zig build run_10` |
| [11_comptime.zig](./11_comptime.zig) | Metaprogramación, validación de formatos en compilación | `zig build run_11` |
| [12_genericos.zig](./12_genericos.zig) | Tipos genéricos y `std.ArrayList` (`.empty`) | `zig build run_12` |
| [13_tiempo_vida.zig](./13_tiempo_vida.zig) | Stack frames, heap y prevención de dangling pointers | `zig build run_13` |
| [14_iteradores_personalizados.zig](./14_iteradores_personalizados.zig) | Patrón iterador en Zig | `zig build run_14` |
| [15_modulos.zig](./15_modulos.zig) | Importación de módulos ([_15_helper.zig](./_15_helper.zig)) | `zig build run_15` |
| [16_punteros_inteligentes.zig](./16_punteros_inteligentes.zig) | Implementación de `Unique(T)` y `Shared(T)` | `zig build run_16` |
| [17_concurrencia.zig](./17_concurrencia.zig) | Hilos, `std.Io.Mutex`, spinlocks y `threadlocal` | `zig build run_17` |
| [23_test.zig](./23_test.zig) | `std.testing`, detección de fugas y RingBuffer | `zig test src/nivel_3_avanzado/23_test.zig` |

## Puntos clave de Zig 0.17.0 en este nivel
- `errdefer` ya no acepta captura de error (`|err|`); ver [10_errores.zig](./10_errores.zig).
- `std.ArrayList(T)` se inicializa con `.empty` y recibe el `allocator` en `append`/`deinit` (ver [12_genericos.zig](./12_genericos.zig) y [23_test.zig](./23_test.zig)).
- `@typeInfo(Struct).@"struct"` usa `field_names` (ver [11_comptime.zig](./11_comptime.zig)).

