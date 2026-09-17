const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Lista de todos los archivos del curso
    const course_files = [_][]const u8{
        "01_variables.zig",
        "02_funciones.zig",
        "03_bucles.zig",
        "04_punteros.zig",
        "05_structs.zig",
        "06_enums.zig",
        "07_union.zig",
        "08_memoria.zig",
        "09_strings.zig",
        "10_errores.zig",
        "11_comptime.zig",
        "12_genericos.zig",
        "13_tiempo_vida.zig",
        "14_iteradores_personalizados.zig",
        "15_modulos.zig",
        "16_punteros_inteligentes.zig",
        "17_concurrencia.zig",
        "18_comentarios.zig",
        "19_identificadores.zig",
        "20_operadores.zig",
        "21_arreglos.zig",
        "22_vectores.zig",
        "23_test.zig",
        "24_builtins_1.zig",
        "25_builtins_2.zig",
        "26_builtins_3.zig",
        "27_builtins_4.zig",
        "28_builtins_5.zig",
        "29_builtins_6.zig",
        "30_builtins_7.zig",
        "31_builtins_8.zig",
        "32_builtins_9.zig",
        "33_formato.zig",
        "34_tiempo.zig",
        "35_bitwise.zig",
        "36_ffi.zig",
        "37_asm.zig",
        "38_wasm.zig",
        "39_build_modes.zig",
        "40_rls.zig",
        "41_archivos.zig",
    };

    // Obtener nombre del archivo fuente desde argumentos o usar default
    const src_file = b.option([]const u8, "src", "Archivo fuente a compilar") orelse "01_variables.zig";

    const root_module = b.createModule(.{
        .root_source_file = b.path(src_file),
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
    for (course_files, 0..) |file, idx| {
        const step_name = b.fmt("run_{d}", .{idx + 1});
        const step_desc = b.fmt("Ejecutar {s}", .{file});

        const file_module = b.createModule(.{
            .root_source_file = b.path(file),
            .target = target,
            .optimize = optimize,
            .link_libc = (idx == 35), // El modulo 36 (FFI) requiere linking con libc
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
    for (course_files, 0..) |file, idx| {
        const file_module = b.createModule(.{
            .root_source_file = b.path(file),
            .target = target,
            .optimize = optimize,
            .link_libc = (idx == 35), // El modulo 36 (FFI) requiere linking con libc
        });

        const file_exe = b.addExecutable(.{
            .name = b.fmt("curso_all_{d}", .{idx + 1}),
            .root_module = file_module,
        });

        const file_run = b.addRunArtifact(file_exe);
        all_step.dependOn(&file_run.step);
    }
}
