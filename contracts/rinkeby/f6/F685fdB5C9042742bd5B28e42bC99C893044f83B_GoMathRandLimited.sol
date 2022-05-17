// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8;

contract GoMathRandLimited {
    struct Traits {
        uint8 class;
        uint8 body;
        uint8 weapon;
        uint8 hair;
        uint8 hairColor;
        uint8 back;
        uint8 aura;
        uint8 top;
        uint8 bottom;
    }

    // The original approach used an unstable sort as part of the weighted random
    // selection via https://github.com/mroth/weightedrand. We avoid re-implementing
    // Go's unstable sort here and just hardcode the resulting order of the items.
    // Tightly pack values in a byte array rather than waste 32 bytes on a single ID,
    // which is what Solidity does for regular arrays.
    // For partial sums we use a a 2 byte little-endian encoding.
    bytes constant classIds = "\x00\x01\x02\x03\x04\x05\x06";
    bytes constant classPartialSum =
        "\x0a\x00\x14\x00\x1e\x00\x28\x00\x32\x00\x3c\x00";
    bytes constant bodyIds = "\x05\x03\x04\x00\x01\x02";
    bytes constant bodyPartialSum =
        "\x01\x00\x08\x00\x0f\x00\x2b\x00\x47\x00\x63\x00";
    bytes constant weaponIds = "\x09\x08\x07\x06\x05\x04\x03\x02\x01\x00";
    bytes constant weaponPartialSum =
        "\x01\x00\x06\x00\x0c\x00\x13\x00\x1c\x00\x26\x00\x32\x00\x3f\x00\x4e\x00\x64\x00";
    bytes constant hairIds =
        "\x11\x02\x03\x13\x04\x0d\x0a\x01\x0b\x10\x0c\x00\x09\x08\x0e\x0f\x07\x06\x12\x05\x14\x15\x16";
    bytes constant hairPartialSum =
        "\x0a\x00\x49\x00\x88\x00\xc7\x00\x5d\x01\xf3\x01\x89\x02\xb5\x03\xe1\x04\x0d\x06\x39\x07\x2d\x09\x21\x0b\x15\x0d\x09\x0f\xfd\x10\xf1\x12\xe5\x14\xd9\x16\xcd\x18\xc1\x1a\xb5\x1c\xa9\x1e";
    bytes constant hairColorIds = "\x06\x01\x04\x03\x02\x05\x00\x07\x08";
    bytes constant hairColorPartialSum =
        "\x19\x00\x4b\x00\x7d\x00\xfa\x00\x90\x01\x26\x02\xbc\x02\x52\x03\xe8\x03";
    bytes constant backIds =
        "\x0a\x07\x0f\x03\x02\x10\x04\x05\x06\x08\x09\x01\x12\x11\x13\x0e\x0d\x0c\x0b\x00";
    bytes constant backPartialSum =
        "\x01\x00\x03\x00\x05\x00\x0a\x00\x0f\x00\x14\x00\x1e\x00\x28\x00\x32\x00\x3c\x00\x46\x00\x50\x00\x5a\x00\x64\x00\x6e\x00\x87\x00\xa0\x00\xb9\x00\xd2\x00\x22\x01";
    // Archers/Slayers can't have some back items and their lack unstably affects
    // the order, so consider those separately
    bytes constant backArcherSlayerId =
        "\x0a\x0f\x02\x03\x01\x04\x05\x06\x08\x09\x11\x13\x0d\x0e\x0c\x0b\x00";
    bytes constant backArcherSlayerPartialSum =
        "\x01\x00\x03\x00\x08\x00\x0d\x00\x17\x00\x21\x00\x2b\x00\x35\x00\x3f\x00\x49\x00\x53\x00\x5d\x00\x76\x00\x8f\x00\xa8\x00\xc1\x00\x11\x01";
    bytes constant auraIds =
        "\x02\x0b\x08\x0c\x04\x0a\x06\x0f\x07\x09\x05\x03\x01\x0d\x0e\x00";
    bytes constant auraPartialSum =
        "\x32\x00\x64\x00\xaf\x00\xfa\x00\x45\x01\x90\x01\xdb\x01\x26\x02\x8a\x02\xee\x02\x52\x03\xb6\x03\x1a\x04\x7e\x04\xe2\x04\x10\x27";
    bytes constant topIds =
        "\x37\x36\x35\x34\x30\x32\x31\x33\x2f\x2e\x2d\x2c\x2b\x2a\x29\x28\x21\x26\x25\x24\x22\x1c\x16\x17\x18\x19\x1a\x1b\x27\x1d\x1e\x1f\x20\x23\x14\x15\x13\x12\x11\x10\x0f\x0e\x0d\x0c\x0b\x0a\x09\x08\x07\x06\x05\x04\x03\x02\x01\x00";
    bytes constant topPartialSum =
        "\x32\x00\x64\x00\x96\x00\xc8\x00\x13\x01\x5e\x01\xa9\x01\xf4\x01\x3f\x02\x8a\x02\xd5\x02\x20\x03\x6b\x03\xb6\x03\x01\x04\x4c\x04\xe2\x04\x78\x05\x0e\x06\xa4\x06\x3a\x07\xd0\x07\x66\x08\xfc\x08\x92\x09\x28\x0a\xbe\x0a\x54\x0b\xea\x0b\x80\x0c\x16\x0d\xac\x0d\x42\x0e\xd8\x0e\x04\x10\x30\x11\x5c\x12\x88\x13\xb4\x14\xe0\x15\x0c\x17\x38\x18\x64\x19\x90\x1a\xbc\x1b\xe8\x1c\x14\x1e\x40\x1f\x6c\x20\x98\x21\xc4\x22\xf0\x23\x1c\x25\x48\x26\x74\x27\xa0\x28";
    bytes constant bottomIds =
        "\x11\x10\x12\x0c\x0e\x0d\x0f\x0b\x07\x08\x0a\x09\x06\x05\x04\x03\x02\x01\x00";
    bytes constant bottomPartialSum =
        "\x00\x00\x00\x00\x00\x00\x03\x00\x06\x00\x09\x00\x0c\x00\x11\x00\x16\x00\x1b\x00\x20\x00\x25\x00\x2e\x00\x37\x00\x40\x00\x49\x00\x52\x00\x5b\x00\x64\x00";

    function getTraits(uint256 seed) public pure returns (Traits memory) {
        // The original version used Go's math/rand and https://github.com/mroth/weightedrand
        // to pick the traits on the back-end and serve that as an API endpoint.
        // This attempts to faithfully recreate this logic on-chain for
        // transparency and redundancy's sake.
        Source memory rng = newRand(seed);

        Traits memory returned;

        unchecked {
            // TODO: Investigate using inline bin-search lookup tables for traits
            // I really would split that into digestible chunk but I don't want to incur the
            // cost of copying all that data at runtime (can't unsize fixed-size
            // array as dynamic nor Solidity supports generics for the array size).
            uint256 i;
            uint256 j;
            uint256 h;
            uint16 readValue;
            // Class
            uint256 pick = uint32(Int31n(rng, 60) + 1);
            (i, j) = (0, classIds.length);
            while (i < j) {
                h = (i + j) / 2;
                // Manually copy over the little-endian-encoded uint16 from the byte stream
                readValue =
                    uint16(uint8(classPartialSum[(2 * h)])) +
                    (uint16(uint8(classPartialSum[(2 * h) + 1])) << 8);
                if (readValue < pick) {
                    i = h + 1;
                } else {
                    j = h;
                }
            }
            returned.class = uint8(classIds[i]);

            // Body
            pick = uint32(Int31n(rng, 99) + 1);
            (i, j) = (0, bodyIds.length);
            while (i < j) {
                h = (i + j) / 2;
                // Manually copy over the little-endian-encoded uint16 from the byte stream
                readValue =
                    uint16(uint8(bodyPartialSum[(2 * h)])) +
                    (uint16(uint8(bodyPartialSum[(2 * h) + 1])) << 8);
                if (readValue < pick) {
                    i = h + 1;
                } else {
                    j = h;
                }
            }
            returned.body = uint8(bodyIds[i]);

            // Weapon
            pick = uint32(Int31n(rng, 100) + 1); // fighter<Weapons>
            (i, j) = (0, weaponIds.length);
            while (i < j) {
                h = (i + j) / 2;
                // Manually copy over the little-endian-encoded uint16 from the byte stream
                readValue =
                    uint16(uint8(weaponPartialSum[(2 * h)])) +
                    (uint16(uint8(weaponPartialSum[(2 * h) + 1])) << 8);
                if (readValue < pick) {
                    i = h + 1;
                } else {
                    j = h;
                }
            }
            returned.weapon = uint8(weaponIds[i]);

            // Hair
            pick = uint32(Int31n(rng, 7849) + 1);
            (i, j) = (0, hairIds.length);
            while (i < j) {
                h = (i + j) / 2;
                // Manually copy over the little-endian-encoded uint16 from the byte stream
                readValue =
                    uint16(uint8(hairPartialSum[(2 * h)])) +
                    (uint16(uint8(hairPartialSum[(2 * h) + 1])) << 8);
                if (readValue < pick) {
                    i = h + 1;
                } else {
                    j = h;
                }
            }
            returned.hair = uint8(hairIds[i]);

            // Hair color
            pick = uint32(Int31n(rng, 1000) + 1);
            (i, j) = (0, hairColorIds.length);
            while (i < j) {
                h = (i + j) / 2;
                // Manually copy over the little-endian-encoded uint16 from the byte stream
                readValue =
                    uint16(uint8(hairColorPartialSum[(2 * h)])) +
                    (uint16(uint8(hairColorPartialSum[(2 * h) + 1])) << 8);
                if (readValue < pick) {
                    i = h + 1;
                } else {
                    j = h;
                }
            }
            returned.hairColor = uint8(hairColorIds[i]);

            // Back
            // Archers and Slayers can't equip some backs; the valid item set
            // and order is wholly different
            if (returned.class == 0 || returned.class == 3) {
                pick = uint32(Int31n(rng, 273) + 1);
                (i, j) = (0, backArcherSlayerId.length);
                while (i < j) {
                    h = (i + j) / 2;
                    // Manually copy over the little-endian-encoded uint16 from the byte stream
                    readValue =
                        uint16(uint8(backArcherSlayerPartialSum[(2 * h)])) +
                        (uint16(
                            uint8(backArcherSlayerPartialSum[(2 * h) + 1])
                        ) << 8);
                    if (readValue < pick) {
                        i = h + 1;
                    } else {
                        j = h;
                    }
                }
                returned.back = uint8(backArcherSlayerId[i]);
            } else {
                pick = uint32(Int31n(rng, 290) + 1);
                (i, j) = (0, backIds.length);
                while (i < j) {
                    h = (i + j) / 2;
                    // Manually copy over the little-endian-encoded uint16 from the byte stream
                    readValue =
                        uint16(uint8(backPartialSum[(2 * h)])) +
                        (uint16(uint8(backPartialSum[(2 * h) + 1])) << 8);
                    if (readValue < pick) {
                        i = h + 1;
                    } else {
                        j = h;
                    }
                }
                returned.back = uint8(backIds[i]);
            }

            // Aura
            pick = uint32(Int31n(rng, 10000) + 1);
            (i, j) = (0, auraIds.length);
            while (i < j) {
                h = (i + j) / 2;
                // Manually copy over the little-endian-encoded uint16 from the byte stream
                readValue =
                    uint16(uint8(auraPartialSum[(2 * h)])) +
                    (uint16(uint8(auraPartialSum[(2 * h) + 1])) << 8);
                if (readValue < pick) {
                    i = h + 1;
                } else {
                    j = h;
                }
            }
            returned.aura = uint8(auraIds[i]);

            // Top
            pick = uint32(Int31n(rng, 10400) + 1);
            (i, j) = (0, topIds.length);
            while (i < j) {
                h = (i + j) / 2;
                // Manually copy over the little-endian-encoded uint16 from the byte stream
                readValue =
                    uint16(uint8(topPartialSum[(2 * h)])) +
                    (uint16(uint8(topPartialSum[(2 * h) + 1])) << 8);
                if (readValue < pick) {
                    i = h + 1;
                } else {
                    j = h;
                }
            }
            uint8 top = uint8(topIds[i]);
            returned.top = top;

            // Bottom
            if (top == 31) {
                returned.bottom = 17; // Thrifty Getup set
            } else if (top == 30) {
                returned.bottom = 16; // Farmer Apron set
            } else if (
                top == 54 ||
                top == 48 ||
                (top <= 46 && top >= 40) ||
                top == 24 ||
                top == 26 ||
                top == 29 ||
                top == 3
            ) {
                returned.bottom = 0; // Full-body tops
            } else {
                pick = uint32(Int31n(rng, 100) + 1);
                (i, j) = (0, bottomIds.length);
                while (i < j) {
                    h = (i + j) / 2;
                    // Manually copy over the little-endian-encoded uint16 from the byte stream
                    readValue =
                        uint16(uint8(bottomPartialSum[(2 * h)])) +
                        (uint16(uint8(bottomPartialSum[(2 * h) + 1])) << 8);
                    if (readValue < pick) {
                        i = h + 1;
                    } else {
                        j = h;
                    }
                }
                returned.bottom = uint8(bottomIds[i]);
            }

            return returned;
        }
    }

    Traits public traits;

    function storeTraits(uint256 seed) public {
        traits = getTraits(seed);
    }

    // Here is modified Go's math/rand logic optimized for capped on-chain random
    // number generation.
    // https://cs.opensource.google/go/go/+/master:src/math/rand/rand.go;l=5;drc=690ac4071fa3e07113bf371c9e74394ab54d6749
    // rand.go
    /// @dev Equivalent of Go's `rand.New(rand.NewSource(seed.Int64))`
    /// We only support `rand.Intn`, so we use `Source` directly
    function newRand(uint256 seed) public pure returns (Source memory) {
        // https://etherscan.io/address/0x2ed251752da7f24f33cfbd38438748bb8eeb44e1#readContract
        // seed = getSeed(
        //   origin = [email protected],
        //   identifier
        // )
        // Equivalent of `seed.Int64()`
        // https://cs.opensource.google/go/go/+/master:src/math/big/int.go;l=368;drc=831f1168289e65a7ef49942ad8d16cf14af2ef43
        // Takes the least significant 64 bits of x and then preserves the sign
        // NOTE: Go's `math/big` uses little-endian encoding, so does Solidity
        // for the numbers so just use the truncating conversion directly
        uint64 truncatedSeed = uint64(seed);
        // Equivalent of `rand.NewSource(..)`
        Source memory source = NewSource(int64(truncatedSeed));
        // We only care about `rand.Intn` so we use the underlying `Source` directly
        return source;
    }

    // https://cs.opensource.google/go/go/+/master:src/math/rand/rand.go;l=43;drc=690ac4071fa3e07113bf371c9e74394ab54d6749
    function NewSource(int64 seed) public pure returns (Source memory) {
        Source memory source;
        Seed(source, seed);
        return source;
    }

    // Intn returns, as an int, a non-negative pseudo-random number in the half-open interval [0,n).
    // It panics if n <= 0.
    function Int31n(Source memory rng, int32 n) public pure returns (int32) {
        unchecked {
            require(n > 0, "invalid argument to Int31n");
            if (n & (n - 1) == 0) {
                // n is power of two, can mask
                return Int31(rng) & (n - 1);
            }
            int32 max = int32((1 << 31) - 1 - ((1 << 31) % uint32(n)));
            int32 v = Int31(rng);
            while (v > max) {
                v = Int31(rng);
            }
            return v % n;
        }
    }

    function Int31(Source memory rng) public pure returns (int32) {
        return int32(Int63(rng) >> 32);
    }

    // rng.go

    // NOTE: This is a modified version that allows only for a stream of up to
    // 10 random numbers to save the PRNG initialization gas cost.

    uint16 constant RNG_LEN = 607;
    uint16 constant RNG_TAP = 273;
    uint64 constant RNG_MASK = uint64(type(int64).max);
    int32 constant int32max = type(int32).max;

    uint8 constant RNG_COUNT = 10;

    struct Source {
        uint16 tap;
        uint16 feed;
        // int64[RNG_LEN] vec;
        int64[RNG_COUNT * 2] vec;
    }

    // https://cs.opensource.google/go/go/+/master:src/math/rand/rng.go;l=204;drc=2bea43b0e7f3e636ffc8239f9d3fccdd5d763c8b
    // NOTE: We assume seed is not zero
    function Seed(Source memory rng, int64 seed) internal pure {
        rng.tap = 0;
        rng.feed = RNG_COUNT;
        // rng.feed = RNG_LEN - RNG_TAP;

        unchecked {
            seed = seed % int32max;
            if (seed < 0) {
                seed += int32max;
            }
            if (seed == 0) {
                seed = 89482311;
            }
        }

        // We keep the seed in a full word instead to save on constant widening
        uint256 x = uint64(seed);
        uint256 u;
        unchecked {
            // NOTE: This is split into two loops comparing to the original to save
            // on type conversions
            // We're dealing with Lehmer (multiplicative congruential) generator,
            // so we can amortize some of the computations due to the fact that
            // x_i = a^i * x_0 mod m = (a^i mod m) * x_0 mod m
            // where x_0 is the seed, a is the multiplier and m is the modulus.
            // Originally we were calling it initially 20 times, so pre-compute
            // the amortized multiplier with 48271^20 mod 0x7fffffff = 2075782095.
            assembly {
                x := mulmod(x, 2075782095, 0x7fffffff)
            }
            // Then, we optimize by only computing necessary generator state for
            // up to a given random number count (RNG_COUNT). Because of this and
            // because the original algorithm started with numbers from the middle
            // of the pre-cooked values, simply skip the initial phases, which
            // only internally generated random state.
            // Here we skip 324 iterations of generating 2 values, so
            // 48271^(3*324) mod 0x7fffffff = 750037089. (324 = RNG_LEN - RNG_TAP - RNG_COUNT)
            assembly {
                x := mulmod(x, 750037089, 0x7fffffff)
            }
            // Then, we process the part of the generator array originally read
            // by the `feed` cursor (starting from index = RNG_LEN - RNG_TAP - RNG_COUNT)
            int64[10] memory RNG_COOKED_FEED = [
                -6564663803938238204,
                -8060058171802589521,
                581945337509520675,
                3648778920718647903,
                -4799698790548231394,
                -7602572252857820065,
                220828013409515943,
                -1072987336855386047,
                4287360518296753003,
                -4633371852008891965
            ];
            for (uint256 i = 0; i < RNG_COUNT; i++) {
                x = seedrand(x);

                u = x << 40;
                x = seedrand(x);
                u ^= x << 20;
                x = seedrand(x);
                u ^= x;
                u ^= uint64(RNG_COOKED_FEED[i]);

                rng.vec[i] = int64(uint64(u));
            }
            // Again, we skip again the unnedeed feedback register values...
            // 48271^(3*263) mod 0x7fffffff = 1483819319.
            assembly {
                x := mulmod(x, 1483819319, 0x7fffffff)
            }
            // And finally we read the last values originally read by the `tap`
            // cursor (starting from index = RNG_LEN - RNG_COUNT)
            int64[10] memory RNG_COOKED_TAP = [
                -6344160503358350167,
                5896236396443472108,
                -758328221503023383,
                -1894351639983151068,
                -307900319840287220,
                -6278469401177312761,
                -2171292963361310674,
                8382142935188824023,
                9103922860780351547,
                4152330101494654406
            ];
            for (uint256 i = 0; i < RNG_COUNT; i++) {
                x = seedrand(x);
                u = x << 40;
                x = seedrand(x);
                u ^= x << 20;
                x = seedrand(x);
                u ^= x;
                u ^= uint64(RNG_COOKED_TAP[i]);

                rng.vec[RNG_COUNT + i] = int64(uint64(u));
            }
        }
    }

    // https://en.wikipedia.org/wiki/Lehmer_random_number_generator
    // seed rng x[n+1] = 48271 * x[n] mod (2**31 - 1)
    function seedrand(uint256 x) internal pure returns (uint256 r) {
        assembly {
            r := mulmod(x, 48271, 0x7fffffff)
        }
    }

    function Uint64(Source memory rng) public pure returns (uint64) {
        unchecked {
            if (rng.tap == 0) {
                // rng.tap = RNG_LEN - 1;
                rng.tap = (2 * RNG_COUNT) - 1;
            } else {
                rng.tap--;
            }

            if (rng.feed == 0) {
                // rng.feed = RNG_LEN - 1;
                rng.feed = (2 * RNG_COUNT) - 1;
            } else {
                rng.feed--;
            }

            // NOTE: Go version relies on wrapping arithmetic
            int64 x = rng.vec[rng.feed] + rng.vec[rng.tap];
            rng.vec[rng.feed] = x;
            return uint64(x);
        }
    }

    // Int63 returns a non-negative pseudo-random 63-bit integer as an int64.
    function Int63(Source memory rng) public pure returns (int64) {
        return int64(Uint64(rng) & RNG_MASK);
    }
}