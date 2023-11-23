const std = @import("std");
const Bencher = @import("bencher.zig").Bencher;

const dim = 2;
const Vec = @Vector(dim, f32);

fn dot(u: Vec, v: Vec) f32 {
    return @reduce(.Add, u * v);
}

fn rocketEase(x0: Vec, x1: Vec, v0: Vec, v1: Vec, t_total: f32, t: f32) Vec {
    const vec_t: Vec = @splat(t);

    if (t < 0.0) {
        return x0 + vec_t * v0;
    }

    const vec_T: Vec = @splat(t_total);
    if (t > t_total) {
        return x1 + (vec_t - vec_T) * v1;
    }

    const vec_2: Vec = @splat(2.0);

    const dx = x1 - x0;
    const w = vec_T * (v0 + v1) - vec_2 * dx;
    const y = dot(v1 - v0, w);
    const a = 2.0 * t_total * y;
    const b = -4.0 * dot(vec_T * v1 - dx, w);
    const c = dot(w, w);
    const d = 4.0 * (c * c + t_total * t_total * y * y);

    if (a == 0 and b == 0) {
        return x0 + vec_t * v0;
    }

    const delta = if (a != 0) (-b - @sqrt(d)) / (2.0 * a) else -c / b;

    const vec_half: Vec = @splat(0.5);

    if (t < delta * t_total) {
        const fv1: Vec = @splat((delta - 1) / (t_total * delta));
        const fv0: Vec = @splat(-(delta + 1) / (t_total * delta));
        const fdx: Vec = @splat(2 / (t_total * t_total * delta));

        const a0 = fv1 * v1 + fv0 * v0 + fdx * dx;

        return x0 + vec_t * v0 + vec_half * vec_t * vec_t * a0;
    } else {
        const vec_tp = vec_t - vec_T;

        const fv1: Vec = @splat((2 - delta) / (t_total * (1 - delta)));
        const fv0: Vec = @splat(delta / (t_total * (1 - delta)));
        const fdx: Vec = @splat(-2 / (t_total * t_total * (1 - delta)));

        const a1 = fv1 * v1 + fv0 * v0 + fdx * dx;

        return x1 + vec_tp * v1 + vec_half * vec_tp * vec_tp * a1;
    }
}

fn rocketEaseAccs(x0: Vec, x1: Vec, v0: Vec, v1: Vec, t_total: f32) struct { Vec, Vec, f32 } {
    const vec_T: Vec = @splat(t_total);
    const vec_2: Vec = @splat(2.0);

    const dx = x1 - x0;
    const w = vec_T * (v0 + v1) - vec_2 * dx;
    const y = dot(v1 - v0, w);
    const a = 2.0 * t_total * y;
    const b = -4.0 * dot(vec_T * v1 - dx, w);
    const c = dot(w, w);
    const d = 4.0 * (c * c + t_total * t_total * y * y);

    if (a == 0 and b == 0) {
        const vec_0: Vec = @splat(0);
        return .{ vec_0, vec_0, 0.0 };
    }

    const delta = if (a != 0) (-b - @sqrt(d)) / (2.0 * a) else -c / b;

    const a0 = blk: {
        const fv1: Vec = @splat((delta - 1) / (t_total * delta));
        const fv0: Vec = @splat(-(delta + 1) / (t_total * delta));
        const fdx: Vec = @splat(2 / (t_total * t_total * delta));

        break :blk fv1 * v1 + fv0 * v0 + fdx * dx;
    };

    const a1 = blk: {
        const fv1: Vec = @splat((2 - delta) / (t_total * (1 - delta)));
        const fv0: Vec = @splat(delta / (t_total * (1 - delta)));
        const fdx: Vec = @splat(-2 / (t_total * t_total * (1 - delta)));

        break :blk fv1 * v1 + fv0 * v0 + fdx * dx;
    };

    return .{ a0, a1, delta };
}

fn rocketEaseWithAccs(x0: Vec, x1: Vec, v0: Vec, v1: Vec, a0: Vec, a1: Vec, t_total: f32, t: f32, delta: f32) Vec {
    const vec_t: Vec = @splat(t);
    const vec_half: Vec = @splat(0.5);

    if (t < delta * t_total) {
        return x0 + vec_t * v0 + vec_half * vec_t * vec_t * a0;
    }

    const vec_T: Vec = @splat(t_total);
    const vec_tp = vec_t - vec_T;
    return x1 + vec_tp * v1 + vec_half * vec_tp * vec_tp * a1;
}

