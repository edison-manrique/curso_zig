// =========================================================================================
// MASTERCLASS: TRIGONOMETRIA, EXPONENCIALES Y REDONDEO FPU (ZIG 0.16.0)
// =========================================================================================
//
// CONTENIDO DE LA MASTERCLASS (15 Builtins cubiertos):
// 1. Trigonometria y Exponenciales: @sin, @cos, @tan, @exp, @exp2, @log, @log2, @log10.
// 2. Algebra de Precision y Redondeo: @sqrt, @abs, @floor, @ceil, @trunc, @round.
// 3. Matematicas Seguras de CPU: @subWithOverflow (Resta con overflow controlado).
//
// Todo el codigo esta en ASCII puro para compatibilidad universal con terminales.
// =========================================================================================

const std = @import("std");
const builtin = @import("builtin");

// =========================================================================================
// ZIG 0.16.0 "JUICY MAIN" - ENTRY POINT
// =========================================================================================
pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [16384]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;

    defer stdout.flush() catch {};

    try imprimirCabecera(stdout);

    try modulo1_TrigonometriaYLogaritmos(stdout);
    try modulo2_AlgebraYRedondeo(stdout);
    try modulo3_MatematicasDeSistema(stdout);

    try imprimirCierre(stdout);
}

// =========================================================================================
// MODULO 1: TRIGONOMETRIA Y LOGARITMOS DE HARDWARE
// =========================================================================================
fn modulo1_TrigonometriaYLogaritmos(stdout: anytype) !void {
    try stdout.print(">> Modulo 1: Trigonometria y Logaritmos Acelerados por FPU\n", .{});

    // Todas estas funciones se traducen a una sola instruccion nativa del procesador
    // (ej. FCOS, FSIN en x86 o instrucciones NEON/VFP en ARM) si la CPU lo soporta.
    // Trabajan sobre flotantes o vectores de flotantes.

    const pi_medio: f32 = 1.57079632; // Aproximadamente pi/2 en radianes

    // 1. Trigonometria
    const sen = @sin(pi_medio);
    const cos = @cos(pi_medio);
    const tg = @tan(@as(f32, 0.78539816)); // pi/4 radianes = 45 grados (tangente debe ser ~1.0)

    try stdout.print("  [Trig] sin(pi/2): {d:.4} | cos(pi/2): {d:.4} | tan(pi/4): {d:.4}\n", .{ sen, cos, tg });

    // 2. Exponenciales
    const exp_natural = @exp(@as(f32, 1.0)); // e^1 (Constante de Euler ~2.7182)
    const exp_base2 = @exp2(@as(f32, 3.0)); // 2^3 = 8.0

    try stdout.print("  [Exp] exp(1.0) (e^1): {d:.4} | exp2(3.0) (2^3): {d:.1}\n", .{ exp_natural, exp_base2 });

    // 3. Logaritmos
    const log_natural = @log(exp_natural); // ln(e) = 1.0
    const log_b2 = @log2(exp_base2); // log2(8) = 3.0
    const log_b10 = @log10(@as(f32, 100.0)); // log10(100) = 2.0

    try stdout.print("  [Log] log(e) (ln): {d:.1} | log2(8): {d:.1} | log10(100): {d:.1}\n\n", .{ log_natural, log_b2, log_b10 });
}

