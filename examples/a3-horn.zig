const std = @import("std");
const rappa = @import("rappa");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    defer init.arena.deinit();

    const horn = rappa{
        .frequency = 220.0,
        .sample_rate = 44100,
        .channels = 2,
        .adsr = .{ .a = 0.1, .d = 0.1, .s = 0.7, .r = 0.2 },
    };
    const wave = try horn.wave(f64, allocator, 88200);

    // // Writes to a file
    // {
    //     const file = try std.fs.cwd().createFile("a3-horn.zig.wav", .{});
    //     defer file.close();
    //     const bits = 16;
    //     const bytes_per_sample = (bits + 7) / 8;
    //     const header_size = 44;
    //     const total_size = header_size + (wave.samples.len * wave.channels * bytes_per_sample);
    //     const buf = try allocator.alloc(u8, total_size);
    //     defer allocator.free(buf);
    //     var writer = file.writer(buf);

    //     try wave.write(.wav, &writer.interface, .{
    //         .bits = 16,
    //         .format_code = .pcm,
    //         .peak_timestamp = 0,
    //         .use_fact = false,
    //         .use_peak = false,
    //     });
    //     try writer.interface.flush();
    // }

    try wave.play();
}