fn rocketEaseDelta(x0: Vec, x1: Vec, v0: Vec, v1: Vec, t_total: f32) f32 {
    const vec_T: Vec = @splat(t_total);
    const vec_2: Vec = @splat(2.0);

    const dx = x1 - x0;
    const w = vec_T * (v0 + v1) - vec_2 * dx;
    const y = dot(v1 - v0, w);
    const a = 2.0 * t_total * y;
    const b = -4.0 * dot(vec_T * v1 - dx, w);
    const c = dot(w, w);
    const d = 4.0 * (c * c + t_total * t_total * y * y);

    if (a == 0 and b == 0) {
        return 0.0;
    }

    const delta = if (a != 0) (-b - @sqrt(d)) / (2.0 * a) else -c / b;
    return delta;
}

fn rocketEaseWithDelta(x0: Vec, x1: Vec, v0: Vec, v1: Vec, t_total: f32, t: f32, delta: f32) Vec {
    const vec_t: Vec = @splat(t);
    const vec_half: Vec = @splat(0.5);

    const dx = x1 - x0;

    if (t < delta * t_total) {
        const a0 = blk: {
            const fv1: Vec = @splat((delta - 1) / (t_total * delta));
            const fv0: Vec = @splat(-(delta + 1) / (t_total * delta));
            const fdx: Vec = @splat(2 / (t_total * t_total * delta));

            break :blk fv1 * v1 + fv0 * v0 + fdx * dx;
        };

        return x0 + vec_t * v0 + vec_half * vec_t * vec_t * a0;
    }

    const a1 = blk: {
        const fv1: Vec = @splat((2 - delta) / (t_total * (1 - delta)));
        const fv0: Vec = @splat(delta / (t_total * (1 - delta)));
        const fdx: Vec = @splat(-2 / (t_total * t_total * (1 - delta)));

        break :blk fv1 * v1 + fv0 * v0 + fdx * dx;
    };

    const vec_T: Vec = @splat(t_total);
    const vec_tp = vec_t - vec_T;
    return x1 + vec_tp * v1 + vec_half * vec_tp * vec_tp * a1;
}

fn rocketEaseWithDeltaNewAccConstruction(x0: Vec, x1: Vec, v0: Vec, v1: Vec, t_total: f32, t: f32, delta: f32) Vec {
    const vec_t: Vec = @splat(t);
    _ = vec_t;
    const vec_half: Vec = @splat(0.5);
    _ = vec_half;

    const dx = x1 - x0;

    if (t < delta * t_total) {
        const fv1 = (delta - 1) / (t_total * delta);
        const fv0 = -(delta + 1) / (t_total * delta);
        const fdx = 2 / (t_total * t_total * delta);

        var output: Vec = undefined;
        inline for (0..dim) |d| {
            // a0[d] = fv1 * v1[d] + fv0 * v0[d] + fdx * dx[d];
            output[d] =
                x0[d] + t * v0[d] + 0.5 * t * t * (fv1 * v1[d] + fv0 * v0[d] + fdx * dx[d]);
        }

        return output;
    }

    const tp = t - t_total;

    const fv1 = (2 - delta) / (t_total * (1 - delta));
    const fv0 = delta / (t_total * (1 - delta));
    const fdx = -2 / (t_total * t_total * (1 - delta));

    var output: Vec = undefined;
    inline for (0..dim) |d| {
        // a0[d] = fv1 * v1[d] + fv0 * v0[d] + fdx * dx[d];
        output[d] =
            x1[d] + tp * v1[d] + 0.5 * tp * tp * (fv1 * v1[d] + fv0 * v0[d] + fdx * dx[d]);
    }

    return output;
}

fn setRandomVec(v: *Vec, rand: *std.rand.Random) void {
    inline for (0..dim) |i| {
        v[i] = rand.float(f32);
    }
}

