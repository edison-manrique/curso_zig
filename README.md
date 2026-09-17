# Curso Completo de Zig 🦀

Un curso completo y modular para aprender Zig desde cero hasta temas avanzados. Este proyecto está diseñado para ser claro, ordenado y fácil de seguir.

## 📋 Requisitos Previos

- **Zig**: Versión 0.16.0
- **Bun**: Versión 1.4.2 (para documentación y herramientas auxiliares)
- **Python**: Versión 3.x (ya instalado por defecto en la mayoría de sistemas)
- **SSH**: Configurado para conexión con GitHub

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone git@github.com:edison-manrique/curso_zig.git
cd curso_zig
```

### 2. Verificar instalación de Zig

```bash
zig version
# Debe mostrar: 0.16.0
```

## 📁 Estructura del Proyecto

```
curso_zig/
├── src/                    # Código fuente del curso
│   ├── 01_*.zig           # Introducción y conceptos básicos
│   ├── 02_*.zig           # Variables y tipos de datos
│   ├── 03_*.zig           # Funciones
│   ├── ...
│   └── 41_*.zig           # Temas avanzados
├── build.zig              # Sistema de build automatizado
├── build.zig.zon          # Configuración del paquete
├── .gitignore             # Archivos ignorados por git
└── README.md              # Este archivo
```

## 🎯 Cómo Usar

### Ejecutar un módulo específico

```bash
zig build run_N
# Donde N es el número del módulo (1-41)
```

### Ejecutar todos los módulos

```bash
zig build all
```

### Ejecutar tests

```bash
zig build test
```

## 📚 Contenido del Curso

### Nivel Básico
1. **Introducción** - Hola Mundo y configuración
2. **Variables** - Declaración, mutabilidad, tipos
3. **Funciones** - Definición, parámetros, retorno
4. **Control de Flujo** - if, else, switch
5. **Bucles** - while, for
6. **Arrays y Slices** - Manipulación de colecciones

### Nivel Intermedio
7. **Punteros** - Referencias, punteros opcionales
8. **Structs** - Tipos compuestos, métodos
9. **Enums** - Tipos enumerados
10. **Unions** - Uniones etiquetadas y no etiquetadas
11. **Manejo de Memoria** - Allocators, arena, heap
12. **Strings** - Manipulación de texto
13. **Errores** - Error sets, try, catch, defer

### Nivel Avanzado
14. **Comptime** - Metaprogramación, reflexión
15. **Genéricos** - Funciones y tipos genéricos
16. **FFI** - Interoperabilidad con C
17. **Inline Assembly** - Ensamblador en línea
18. **WebAssembly** - Compilación a WASM
19. **Testing** - Tests unitarios, integration tests
20. **Builtins** - Funciones incorporadas
21. **Concurrencia** - Async, frames, suspend
22. **Archivos** - I/O, sistema de archivos
23. **Metaprogramación Avanzada** - Macros, code generation

## 🔧 Configuración del Entorno

### Variables de Entorno

Las herramientas se instalan en `$HOME/tmp` y se agregan al PATH:

```bash
export PATH="$HOME/tmp/zig:$HOME/tmp/bun:$PATH"
```

### Caché y Archivos Temporales

Todos los archivos generados durante la compilación se almacenan en `$HOME/tmp`:
- `.zig-cache` → `$HOME/tmp/zig-cache`
- `zig-out` → `$HOME/tmp/zig-out`
- Binarios temporales → `$HOME/tmp`

Esto mantiene el directorio del proyecto limpio.

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 👤 Autor

- **Edison Manrique Chocce**
- Email: edison.manrique.chocce@gmail.com
- GitHub: [@edison-manrique](https://github.com/edison-manrique)

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 🔗 Recursos Adicionales

- [Documentación Oficial de Zig](https://ziglang.org/documentation/)
- [Zig Learn](https://ziglearn.org/)
- [Zig Github](https://github.com/ziglang/zig)
- [Zig Discord](https://discord.gg/zig)

## ✅ Estado del Proyecto

- [x] Todos los módulos ejecutándose correctamente
- [x] Tests pasando
- [x] Build system configurado
- [x] Documentación básica
- [ ] Ejercicios prácticos (en progreso)
- [ ] Proyectos finales (pendiente)
- [ ] Video tutoriales (pendiente)

---

¡Happy Coding! 🦀✨
