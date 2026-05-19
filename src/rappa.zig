//! # rappa

const std = @import("std");

const lightmix = @import("lightmix");

const Self = @This();

frequency: comptime_float,
sample_rate: comptime_int,

pub const Error = error{OutOfMemory};

pub fn array(
    self: Self,
    comptime T: type,
    allocator: std.mem.Allocator,
    length: usize,
) Self.Error![]T {
    var result: []T = try allocator.alloc(T, length);

    const attack_samples: isize = self.sample_rate * 0.1;
    const attack_samples_mod: isize = @as(comptime_float, @floatFromInt(attack_samples)) * 0.8;

    for (0..length) |i| {
        // Cast values to float before arithmetic operations to prevent underflow
        const i_f = @as(T, @floatFromInt(i));
        const attack_samples_f = @as(T, @floatFromInt(attack_samples));
        const attack_samples_mod_f = @as(T, @floatFromInt(attack_samples_mod));
        const length_f = @as(T, @floatFromInt(length));

        // time
        const t: T = i_f / @as(T, @floatFromInt(self.sample_rate));

        // amplitude envelope
        const a_env: T = if (i < attack_samples)
            i_f / attack_samples_f
        else
            1.0 - (i_f - attack_samples_f) / (length_f - attack_samples_f);

        // modulation index envelope
        const i_env: T = if (i < attack_samples_mod)
            5.0 * (i_f / attack_samples_mod_f)
        else
            5.0 - 4.0 * (i_f - attack_samples_f) / (length_f - attack_samples_mod_f);

        // phases (fc = fm = freq)
        const carrier_phase: T = 2.0 * std.math.pi * self.frequency * t;
        const modulator_phase: T = 2.0 * std.math.pi * self.frequency * t;

        // Calculate and store the FM synthesis sample
        result[i] = a_env * std.math.sin(carrier_phase + i_env * std.math.sin(modulator_phase));
    }

    return result;
}

pub fn wave(
    self: Self,
    comptime T: type,
    allocator: std.mem.Allocator,
    length: usize,
) Self.Error!lightmix.Wave(T) {
    const samples = try self.array(T, allocator, length);
    const channels = 1;
    return lightmix.Wave(T){
        .allocator = allocator,
        .samples = samples,
        .channels = channels,
        .sample_rate = self.sample_rate,
    };
}

test {
    _ = Self;
    _ = Self{
        .frequency = 440.0,
        .sample_rate = 44100,
    };
}
