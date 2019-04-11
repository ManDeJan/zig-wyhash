// Author: Jan Halsema
// Zig implementation of wyhash

const std = @import("std");
const mem = std.mem;

const primes = []u64{
    0xa0761d6478bd642f, 0xe7037ed1a0b428db,
    0x8ebc6af09c88c6e3, 0x589965cc75374cc3,
    0x1d8e4e27c47d124f, 0xeb44accab455d165,
};

fn read_bytes(comptime bytes: u8, data: []const u8) u64 {
    return mem.readVarInt(u64, data[0..bytes], @import("builtin").endian);
}

fn read_8bytes_swapped(data: []const u8) u64 {
    return (read_bytes(4, data) << 32 | read_bytes(4, data[4..]));
}

fn mum(a: u64, b: u64) u64 {
    var r: u128 = @intCast(u128, a) * @intCast(u128, b);
    r = (r >> 64) ^ r;
    return @truncate(u64, r);
}

pub fn hash(key: []const u8, initial_seed: u64) u64 {
    const len = key.len;

    var seed = initial_seed;

    var i: usize = 0;
    while (i + 32 <= key.len) : (i += 32) {
        seed = mum(seed                              ^ primes[0],
                   mum(read_bytes(8, key[i      ..]) ^ primes[1],
                       read_bytes(8, key[i +  8 ..]) ^ primes[2]) ^
                   mum(read_bytes(8, key[i + 16 ..]) ^ primes[3],
                       read_bytes(8, key[i + 24 ..]) ^ primes[4]));
    }
    seed ^= primes[0];

    seed = switch (@truncate(u5, len & 31)) {
        0 => seed,
        1 => mum(seed, read_bytes(1, key[i..]) ^ primes[1]),
        2 => mum(seed, read_bytes(2, key[i..]) ^ primes[1]),
        3 => mum(seed, ((read_bytes(2, key[i..]) << 8) | read_bytes(1, key[i + 2 ..])) ^ primes[1]),
        4 => mum(seed, read_bytes(4, key[i..]) ^ primes[1]),
        5 => mum(seed, ((read_bytes(4, key[i..]) << 8) | read_bytes(1, key[i + 4 ..])) ^ primes[1]),
        6 => mum(seed, ((read_bytes(4, key[i..]) << 16) | read_bytes(2, key[i + 4 ..])) ^ primes[1]),
        7 => mum(seed, ((read_bytes(4, key[i..]) << 24) | (read_bytes(2, key[i + 4 ..]) << 8) | read_bytes(1, key[i + 6 ..])) ^ primes[1]),
        8 => mum(seed, read_8bytes_swapped(key[i..]) ^ primes[1]),
        9 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_bytes(1, key[i + 8 ..]) ^ primes[2]),
        10 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_bytes(2, key[i + 8 ..]) ^ primes[2]),
        11 => mum(read_8bytes_swapped(key[i..]) ^ seed, ((read_bytes(2, key[i + 8 ..]) << 8) | read_bytes(1, key[i + 8 + 2 ..])) ^ primes[2]),
        12 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_bytes(4, key[i + 8 ..]) ^ primes[2]),
        13 => mum(read_8bytes_swapped(key[i..]) ^ seed, ((read_bytes(4, key[i + 8 ..]) << 8) | read_bytes(1, key[i + 8 + 4 ..])) ^ primes[2]),
        14 => mum(read_8bytes_swapped(key[i..]) ^ seed, ((read_bytes(4, key[i + 8 ..]) << 16) | read_bytes(2, key[i + 8 + 4 ..])) ^ primes[2]),
        15 => mum(read_8bytes_swapped(key[i..]) ^ seed, ((read_bytes(4, key[i + 8 ..]) << 24) | (read_bytes(2, key[i + 8 + 4 ..]) << 8) | read_bytes(1, key[i + 8 + 6 ..])) ^ primes[2]),
        16 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]),
        17 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, read_bytes(1, key[i + 16 ..]) ^ primes[3]),
        18 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, read_bytes(2, key[i + 16 ..]) ^ primes[3]),
        19 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, ((read_bytes(2, key[i + 16 ..]) << 8) | read_bytes(1, key[i + 16 + 2 ..])) ^ primes[3]),
        20 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, read_bytes(4, key[i + 16 ..]) ^ primes[3]),
        21 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, ((read_bytes(4, key[i + 16 ..]) << 8) | read_bytes(1, key[i + 16 + 4 ..])) ^ primes[3]),
        22 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, ((read_bytes(4, key[i + 16 ..]) << 16) | read_bytes(2, key[i + 16 + 4 ..])) ^ primes[3]),
        23 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, ((read_bytes(4, key[i + 16 ..]) << 24) | (read_bytes(2, key[i + 16 + 4 ..]) << 8) | read_bytes(1, key[i + 16 + 6 ..])) ^ primes[3]),
        24 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(seed, read_8bytes_swapped(key[i + 16 ..]) ^ primes[3]),
        25 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(read_8bytes_swapped(key[i + 16 ..]) ^ seed, read_bytes(1, key[i + 24 ..]) ^ primes[4]),
        26 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(read_8bytes_swapped(key[i + 16 ..]) ^ seed, read_bytes(2, key[i + 24 ..]) ^ primes[4]),
        27 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(read_8bytes_swapped(key[i + 16 ..]) ^ seed, ((read_bytes(2, key[i + 24 ..]) << 8) | read_bytes(1, key[i + 24 + 2 ..])) ^ primes[4]),
        28 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(read_8bytes_swapped(key[i + 16 ..]) ^ seed, read_bytes(4, key[i + 24 ..]) ^ primes[4]),
        29 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(read_8bytes_swapped(key[i + 16 ..]) ^ seed, ((read_bytes(4, key[i + 24 ..]) << 8) | read_bytes(1, key[i + 24 + 4 ..])) ^ primes[4]),
        30 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(read_8bytes_swapped(key[i + 16 ..]) ^ seed, ((read_bytes(4, key[i + 24 ..]) << 16) | read_bytes(2, key[i + 24 + 4 ..])) ^ primes[4]),
        31 => mum(read_8bytes_swapped(key[i..]) ^ seed, read_8bytes_swapped(key[i + 8 ..]) ^ primes[2]) ^ mum(read_8bytes_swapped(key[i + 16 ..]) ^ seed, ((read_bytes(4, key[i + 24 ..]) << 24) | (read_bytes(2, key[i + 24 + 4 ..]) << 8) | read_bytes(1, key[i + 24 + 6 ..])) ^ primes[4]),
    };

    return mum(seed, len ^ primes[5]);
}

pub fn rng(initial_seed: u64) u64 {
    var seed = initial_seed +% primes[0];
    return mum(seed ^ primes[1], seed);
}
