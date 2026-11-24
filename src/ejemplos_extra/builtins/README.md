# Builtins de Zig 0.17.0

Colección de 27 ejemplos enfocados en las funciones integradas (`@...`) del compilador de Zig:

- **Matemáticos (`matematicos/`)**: `@abs`, `@sqrt`, `@sin`/`@cos`/`@tan`, `@exp`/`@exp2`, `@floor`/`@ceil`, `@min`/`@max`, `@log`/`@log10`.
- **Bitwise (`bitwise/`)**: `@byteSwap`, `@bitReverse`, `@popCount`, `@clz`, `@ctz`.
- **Memoria (`memoria/`)**: `@memcpy`, `@memset`, `std.mem.eql`, `@alignOf`, `@sizeOf`, `@offsetOf`.
- **Atómicos (`atomicos/`)**: `@atomicLoad`, `@atomicStore`, `@atomicRmw`, simulación de barreras (*fence*).
- **Sistema (`sistema/`)**: `@returnAddress`, `@prefetch`, `@trap`, `@breakpoint`, `unreachable`, `comptime`.

Puedes ejecutar cualquiera usando `zig run` o `zig build run_N` (pasos `run_24` a `run_50`).

