// =========================================================================
// ARCHIVO LOCAL: _15_helper.zig (Modulo Auxiliar de Soporte)
// =========================================================================
// Este archivo es tratado como un struct implicito en tiempo de compilacion.
// Solo aquellos miembros precedidos por 'pub' seran accesibles externamente.

const std = @import("std");

// Constante publica accesible desde cualquier archivo que nos importe
pub const VERSION = "1.0.0-Helper";

// Una estructura publica. Sus funciones tambien deben ser 'pub' para ser usables.
pub const Calculadora = struct {
    pub fn sumar(a: i32, b: i32) i32 {
        return a + b;
    }

    pub fn restar(a: i32, b: i32) i32 {
        return a - b;
    }
};

// Al no tener la palabra clave 'pub', esta funcion es privada.
// Intentar invocarla desde fuera de este archivo generara un error de compilacion.
fn funcionPrivada() void {
    // Logica oculta encapsulada dentro del modulo
}
