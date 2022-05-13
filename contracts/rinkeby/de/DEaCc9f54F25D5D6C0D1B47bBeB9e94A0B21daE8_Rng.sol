/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// https://cs.opensource.google/go/go/+/master:src/math/rand/rng.go;l=16;drc=2bea43b0e7f3e636ffc8239f9d3fccdd5d763c8b
contract Rng {
    // rand.go

    int64[] values = new int64[](5);

    function doStuff() public {
        Source memory rng = newRand(1337);
        values[0] = Intn(rng, 28);
    }

    function doStuffMany() public {
        Source memory rng = newRand(1337);
        values[0] = Intn(rng, 28);
        values[1] = Intn(rng, 28);
        values[2] = Intn(rng, 28);
        values[3] = Intn(rng, 28);
        values[4] = Intn(rng, 28);
    }

    /// @dev Equivalent of Go's `rand.New(rand.NewSource(seed.Int64))`
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
        // We're only interested in `rand.Intn` so just use return type from `NewSource`
        return source;
        // src := rand.New(
        // rand.NewSource(
        // ))
    }

    // https://cs.opensource.google/go/go/+/master:src/math/rand/rand.go;l=43;drc=690ac4071fa3e07113bf371c9e74394ab54d6749
    function NewSource(int64 seed) public pure returns (Source memory) {
        Source memory source;
        go_seed(source, seed);
        return source;
    }

    // Intn returns, as an int, a non-negative pseudo-random number in the half-open interval [0,n).
    // It panics if n <= 0.
    function Intn(Source memory rng, int32 n) public pure returns (int32) {
        require(n > 0, "invalid argument to Int31n");
        if (n <= type(int32).max) {
            return int32(Int31n(rng, n));
        } else {
            require(false, "unimplemented");
            return -1;
            // return int(r.Int63n(int64(n)))
        }
    }

    function IntnMany(Source memory rng, int32 n)
        public
        pure
        returns (
            int32,
            int32,
            int32
        )
    {
        int32 a = Intn(rng, n);
        int32 b = Intn(rng, n);
        int32 c = Intn(rng, n);
        return (a, b, c);
    }

    function Int31n(Source memory rng, int32 n) internal pure returns (int32) {
        require(n > 0, "invalid argument to Int31n");
        if (n & (n - 1) == 0) {
            // n is power of two, can mask
            return Int31(rng) & (n - 1);
        }
        unchecked {
            int32 max = int32((1 << 31) - 1 - ((1 << 31) % uint32(n)));
            int32 v = Int31(rng);
            while (v > max) {
                v = Int31(rng);
            }
            return v % n;
        }
    }

    function Int31(Source memory rng) internal pure returns (int32) {
        return int32(Int63(rng) >> 32);
    }

    // rng.go

    uint16 constant RNG_LEN = 607;
    uint16 constant RNG_TAP = 273;
    uint64 constant RNG_MASK = uint64(type(int64).max);
    int32 constant int32max = type(int32).max;

    int32 constant A = 48271;
    int32 constant Q = 44488;
    int32 constant R = 3399;

    struct Source {
        uint16 tap;
        uint16 feed;
        int64[RNG_LEN] vec;
    }

    // https://cs.opensource.google/go/go/+/master:src/math/rand/rng.go;l=204;drc=2bea43b0e7f3e636ffc8239f9d3fccdd5d763c8b
    function go_seed(Source memory rng, int64 seed) internal pure {
        rng.tap = 0;
        rng.feed = RNG_LEN - RNG_TAP;

        seed = seed % int32max;
        if (seed < 0) {
            seed += int32max;
        }
        if (seed == 0) {
            seed = 89482311;
        }

        int32 x = int32(seed);
        // NOTE: This is split into two loops comparing to the original to save
        // on type conversions
        for (int256 i = -20; i < 0; i++) {
            x = seedrand(x);
        }
        for (uint256 i = 0; i < RNG_LEN; i++) {
            x = seedrand(x);
            if (i >= 0) {
                int64 u;
                u = int64(x) << 40;
                x = seedrand(x);
                u ^= int64(x) << 20;
                x = seedrand(x);
                u ^= int64(x);
                u ^= rngCooked(i);
                rng.vec[i] = u;
            }
        }
    }

    // seed rng x[n+1] = 48271 * x[n] mod (2**31 - 1)
    function seedrand(int32 x) internal pure returns (int32) {
        unchecked {
            int32 hi = x / Q;
            int32 lo = x % Q;
            x = A * lo - R * hi;
            if (x < 0) {
                x += int32max;
            }
            return x;
        }
    }

    function Uint64(Source memory rng) internal pure returns (uint64) {
        if (rng.tap == 0) {
            rng.tap = RNG_LEN - 1;
        } else {
            rng.tap--;
        }

        if (rng.feed == 0) {
            rng.feed = RNG_LEN - 1;
        } else {
            rng.feed--;
        }
        // rng.feed--;
        // if (rng.feed < 0) {
        //     rng.feed += int16(RNG_LEN);
        // }

        unchecked {
            int64 x = rng.vec[rng.feed] + rng.vec[rng.tap];
            rng.vec[rng.feed] = x;
            return uint64(x);
        }
    }

    // Int63 returns a non-negative pseudo-random 63-bit integer as an int64.
    function Int63(Source memory rng) internal pure returns (int64) {
        return int64(Uint64(rng) & RNG_MASK);
    }

    // FIXME: Needs a sane constant lookup table mechanism,
    // see: https://github.com/ethereum/solidity/issues/12821
    function rngCooked(uint256 index) public pure returns (int64 r) {
        // https://cs.opensource.google/go/go/+/master:src/math/rand/rng.go;l=23;drc=2bea43b0e7f3e636ffc8239f9d3fccdd5d763c8b
        if (index <= 303) {
            if (index <= 151) {
                if (index <= 75) {
                    if (index <= 37) {
                        if (index <= 18) {
                            if (index <= 9) {
                                if (index <= 4) {
                                    if (index <= 2) {
                                        if (index <= 1) {
                                            if (index <= 0) {
                                                return -4181792142133755926;
                                            } else {
                                                return -4576982950128230565;
                                            }
                                        } else {
                                            return 1395769623340756751;
                                        }
                                    } else {
                                        if (index <= 3) {
                                            return 5333664234075297259;
                                        } else {
                                            return -6347679516498800754;
                                        }
                                    }
                                } else {
                                    if (index <= 7) {
                                        if (index <= 6) {
                                            if (index <= 5) {
                                                return 9033628115061424579;
                                            } else {
                                                return 7143218595135194537;
                                            }
                                        } else {
                                            return 4812947590706362721;
                                        }
                                    } else {
                                        if (index <= 8) {
                                            return 7937252194349799378;
                                        } else {
                                            return 5307299880338848416;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 14) {
                                    if (index <= 12) {
                                        if (index <= 11) {
                                            if (index <= 10) {
                                                return 8209348851763925077;
                                            } else {
                                                return -7107630437535961764;
                                            }
                                        } else {
                                            return 4593015457530856296;
                                        }
                                    } else {
                                        if (index <= 13) {
                                            return 8140875735541888011;
                                        } else {
                                            return -5903942795589686782;
                                        }
                                    }
                                } else {
                                    if (index <= 16) {
                                        if (index <= 15) {
                                            return -603556388664454774;
                                        } else {
                                            return -7496297993371156308;
                                        }
                                    } else {
                                        if (index <= 17) {
                                            return 113108499721038619;
                                        } else {
                                            return 4569519971459345583;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 28) {
                                if (index <= 23) {
                                    if (index <= 21) {
                                        if (index <= 20) {
                                            if (index <= 19) {
                                                return -4160538177779461077;
                                            } else {
                                                return -6835753265595711384;
                                            }
                                        } else {
                                            return -6507240692498089696;
                                        }
                                    } else {
                                        if (index <= 22) {
                                            return 6559392774825876886;
                                        } else {
                                            return 7650093201692370310;
                                        }
                                    }
                                } else {
                                    if (index <= 26) {
                                        if (index <= 25) {
                                            if (index <= 24) {
                                                return 7684323884043752161;
                                            } else {
                                                return -8965504200858744418;
                                            }
                                        } else {
                                            return -2629915517445760644;
                                        }
                                    } else {
                                        if (index <= 27) {
                                            return 271327514973697897;
                                        } else {
                                            return -6433985589514657524;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 33) {
                                    if (index <= 31) {
                                        if (index <= 30) {
                                            if (index <= 29) {
                                                return 1065192797246149621;
                                            } else {
                                                return 3344507881999356393;
                                            }
                                        } else {
                                            return -4763574095074709175;
                                        }
                                    } else {
                                        if (index <= 32) {
                                            return 7465081662728599889;
                                        } else {
                                            return 1014950805555097187;
                                        }
                                    }
                                } else {
                                    if (index <= 35) {
                                        if (index <= 34) {
                                            return -4773931307508785033;
                                        } else {
                                            return -5742262670416273165;
                                        }
                                    } else {
                                        if (index <= 36) {
                                            return 2418672789110888383;
                                        } else {
                                            return 5796562887576294778;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 56) {
                            if (index <= 47) {
                                if (index <= 42) {
                                    if (index <= 40) {
                                        if (index <= 39) {
                                            if (index <= 38) {
                                                return 4484266064449540171;
                                            } else {
                                                return 3738982361971787048;
                                            }
                                        } else {
                                            return -4699774852342421385;
                                        }
                                    } else {
                                        if (index <= 41) {
                                            return 10530508058128498;
                                        } else {
                                            return -589538253572429690;
                                        }
                                    }
                                } else {
                                    if (index <= 45) {
                                        if (index <= 44) {
                                            if (index <= 43) {
                                                return -6598062107225984180;
                                            } else {
                                                return 8660405965245884302;
                                            }
                                        } else {
                                            return 10162832508971942;
                                        }
                                    } else {
                                        if (index <= 46) {
                                            return -2682657355892958417;
                                        } else {
                                            return 7031802312784620857;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 52) {
                                    if (index <= 50) {
                                        if (index <= 49) {
                                            if (index <= 48) {
                                                return 6240911277345944669;
                                            } else {
                                                return 831864355460801054;
                                            }
                                        } else {
                                            return -1218937899312622917;
                                        }
                                    } else {
                                        if (index <= 51) {
                                            return 2116287251661052151;
                                        } else {
                                            return 2202309800992166967;
                                        }
                                    }
                                } else {
                                    if (index <= 54) {
                                        if (index <= 53) {
                                            return 9161020366945053561;
                                        } else {
                                            return 4069299552407763864;
                                        }
                                    } else {
                                        if (index <= 55) {
                                            return 4936383537992622449;
                                        } else {
                                            return 457351505131524928;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 66) {
                                if (index <= 61) {
                                    if (index <= 59) {
                                        if (index <= 58) {
                                            if (index <= 57) {
                                                return -8881176990926596454;
                                            } else {
                                                return -6375600354038175299;
                                            }
                                        } else {
                                            return -7155351920868399290;
                                        }
                                    } else {
                                        if (index <= 60) {
                                            return 4368649989588021065;
                                        } else {
                                            return 887231587095185257;
                                        }
                                    }
                                } else {
                                    if (index <= 64) {
                                        if (index <= 63) {
                                            if (index <= 62) {
                                                return -3659780529968199312;
                                            } else {
                                                return -2407146836602825512;
                                            }
                                        } else {
                                            return 5616972787034086048;
                                        }
                                    } else {
                                        if (index <= 65) {
                                            return -751562733459939242;
                                        } else {
                                            return 1686575021641186857;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 71) {
                                    if (index <= 69) {
                                        if (index <= 68) {
                                            if (index <= 67) {
                                                return -5177887698780513806;
                                            } else {
                                                return -4979215821652996885;
                                            }
                                        } else {
                                            return -1375154703071198421;
                                        }
                                    } else {
                                        if (index <= 70) {
                                            return 5632136521049761902;
                                        } else {
                                            return -8390088894796940536;
                                        }
                                    }
                                } else {
                                    if (index <= 73) {
                                        if (index <= 72) {
                                            return -193645528485698615;
                                        } else {
                                            return -5979788902190688516;
                                        }
                                    } else {
                                        if (index <= 74) {
                                            return -4907000935050298721;
                                        } else {
                                            return -285522056888777828;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (index <= 113) {
                        if (index <= 94) {
                            if (index <= 85) {
                                if (index <= 80) {
                                    if (index <= 78) {
                                        if (index <= 77) {
                                            if (index <= 76) {
                                                return -2776431630044341707;
                                            } else {
                                                return 1679342092332374735;
                                            }
                                        } else {
                                            return 6050638460742422078;
                                        }
                                    } else {
                                        if (index <= 79) {
                                            return -2229851317345194226;
                                        } else {
                                            return -1582494184340482199;
                                        }
                                    }
                                } else {
                                    if (index <= 83) {
                                        if (index <= 82) {
                                            if (index <= 81) {
                                                return 5881353426285907985;
                                            } else {
                                                return 812786550756860885;
                                            }
                                        } else {
                                            return 4541845584483343330;
                                        }
                                    } else {
                                        if (index <= 84) {
                                            return -6497901820577766722;
                                        } else {
                                            return 4980675660146853729;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 90) {
                                    if (index <= 88) {
                                        if (index <= 87) {
                                            if (index <= 86) {
                                                return -4012602956251539747;
                                            } else {
                                                return -329088717864244987;
                                            }
                                        } else {
                                            return -2896929232104691526;
                                        }
                                    } else {
                                        if (index <= 89) {
                                            return 1495812843684243920;
                                        } else {
                                            return -2153620458055647789;
                                        }
                                    }
                                } else {
                                    if (index <= 92) {
                                        if (index <= 91) {
                                            return 7370257291860230865;
                                        } else {
                                            return -2466442761497833547;
                                        }
                                    } else {
                                        if (index <= 93) {
                                            return 4706794511633873654;
                                        } else {
                                            return -1398851569026877145;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 104) {
                                if (index <= 99) {
                                    if (index <= 97) {
                                        if (index <= 96) {
                                            if (index <= 95) {
                                                return 8549875090542453214;
                                            } else {
                                                return -9189721207376179652;
                                            }
                                        } else {
                                            return -7894453601103453165;
                                        }
                                    } else {
                                        if (index <= 98) {
                                            return 7297902601803624459;
                                        } else {
                                            return 1011190183918857495;
                                        }
                                    }
                                } else {
                                    if (index <= 102) {
                                        if (index <= 101) {
                                            if (index <= 100) {
                                                return -6985347000036920864;
                                            } else {
                                                return 5147159997473910359;
                                            }
                                        } else {
                                            return -8326859945294252826;
                                        }
                                    } else {
                                        if (index <= 103) {
                                            return 2659470849286379941;
                                        } else {
                                            return 6097729358393448602;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 109) {
                                    if (index <= 107) {
                                        if (index <= 106) {
                                            if (index <= 105) {
                                                return -7491646050550022124;
                                            } else {
                                                return -5117116194870963097;
                                            }
                                        } else {
                                            return -896216826133240300;
                                        }
                                    } else {
                                        if (index <= 108) {
                                            return -745860416168701406;
                                        } else {
                                            return 5803876044675762232;
                                        }
                                    }
                                } else {
                                    if (index <= 111) {
                                        if (index <= 110) {
                                            return -787954255994554146;
                                        } else {
                                            return -3234519180203704564;
                                        }
                                    } else {
                                        if (index <= 112) {
                                            return -4507534739750823898;
                                        } else {
                                            return -1657200065590290694;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 132) {
                            if (index <= 123) {
                                if (index <= 118) {
                                    if (index <= 116) {
                                        if (index <= 115) {
                                            if (index <= 114) {
                                                return 505808562678895611;
                                            } else {
                                                return -4153273856159712438;
                                            }
                                        } else {
                                            return -8381261370078904295;
                                        }
                                    } else {
                                        if (index <= 117) {
                                            return 572156825025677802;
                                        } else {
                                            return 1791881013492340891;
                                        }
                                    }
                                } else {
                                    if (index <= 121) {
                                        if (index <= 120) {
                                            if (index <= 119) {
                                                return 3393267094866038768;
                                            } else {
                                                return -5444650186382539299;
                                            }
                                        } else {
                                            return 2352769483186201278;
                                        }
                                    } else {
                                        if (index <= 122) {
                                            return -7930912453007408350;
                                        } else {
                                            return -325464993179687389;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 128) {
                                    if (index <= 126) {
                                        if (index <= 125) {
                                            if (index <= 124) {
                                                return -3441562999710612272;
                                            } else {
                                                return -6489413242825283295;
                                            }
                                        } else {
                                            return 5092019688680754699;
                                        }
                                    } else {
                                        if (index <= 127) {
                                            return -227247482082248967;
                                        } else {
                                            return 4234737173186232084;
                                        }
                                    }
                                } else {
                                    if (index <= 130) {
                                        if (index <= 129) {
                                            return 5027558287275472836;
                                        } else {
                                            return 4635198586344772304;
                                        }
                                    } else {
                                        if (index <= 131) {
                                            return -536033143587636457;
                                        } else {
                                            return 5907508150730407386;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 142) {
                                if (index <= 137) {
                                    if (index <= 135) {
                                        if (index <= 134) {
                                            if (index <= 133) {
                                                return -8438615781380831356;
                                            } else {
                                                return 972392927514829904;
                                            }
                                        } else {
                                            return -3801314342046600696;
                                        }
                                    } else {
                                        if (index <= 136) {
                                            return -4064951393885491917;
                                        } else {
                                            return -174840358296132583;
                                        }
                                    }
                                } else {
                                    if (index <= 140) {
                                        if (index <= 139) {
                                            if (index <= 138) {
                                                return 2407211146698877100;
                                            } else {
                                                return -1640089820333676239;
                                            }
                                        } else {
                                            return 3940796514530962282;
                                        }
                                    } else {
                                        if (index <= 141) {
                                            return -5882197405809569433;
                                        } else {
                                            return 3095313889586102949;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 147) {
                                    if (index <= 145) {
                                        if (index <= 144) {
                                            if (index <= 143) {
                                                return -1818050141166537098;
                                            } else {
                                                return 5832080132947175283;
                                            }
                                        } else {
                                            return 7890064875145919662;
                                        }
                                    } else {
                                        if (index <= 146) {
                                            return 8184139210799583195;
                                        } else {
                                            return -8073512175445549678;
                                        }
                                    }
                                } else {
                                    if (index <= 149) {
                                        if (index <= 148) {
                                            return -7758774793014564506;
                                        } else {
                                            return -4581724029666783935;
                                        }
                                    } else {
                                        if (index <= 150) {
                                            return 3516491885471466898;
                                        } else {
                                            return -8267083515063118116;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (index <= 227) {
                    if (index <= 189) {
                        if (index <= 170) {
                            if (index <= 161) {
                                if (index <= 156) {
                                    if (index <= 154) {
                                        if (index <= 153) {
                                            if (index <= 152) {
                                                return 6657089965014657519;
                                            } else {
                                                return 5220884358887979358;
                                            }
                                        } else {
                                            return 1796677326474620641;
                                        }
                                    } else {
                                        if (index <= 155) {
                                            return 5340761970648932916;
                                        } else {
                                            return 1147977171614181568;
                                        }
                                    }
                                } else {
                                    if (index <= 159) {
                                        if (index <= 158) {
                                            if (index <= 157) {
                                                return 5066037465548252321;
                                            } else {
                                                return 2574765911837859848;
                                            }
                                        } else {
                                            return 1085848279845204775;
                                        }
                                    } else {
                                        if (index <= 160) {
                                            return -5873264506986385449;
                                        } else {
                                            return 6116438694366558490;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 166) {
                                    if (index <= 164) {
                                        if (index <= 163) {
                                            if (index <= 162) {
                                                return 2107701075971293812;
                                            } else {
                                                return -7420077970933506541;
                                            }
                                        } else {
                                            return 2469478054175558874;
                                        }
                                    } else {
                                        if (index <= 165) {
                                            return -1855128755834809824;
                                        } else {
                                            return -5431463669011098282;
                                        }
                                    }
                                } else {
                                    if (index <= 168) {
                                        if (index <= 167) {
                                            return -9038325065738319171;
                                        } else {
                                            return -6966276280341336160;
                                        }
                                    } else {
                                        if (index <= 169) {
                                            return 7217693971077460129;
                                        } else {
                                            return -8314322083775271549;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 180) {
                                if (index <= 175) {
                                    if (index <= 173) {
                                        if (index <= 172) {
                                            if (index <= 171) {
                                                return 7196649268545224266;
                                            } else {
                                                return -3585711691453906209;
                                            }
                                        } else {
                                            return -5267827091426810625;
                                        }
                                    } else {
                                        if (index <= 174) {
                                            return 8057528650917418961;
                                        } else {
                                            return -5084103596553648165;
                                        }
                                    }
                                } else {
                                    if (index <= 178) {
                                        if (index <= 177) {
                                            if (index <= 176) {
                                                return -2601445448341207749;
                                            } else {
                                                return -7850010900052094367;
                                            }
                                        } else {
                                            return 6527366231383600011;
                                        }
                                    } else {
                                        if (index <= 179) {
                                            return 3507654575162700890;
                                        } else {
                                            return 9202058512774729859;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 185) {
                                    if (index <= 183) {
                                        if (index <= 182) {
                                            if (index <= 181) {
                                                return 1954818376891585542;
                                            } else {
                                                return -2582991129724600103;
                                            }
                                        } else {
                                            return 8299563319178235687;
                                        }
                                    } else {
                                        if (index <= 184) {
                                            return -5321504681635821435;
                                        } else {
                                            return 7046310742295574065;
                                        }
                                    }
                                } else {
                                    if (index <= 187) {
                                        if (index <= 186) {
                                            return -2376176645520785576;
                                        } else {
                                            return -7650733936335907755;
                                        }
                                    } else {
                                        if (index <= 188) {
                                            return 8850422670118399721;
                                        } else {
                                            return 3631909142291992901;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 208) {
                            if (index <= 199) {
                                if (index <= 194) {
                                    if (index <= 192) {
                                        if (index <= 191) {
                                            if (index <= 190) {
                                                return 5158881091950831288;
                                            } else {
                                                return -6340413719511654215;
                                            }
                                        } else {
                                            return 4763258931815816403;
                                        }
                                    } else {
                                        if (index <= 193) {
                                            return 6280052734341785344;
                                        } else {
                                            return -4979582628649810958;
                                        }
                                    }
                                } else {
                                    if (index <= 197) {
                                        if (index <= 196) {
                                            if (index <= 195) {
                                                return 2043464728020827976;
                                            } else {
                                                return -2678071570832690343;
                                            }
                                        } else {
                                            return 4562580375758598164;
                                        }
                                    } else {
                                        if (index <= 198) {
                                            return 5495451168795427352;
                                        } else {
                                            return -7485059175264624713;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 204) {
                                    if (index <= 202) {
                                        if (index <= 201) {
                                            if (index <= 200) {
                                                return 553004618757816492;
                                            } else {
                                                return 6895160632757959823;
                                            }
                                        } else {
                                            return -989748114590090637;
                                        }
                                    } else {
                                        if (index <= 203) {
                                            return 7139506338801360852;
                                        } else {
                                            return -672480814466784139;
                                        }
                                    }
                                } else {
                                    if (index <= 206) {
                                        if (index <= 205) {
                                            return 5535668688139305547;
                                        } else {
                                            return 2430933853350256242;
                                        }
                                    } else {
                                        if (index <= 207) {
                                            return -3821430778991574732;
                                        } else {
                                            return -1063731997747047009;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 218) {
                                if (index <= 213) {
                                    if (index <= 211) {
                                        if (index <= 210) {
                                            if (index <= 209) {
                                                return -3065878205254005442;
                                            } else {
                                                return 7632066283658143750;
                                            }
                                        } else {
                                            return 6308328381617103346;
                                        }
                                    } else {
                                        if (index <= 212) {
                                            return 3681878764086140361;
                                        } else {
                                            return 3289686137190109749;
                                        }
                                    }
                                } else {
                                    if (index <= 216) {
                                        if (index <= 215) {
                                            if (index <= 214) {
                                                return 6587997200611086848;
                                            } else {
                                                return 244714774258135476;
                                            }
                                        } else {
                                            return -5143583659437639708;
                                        }
                                    } else {
                                        if (index <= 217) {
                                            return 8090302575944624335;
                                        } else {
                                            return 2945117363431356361;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 223) {
                                    if (index <= 221) {
                                        if (index <= 220) {
                                            if (index <= 219) {
                                                return -8359047641006034763;
                                            } else {
                                                return 3009039260312620700;
                                            }
                                        } else {
                                            return -793344576772241777;
                                        }
                                    } else {
                                        if (index <= 222) {
                                            return 401084700045993341;
                                        } else {
                                            return -1968749590416080887;
                                        }
                                    }
                                } else {
                                    if (index <= 225) {
                                        if (index <= 224) {
                                            return 4707864159563588614;
                                        } else {
                                            return -3583123505891281857;
                                        }
                                    } else {
                                        if (index <= 226) {
                                            return -3240864324164777915;
                                        } else {
                                            return -5908273794572565703;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (index <= 265) {
                        if (index <= 246) {
                            if (index <= 237) {
                                if (index <= 232) {
                                    if (index <= 230) {
                                        if (index <= 229) {
                                            if (index <= 228) {
                                                return -3719524458082857382;
                                            } else {
                                                return -5281400669679581926;
                                            }
                                        } else {
                                            return 8118566580304798074;
                                        }
                                    } else {
                                        if (index <= 231) {
                                            return 3839261274019871296;
                                        } else {
                                            return 7062410411742090847;
                                        }
                                    }
                                } else {
                                    if (index <= 235) {
                                        if (index <= 234) {
                                            if (index <= 233) {
                                                return -8481991033874568140;
                                            } else {
                                                return 6027994129690250817;
                                            }
                                        } else {
                                            return -6725542042704711878;
                                        }
                                    } else {
                                        if (index <= 236) {
                                            return -2971981702428546974;
                                        } else {
                                            return -7854441788951256975;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 242) {
                                    if (index <= 240) {
                                        if (index <= 239) {
                                            if (index <= 238) {
                                                return 8809096399316380241;
                                            } else {
                                                return 6492004350391900708;
                                            }
                                        } else {
                                            return 2462145737463489636;
                                        }
                                    } else {
                                        if (index <= 241) {
                                            return -8818543617934476634;
                                        } else {
                                            return -5070345602623085213;
                                        }
                                    }
                                } else {
                                    if (index <= 244) {
                                        if (index <= 243) {
                                            return -8961586321599299868;
                                        } else {
                                            return -3758656652254704451;
                                        }
                                    } else {
                                        if (index <= 245) {
                                            return -8630661632476012791;
                                        } else {
                                            return 6764129236657751224;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 256) {
                                if (index <= 251) {
                                    if (index <= 249) {
                                        if (index <= 248) {
                                            if (index <= 247) {
                                                return -709716318315418359;
                                            } else {
                                                return -3403028373052861600;
                                            }
                                        } else {
                                            return -8838073512170985897;
                                        }
                                    } else {
                                        if (index <= 250) {
                                            return -3999237033416576341;
                                        } else {
                                            return -2920240395515973663;
                                        }
                                    }
                                } else {
                                    if (index <= 254) {
                                        if (index <= 253) {
                                            if (index <= 252) {
                                                return -2073249475545404416;
                                            } else {
                                                return 368107899140673753;
                                            }
                                        } else {
                                            return -6108185202296464250;
                                        }
                                    } else {
                                        if (index <= 255) {
                                            return -6307735683270494757;
                                        } else {
                                            return 4782583894627718279;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 261) {
                                    if (index <= 259) {
                                        if (index <= 258) {
                                            if (index <= 257) {
                                                return 6718292300699989587;
                                            } else {
                                                return 8387085186914375220;
                                            }
                                        } else {
                                            return 3387513132024756289;
                                        }
                                    } else {
                                        if (index <= 260) {
                                            return 4654329375432538231;
                                        } else {
                                            return -292704475491394206;
                                        }
                                    }
                                } else {
                                    if (index <= 263) {
                                        if (index <= 262) {
                                            return -3848998599978456535;
                                        } else {
                                            return 7623042350483453954;
                                        }
                                    } else {
                                        if (index <= 264) {
                                            return 7725442901813263321;
                                        } else {
                                            return 9186225467561587250;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 284) {
                            if (index <= 275) {
                                if (index <= 270) {
                                    if (index <= 268) {
                                        if (index <= 267) {
                                            if (index <= 266) {
                                                return -5132344747257272453;
                                            } else {
                                                return -6865740430362196008;
                                            }
                                        } else {
                                            return 2530936820058611833;
                                        }
                                    } else {
                                        if (index <= 269) {
                                            return 1636551876240043639;
                                        } else {
                                            return -3658707362519810009;
                                        }
                                    }
                                } else {
                                    if (index <= 273) {
                                        if (index <= 272) {
                                            if (index <= 271) {
                                                return 1452244145334316253;
                                            } else {
                                                return -7161729655835084979;
                                            }
                                        } else {
                                            return -7943791770359481772;
                                        }
                                    } else {
                                        if (index <= 274) {
                                            return 9108481583171221009;
                                        } else {
                                            return -3200093350120725999;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 280) {
                                    if (index <= 278) {
                                        if (index <= 277) {
                                            if (index <= 276) {
                                                return 5007630032676973346;
                                            } else {
                                                return 2153168792952589781;
                                            }
                                        } else {
                                            return 6720334534964750538;
                                        }
                                    } else {
                                        if (index <= 279) {
                                            return -3181825545719981703;
                                        } else {
                                            return 3433922409283786309;
                                        }
                                    }
                                } else {
                                    if (index <= 282) {
                                        if (index <= 281) {
                                            return 2285479922797300912;
                                        } else {
                                            return 3110614940896576130;
                                        }
                                    } else {
                                        if (index <= 283) {
                                            return -2856812446131932915;
                                        } else {
                                            return -3804580617188639299;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 294) {
                                if (index <= 289) {
                                    if (index <= 287) {
                                        if (index <= 286) {
                                            if (index <= 285) {
                                                return 7163298419643543757;
                                            } else {
                                                return 4891138053923696990;
                                            }
                                        } else {
                                            return 580618510277907015;
                                        }
                                    } else {
                                        if (index <= 288) {
                                            return 1684034065251686769;
                                        } else {
                                            return 4429514767357295841;
                                        }
                                    }
                                } else {
                                    if (index <= 292) {
                                        if (index <= 291) {
                                            if (index <= 290) {
                                                return -8893025458299325803;
                                            } else {
                                                return -8103734041042601133;
                                            }
                                        } else {
                                            return 7177515271653460134;
                                        }
                                    } else {
                                        if (index <= 293) {
                                            return 4589042248470800257;
                                        } else {
                                            return -1530083407795771245;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 299) {
                                    if (index <= 297) {
                                        if (index <= 296) {
                                            if (index <= 295) {
                                                return 143607045258444228;
                                            } else {
                                                return 246994305896273627;
                                            }
                                        } else {
                                            return -8356954712051676521;
                                        }
                                    } else {
                                        if (index <= 298) {
                                            return 6473547110565816071;
                                        } else {
                                            return 3092379936208876896;
                                        }
                                    }
                                } else {
                                    if (index <= 301) {
                                        if (index <= 300) {
                                            return 2058427839513754051;
                                        } else {
                                            return -4089587328327907870;
                                        }
                                    } else {
                                        if (index <= 302) {
                                            return 8785882556301281247;
                                        } else {
                                            return -3074039370013608197;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (index <= 455) {
                if (index <= 379) {
                    if (index <= 341) {
                        if (index <= 322) {
                            if (index <= 313) {
                                if (index <= 308) {
                                    if (index <= 306) {
                                        if (index <= 305) {
                                            if (index <= 304) {
                                                return -637529855400303673;
                                            } else {
                                                return 6137678347805511274;
                                            }
                                        } else {
                                            return -7152924852417805802;
                                        }
                                    } else {
                                        if (index <= 307) {
                                            return 5708223427705576541;
                                        } else {
                                            return -3223714144396531304;
                                        }
                                    }
                                } else {
                                    if (index <= 311) {
                                        if (index <= 310) {
                                            if (index <= 309) {
                                                return 4358391411789012426;
                                            } else {
                                                return 325123008708389849;
                                            }
                                        } else {
                                            return 6837621693887290924;
                                        }
                                    } else {
                                        if (index <= 312) {
                                            return 4843721905315627004;
                                        } else {
                                            return -3212720814705499393;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 318) {
                                    if (index <= 316) {
                                        if (index <= 315) {
                                            if (index <= 314) {
                                                return -3825019837890901156;
                                            } else {
                                                return 4602025990114250980;
                                            }
                                        } else {
                                            return 1044646352569048800;
                                        }
                                    } else {
                                        if (index <= 317) {
                                            return 9106614159853161675;
                                        } else {
                                            return -8394115921626182539;
                                        }
                                    }
                                } else {
                                    if (index <= 320) {
                                        if (index <= 319) {
                                            return -4304087667751778808;
                                        } else {
                                            return 2681532557646850893;
                                        }
                                    } else {
                                        if (index <= 321) {
                                            return 3681559472488511871;
                                        } else {
                                            return -3915372517896561773;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 332) {
                                if (index <= 327) {
                                    if (index <= 325) {
                                        if (index <= 324) {
                                            if (index <= 323) {
                                                return -2889241648411946534;
                                            } else {
                                                return -6564663803938238204;
                                            }
                                        } else {
                                            return -8060058171802589521;
                                        }
                                    } else {
                                        if (index <= 326) {
                                            return 581945337509520675;
                                        } else {
                                            return 3648778920718647903;
                                        }
                                    }
                                } else {
                                    if (index <= 330) {
                                        if (index <= 329) {
                                            if (index <= 328) {
                                                return -4799698790548231394;
                                            } else {
                                                return -7602572252857820065;
                                            }
                                        } else {
                                            return 220828013409515943;
                                        }
                                    } else {
                                        if (index <= 331) {
                                            return -1072987336855386047;
                                        } else {
                                            return 4287360518296753003;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 337) {
                                    if (index <= 335) {
                                        if (index <= 334) {
                                            if (index <= 333) {
                                                return -4633371852008891965;
                                            } else {
                                                return 5513660857261085186;
                                            }
                                        } else {
                                            return -2258542936462001533;
                                        }
                                    } else {
                                        if (index <= 336) {
                                            return -8744380348503999773;
                                        } else {
                                            return 8746140185685648781;
                                        }
                                    }
                                } else {
                                    if (index <= 339) {
                                        if (index <= 338) {
                                            return 228500091334420247;
                                        } else {
                                            return 1356187007457302238;
                                        }
                                    } else {
                                        if (index <= 340) {
                                            return 3019253992034194581;
                                        } else {
                                            return 3152601605678500003;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 360) {
                            if (index <= 351) {
                                if (index <= 346) {
                                    if (index <= 344) {
                                        if (index <= 343) {
                                            if (index <= 342) {
                                                return -8793219284148773595;
                                            } else {
                                                return 5559581553696971176;
                                            }
                                        } else {
                                            return 4916432985369275664;
                                        }
                                    } else {
                                        if (index <= 345) {
                                            return -8559797105120221417;
                                        } else {
                                            return -5802598197927043732;
                                        }
                                    }
                                } else {
                                    if (index <= 349) {
                                        if (index <= 348) {
                                            if (index <= 347) {
                                                return 2868348622579915573;
                                            } else {
                                                return -7224052902810357288;
                                            }
                                        } else {
                                            return -5894682518218493085;
                                        }
                                    } else {
                                        if (index <= 350) {
                                            return 2587672709781371173;
                                        } else {
                                            return -7706116723325376475;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 356) {
                                    if (index <= 354) {
                                        if (index <= 353) {
                                            if (index <= 352) {
                                                return 3092343956317362483;
                                            } else {
                                                return -5561119517847711700;
                                            }
                                        } else {
                                            return 972445599196498113;
                                        }
                                    } else {
                                        if (index <= 355) {
                                            return -1558506600978816441;
                                        } else {
                                            return 1708913533482282562;
                                        }
                                    }
                                } else {
                                    if (index <= 358) {
                                        if (index <= 357) {
                                            return -2305554874185907314;
                                        } else {
                                            return -6005743014309462908;
                                        }
                                    } else {
                                        if (index <= 359) {
                                            return -6653329009633068701;
                                        } else {
                                            return -483583197311151195;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 370) {
                                if (index <= 365) {
                                    if (index <= 363) {
                                        if (index <= 362) {
                                            if (index <= 361) {
                                                return 2488075924621352812;
                                            } else {
                                                return -4529369641467339140;
                                            }
                                        } else {
                                            return -4663743555056261452;
                                        }
                                    } else {
                                        if (index <= 364) {
                                            return 2997203966153298104;
                                        } else {
                                            return 1282559373026354493;
                                        }
                                    }
                                } else {
                                    if (index <= 368) {
                                        if (index <= 367) {
                                            if (index <= 366) {
                                                return 240113143146674385;
                                            } else {
                                                return 8665713329246516443;
                                            }
                                        } else {
                                            return 628141331766346752;
                                        }
                                    } else {
                                        if (index <= 369) {
                                            return -4651421219668005332;
                                        } else {
                                            return -7750560848702540400;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 375) {
                                    if (index <= 373) {
                                        if (index <= 372) {
                                            if (index <= 371) {
                                                return 7596648026010355826;
                                            } else {
                                                return -3132152619100351065;
                                            }
                                        } else {
                                            return 7834161864828164065;
                                        }
                                    } else {
                                        if (index <= 374) {
                                            return 7103445518877254909;
                                        } else {
                                            return 4390861237357459201;
                                        }
                                    }
                                } else {
                                    if (index <= 377) {
                                        if (index <= 376) {
                                            return -4780718172614204074;
                                        } else {
                                            return -319889632007444440;
                                        }
                                    } else {
                                        if (index <= 378) {
                                            return 622261699494173647;
                                        } else {
                                            return -3186110786557562560;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (index <= 417) {
                        if (index <= 398) {
                            if (index <= 389) {
                                if (index <= 384) {
                                    if (index <= 382) {
                                        if (index <= 381) {
                                            if (index <= 380) {
                                                return -8718967088789066690;
                                            } else {
                                                return -1948156510637662747;
                                            }
                                        } else {
                                            return -8212195255998774408;
                                        }
                                    } else {
                                        if (index <= 383) {
                                            return -7028621931231314745;
                                        } else {
                                            return 2623071828615234808;
                                        }
                                    }
                                } else {
                                    if (index <= 387) {
                                        if (index <= 386) {
                                            if (index <= 385) {
                                                return -4066058308780939700;
                                            } else {
                                                return -5484966924888173764;
                                            }
                                        } else {
                                            return -6683604512778046238;
                                        }
                                    } else {
                                        if (index <= 388) {
                                            return -6756087640505506466;
                                        } else {
                                            return 5256026990536851868;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 394) {
                                    if (index <= 392) {
                                        if (index <= 391) {
                                            if (index <= 390) {
                                                return 7841086888628396109;
                                            } else {
                                                return 6640857538655893162;
                                            }
                                        } else {
                                            return -8021284697816458310;
                                        }
                                    } else {
                                        if (index <= 393) {
                                            return -7109857044414059830;
                                        } else {
                                            return -1689021141511844405;
                                        }
                                    }
                                } else {
                                    if (index <= 396) {
                                        if (index <= 395) {
                                            return -4298087301956291063;
                                        } else {
                                            return -4077748265377282003;
                                        }
                                    } else {
                                        if (index <= 397) {
                                            return -998231156719803476;
                                        } else {
                                            return 2719520354384050532;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 408) {
                                if (index <= 403) {
                                    if (index <= 401) {
                                        if (index <= 400) {
                                            if (index <= 399) {
                                                return 9132346697815513771;
                                            } else {
                                                return 4332154495710163773;
                                            }
                                        } else {
                                            return -2085582442760428892;
                                        }
                                    } else {
                                        if (index <= 402) {
                                            return 6994721091344268833;
                                        } else {
                                            return -2556143461985726874;
                                        }
                                    }
                                } else {
                                    if (index <= 406) {
                                        if (index <= 405) {
                                            if (index <= 404) {
                                                return -8567931991128098309;
                                            } else {
                                                return 59934747298466858;
                                            }
                                        } else {
                                            return -3098398008776739403;
                                        }
                                    } else {
                                        if (index <= 407) {
                                            return -265597256199410390;
                                        } else {
                                            return 2332206071942466437;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 413) {
                                    if (index <= 411) {
                                        if (index <= 410) {
                                            if (index <= 409) {
                                                return -7522315324568406181;
                                            } else {
                                                return 3154897383618636503;
                                            }
                                        } else {
                                            return -7585605855467168281;
                                        }
                                    } else {
                                        if (index <= 412) {
                                            return -6762850759087199275;
                                        } else {
                                            return 197309393502684135;
                                        }
                                    }
                                } else {
                                    if (index <= 415) {
                                        if (index <= 414) {
                                            return -8579694182469508493;
                                        } else {
                                            return 2543179307861934850;
                                        }
                                    } else {
                                        if (index <= 416) {
                                            return 4350769010207485119;
                                        } else {
                                            return -4468719947444108136;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 436) {
                            if (index <= 427) {
                                if (index <= 422) {
                                    if (index <= 420) {
                                        if (index <= 419) {
                                            if (index <= 418) {
                                                return -7207776534213261296;
                                            } else {
                                                return -1224312577878317200;
                                            }
                                        } else {
                                            return 4287946071480840813;
                                        }
                                    } else {
                                        if (index <= 421) {
                                            return 8362686366770308971;
                                        } else {
                                            return 6486469209321732151;
                                        }
                                    }
                                } else {
                                    if (index <= 425) {
                                        if (index <= 424) {
                                            if (index <= 423) {
                                                return -5605644191012979782;
                                            } else {
                                                return -1669018511020473564;
                                            }
                                        } else {
                                            return 4450022655153542367;
                                        }
                                    } else {
                                        if (index <= 426) {
                                            return -7618176296641240059;
                                        } else {
                                            return -3896357471549267421;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 432) {
                                    if (index <= 430) {
                                        if (index <= 429) {
                                            if (index <= 428) {
                                                return -4596796223304447488;
                                            } else {
                                                return -6531150016257070659;
                                            }
                                        } else {
                                            return -8982326463137525940;
                                        }
                                    } else {
                                        if (index <= 431) {
                                            return -4125325062227681798;
                                        } else {
                                            return -1306489741394045544;
                                        }
                                    }
                                } else {
                                    if (index <= 434) {
                                        if (index <= 433) {
                                            return -8338554946557245229;
                                        } else {
                                            return 5329160409530630596;
                                        }
                                    } else {
                                        if (index <= 435) {
                                            return 7790979528857726136;
                                        } else {
                                            return 4955070238059373407;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 446) {
                                if (index <= 441) {
                                    if (index <= 439) {
                                        if (index <= 438) {
                                            if (index <= 437) {
                                                return -4304834761432101506;
                                            } else {
                                                return -6215295852904371179;
                                            }
                                        } else {
                                            return 3007769226071157901;
                                        }
                                    } else {
                                        if (index <= 440) {
                                            return -6753025801236972788;
                                        } else {
                                            return 8928702772696731736;
                                        }
                                    }
                                } else {
                                    if (index <= 444) {
                                        if (index <= 443) {
                                            if (index <= 442) {
                                                return 7856187920214445904;
                                            } else {
                                                return -4748497451462800923;
                                            }
                                        } else {
                                            return 7900176660600710914;
                                        }
                                    } else {
                                        if (index <= 445) {
                                            return -7082800908938549136;
                                        } else {
                                            return -6797926979589575837;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 451) {
                                    if (index <= 449) {
                                        if (index <= 448) {
                                            if (index <= 447) {
                                                return -6737316883512927978;
                                            } else {
                                                return 4186670094382025798;
                                            }
                                        } else {
                                            return 1883939007446035042;
                                        }
                                    } else {
                                        if (index <= 450) {
                                            return -414705992779907823;
                                        } else {
                                            return 3734134241178479257;
                                        }
                                    }
                                } else {
                                    if (index <= 453) {
                                        if (index <= 452) {
                                            return 4065968871360089196;
                                        } else {
                                            return 6953124200385847784;
                                        }
                                    } else {
                                        if (index <= 454) {
                                            return -7917685222115876751;
                                        } else {
                                            return -7585632937840318161;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (index <= 531) {
                    if (index <= 493) {
                        if (index <= 474) {
                            if (index <= 465) {
                                if (index <= 460) {
                                    if (index <= 458) {
                                        if (index <= 457) {
                                            if (index <= 456) {
                                                return -5567246375906782599;
                                            } else {
                                                return -5256612402221608788;
                                            }
                                        } else {
                                            return 3106378204088556331;
                                        }
                                    } else {
                                        if (index <= 459) {
                                            return -2894472214076325998;
                                        } else {
                                            return 4565385105440252958;
                                        }
                                    }
                                } else {
                                    if (index <= 463) {
                                        if (index <= 462) {
                                            if (index <= 461) {
                                                return 1979884289539493806;
                                            } else {
                                                return -6891578849933910383;
                                            }
                                        } else {
                                            return 3783206694208922581;
                                        }
                                    } else {
                                        if (index <= 464) {
                                            return 8464961209802336085;
                                        } else {
                                            return 2843963751609577687;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 470) {
                                    if (index <= 468) {
                                        if (index <= 467) {
                                            if (index <= 466) {
                                                return 3030678195484896323;
                                            } else {
                                                return -4429654462759003204;
                                            }
                                        } else {
                                            return 4459239494808162889;
                                        }
                                    } else {
                                        if (index <= 469) {
                                            return 402587895800087237;
                                        } else {
                                            return 8057891408711167515;
                                        }
                                    }
                                } else {
                                    if (index <= 472) {
                                        if (index <= 471) {
                                            return 4541888170938985079;
                                        } else {
                                            return 1042662272908816815;
                                        }
                                    } else {
                                        if (index <= 473) {
                                            return -3666068979732206850;
                                        } else {
                                            return 2647678726283249984;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 484) {
                                if (index <= 479) {
                                    if (index <= 477) {
                                        if (index <= 476) {
                                            if (index <= 475) {
                                                return 2144477441549833761;
                                            } else {
                                                return -3417019821499388721;
                                            }
                                        } else {
                                            return -2105601033380872185;
                                        }
                                    } else {
                                        if (index <= 478) {
                                            return 5916597177708541638;
                                        } else {
                                            return -8760774321402454447;
                                        }
                                    }
                                } else {
                                    if (index <= 482) {
                                        if (index <= 481) {
                                            if (index <= 480) {
                                                return 8833658097025758785;
                                            } else {
                                                return 5970273481425315300;
                                            }
                                        } else {
                                            return 563813119381731307;
                                        }
                                    } else {
                                        if (index <= 483) {
                                            return -6455022486202078793;
                                        } else {
                                            return 1598828206250873866;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 489) {
                                    if (index <= 487) {
                                        if (index <= 486) {
                                            if (index <= 485) {
                                                return -4016978389451217698;
                                            } else {
                                                return -2988328551145513985;
                                            }
                                        } else {
                                            return -6071154634840136312;
                                        }
                                    } else {
                                        if (index <= 488) {
                                            return 8469693267274066490;
                                        } else {
                                            return 125672920241807416;
                                        }
                                    }
                                } else {
                                    if (index <= 491) {
                                        if (index <= 490) {
                                            return -3912292412830714870;
                                        } else {
                                            return -2559617104544284221;
                                        }
                                    } else {
                                        if (index <= 492) {
                                            return -486523741806024092;
                                        } else {
                                            return -4735332261862713930;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 512) {
                            if (index <= 503) {
                                if (index <= 498) {
                                    if (index <= 496) {
                                        if (index <= 495) {
                                            if (index <= 494) {
                                                return 5923302823487327109;
                                            } else {
                                                return -9082480245771672572;
                                            }
                                        } else {
                                            return -1808429243461201518;
                                        }
                                    } else {
                                        if (index <= 497) {
                                            return 7990420780896957397;
                                        } else {
                                            return 4317817392807076702;
                                        }
                                    }
                                } else {
                                    if (index <= 501) {
                                        if (index <= 500) {
                                            if (index <= 499) {
                                                return 3625184369705367340;
                                            } else {
                                                return -6482649271566653105;
                                            }
                                        } else {
                                            return -3480272027152017464;
                                        }
                                    } else {
                                        if (index <= 502) {
                                            return -3225473396345736649;
                                        } else {
                                            return -368878695502291645;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 508) {
                                    if (index <= 506) {
                                        if (index <= 505) {
                                            if (index <= 504) {
                                                return -3981164001421868007;
                                            } else {
                                                return -8522033136963788610;
                                            }
                                        } else {
                                            return 7609280429197514109;
                                        }
                                    } else {
                                        if (index <= 507) {
                                            return 3020985755112334161;
                                        } else {
                                            return -2572049329799262942;
                                        }
                                    }
                                } else {
                                    if (index <= 510) {
                                        if (index <= 509) {
                                            return 2635195723621160615;
                                        } else {
                                            return 5144520864246028816;
                                        }
                                    } else {
                                        if (index <= 511) {
                                            return -8188285521126945980;
                                        } else {
                                            return 1567242097116389047;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 522) {
                                if (index <= 517) {
                                    if (index <= 515) {
                                        if (index <= 514) {
                                            if (index <= 513) {
                                                return 8172389260191636581;
                                            } else {
                                                return -2885551685425483535;
                                            }
                                        } else {
                                            return -7060359469858316883;
                                        }
                                    } else {
                                        if (index <= 516) {
                                            return -6480181133964513127;
                                        } else {
                                            return -7317004403633452381;
                                        }
                                    }
                                } else {
                                    if (index <= 520) {
                                        if (index <= 519) {
                                            if (index <= 518) {
                                                return 6011544915663598137;
                                            } else {
                                                return 5932255307352610768;
                                            }
                                        } else {
                                            return 2241128460406315459;
                                        }
                                    } else {
                                        if (index <= 521) {
                                            return -8327867140638080220;
                                        } else {
                                            return 3094483003111372717;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 527) {
                                    if (index <= 525) {
                                        if (index <= 524) {
                                            if (index <= 523) {
                                                return 4583857460292963101;
                                            } else {
                                                return 9079887171656594975;
                                            }
                                        } else {
                                            return -384082854924064405;
                                        }
                                    } else {
                                        if (index <= 526) {
                                            return -3460631649611717935;
                                        } else {
                                            return 4225072055348026230;
                                        }
                                    }
                                } else {
                                    if (index <= 529) {
                                        if (index <= 528) {
                                            return -7385151438465742745;
                                        } else {
                                            return 3801620336801580414;
                                        }
                                    } else {
                                        if (index <= 530) {
                                            return -399845416774701952;
                                        } else {
                                            return -7446754431269675473;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (index <= 569) {
                        if (index <= 550) {
                            if (index <= 541) {
                                if (index <= 536) {
                                    if (index <= 534) {
                                        if (index <= 533) {
                                            if (index <= 532) {
                                                return 7899055018877642622;
                                            } else {
                                                return 5421679761463003041;
                                            }
                                        } else {
                                            return 5521102963086275121;
                                        }
                                    } else {
                                        if (index <= 535) {
                                            return -4975092593295409910;
                                        } else {
                                            return 8735487530905098534;
                                        }
                                    }
                                } else {
                                    if (index <= 539) {
                                        if (index <= 538) {
                                            if (index <= 537) {
                                                return -7462844945281082830;
                                            } else {
                                                return -2080886987197029914;
                                            }
                                        } else {
                                            return -1000715163927557685;
                                        }
                                    } else {
                                        if (index <= 540) {
                                            return -4253840471931071485;
                                        } else {
                                            return -5828896094657903328;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 546) {
                                    if (index <= 544) {
                                        if (index <= 543) {
                                            if (index <= 542) {
                                                return 6424174453260338141;
                                            } else {
                                                return 359248545074932887;
                                            }
                                        } else {
                                            return -5949720754023045210;
                                        }
                                    } else {
                                        if (index <= 545) {
                                            return -2426265837057637212;
                                        } else {
                                            return 3030918217665093212;
                                        }
                                    }
                                } else {
                                    if (index <= 548) {
                                        if (index <= 547) {
                                            return -9077771202237461772;
                                        } else {
                                            return -3186796180789149575;
                                        }
                                    } else {
                                        if (index <= 549) {
                                            return 740416251634527158;
                                        } else {
                                            return -2142944401404840226;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 560) {
                                if (index <= 555) {
                                    if (index <= 553) {
                                        if (index <= 552) {
                                            if (index <= 551) {
                                                return 6951781370868335478;
                                            } else {
                                                return 399922722363687927;
                                            }
                                        } else {
                                            return -8928469722407522623;
                                        }
                                    } else {
                                        if (index <= 554) {
                                            return -1378421100515597285;
                                        } else {
                                            return -8343051178220066766;
                                        }
                                    }
                                } else {
                                    if (index <= 558) {
                                        if (index <= 557) {
                                            if (index <= 556) {
                                                return -3030716356046100229;
                                            } else {
                                                return -8811767350470065420;
                                            }
                                        } else {
                                            return 9026808440365124461;
                                        }
                                    } else {
                                        if (index <= 559) {
                                            return 6440783557497587732;
                                        } else {
                                            return 4615674634722404292;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 565) {
                                    if (index <= 563) {
                                        if (index <= 562) {
                                            if (index <= 561) {
                                                return 539897290441580544;
                                            } else {
                                                return 2096238225866883852;
                                            }
                                        } else {
                                            return 8751955639408182687;
                                        }
                                    } else {
                                        if (index <= 564) {
                                            return -7316147128802486205;
                                        } else {
                                            return 7381039757301768559;
                                        }
                                    }
                                } else {
                                    if (index <= 567) {
                                        if (index <= 566) {
                                            return 6157238513393239656;
                                        } else {
                                            return -1473377804940618233;
                                        }
                                    } else {
                                        if (index <= 568) {
                                            return 8629571604380892756;
                                        } else {
                                            return 5280433031239081479;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (index <= 588) {
                            if (index <= 579) {
                                if (index <= 574) {
                                    if (index <= 572) {
                                        if (index <= 571) {
                                            if (index <= 570) {
                                                return 7101611890139813254;
                                            } else {
                                                return 2479018537985767835;
                                            }
                                        } else {
                                            return 7169176924412769570;
                                        }
                                    } else {
                                        if (index <= 573) {
                                            return -1281305539061572506;
                                        } else {
                                            return -7865612307799218120;
                                        }
                                    }
                                } else {
                                    if (index <= 577) {
                                        if (index <= 576) {
                                            if (index <= 575) {
                                                return 2278447439451174845;
                                            } else {
                                                return 3625338785743880657;
                                            }
                                        } else {
                                            return 6477479539006708521;
                                        }
                                    } else {
                                        if (index <= 578) {
                                            return 8976185375579272206;
                                        } else {
                                            return -3712000482142939688;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 584) {
                                    if (index <= 582) {
                                        if (index <= 581) {
                                            if (index <= 580) {
                                                return 1326024180520890843;
                                            } else {
                                                return 7537449876596048829;
                                            }
                                        } else {
                                            return 5464680203499696154;
                                        }
                                    } else {
                                        if (index <= 583) {
                                            return 3189671183162196045;
                                        } else {
                                            return 6346751753565857109;
                                        }
                                    }
                                } else {
                                    if (index <= 586) {
                                        if (index <= 585) {
                                            return -8982212049534145501;
                                        } else {
                                            return -6127578587196093755;
                                        }
                                    } else {
                                        if (index <= 587) {
                                            return -245039190118465649;
                                        } else {
                                            return -6320577374581628592;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (index <= 597) {
                                if (index <= 593) {
                                    if (index <= 591) {
                                        if (index <= 590) {
                                            if (index <= 589) {
                                                return 7208698530190629697;
                                            } else {
                                                return 7276901792339343736;
                                            }
                                        } else {
                                            return -7490986807540332668;
                                        }
                                    } else {
                                        if (index <= 592) {
                                            return 4133292154170828382;
                                        } else {
                                            return 2918308698224194548;
                                        }
                                    }
                                } else {
                                    if (index <= 595) {
                                        if (index <= 594) {
                                            return -7703910638917631350;
                                        } else {
                                            return -3929437324238184044;
                                        }
                                    } else {
                                        if (index <= 596) {
                                            return -4300543082831323144;
                                        } else {
                                            return -6344160503358350167;
                                        }
                                    }
                                }
                            } else {
                                if (index <= 602) {
                                    if (index <= 600) {
                                        if (index <= 599) {
                                            if (index <= 598) {
                                                return 5896236396443472108;
                                            } else {
                                                return -758328221503023383;
                                            }
                                        } else {
                                            return -1894351639983151068;
                                        }
                                    } else {
                                        if (index <= 601) {
                                            return -307900319840287220;
                                        } else {
                                            return -6278469401177312761;
                                        }
                                    }
                                } else {
                                    if (index <= 604) {
                                        if (index <= 603) {
                                            return -2171292963361310674;
                                        } else {
                                            return 8382142935188824023;
                                        }
                                    } else {
                                        if (index <= 605) {
                                            return 9103922860780351547;
                                        } else {
                                            return 4152330101494654406;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}