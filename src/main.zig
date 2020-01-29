// Author: Jan Halsema
// Zig implementation of wyhash

const std = @import("std");
const mem = std.mem;

const primes = [_]u64{
    0xa0761d6478bd642f,
    0xe7037ed1a0b428db,
    0x8ebc6af09c88c6e3,
    0x589965cc75374cc3,
    0x1d8e4e27c47d124f,
};

inline fn read_bytes(comptime bytes: u8, data: []const u8) u64 {
    const T = @IntType(false, 8 * bytes);
    return mem.readIntSliceLittle(T, data[0..bytes]);
}

inline fn mum(a: u64, b: u64) u64 {
    var r = std.math.mulWide(u64, a, b);
    r = (r >> 64) ^ r;
    return @truncate(u64, r);
}

inline fn mix0(a: u64, b: u64, seed: u64) u64 {
    return mum(a ^ seed ^ primes[0], b ^ seed ^ primes[1]);
}

inline fn mix1(a: u64, b: u64, seed: u64) u64 {
    return mum(a ^ seed ^ primes[2], b ^ seed ^ primes[3]);
}

inline fn mix2(a: u64, b: u64, seed: u64) u64 {
    return mum(a ^ seed ^ primes[1], b ^ seed ^ primes[2]);
}

inline fn mix3(a: u64, b: u64, seed: u64) u64 {
    return mum(a ^ seed ^ primes[3], b ^ seed ^ primes[0]);
}

pub fn hash(key: []const u8, initial_seed: u64) u64 {
    const len = key.len;

    var seed = initial_seed;
    var i: u64 = @truncate(u6, len);

         if (i <   4) { seed = mix0(read_bytes(3, key[i..]), 0, seed); }
    else if (i <=  8) { seed = mix0(read_bytes(4, key[0..]), read_bytes(4, key[i - 4..]), seed); }
    else if (i <= 16) { seed = mix0(read_bytes(8, key[0..]), read_bytes(8, key[i - 8..]), seed); }
    else if (i <= 24) { seed = mix0(read_bytes(8, key[0..]), read_bytes(8, key[8..]), seed) ^ mix1(read_bytes(8, key[i - 8..]), 0, seed); }
    else if (i <= 32) { seed = mix0(read_bytes(8, key[0..]), read_bytes(8, key[8..]), seed) ^ mix1(read_bytes(8, key[16..]), read_bytes(8, key[i - 8..]), seed); }
    else              { seed = mix0(read_bytes(8, key[0..]), read_bytes(8, key[8..]), seed) ^ mix1(read_bytes(8, key[16..]), read_bytes(8, key[24..]), seed) ^
                               mix2(read_bytes(8, key[i - 32..]), read_bytes(8, key[i - 24..]), seed) ^ mix3(read_bytes(8, key[i - 16..]), read_bytes(8, key[i - 8..]), seed); }

    if (i == len) return mum(seed, len ^ primes[4]);

    var see1 = seed;
    var see2 = seed;
    var see3 = seed;

    var rem_key = key[i..];

    i = len - i;
    while (i >= 64) : ({ i -= 64; rem_key = rem_key[64..]; }) {
        seed = mix0(read_bytes(8, rem_key[ 0..]), read_bytes(8, rem_key[ 8..]), seed);
        see1 = mix1(read_bytes(8, rem_key[16..]), read_bytes(8, rem_key[24..]), see1);
        see2 = mix2(read_bytes(8, rem_key[32..]), read_bytes(8, rem_key[40..]), see2);
        see3 = mix3(read_bytes(8, rem_key[48..]), read_bytes(8, rem_key[56..]), see3);
    }

    return mum(seed ^ see1 ^ see2, see3 ^ len ^ primes[4]);
}

export fn wyhash(ptr: [*]const u8, len: u64, seed: u64) u64 {
    return hash(ptr[0..len], seed);
}

pub fn rng(initial_seed: u64) u64 {
    var seed = initial_seed +% primes[0];
    return mum(seed ^ primes[1], seed);
}
