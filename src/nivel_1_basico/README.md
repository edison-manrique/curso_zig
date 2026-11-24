# Nivel 1: Fundamentos Básicos de Zig 0.17.0

En esta sección aprenderás la sintaxis esencial de Zig y cómo el lenguaje garantiza seguridad sin ocultar lo que ocurre en memoria.

## Contenido

| Archivo | Tema | Comando |
| :--- | :--- | :--- |
| [01_variables.zig](./01_variables.zig) | `const` vs `var`, tipos primitivos, `undefined`, `noreturn` | `zig build run_1` |
| [02_funciones.zig](./02_funciones.zig) | Funciones, bloques etiquetados, `defer`, callbacks | `zig build run_2` |
| [03_bucles.zig](./03_bucles.zig) | `while` con continuación, `for` sobre slices/rangos | `zig build run_3` |
| [04_punteros.zig](./04_punteros.zig) | `*T`, `[*]T`, `?*T`, alineación y desreferenciación | `zig build run_4` |
| [18_comentarios.zig](./18_comentarios.zig) | Comentarios normales, `///` doc-comments y `//!` | `zig build run_18` |
| [19_identificadores.zig](./19_identificadores.zig) | Identificadores `@"..."` y reflexión básica | `zig build run_19` |
| [20_operadores.zig](./20_operadores.zig) | Aritmética normal, modular (`+%`), saturada (`+\|`), `@splat` | `zig build run_20` |

## Puntos clave de Zig 0.17.0 en este nivel
- El operador `**` fue eliminado en favor de `@splat(valor)` (ver [20_operadores.zig](./20_operadores.zig)).
- Toda variable sin usar o `var` sin mutar produce un error de compilación.

