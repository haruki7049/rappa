const std = @import("std");
const rappa = @import("rappa");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    const horn = rappa{ .frequency = 440.0, .sample_rate = 44100 };
    const wave = try horn.wave(f64, allocator, 88200);
    try wave.play();
}
