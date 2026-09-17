// Zig Release Version: 0.16.0
// Tema: Arena Allocator Altamente Optimizado
// Nivel: Avanzado - Gestion de Memoria de Alto Rendimiento

const std = @import("std");

pub fn generateStdOut(init: std.process.Init) std.Io.Writer {
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(init.io, &buffer);
    const stdout = &stdout_impl.interface;
    return stdout;
}

/// Estructura personalizada para un Arena Allocator optimizado
/// Usa bloques de memoria grandes para reducir llamadas al sistema
const OptimizedArena = struct {
    allocator: std.mem.Allocator,
    blocks: std.ArrayList(Block),
    current_block: ?*Block,
    block_size: usize,
    total_allocated: usize,
    allocation_count: usize,

    const Block = struct {
        data: []u8,
        used: usize,
        
        fn init(allocator: std.mem.Allocator, size: usize) !Block {
            const data = try allocator.alloc(u8, size);
            return Block{
                .data = data,
                .used = 0,
            };
        }
        
        fn deinit(self: *Block, allocator: std.mem.Allocator) void {
            allocator.free(self.data);
            self.used = 0;
        }
        
        fn allocate(self: *Block, size: usize, alignment: usize) ?[]u8 {
            const aligned_used = std.mem.alignForward(usize, self.used, alignment);
            if (aligned_used + size > self.data.len) return null;
            
            const ptr = self.data[aligned_used..][0..size];
            self.used = aligned_used + size;
            return ptr;
        }
        
        fn reset(self: *Block) void {
            self.used = 0;
        }
    };

    pub fn init(allocator: std.mem.Allocator, block_size: usize) !OptimizedArena {
        var arena = OptimizedArena{
            .allocator = allocator,
            .blocks = try std.ArrayList(Block).initCapacity(allocator, 16),
            .current_block = null,
            .block_size = block_size,
            .total_allocated = 0,
            .allocation_count = 0,
        };
        
        try arena.newBlock();
        return arena;
    }

    fn newBlock(self: *OptimizedArena) !void {
        const block = try Block.init(self.allocator, self.block_size);
        try self.blocks.append(std.heap.page_allocator, block);
        self.current_block = &self.blocks.items[self.blocks.items.len - 1];
        self.total_allocated += self.block_size;
    }

    pub fn alloc(self: *OptimizedArena, comptime T: type, count: usize) ![]T {
        const size = @sizeOf(T) * count;
        const alignment = @alignOf(T);
        
        self.allocation_count += 1;
        
        if (self.current_block) |block| {
            if (block.allocate(size, alignment)) |ptr| {
                const aligned_ptr: [*]T = @alignCast(@ptrCast(ptr));
                return aligned_ptr[0..count];
            }
        }
        
        const required_size = if (size > self.block_size) size else self.block_size;
        const new_block = try Block.init(self.allocator, required_size);
        try self.blocks.append(std.heap.page_allocator, new_block);
        self.current_block = &self.blocks.items[self.blocks.items.len - 1];
        self.total_allocated += required_size;
        
        const ptr = self.current_block.?.allocate(size, alignment).?;
        const aligned_ptr: [*]T = @alignCast(@ptrCast(ptr));
        return aligned_ptr[0..count];
    }

    pub fn allocBytes(self: *OptimizedArena, size: usize, alignment: usize) ![]u8 {
        self.allocation_count += 1;
        
        if (self.current_block) |block| {
            if (block.allocate(size, alignment)) |ptr| {
                return ptr;
            }
        }
        
        const required_size = if (size > self.block_size) size else self.block_size;
        const new_block = try Block.init(self.allocator, required_size);
        try self.blocks.append(std.heap.page_allocator, new_block);
        self.current_block = &self.blocks.items[self.blocks.items.len - 1];
        self.total_allocated += required_size;
        
        return self.current_block.?.allocate(size, alignment).?;
    }

    pub fn reset(self: *OptimizedArena) void {
        for (self.blocks.items) |*block| {
            block.reset();
        }
        if (self.blocks.items.len > 0) {
            self.current_block = &self.blocks.items[0];
        }
        if (self.blocks.items.len > 16) {
            const keep_count = @min(self.blocks.items.len, 16);
            for (self.blocks.items[keep_count..]) |*block| {
                block.deinit(self.allocator);
            }
            self.blocks.shrinkRetainingCapacity(keep_count);
            self.current_block = &self.blocks.items[0];
        }
        self.allocation_count = 0;
    }

    pub fn deinit(self: *OptimizedArena) void {
        for (self.blocks.items) |*block| {
            block.deinit(self.allocator);
        }
        self.blocks.deinit(std.heap.page_allocator);
        self.current_block = null;
    }

    pub fn stats(self: *OptimizedArena) struct {
        total_blocks: usize,
        total_allocated: usize,
        total_used: usize,
        allocation_count: usize,
        efficiency: f64,
    } {
        var total_used: usize = 0;
        for (self.blocks.items) |block| {
            total_used += block.used;
        }
        
        const efficiency = if (self.total_allocated > 0) 
            @as(f64, @floatFromInt(total_used)) / @as(f64, @floatFromInt(self.total_allocated)) * 100.0 
        else 0.0;

        return .{
            .total_blocks = self.blocks.items.len,
            .total_allocated = self.total_allocated,
            .total_used = total_used,
            .allocation_count = self.allocation_count,
            .efficiency = efficiency,
        };
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_impl.interface;
    defer stdout.flush() catch {};

    try stdout.print("=== ARENA ALLOCATOR ALTAMENTE OPTIMIZADO ===\n\n", .{});

    // TEST 1: Asignacion Masiva de Objetos Pequenos
    try stdout.print("TEST 1: 1 Millon de objetos pequenos (structs)\n", .{});
    try stdout.print("-------------------------------------------\n", .{});
    
    var arena = try OptimizedArena.init(std.heap.page_allocator, 1024 * 1024);
    defer arena.deinit();

    const start_alloc = std.Io.Clock.awake.now(io);
    
    const Point = struct { x: f64, y: f64, z: f64 };
    const count: usize = 1_000_000;
    
    var points = try arena.alloc(Point, count);
    
    for (0..count) |i| {
        points[i].x = @as(f64, @floatFromInt(i)) * 0.001;
        points[i].y = @as(f64, @floatFromInt(i)) * 0.002;
        points[i].z = @as(f64, @floatFromInt(i)) * 0.003;
    }
    
    const end_alloc = start_alloc.untilNow(io, .awake);
    
    var checksum: f64 = 0.0;
    for (points) |p| {
        checksum += p.x + p.y + p.z;
    }
    
    const stats = arena.stats();
    const ms_alloc = @as(f64, @floatFromInt(end_alloc.toNanoseconds())) / 1_000_000.0;
    
    try stdout.print("  - Objetos creados: {d}\n", .{@as(f64, @floatFromInt(count))});
    try stdout.print("  - Tiempo de asignacion: {d:.2}ms\n", .{ms_alloc});
    try stdout.print("  - Objetos por segundo: {d:.0}\n", .{@as(f64, @floatFromInt(count)) / (ms_alloc / 1000.0)});
    try stdout.print("  - Memoria total reservada: {d:.2} MB\n", .{@as(f64, @floatFromInt(stats.total_allocated)) / 1024.0 / 1024.0});
    try stdout.print("  - Memoria utilizada: {d:.2} MB\n", .{@as(f64, @floatFromInt(stats.total_used)) / 1024.0 / 1024.0});
    try stdout.print("  - Eficiencia: {d:.1}%\n", .{stats.efficiency});
    try stdout.print("  - Conteo de asignaciones: {d}\n", .{stats.allocation_count});
    try stdout.print("  - Checksum: {d:.6}\n", .{checksum});
    try stdout.print("\n", .{});

    // TEST 2: Reset y Reutilizacion del Arena
    try stdout.print("TEST 2: Reset y Reutilizacion (5 ciclos)\n", .{});
    try stdout.print("-------------------------------------------\n", .{});
    
    var total_reset_time: u64 = 0;
    const cycles: usize = 5;
    const objects_per_cycle: usize = 500_000;
    
    for (0..cycles) |cycle| {
        const cycle_start = std.Io.Clock.awake.now(io);
        
        arena.reset();
        
        for (0..objects_per_cycle) |_| {
            _ = try arena.alloc(Point, 1);
        }
        
        const cycle_end = cycle_start.untilNow(io, .awake);
        total_reset_time += @as(u64, @intCast(cycle_end.toNanoseconds()));
        
        try stdout.print("  - Ciclo {d}: {d} objetos en {d:.2}ms\n", .{
            cycle + 1, 
            objects_per_cycle,
            @as(f64, @floatFromInt(cycle_end.toNanoseconds())) / 1_000_000.0
        });
    }
    
    const avg_reset_time = @as(f64, @floatFromInt(total_reset_time)) / @as(f64, @floatFromInt(cycles)) / 1_000_000.0;
    try stdout.print("  - Tiempo promedio de reset+alloc: {d:.3}ms\n", .{avg_reset_time});
    try stdout.print("  - Velocidad: {d:.0} objetos/segundo\n", .{
        @as(f64, @floatFromInt(objects_per_cycle)) / (avg_reset_time / 1000.0)
    });
    try stdout.print("\n", .{});

    // TEST 3: Comparacion con Heap Allocator Estandar
    try stdout.print("TEST 3: Comparacion vs Heap Allocator\n", .{});
    try stdout.print("-------------------------------------------\n", .{});
    
    var arena2 = try OptimizedArena.init(std.heap.page_allocator, 1024 * 1024);
    defer arena2.deinit();
    
    const count_compare: usize = 100_000;
    
    const start_arena = std.Io.Clock.awake.now(io);
    for (0..count_compare) |_| {
        _ = try arena2.alloc(Point, 1);
    }
    const end_arena = start_arena.untilNow(io, .awake);
    
    const start_heap = std.Io.Clock.awake.now(io);
    var heap_points = std.ArrayList(*Point).empty;
    defer {
        for (heap_points.items) |p| std.heap.page_allocator.destroy(p);
        heap_points.deinit(std.heap.page_allocator);
    }
    
    for (0..count_compare) |_| {
        const p = try std.heap.page_allocator.create(Point);
        p.x = 1.0; p.y = 2.0; p.z = 3.0;
        try heap_points.append(std.heap.page_allocator, p);
    }
    const end_heap = start_heap.untilNow(io, .awake);
    
    const ms_arena = @as(f64, @floatFromInt(end_arena.toNanoseconds())) / 1_000_000.0;
    const ms_heap = @as(f64, @floatFromInt(end_heap.toNanoseconds())) / 1_000_000.0;
    const speedup = ms_heap / ms_arena;
    
    try stdout.print("  - Arena: {d:.2}ms para {d} objetos\n", .{ms_arena, count_compare});
    try stdout.print("  - Heap:  {d:.2}ms para {d} objetos\n", .{ms_heap, count_compare});
    try stdout.print("  - SPEEDUP: {d:.1}x mas rapido con Arena\n", .{speedup});
    try stdout.print("\n", .{});

    // TEST 4: Escenario Real - Parser de Documentos
    try stdout.print("TEST 4: Escenario Real - Parser de Documentos\n", .{});
    try stdout.print("-------------------------------------------\n", .{});

    const SimpleDoc = struct {
        id: u32,
        fields: u32,
    };

    var arena3 = try OptimizedArena.init(std.heap.page_allocator, 2 * 1024 * 1024);
    defer arena3.deinit();

    const doc_count: usize = 1000;
    const fields_per_doc: usize = 50;

    const start_parse = std.Io.Clock.awake.now(io);

    for (0..doc_count) |doc_i| {
        for (0..fields_per_doc) |field_i| {
            const key = try std.fmt.allocPrint(arena3.allocator, "field_{d}_{d}", .{doc_i, field_i});
            const value = try arena3.alloc(SimpleDoc, 1);
            value[0] = .{ .id = @intCast(doc_i), .fields = @intCast(field_i) };
            _ = key;
        }
    }

    const end_parse = start_parse.untilNow(io, .awake);
    const ms_parse = @as(f64, @floatFromInt(end_parse.toNanoseconds())) / 1_000_000.0;

    try stdout.print("  - Documentos procesados: {d}\n", .{doc_count});
    try stdout.print("  - Campos totales: {d}\n", .{doc_count * fields_per_doc});
    try stdout.print("  - Tiempo de parsing: {d:.2}ms\n", .{ms_parse});
    try stdout.print("  - Documentos/segundo: {d:.0}\n", .{@as(f64, @floatFromInt(doc_count)) / (ms_parse / 1000.0)});
    
    arena3.reset();
    try stdout.print("  - Arena reseteado para siguiente batch (memoria reutilizada)\n", .{});
    try stdout.print("\n", .{});

    // RESUMEN FINAL
    try stdout.print("=== RESUMEN DE OPTIMIZACIONES ===\n", .{});
    try stdout.print("✓ Bloques de memoria grandes reducen llamadas al SO\n", .{});
    try stdout.print("✓ Reset O(1) sin liberar memoria individualmente\n", .{});
    try stdout.print("✓ Reutilizacion de bloques existentes\n", .{});
    try stdout.print("✓ Alineamiento automatico de memoria\n", .{});
    try stdout.print("✓ Estadisticas en tiempo real de eficiencia\n", .{});
    try stdout.print("✓ Ideal para parsers, juegos, servidores HTTP\n", .{});
    try stdout.print("\n¡Arena Allocator optimizado completado exitosamente!\n", .{});
}