pub fn main() !void {
    var bencher = Bencher(1000){};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var num_slots: usize = 1_000;
    var num_time_slots: usize = 100;
    for (args[1..]) |arg| {
        if (std.mem.startsWith(u8, arg, "--num-slots=")) {
            const start = "--num-slots=".len;
            num_slots = try std.fmt.parseInt(usize, arg[start..], 10);
            continue;
        }

        if (std.mem.startsWith(u8, arg, "--num-time-slots=")) {
            const start = "--num-time-slots=".len;
            num_time_slots = try std.fmt.parseInt(usize, arg[start..], 10);
            continue;
        }

        std.debug.print("Unrecognized argument `{s}`.\nPossible arguments are:\n   --num-slots=x\n   --num-time-slots=x\n", .{arg});
        return;
    }

    var rng = std.rand.DefaultPrng.init(0);
    var rand = rng.random();

    const t_total: f32 = 1.0;

    // {
    //     // Compute on the fly -- data-oriented
    //     const DataDO = struct {
    //         x0: Vec,
    //         x1: Vec,
    //         v0: Vec,
    //         v1: Vec,
    //     };

    //     var slice_do = alloc.alloc(DataDO, num_slots) catch unreachable;
    //     defer alloc.free(slice_do);

    //     // Randomly init slice
    //     for (slice_do) |*ddo| {
    //         setRandomVec(&ddo.x0, &rand);
    //         setRandomVec(&ddo.x1, &rand);
    //         setRandomVec(&ddo.v0, &rand);
    //         setRandomVec(&ddo.v1, &rand);
    //     }

    //     bencher.init("rocket easing - data oriented");
    //     while (bencher.next()) |lap| {
    //         lap.start();

    //         for (0..num_time_slots) |ti| {
    //             const t: f32 = t_total * @as(f32, @floatFromInt(ti)) / @as(f32, @floatFromInt(num_time_slots));
    //             for (slice_do) |data| {
    //                 bencher.blackBox(rocketEase(data.x0, data.x1, data.v0, data.v1, t_total, t));
    //             }
    //         }

    //         lap.stop();
    //     }

    //     bencher.printResults();
    // }

    {
        // Cache results
        const DataC = struct {
            x0: Vec,
            x1: Vec,
            v0: Vec,
            v1: Vec,
            a0: Vec,
            a1: Vec,
            delta: f32,
        };

        var slice_c = alloc.alloc(DataC, num_slots) catch unreachable;
        defer alloc.free(slice_c);

        // Randomly init slice
        for (slice_c) |*data| {
            setRandomVec(&data.x0, &rand);
            setRandomVec(&data.x1, &rand);
            setRandomVec(&data.v0, &rand);
            setRandomVec(&data.v1, &rand);
        }

        bencher.init("rocket easing - caching full");
        while (bencher.next()) |lap| {
            lap.start();

            // Calculate the accs and deltas
            for (slice_c) |*data| {
                const a0, const a1, const delta = rocketEaseAccs(data.x0, data.x1, data.v0, data.v1, t_total);

                data.a0 = a0;
                data.a1 = a1;
                data.delta = delta;
            }

            for (0..num_time_slots) |ti| {
                const t: f32 = t_total * @as(f32, @floatFromInt(ti)) / @as(f32, @floatFromInt(num_time_slots));
                for (slice_c) |data| {
                    bencher.blackBox(rocketEaseWithAccs(data.x0, data.x1, data.v0, data.v1, data.a0, data.a1, t_total, t, data.delta));
                }
            }

            lap.stop();
        }

        bencher.printResults();
    }

    {
        // Cache results
        const DataC = struct {
            x0: Vec,
            x1: Vec,
            v0: Vec,
            v1: Vec,
            delta: f32,
        };

        var slice_c = alloc.alloc(DataC, num_slots) catch unreachable;
        defer alloc.free(slice_c);

        // Randomly init slice
        for (slice_c) |*data| {
            setRandomVec(&data.x0, &rand);
            setRandomVec(&data.x1, &rand);
            setRandomVec(&data.v0, &rand);
            setRandomVec(&data.v1, &rand);
        }

        bencher.init("rocket easing - caching only delta");
        while (bencher.next()) |lap| {
            lap.start();

            // Calculate the accs and deltas
            for (slice_c) |*data| {
                const delta = rocketEaseDelta(data.x0, data.x1, data.v0, data.v1, t_total);
                data.delta = delta;
            }

            for (0..num_time_slots) |ti| {
                const t: f32 = t_total * @as(f32, @floatFromInt(ti)) / @as(f32, @floatFromInt(num_time_slots));
                for (slice_c) |data| {
                    bencher.blackBox(rocketEaseWithDelta(data.x0, data.x1, data.v0, data.v1, t_total, t, data.delta));
                }
            }

            lap.stop();
        }

        bencher.printResults();
    }

    {
        // Cache results
        const DataC = struct {
            x0: Vec,
            x1: Vec,
            v0: Vec,
            v1: Vec,
            delta: f32,
        };

        var slice_c = alloc.alloc(DataC, num_slots) catch unreachable;
        defer alloc.free(slice_c);

        // Randomly init slice
        for (slice_c) |*data| {
            setRandomVec(&data.x0, &rand);
            setRandomVec(&data.x1, &rand);
            setRandomVec(&data.v0, &rand);
            setRandomVec(&data.v1, &rand);
        }

        bencher.init("rocket easing - caching only delta v2");
        while (bencher.next()) |lap| {
            lap.start();

            // Calculate the accs and deltas
            for (slice_c) |*data| {
                const delta = rocketEaseDelta(data.x0, data.x1, data.v0, data.v1, t_total);
                data.delta = delta;
            }

            for (0..num_time_slots) |ti| {
                const t: f32 = t_total * @as(f32, @floatFromInt(ti)) / @as(f32, @floatFromInt(num_time_slots));
                for (slice_c) |data| {
                    bencher.blackBox(rocketEaseWithDeltaNewAccConstruction(data.x0, data.x1, data.v0, data.v1, t_total, t, data.delta));
                }
            }

            lap.stop();
        }

        bencher.printResults();
    }
}