// =========================================================================================
// MODULO 2: ALGEBRA DE PRECISION Y REDONDEO FPU
// =========================================================================================
fn modulo2_AlgebraYRedondeo(stdout: anytype) !void {
    try stdout.print(">> Modulo 2: Algebra de Precision y Modos de Redondeo\n", .{});

    // 1. @sqrt: Raiz cuadrada acelerada por hardware (ej. SQRTSS en x86)
    const raiz = @sqrt(@as(f32, 16.0));
    try stdout.print("  Raiz cuadrada de 16.0 (@sqrt): {d:.1}\n", .{raiz});

    // 2. @abs: Valor absoluto.
    // NOTA DE SEGURIDAD EXTREMA: Para tipos enteros firmados (como i32), @abs devuelve
    // un entero SIN FIRMA del mismo ancho de bits (u32). Esto garantiza matematicamente
    // que la operacion NUNCA desborde (ya que en enteros firmados, abs(MIN_INT) no cabe
    // en el propio rango firmado, pero si cabe en el rango no firmado correspondiente).
    const entero_firmado: i32 = -12345;
    const abs_entero: u32 = @abs(entero_firmado); // Devuelve u32 de forma segura sin overflow!

    const flotante_negativo: f32 = -3.1415;
    const abs_flotante = @abs(flotante_negativo);

    try stdout.print("  @abs de i32 (-12345): {d} (Tipo devuelto: {any})\n", .{ abs_entero, @TypeOf(abs_entero) });
    try stdout.print("  @abs de f32 (-3.1415): {d:.4}\n", .{abs_flotante});

    // 3. Diferencias Criticas de Redondeo FPU:
    const valor_muestra: f32 = 1.6;
    const valor_negativo: f32 = -1.6;

    // @floor: El entero mas grande no mayor al numero (Rounds down)
    const f = @floor(valor_muestra); // 1.0
    const f_neg = @floor(valor_negativo); // -2.0

    // @ceil: El entero mas pequeno no menor al numero (Rounds up)
    const c = @ceil(valor_muestra); // 2.0
    const c_neg = @ceil(valor_negativo); // -1.0

    // @trunc: Descarta los decimales, redondeando hacia cero (Rounds toward zero)
    const t = @trunc(valor_muestra); // 1.0
    const t_neg = @trunc(valor_negativo); // -1.0

    // @round: Redondea al entero mas cercano. En caso de empate (.5), redondea lejos de cero
    const r1 = @round(@as(f32, 1.4)); // 1.0
    const r2 = @round(@as(f32, 1.5)); // 2.0 (Empate, se aleja de cero)
    const r3 = @round(@as(f32, -2.5)); // -3.0 (Empate, se aleja de cero hacia -inf)

    try stdout.print("  Modos de Redondeo FPU:\n", .{});
    try stdout.print("    @floor de 1.6: {d:.1}  | @floor de -1.6: {d:.1}\n", .{ f, f_neg });
    try stdout.print("    @ceil de 1.6: {d:.1}   | @ceil de -1.6: {d:.1}\n", .{ c, c_neg });
    try stdout.print("    @trunc de 1.6: {d:.1}  | @trunc de -1.6: {d:.1}\n", .{ t, t_neg });
    try stdout.print("    @round de 1.4: {d:.1}  | @round de 1.5: {d:.1} | @round de -2.5: {d:.1}\n\n", .{ r1, r2, r3 });
}

// =========================================================================================
// MODULO 3: MATEMATICAS DE SISTEMA (@subWithOverflow)
// =========================================================================================
fn modulo3_MatematicasDeSistema(stdout: anytype) !void {
    try stdout.print(">> Modulo 3: Restas con Control de Desbordamiento por Hardware\n", .{});

    // Al igual que @addWithOverflow y @mulWithOverflow, @subWithOverflow realiza la resta (a - b)
    // de manera segura en un solo ciclo de CPU, capturando si ocurrio un desbordamiento inferior (underflow).
    // Retorna una tupla: { resultado_truncado, bit_de_desbordamiento }

    const a: u8 = 10;
    const b: u8 = 20;

    const resultado_tupla = @subWithOverflow(a, b); // 10 - 20 = -10 (Desborda u8 ya que el minimo es 0)

    const valor_truncado = resultado_tupla[0]; // Equivale a -10 interpretado en binario de complemento a dos (246)
    const hubo_overflow = resultado_tupla[1] == 1;

    try stdout.print("  Operacion u8: {d} - {d}\n", .{ a, b });
    try stdout.print("  Resultado truncado (u8): {d}\n", .{valor_truncado});
    try stdout.print("  Hubo Desbordamiento (Underflow)? {s}\n\n", .{if (hubo_overflow) "SI" else "NO"});
}

// =========================================================================================
// UTILIDADES DE IMPRESION
// =========================================================================================
fn imprimirCabecera(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\     ___ _   _ ___ _  _____ ___ _  _ ___ 
        \\    | _ ) | | |_ _| |__   _|_ _| \| / __|
        \\    | _ \ |_| || || |__| |  | || .` \__ \
        \\    |___/\___/|___|____|_| |___|_|\_|___/
        \\                                                            
        \\    MASTERCLASS 15: TRIGONOMETRIA Y REDONDEO FPU (ZIG 0.16.0)
        \\====================================================================
        \\
    , .{});
}

fn imprimirCierre(stdout: anytype) !void {
    try stdout.print(
        \\====================================================================
        \\ FIN DE LA MASTERCLASS.
        \\====================================================================
        \\ CONCEPTOS CLAVE REPASADOS:
        \\ - Las operaciones trigonometricas y exponenciales explotan el hardware FPU.
        \\ - @abs de enteros devuelve un tipo No Firmado para imposibilitar el overflow.
        \\ - @floor, @ceil, @trunc y @round son mapeados a instrucciones asm de redondeo.
        \\ - @subWithOverflow detecta de manera segura restas invalidas en bajo nivel.
        \\====================================================================
        \\
    , .{});
}
