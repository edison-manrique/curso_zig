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
        .{ .path = "src/ejemplos_extra/24_builtins_1.zig", .name = "24_builtins_1", .link_libc = false },
        .{ .path = "src/ejemplos_extra/25_builtins_2.zig", .name = "25_builtins_2", .link_libc = false },
        .{ .path = "src/ejemplos_extra/26_builtins_3.zig", .name = "26_builtins_3", .link_libc = false },
        .{ .path = "src/ejemplos_extra/27_builtins_4.zig", .name = "27_builtins_4", .link_libc = false },
        .{ .path = "src/ejemplos_extra/28_builtins_5.zig", .name = "28_builtins_5", .link_libc = false },
        .{ .path = "src/ejemplos_extra/29_builtins_6.zig", .name = "29_builtins_6", .link_libc = false },
        .{ .path = "src/ejemplos_extra/30_builtins_7.zig", .name = "30_builtins_7", .link_libc = false },
        .{ .path = "src/ejemplos_extra/31_builtins_8.zig", .name = "31_builtins_8", .link_libc = false },
        .{ .path = "src/ejemplos_extra/32_builtins_9.zig", .name = "32_builtins_9", .link_libc = false },
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
