// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ISeeder.sol";

/// @title RaidParty Fighter Trait Generation, on-chain version
/// @author xanewok.eth
/// @notice This is a recreation of the original trait generation logic
/// on-chain for transparency and redundancy's sake. The traits calculated here
/// are only numerical and do not carry a user-facing name to limit the scope
// and to save on gas. The trait ID <-> name mapping should be available publicly,
// however it is not stored on the chain for the time being.
contract FighterTraits is Ownable {
    address _fighter;
    address _seeder;

    constructor(address fighter, address seeder) {
        _fighter = fighter;
        _seeder = seeder;
    }

    function setFighter(address fighter) external onlyOwner {
        _fighter = fighter;
    }

    function setSeeder(address fighter) external onlyOwner {
        _fighter = fighter;
    }

    function isSeeded(uint256 identifier) public view returns (bool) {
        return ISeeder(_seeder).isSeeded(_fighter, identifier);
    }

    function getSeed(uint256 identifier) public view returns (uint256) {
        return ISeeder(_seeder).getSeed(_fighter, identifier);
    }

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

    /// @notice Retrieve raw trait IDs for a given seed value.
    function getStartingTraitsBySeed(uint256 seed)
        public
        pure
        returns (Traits memory)
    {
        // The original version used Go's math/rand and https://github.com/mroth/weightedrand
        // to pick the traits on the back-end and serve that as an API endpoint.
        // This attempts to faithfully recreate this logic on-chain for
        // transparency and redundancy's sake.
        Source memory rng = newRand(seed);

        Traits memory returned;

        unchecked {
            // Pick traits using a weighted random; the upper bound is a sum of
            // those weights
            returned.class = pickClass(Int31n(rng, 60) + 1);
            returned.body = pickBody(Int31n(rng, 99) + 1);
            returned.weapon = pickWeapon(Int31n(rng, 100) + 1);
            returned.hair = pickHair(Int31n(rng, 7849) + 1);
            returned.hairColor = pickHairColor(Int31n(rng, 1000) + 1);
            // Archers and Slayers can't equip some backs; the valid item set
            // and order is wholly different, so we use a different lookup
            if (returned.class == 0 || returned.class == 3) {
                returned.back = pickBackArcherSlayer(Int31n(rng, 273) + 1);
            } else {
                returned.back = pickBack(Int31n(rng, 290) + 1);
            }
            returned.aura = pickAura(Int31n(rng, 10000) + 1);
            returned.top = pickTop(Int31n(rng, 10400) + 1);
            uint8 top = returned.top;
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
                returned.bottom = 18; // Full-body tops, return "None"
            } else {
                returned.bottom = pickBottom(Int31n(rng, 100) + 1);
            }

            return returned;
        }
    }

    /// @notice Retrieves the default trait IDs for a given tokenId
    function getStartingTraitsById(uint256 identifier)
        public
        view
        returns (Traits memory)
    {
        uint256 seed = getSeed(identifier);
        return getStartingTraitsBySeed(seed);
    }

    // HERE BE DRAGONS
    error ValueOutOfBounds();

    // The original approach used an unstable sort as part of the weighted random
    // selection via https://github.com/mroth/weightedrand. We avoid re-implementing
    // Go's unstable sort here and just hardcode the resulting order of the items.
    // The inlined bin lookup was generated with the `resource/inline-trait-selection` script.
    function pickClass(int32 pick) internal pure returns (uint8 id) {
        if (40 < pick) {
            if (60 < pick) {
                revert ValueOutOfBounds();
            } else {
                if (50 < pick) {
                    return (5);
                } else {
                    return (4);
                }
            }
        } else {
            if (20 < pick) {
                if (30 < pick) {
                    return (3);
                } else {
                    return (2);
                }
            } else {
                if (10 < pick) {
                    return (1);
                } else {
                    return (0);
                }
            }
        }
    }

    function pickBody(int32 pick) internal pure returns (uint8 id) {
        if (43 < pick) {
            if (99 < pick) {
                revert ValueOutOfBounds();
            } else {
                if (71 < pick) {
                    return (2);
                } else {
                    return (1);
                }
            }
        } else {
            if (8 < pick) {
                if (15 < pick) {
                    return (0);
                } else {
                    return (4);
                }
            } else {
                if (1 < pick) {
                    return (3);
                } else {
                    return (5);
                }
            }
        }
    }

    function pickWeapon(int32 pick) internal pure returns (uint8 id) {
        if (38 < pick) {
            if (78 < pick) {
                if (100 < pick) {
                    revert ValueOutOfBounds();
                } else {
                    return (0);
                }
            } else {
                if (63 < pick) {
                    return (1);
                } else {
                    if (50 < pick) {
                        return (2);
                    } else {
                        return (3);
                    }
                }
            }
        } else {
            if (12 < pick) {
                if (28 < pick) {
                    return (4);
                } else {
                    if (19 < pick) {
                        return (5);
                    } else {
                        return (6);
                    }
                }
            } else {
                if (6 < pick) {
                    return (7);
                } else {
                    if (1 < pick) {
                        return (8);
                    } else {
                        return (9);
                    }
                }
            }
        }
    }

    function pickHair(int32 pick) internal pure returns (uint8 id) {
        if (2349 < pick) {
            if (5349 < pick) {
                if (6849 < pick) {
                    if (7849 < pick) {
                        revert ValueOutOfBounds();
                    } else {
                        if (7349 < pick) {
                            return (22);
                        } else {
                            return (21);
                        }
                    }
                } else {
                    if (6349 < pick) {
                        return (20);
                    } else {
                        if (5849 < pick) {
                            return (5);
                        } else {
                            return (18);
                        }
                    }
                }
            } else {
                if (3849 < pick) {
                    if (4849 < pick) {
                        return (6);
                    } else {
                        if (4349 < pick) {
                            return (7);
                        } else {
                            return (15);
                        }
                    }
                } else {
                    if (3349 < pick) {
                        return (14);
                    } else {
                        if (2849 < pick) {
                            return (8);
                        } else {
                            return (9);
                        }
                    }
                }
            }
        } else {
            if (499 < pick) {
                if (1249 < pick) {
                    if (1849 < pick) {
                        return (0);
                    } else {
                        if (1549 < pick) {
                            return (12);
                        } else {
                            return (16);
                        }
                    }
                } else {
                    if (949 < pick) {
                        return (11);
                    } else {
                        if (649 < pick) {
                            return (1);
                        } else {
                            return (10);
                        }
                    }
                }
            } else {
                if (136 < pick) {
                    if (349 < pick) {
                        return (13);
                    } else {
                        if (199 < pick) {
                            return (4);
                        } else {
                            return (19);
                        }
                    }
                } else {
                    if (73 < pick) {
                        return (3);
                    } else {
                        if (10 < pick) {
                            return (2);
                        } else {
                            return (17);
                        }
                    }
                }
            }
        }
    }

    function pickHairColor(int32 pick) internal pure returns (uint8 id) {
        if (400 < pick) {
            if (850 < pick) {
                if (1000 < pick) {
                    revert ValueOutOfBounds();
                } else {
                    return (8);
                }
            } else {
                if (700 < pick) {
                    return (7);
                } else {
                    if (550 < pick) {
                        return (0);
                    } else {
                        return (5);
                    }
                }
            }
        } else {
            if (125 < pick) {
                if (250 < pick) {
                    return (2);
                } else {
                    return (3);
                }
            } else {
                if (75 < pick) {
                    return (4);
                } else {
                    if (25 < pick) {
                        return (1);
                    } else {
                        return (6);
                    }
                }
            }
        }
    }

    function pickBack(int32 pick) internal pure returns (uint8 id) {
        if (70 < pick) {
            if (135 < pick) {
                if (210 < pick) {
                    if (290 < pick) {
                        revert ValueOutOfBounds();
                    } else {
                        return (0);
                    }
                } else {
                    if (185 < pick) {
                        return (11);
                    } else {
                        if (160 < pick) {
                            return (12);
                        } else {
                            return (13);
                        }
                    }
                }
            } else {
                if (100 < pick) {
                    if (110 < pick) {
                        return (14);
                    } else {
                        return (19);
                    }
                } else {
                    if (90 < pick) {
                        return (17);
                    } else {
                        if (80 < pick) {
                            return (18);
                        } else {
                            return (1);
                        }
                    }
                }
            }
        } else {
            if (20 < pick) {
                if (50 < pick) {
                    if (60 < pick) {
                        return (9);
                    } else {
                        return (8);
                    }
                } else {
                    if (40 < pick) {
                        return (6);
                    } else {
                        if (30 < pick) {
                            return (5);
                        } else {
                            return (4);
                        }
                    }
                }
            } else {
                if (5 < pick) {
                    if (15 < pick) {
                        return (16);
                    } else {
                        if (10 < pick) {
                            return (2);
                        } else {
                            return (3);
                        }
                    }
                } else {
                    if (3 < pick) {
                        return (15);
                    } else {
                        if (1 < pick) {
                            return (7);
                        } else {
                            return (10);
                        }
                    }
                }
            }
        }
    }

    function pickBackArcherSlayer(int32 pick) internal pure returns (uint8 id) {
        if (63 < pick) {
            if (143 < pick) {
                if (193 < pick) {
                    if (273 < pick) {
                        revert ValueOutOfBounds();
                    } else {
                        return (0);
                    }
                } else {
                    if (168 < pick) {
                        return (11);
                    } else {
                        return (12);
                    }
                }
            } else {
                if (93 < pick) {
                    if (118 < pick) {
                        return (14);
                    } else {
                        return (13);
                    }
                } else {
                    if (83 < pick) {
                        return (19);
                    } else {
                        if (73 < pick) {
                            return (17);
                        } else {
                            return (9);
                        }
                    }
                }
            }
        } else {
            if (23 < pick) {
                if (43 < pick) {
                    if (53 < pick) {
                        return (8);
                    } else {
                        return (6);
                    }
                } else {
                    if (33 < pick) {
                        return (5);
                    } else {
                        return (4);
                    }
                }
            } else {
                if (8 < pick) {
                    if (13 < pick) {
                        return (1);
                    } else {
                        return (3);
                    }
                } else {
                    if (3 < pick) {
                        return (2);
                    } else {
                        if (1 < pick) {
                            return (15);
                        } else {
                            return (10);
                        }
                    }
                }
            }
        }
    }

    function pickAura(int32 pick) internal pure returns (uint8 id) {
        if (650 < pick) {
            if (1050 < pick) {
                if (1250 < pick) {
                    if (10000 < pick) {
                        revert ValueOutOfBounds();
                    } else {
                        return (0);
                    }
                } else {
                    if (1150 < pick) {
                        return (14);
                    } else {
                        return (13);
                    }
                }
            } else {
                if (850 < pick) {
                    if (950 < pick) {
                        return (1);
                    } else {
                        return (3);
                    }
                } else {
                    if (750 < pick) {
                        return (5);
                    } else {
                        return (9);
                    }
                }
            }
        } else {
            if (325 < pick) {
                if (475 < pick) {
                    if (550 < pick) {
                        return (7);
                    } else {
                        return (15);
                    }
                } else {
                    if (400 < pick) {
                        return (6);
                    } else {
                        return (10);
                    }
                }
            } else {
                if (175 < pick) {
                    if (250 < pick) {
                        return (4);
                    } else {
                        return (12);
                    }
                } else {
                    if (100 < pick) {
                        return (8);
                    } else {
                        if (50 < pick) {
                            return (11);
                        } else {
                            return (2);
                        }
                    }
                }
            }
        }
    }

    function pickTop(int32 pick) internal pure returns (uint8 id) {
        if (3050 < pick) {
            if (6500 < pick) {
                if (8600 < pick) {
                    if (9800 < pick) {
                        if (10400 < pick) {
                            revert ValueOutOfBounds();
                        } else {
                            if (10100 < pick) {
                                return (0);
                            } else {
                                return (1);
                            }
                        }
                    } else {
                        if (9200 < pick) {
                            if (9500 < pick) {
                                return (2);
                            } else {
                                return (3);
                            }
                        } else {
                            if (8900 < pick) {
                                return (4);
                            } else {
                                return (5);
                            }
                        }
                    }
                } else {
                    if (7700 < pick) {
                        if (8300 < pick) {
                            return (6);
                        } else {
                            if (8000 < pick) {
                                return (7);
                            } else {
                                return (8);
                            }
                        }
                    } else {
                        if (7100 < pick) {
                            if (7400 < pick) {
                                return (9);
                            } else {
                                return (10);
                            }
                        } else {
                            if (6800 < pick) {
                                return (11);
                            } else {
                                return (12);
                            }
                        }
                    }
                }
            } else {
                if (4400 < pick) {
                    if (5600 < pick) {
                        if (6200 < pick) {
                            return (13);
                        } else {
                            if (5900 < pick) {
                                return (14);
                            } else {
                                return (15);
                            }
                        }
                    } else {
                        if (5000 < pick) {
                            if (5300 < pick) {
                                return (16);
                            } else {
                                return (17);
                            }
                        } else {
                            if (4700 < pick) {
                                return (18);
                            } else {
                                return (19);
                            }
                        }
                    }
                } else {
                    if (3650 < pick) {
                        if (4100 < pick) {
                            return (21);
                        } else {
                            if (3800 < pick) {
                                return (20);
                            } else {
                                return (35);
                            }
                        }
                    } else {
                        if (3350 < pick) {
                            if (3500 < pick) {
                                return (32);
                            } else {
                                return (31);
                            }
                        } else {
                            if (3200 < pick) {
                                return (30);
                            } else {
                                return (29);
                            }
                        }
                    }
                }
            }
        } else {
            if (1025 < pick) {
                if (2000 < pick) {
                    if (2600 < pick) {
                        if (2900 < pick) {
                            return (39);
                        } else {
                            if (2750 < pick) {
                                return (27);
                            } else {
                                return (26);
                            }
                        }
                    } else {
                        if (2300 < pick) {
                            if (2450 < pick) {
                                return (25);
                            } else {
                                return (24);
                            }
                        } else {
                            if (2150 < pick) {
                                return (23);
                            } else {
                                return (22);
                            }
                        }
                    }
                } else {
                    if (1550 < pick) {
                        if (1850 < pick) {
                            return (28);
                        } else {
                            if (1700 < pick) {
                                return (34);
                            } else {
                                return (36);
                            }
                        }
                    } else {
                        if (1250 < pick) {
                            if (1400 < pick) {
                                return (37);
                            } else {
                                return (38);
                            }
                        } else {
                            if (1100 < pick) {
                                return (33);
                            } else {
                                return (40);
                            }
                        }
                    }
                }
            } else {
                if (500 < pick) {
                    if (800 < pick) {
                        if (950 < pick) {
                            return (41);
                        } else {
                            if (875 < pick) {
                                return (42);
                            } else {
                                return (43);
                            }
                        }
                    } else {
                        if (650 < pick) {
                            if (725 < pick) {
                                return (44);
                            } else {
                                return (45);
                            }
                        } else {
                            if (575 < pick) {
                                return (46);
                            } else {
                                return (47);
                            }
                        }
                    }
                } else {
                    if (200 < pick) {
                        if (350 < pick) {
                            if (425 < pick) {
                                return (51);
                            } else {
                                return (49);
                            }
                        } else {
                            if (275 < pick) {
                                return (50);
                            } else {
                                return (48);
                            }
                        }
                    } else {
                        if (100 < pick) {
                            if (150 < pick) {
                                return (52);
                            } else {
                                return (53);
                            }
                        } else {
                            if (50 < pick) {
                                return (54);
                            } else {
                                return (55);
                            }
                        }
                    }
                }
            }
        }
    }

    function pickBottom(int32 pick) internal pure returns (uint8 id) {
        if (27 < pick) {
            if (64 < pick) {
                if (91 < pick) {
                    if (100 < pick) {
                        revert ValueOutOfBounds();
                    } else {
                        return (0);
                    }
                } else {
                    if (82 < pick) {
                        return (1);
                    } else {
                        if (73 < pick) {
                            return (2);
                        } else {
                            return (3);
                        }
                    }
                }
            } else {
                if (46 < pick) {
                    if (55 < pick) {
                        return (4);
                    } else {
                        return (5);
                    }
                } else {
                    if (37 < pick) {
                        return (6);
                    } else {
                        if (32 < pick) {
                            return (9);
                        } else {
                            return (10);
                        }
                    }
                }
            }
        } else {
            if (6 < pick) {
                if (17 < pick) {
                    if (22 < pick) {
                        return (8);
                    } else {
                        return (7);
                    }
                } else {
                    if (12 < pick) {
                        return (11);
                    } else {
                        if (9 < pick) {
                            return (15);
                        } else {
                            return (13);
                        }
                    }
                }
            } else {
                if (0 < pick) {
                    if (3 < pick) {
                        return (14);
                    } else {
                        return (12);
                    }
                } else {
                    if (0 < pick) {
                        return (18);
                    } else {
                        if (0 < pick) {
                            return (16);
                        } else {
                            return (17);
                        }
                    }
                }
            }
        }
    }

    // Here is the modified Go's math/rand logic optimized for capped, on-chain
    // random number generation.
    //
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
    // 12 random numbers to save the PRNG initialization gas cost.
    // Instead of generating and using the full feedback register with 607 numbers,
    // we pre-generate and use two slices of 12 numbers that are read at first
    // by the original implementation.

    uint16 constant RNG_LEN = 607;
    uint16 constant RNG_TAP = 273;
    uint64 constant RNG_MASK = uint64(type(int64).max);
    int32 constant int32max = type(int32).max;

    uint8 constant RNG_COUNT = 12;

    struct Source {
        uint16 tap;
        uint16 feed;
        int64[RNG_COUNT * 2] vec; // Originally RNG_LEN
    }

    // https://cs.opensource.google/go/go/+/master:src/math/rand/rng.go;l=204;drc=2bea43b0e7f3e636ffc8239f9d3fccdd5d763c8b
    // NOTE: We assume seed is not zero
    function Seed(Source memory rng, int64 seed) internal pure {
        rng.tap = 0;
        rng.feed = RNG_COUNT; // Originally RNG_LEN - RNG_TAP

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
            // NOTE: Comparing to the original loop, we attempt to use as much
            // pre-computed modular multiplication as possible to save on loop cycles
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
            // Here we skip 322 iterations of generating 3 values, so
            // 48271^(3*322) mod 0x7fffffff = 1154623084. (322 = RNG_LEN - RNG_TAP - RNG_COUNT)
            assembly {
                x := mulmod(x, 1154623084, 0x7fffffff)
            }
            // Then, we process the part of the generator array originally read
            // by the `feed` cursor (starting from index = RNG_LEN - RNG_TAP - RNG_COUNT)
            int64[RNG_COUNT] memory RNG_COOKED_FEED = [
                -3915372517896561773,
                -2889241648411946534,
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
            // 48271^(3*261) mod 0x7fffffff = 1819259554.
            assembly {
                x := mulmod(x, 1819259554, 0x7fffffff)
            }
            // And finally we read the last values originally read by the `tap`
            // cursor (starting from index = RNG_LEN - RNG_COUNT)
            int64[RNG_COUNT] memory RNG_COOKED_TAP = [
                -3929437324238184044,
                -4300543082831323144,
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
                rng.tap = (2 * RNG_COUNT) - 1; // Originally RNG_LEN - 1
            } else {
                rng.tap--;
            }

            if (rng.feed == 0) {
                rng.feed = (2 * RNG_COUNT) - 1; // Originally RNG_LEN - 1
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Randomness.sol";

interface ISeeder {
    event Requested(address indexed origin, uint256 indexed identifier);

    event Seeded(bytes32 identifier, uint256 randomness);

    function getIdReferenceCount(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx
    ) external view returns (uint256);

    function getIdentifiers(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx,
        uint256 count
    ) external view returns (uint256[] memory);

    function requestSeed(uint256 identifier) external;

    function getSeed(address origin, uint256 identifier)
        external
        view
        returns (uint256);

    function getSeedSafe(address origin, uint256 identifier)
        external
        view
        returns (uint256);

    function executeRequestMulti() external;

    function isSeeded(address origin, uint256 identifier)
        external
        view
        returns (bool);

    function setFee(uint256 fee) external;

    function getFee() external view returns (uint256);

    function getData(address origin, uint256 identifier)
        external
        view
        returns (Randomness.SeedData memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Randomness {
    struct SeedData {
        uint256 batch;
        bytes32 randomnessId;
    }
}