const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Lista de todos los archivos del curso con sus rutas actualizadas
    const course_files = [_]struct {
        path: []const u8,
        name: []const u8,
        link_libc: bool,
    }{
        .{ .path = "src/nivel_1_basico/01_variables.zig", .name = "01_variables", .link_libc = false },
        .{ .path = "src/nivel_1_basico/02_funciones.zig", .name = "02_funciones", .link_libc = false },
        .{ .path = "src/nivel_1_basico/03_bucles.zig", .name = "03_bucles", .link_libc = false },
        .{ .path = "src/nivel_1_basico/04_punteros.zig", .name = "04_punteros", .link_libc = false },
        .{ .path = "src/nivel_2_intermedio/05_structs.zig", .name = "05_structs", .link_libc = false },
        .{ .path = "src/nivel_2_intermedio/06_enums.zig", .name = "06_enums", .link_libc = false },
        .{ .path = "src/nivel_2_intermedio/07_union.zig", .name = "07_union", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/08_memoria.zig", .name = "08_memoria", .link_libc = false },
        .{ .path = "src/nivel_2_intermedio/09_strings.zig", .name = "09_strings", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/10_errores.zig", .name = "10_errores", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/11_comptime.zig", .name = "11_comptime", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/12_genericos.zig", .name = "12_genericos", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/13_tiempo_vida.zig", .name = "13_tiempo_vida", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/14_iteradores_personalizados.zig", .name = "14_iteradores", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/15_modulos.zig", .name = "15_modulos", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/16_punteros_inteligentes.zig", .name = "16_punteros_inteligentes", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/17_concurrencia.zig", .name = "17_concurrencia", .link_libc = false },
        .{ .path = "src/nivel_1_basico/18_comentarios.zig", .name = "18_comentarios", .link_libc = false },
        .{ .path = "src/nivel_1_basico/19_identificadores.zig", .name = "19_identificadores", .link_libc = false },
        .{ .path = "src/nivel_1_basico/20_operadores.zig", .name = "20_operadores", .link_libc = false },
        .{ .path = "src/nivel_2_intermedio/21_arreglos.zig", .name = "21_arreglos", .link_libc = false },
        .{ .path = "src/nivel_2_intermedio/22_vectores.zig", .name = "22_vectores", .link_libc = false },
        .{ .path = "src/nivel_3_avanzado/23_test.zig", .name = "23_test", .link_libc = false },
        // Builtins - Matematicos
        .{ .path = "src/ejemplos_extra/builtins/matematicos/01_abs.zig", .name = "builtin_01_abs", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/matematicos/02_sqrt.zig", .name = "builtin_02_sqrt", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/matematicos/03_sin_cos.zig", .name = "builtin_03_sin_cos", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/matematicos/04_pow.zig", .name = "builtin_04_pow", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/matematicos/05_log.zig", .name = "builtin_05_log", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/matematicos/06_floor_ceil.zig", .name = "builtin_06_floor_ceil", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/matematicos/07_min_max.zig", .name = "builtin_07_min_max", .link_libc = false },
        // Builtins - Bitwise
        .{ .path = "src/ejemplos_extra/builtins/bitwise/08_bswap.zig", .name = "builtin_08_bswap", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/bitwise/09_bit_reverse.zig", .name = "builtin_09_bit_reverse", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/bitwise/10_popcount.zig", .name = "builtin_10_popcount", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/bitwise/11_leading_zeros.zig", .name = "builtin_11_leading_zeros", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/bitwise/12_trailing_zeros.zig", .name = "builtin_12_trailing_zeros", .link_libc = false },
        // Builtins - Memoria
        .{ .path = "src/ejemplos_extra/builtins/memoria/13_memcpy.zig", .name = "builtin_13_memcpy", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/memoria/14_memset.zig", .name = "builtin_14_memset", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/memoria/15_memcmp.zig", .name = "builtin_15_memcmp", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/memoria/16_align_of.zig", .name = "builtin_16_align_of", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/memoria/17_size_of.zig", .name = "builtin_17_size_of", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/memoria/18_offset_of.zig", .name = "builtin_18_offset_of", .link_libc = false },
        // Builtins - Atomicos
        .{ .path = "src/ejemplos_extra/builtins/atomicos/19_atomic_load.zig", .name = "builtin_19_atomic_load", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/atomicos/20_atomic_store.zig", .name = "builtin_20_atomic_store", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/atomicos/21_atomic_rmw.zig", .name = "builtin_21_atomic_rmw", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/atomicos/22_fence.zig", .name = "builtin_22_fence", .link_libc = false },
        // Builtins - Sistema
        .{ .path = "src/ejemplos_extra/builtins/sistema/23_return_address.zig", .name = "builtin_23_return_address", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/sistema/24_prefetch.zig", .name = "builtin_24_prefetch", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/sistema/25_trap.zig", .name = "builtin_25_trap", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/sistema/26_unreachable.zig", .name = "builtin_26_unreachable", .link_libc = false },
        .{ .path = "src/ejemplos_extra/builtins/sistema/27_compile_time.zig", .name = "builtin_27_compile_time", .link_libc = false },
        // Ejemplos Extra
        .{ .path = "src/ejemplos_extra/28_medicion_tiempo.zig", .name = "28_medicion_tiempo", .link_libc = false },
        .{ .path = "src/ejemplos_extra/arena.zig", .name = "51_arena", .link_libc = false },
        .{ .path = "src/nivel_2_intermedio/33_formato.zig", .name = "33_formato", .link_libc = false },
        .{ .path = "src/ejemplos_extra/34_tiempo.zig", .name = "34_tiempo", .link_libc = false },
        .{ .path = "src/ejemplos_extra/35_bitwise.zig", .name = "35_bitwise", .link_libc = false },
        .{ .path = "src/ejemplos_extra/36_ffi.zig", .name = "36_ffi", .link_libc = true },
        .{ .path = "src/ejemplos_extra/37_asm.zig", .name = "37_asm", .link_libc = false },
        .{ .path = "src/ejemplos_extra/38_wasm.zig", .name = "38_wasm", .link_libc = false },
        .{ .path = "src/ejemplos_extra/39_build_modes.zig", .name = "39_build_modes", .link_libc = false },
        .{ .path = "src/ejemplos_extra/40_rls.zig", .name = "40_rls", .link_libc = false },
        .{ .path = "src/ejemplos_extra/41_archivos.zig", .name = "41_archivos", .link_libc = false },
    };

    // Obtener nombre del archivo fuente desde argumentos o usar default
    const src_file_arg = b.option([]const u8, "src", "Archivo fuente a compilar") orelse "src/nivel_1_basico/01_variables.zig";

    const root_module = b.createModule(.{
        .root_source_file = b.path(src_file_arg),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "curso",
        .root_module = root_module,
    });

    b.installArtifact(exe);

    // Crear step para ejecutar
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Ejecutar el programa");
    run_step.dependOn(&run_cmd.step);

    // Crear steps individuales para cada archivo del curso
    for (course_files, 0..) |file_info, idx| {
        const step_name = b.fmt("run_{d}", .{idx + 1});
        const step_desc = b.fmt("Ejecutar {s}", .{file_info.name});

        const file_module = b.createModule(.{
            .root_source_file = b.path(file_info.path),
            .target = target,
            .optimize = optimize,
            .link_libc = file_info.link_libc,
        });

        const file_exe = b.addExecutable(.{
            .name = b.fmt("curso_{d}", .{idx + 1}),
            .root_module = file_module,
        });

        const file_run = b.addRunArtifact(file_exe);
        const file_step = b.step(step_name, step_desc);
        file_step.dependOn(&file_run.step);
    }

    // Step para ejecutar todos
    const all_step = b.step("all", "Ejecutar todos los archivos del curso");
    for (course_files, 0..) |file_info, idx| {
        const file_module = b.createModule(.{
            .root_source_file = b.path(file_info.path),
            .target = target,
            .optimize = optimize,
            .link_libc = file_info.link_libc,
        });

        const file_exe = b.addExecutable(.{
            .name = b.fmt("curso_all_{d}", .{idx + 1}),
            .root_module = file_module,
        });

        const file_run = b.addRunArtifact(file_exe);
        all_step.dependOn(&file_run.step);
    }
}
