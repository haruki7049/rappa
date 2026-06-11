//! # rappa

const std = @import("std");

const lightmix = @import("lightmix");

pub const ADSR = struct {
    a: f64,
    d: f64,
    s: f64,
    r: f64,
};
const Self = @This();

frequency: comptime_float,
sample_rate: comptime_int,
channels: u16,
adsr: ADSR,

pub const Error = error{OutOfMemory};

pub fn array(
    self: Self,
    comptime T: type,
    allocator: std.mem.Allocator,
    length: usize,
) Self.Error![]T {
    var result: []T = try allocator.alloc(T, length * self.channels);

    // Cast total time and ADSR parameters to type T
    const total_time = @as(T, @floatFromInt(length)) / @as(T, @floatFromInt(self.sample_rate));
    const a_t = @as(T, @floatCast(self.adsr.a));
    const d_t = @as(T, @floatCast(self.adsr.d));
    const s_l = @as(T, @floatCast(self.adsr.s));
    const r_t = @as(T, @floatCast(self.adsr.r));

    for (0..length) |i| {
        const i_f = @as(T, @floatFromInt(i));
        const t: T = i_f / @as(T, @floatFromInt(self.sample_rate));

        // Calculate ADSR envelope amplitude
        var a_env: T = 0.0;
        if (t < a_t) {
            // Attack phase
            a_env = t / a_t;
        } else if (t < a_t + d_t) {
            // Decay phase
            a_env = 1.0 - (1.0 - s_l) * ((t - a_t) / d_t);
        } else if (t < total_time - r_t) {
            // Sustain phase
            a_env = s_l;
        } else if (t < total_time) {
            // Release phase
            const release_start = total_time - r_t;
            a_env = s_l * (1.0 - (t - release_start) / r_t);
        }

        // FM synthesis logic (apply ADSR to modulation index as well)
        const i_env: T = a_env * 5.0;
        const carrier_phase: T = 2.0 * std.math.pi * self.frequency * t;
        const modulator_phase: T = 2.0 * std.math.pi * self.frequency * t;

        const sample = a_env * std.math.sin(carrier_phase + i_env * std.math.sin(modulator_phase));

        // Copy the sample to all channels
        for (0..self.channels) |ch| {
            result[i * self.channels + ch] = sample;
        }
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
    return lightmix.Wave(T){
        .allocator = allocator,
        .samples = samples,
        .channels = self.channels,
        .sample_rate = self.sample_rate,
    };
}

test {
    _ = Self;
    _ = Self{
        .frequency = 440.0,
        .sample_rate = 44100,
        .channels = 1,
        .adsr = .{ .a = 0.1, .d = 0.1, .s = 0.7, .r = 0.2 },
    };
}
