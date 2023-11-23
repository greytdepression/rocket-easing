const std = @import("std");

pub fn Bencher(comptime NUM_SAMPLES: usize) type {
    return struct {
        const N = NUM_SAMPLES;
        const Self = @This();

        const Lap = struct {
            bencher: *Self,
            index: usize,
            start_instant: std.time.Instant,

            pub fn lapIndex(self: Lap) usize {
                return self.index;
            }

            pub fn percentComplete(self: Lap) f32 {
                const index_f: f32 = @floatFromInt(self.index);
                const n_f: f32 = @floatFromInt(NUM_SAMPLES);

                return index_f / n_f;
            }

            pub inline fn start(self: *const Lap) void {
                var self_mut = @constCast(self);

                self_mut.start_instant = std.time.Instant.now() catch unreachable;
            }

            pub inline fn stop(self: *const Lap) void {
                const stop_instant = std.time.Instant.now() catch unreachable;
                const elapsed: u64 = stop_instant.since(self.start_instant);

                self.bencher.samples[self.index] = elapsed;
            }
        };

        const HumanReadableTime = union(enum) {
            s: f64,
            ms: f64,
            us: f64,
            ns: f64,

            const ns_per_us: f64 = 1_000;
            const ns_per_ms: f64 = 1_000_000;
            const ns_per_s: f64 = 1_000_000_000;

            fn fromNanos(nanos: f64) @This() {
                std.debug.assert(nanos >= 0.0);

                if (nanos < ns_per_us) {
                    return .{ .ns = nanos };
                }

                if (nanos < ns_per_ms) {
                    return .{ .us = nanos / ns_per_us };
                }

                if (nanos < ns_per_s) {
                    return .{ .ms = nanos / ns_per_ms };
                }

                return .{ .s = nanos / ns_per_s };
            }

            fn formatString(self: @This(), buf: []u8) []const u8 {
                // "x.xxx ms" -- 4 significant digits + period + space + unit (mu takes 2 bytes utf8)
                //               4 bytes                1 byte   1 byte  <= 3 bytes
                // we'll allocate 16 bytes
                std.debug.assert(buf.len >= 16);

                const unit = switch (self) {
                    .s => "s",
                    .ms => "ms",
                    .us => "μs",
                    .ns => "ns",
                };

                const floating_val: f64 = switch (self) {
                    inline else => |x| x,
                };

                // Since format strings need to be comptime, we need to use if statements.
                if (floating_val >= 100.0) {
                    return std.fmt.bufPrint(buf, "{d:.1} {s}", .{ floating_val, unit }) catch unreachable;
                }

                if (floating_val >= 10.0) {
                    return std.fmt.bufPrint(buf, "{d:.2} {s}", .{ floating_val, unit }) catch unreachable;
                }

                if (floating_val >= 1.0) {
                    return std.fmt.bufPrint(buf, "{d:.3} {s}", .{ floating_val, unit }) catch unreachable;
                }

                unreachable;
            }
        };

        current_index: usize = 0,
        samples: [NUM_SAMPLES]u64 = undefined,
        benchmark_name: ?[]const u8 = null,

        pub fn init(self: *Self, run_name: []const u8) void {
            self.benchmark_name = run_name;
            self.current_index = 0;
        }

        pub inline fn blackBox(self: Self, val: anytype) void {
            _ = self;

            const T = @TypeOf(val);

            var temp: T = undefined;
            const volPtr: *volatile T = &temp;

            volPtr.* = val;
        }

        pub fn next(self: *Self) ?Lap {
            if (self.benchmark_name == null) {
                @panic("Uninitialized bencher.");
            }

            if (self.current_index >= NUM_SAMPLES) {
                return null;
            }

            var lap = Lap{
                .bencher = self,
                .index = self.current_index,
                .start_instant = undefined,
            };

            self.current_index += 1;

            return lap;
        }

        pub fn printResults(self: *Self) void {
            if (self.benchmark_name == null) {
                @panic("Uninitialized bencher.");
            }

            if (NUM_SAMPLES < 2) {
                std.debug.print("Bencher needs to take at least 2 samples to give results.\n", .{});
                return;
            }

            const n: f64 = @floatFromInt(NUM_SAMPLES);
            const n_inv = 1.0 / n;

            const mean_ns: f64 = blk: {
                var accumulator: f64 = 0.0;

                for (self.samples) |val_ns| {
                    accumulator += @as(f64, @floatFromInt(val_ns)) * n_inv;
                }

                break :blk accumulator;
            };
            const mean_hr = HumanReadableTime.fromNanos(mean_ns);

            const std_dev_ns: f64 = blk: {
                const fac: f64 = 1.0 / (n - 1.0);

                var acc: f64 = 0.0;

                for (self.samples) |val_ns| {
                    const val_ns_f: f64 = @floatFromInt(val_ns);

                    acc += (val_ns_f - mean_ns) * (val_ns_f - mean_ns) * fac;
                }

                break :blk @sqrt(acc);
            };
            const std_dev_hr = HumanReadableTime.fromNanos(std_dev_ns);

            const max_ns: f64 = blk: {
                var max: usize = 0;

                for (self.samples) |val_ns| {
                    max = @max(max, val_ns);
                }

                break :blk @floatFromInt(max);
            };

            const max_hr = HumanReadableTime.fromNanos(max_ns);

            const min_ns: f64 = blk: {
                var min: usize = 9999999999;

                for (self.samples) |val_ns| {
                    min = @min(min, val_ns);
                }

                break :blk @floatFromInt(min);
            };

            const min_hr = HumanReadableTime.fromNanos(min_ns);

            var buffer: [128]u8 = undefined;

            const mean_str = mean_hr.formatString(buffer[0..32]);
            const std_dev_str = std_dev_hr.formatString(buffer[32..64]);
            const min_str = min_hr.formatString(buffer[64..96]);
            const max_str = max_hr.formatString(buffer[96..128]);

            std.debug.print(
                "Benchmark '{s}': mean = {s} [{s}, {s}] -- σ = {s}\n",
                .{
                    self.benchmark_name.?,
                    mean_str,
                    min_str,
                    max_str,
                    std_dev_str,
                },
            );

            self.benchmark_name = null;
        }
    };
}

test "Benchmark blackbox" {
    var bencher = Bencher(10_000){};

    const N = 1_000_000;

    bencher.init("noop");
    var counter: usize = 0;
    while (bencher.next()) |lap| {
        counter = 0;
        lap.start();
        for (0..N) |i| {
            counter = counter +% i & 0xff;
        }
        lap.stop();
    }

    std.debug.print("Counter = {}\n", .{counter});
    bencher.printResults();

    bencher.init("blackbox");
    while (bencher.next()) |lap| {
        lap.start();
        for (0..N) |i| {
            bencher.blackBox(i);
        }
        lap.stop();
    }

    bencher.printResults();

    bencher.init("volatile i");
    while (bencher.next()) |lap| {
        lap.start();
        for (0..N) |i| {
            const vol_i: *volatile usize = @constCast(&i);
            vol_i.* = i;
        }
        lap.stop();
    }

    bencher.printResults();

    bencher.init("asm nop");
    while (bencher.next()) |lap| {
        lap.start();
        for (0..N) |i| {
            _ = i;
            asm volatile ("nop");
        }
        lap.stop();
    }

    bencher.printResults();

    bencher.init("xor");
    var temp: usize = undefined;
    while (bencher.next()) |lap| {
        lap.start();
        for (0..N) |i| {
            temp ^= i;
        }
        lap.stop();
    }

    bencher.blackBox(temp);
    bencher.printResults();
}
