// Author: Jan Halsema
// Zig implementation of wyhash

const std = @import("std");
const mem = std.mem;

const primes = []u64{
    0xa0761d6478bd642f, 0xe7037ed1a0b428db,
    0x8ebc6af09c88c6e3, 0x589965cc75374cc3,
    0x1d8e4e27c47d124f, 0xeb44accab455d165,
};

inline fn read_bytes(bytes: u8, data: []const u8) u64 {
    return mem.readVarInt(u64, data[0..bytes], @import("builtin").endian);
}

inline fn read_8bytes_swapped(data: []const u8) u64 {
    return (read_bytes(4, data) << 32 | read_bytes(4, data[4..]));
}

inline fn read_rest(data: []const u8) u64 {
    const len = @truncate(u6, data.len);
    return switch (len) {
        1, 2, 4 => read_bytes(len, data),
        3 => read_bytes(2, data) <<  8 | read_bytes(1, data[2..]),
        5 => read_bytes(4, data) <<  8 | read_bytes(1, data[4..]),
        6 => read_bytes(4, data) << 16 | read_bytes(2, data[4..]),
        7 => read_bytes(4, data) << 24 | read_bytes(2, data[4..]) << 8 | read_bytes(1, data[6..]),
        8 => read_8bytes_swapped(data),
        else => unreachable,
    };
}

inline fn mum(a: u64, b: u64) u64 {
    var r: u128 = @intCast(u128, a) * @intCast(u128, b);
    r = (r >> 64) ^ r;
    return @truncate(u64, r);
}

pub fn hash(key: []const u8, initial_seed: u64) u64 {
    const len = key.len;

    var seed = initial_seed;
    var p    = key;

    var i: usize = 0;
    while (i + 32 <= key.len) : (i += 32) {
        p = key[i..];
        seed = mum(seed ^ primes[0], mum(read_bytes(8, p) ^ primes[1], read_bytes(8, p[8..]) ^ primes[2]) ^
            mum(read_bytes(8, p[16..]) ^ primes[3], read_bytes(8, p[24..]) ^ primes[4]));
    }
    seed ^= primes[0];

    if (len & 31 != 0) {
        seed = switch (((len - 1) & 31) / 8) {
            0 => mum(seed, read_rest(key[i..]) ^ primes[1]),
            1 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_rest(key[i + 8 ..]) ^ primes[2]),
            2 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, read_rest(key[i + 16 ..]) ^ primes[3]),
            3 => mum(
                read_8bytes_swapped(key[i..]) ^ seed,
                read_8bytes_swapped(key[i + 8 ..]) ^ primes[2],
            ) ^ mum(
                read_8bytes_swapped(key[i + 16 ..]) ^ seed,
                read_rest(key[i + 24 ..]) ^ primes[4],
            ),
            else => unreachable,
        };
    }

    return mum(seed, len ^ primes[5]);
}

pub fn rng(initial_seed: u64) u64 {
    var seed = initial_seed +% primes[0];
    return mum(seed ^ primes[1], seed);
}