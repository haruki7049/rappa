const std = @import("std");
const rappa = @import("rappa");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    const horn = rappa{ .frequency = 220.0, .sample_rate = 44100, .channels = 2 };
    const wave = try horn.wave(f64, allocator, 88200);

    const file = try std.fs.cwd().createFile("a3-horn.zig.wav", .{});
    defer file.close();
    const bits = 16;
    const bytes_per_sample = (bits + 7) / 8;
    const header_size = 44;
    const total_size = header_size + (wave.samples.len * wave.channels * bytes_per_sample);
    const buf = try allocator.alloc(u8, total_size);
    defer allocator.free(buf);
    var writer = file.writer(buf);

    try wave.write(.wav, &writer.interface, .{
        .bits = 16,
        .format_code = .pcm,
        .peak_timestamp = 0,
        .use_fact = false,
        .use_peak = false,
    });
    try writer.interface.flush();

    // try wave.play();
}
