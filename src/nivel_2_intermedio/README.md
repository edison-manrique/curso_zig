# Nivel 2: Estructuras de Datos e Intermedio

Aquí dominarás los tipos compuestos de Zig, el manejo de texto UTF-8, arreglos multidimensionales y vectorización SIMD.

## Contenido

| Archivo | Tema | Comando |
| :--- | :--- | :--- |
| [05_structs.zig](./05_structs.zig) | Structs, métodos, tuplas y `packed struct` | `zig build run_5` |
| [06_enums.zig](./06_enums.zig) | Enums, `switch` exhaustivo y `@typeInfo` (`field_names`) | `zig build run_6` |
| [07_union.zig](./07_union.zig) | Uniones desnudas, `union(enum)` y `extern union` | `zig build run_7` |
| [09_strings.zig](./09_strings.zig) | Strings UTF-8, slices `[]const u8` y `std.mem` | `zig build run_9` |
| [21_arreglos.zig](./21_arreglos.zig) | Arreglos, matrices `[3][3]u8` y `@splat` | `zig build run_21` |
| [22_vectores.zig](./22_vectores.zig) | Vectores SIMD (`@Vector`, `@splat`, `@reduce`) | `zig build run_22` |
| [33_formato.zig](./33_formato.zig) | Formateo avanzado con `std.fmt` | `zig build run_53` |

## Puntos clave de Zig 0.17.0 en este nivel
- `@typeInfo(Enum).@"enum"` expone `field_names` y `field_values` en lugar de `fields` (ver [06_enums.zig](./06_enums.zig)).
- Las matrices y arreglos repetidos se inicializan con `@splat` (ver [21_arreglos.zig](./21_arreglos.zig)).

