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

    struct Trait {
        uint8 id;
    }

    function getTraits(uint256 seed) public pure returns (Traits memory) {
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
                returned.bottom = 0; // Full-body tops
            } else {
                returned.bottom = pickBottom(Int31n(rng, 100) + 1);
            }

            return returned;
        }
    }

    struct TraitsNice {
        bytes20 class;
        bytes20 body;
        bytes20 weapon;
        bytes20 hair;
        bytes20 hairColor;
        bytes20 back;
        bytes20 aura;
        bytes20 top;
        bytes20 bottom;
    }

    function getTraitsNice(uint256 seed) public pure returns (TraitsNice memory) {
        Traits memory fetchedTraits = getTraits(seed);
        TraitsNice memory returned;
        returned.class = lookupClass(fetchedTraits.class);
        returned.body = lookupBody(fetchedTraits.body);
        if (fetchedTraits.class == 0) {
            returned.weapon = lookupSword(fetchedTraits.weapon);
        } else if (fetchedTraits.class == 1) {
            returned.weapon = lookupHammer(fetchedTraits.weapon);
        } else if (fetchedTraits.class == 2) {
            returned.weapon = lookupLance(fetchedTraits.weapon);
        } else if (fetchedTraits.class == 3) {
            returned.weapon = lookupBow(fetchedTraits.weapon);
        } else if (fetchedTraits.class == 4) {
            returned.weapon = lookupWand(fetchedTraits.weapon);
        } else if (fetchedTraits.class == 5) {
            returned.weapon = lookupThrown(fetchedTraits.weapon);
        }
        returned.hair = lookupHair(fetchedTraits.hair);
        returned.hairColor = lookupHairColor(fetchedTraits.hairColor);
        returned.back = lookupBack(fetchedTraits.back);
        returned.aura = lookupAura(fetchedTraits.aura);
        returned.top = lookupTop(fetchedTraits.top);
        returned.bottom = lookupBottom(fetchedTraits.bottom);

        return returned;
    }

    Traits public traits;

    function storeTraits(uint256 seed) public {
        getTraits(seed);
    }

    // HERE BE DRAGONS
    // The original approach used an unstable sort as part of the weighted random
    // selection via https://github.com/mroth/weightedrand. We avoid re-implementing
    // Go's unstable sort here and just hardcode the resulting order of the items.
    // The inlined bin search was generated with the `resource/inline-trait-selection` script.
    function pickClass(int32 pick) internal pure returns (uint8 id) {
        if (40 < pick) {
            if (60 < pick) {
                require(false, "Value out of bounds");
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
                require(false, "Value out of bounds");
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
                    require(false, "Value out of bounds");
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
                        require(false, "Value out of bounds");
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
                    require(false, "Value out of bounds");
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
                        require(false, "Value out of bounds");
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
                        require(false, "Value out of bounds");
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
                        require(false, "Value out of bounds");
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
                            require(false, "Value out of bounds");
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
                        require(false, "Value out of bounds");
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

    function lookupClass(uint8 id) public pure returns (bytes20 name) {
        if (3 < id) {
            if (5 < id) {
                require(false, "Value out of bounds");
            } else {
                if (4 < id) {
                    return "Assassin";
                } else {
                    return "Mage";
                }
            }
        } else {
            if (1 < id) {
                if (2 < id) {
                    return "Archer";
                } else {
                    return "Lancer";
                }
            } else {
                if (0 < id) {
                    return "Paladin";
                } else {
                    return "Slayer";
                }
            }
        }
    }

    function lookupBody(uint8 id) public pure returns (bytes20 name) {
        if (3 < id) {
            if (5 < id) {
                require(false, "Value out of bounds");
            } else {
                if (4 < id) {
                    return "Skeleton";
                } else {
                    return "Ghostly";
                }
            }
        } else {
            if (1 < id) {
                if (2 < id) {
                    return "Elf";
                } else {
                    return "Clay";
                }
            } else {
                if (0 < id) {
                    return "Tan";
                } else {
                    return "Light";
                }
            }
        }
    }

    function lookupSword(uint8 id) public pure returns (bytes20 name) {
        if (5 < id) {
            if (8 < id) {
                if (9 < id) {
                    require(false, "Value out of bounds");
                } else {
                    return "Joyeuse";
                }
            } else {
                if (7 < id) {
                    return "Uriel";
                } else {
                    if (6 < id) {
                        return "Lucifer";
                    } else {
                        return "Lunar";
                    }
                }
            }
        } else {
            if (2 < id) {
                if (4 < id) {
                    return "Wandering Blade";
                } else {
                    if (3 < id) {
                        return "Caustic";
                    } else {
                        return "Jadecutter";
                    }
                }
            } else {
                if (1 < id) {
                    return "Boxcutter";
                } else {
                    if (0 < id) {
                        return "Spiked Club";
                    } else {
                        return "Iron Sword";
                    }
                }
            }
        }
    }

    function lookupHammer(uint8 id) public pure returns (bytes20 name) {
        if (5 < id) {
            if (8 < id) {
                if (9 < id) {
                    require(false, "Value out of bounds");
                } else {
                    return "Mjolnir";
                }
            } else {
                if (7 < id) {
                    return "True Cross";
                } else {
                    if (6 < id) {
                        return "Leviathan";
                    } else {
                        return "Jupiter";
                    }
                }
            }
        } else {
            if (2 < id) {
                if (4 < id) {
                    return "Scythe";
                } else {
                    if (3 < id) {
                        return "Monolith";
                    } else {
                        return "Onyx";
                    }
                }
            } else {
                if (1 < id) {
                    return "Chainsaw";
                } else {
                    if (0 < id) {
                        return "Smith";
                    } else {
                        return "Mace";
                    }
                }
            }
        }
    }

    function lookupLance(uint8 id) public pure returns (bytes20 name) {
        if (5 < id) {
            if (8 < id) {
                if (9 < id) {
                    require(false, "Value out of bounds");
                } else {
                    return "Gae Bolg";
                }
            } else {
                if (7 < id) {
                    return "Michael";
                } else {
                    if (6 < id) {
                        return "Harbinger";
                    } else {
                        return "Scorpius";
                    }
                }
            }
        } else {
            if (2 < id) {
                if (4 < id) {
                    return "Banner";
                } else {
                    if (3 < id) {
                        return "Glacial Lance";
                    } else {
                        return "Skypiercer";
                    }
                }
            } else {
                if (1 < id) {
                    return "Gunlance";
                } else {
                    if (0 < id) {
                        return "Lance";
                    } else {
                        return "Javelin";
                    }
                }
            }
        }
    }

    function lookupBow(uint8 id) public pure returns (bytes20 name) {
        if (5 < id) {
            if (8 < id) {
                if (9 < id) {
                    require(false, "Value out of bounds");
                } else {
                    return "Gandiva";
                }
            } else {
                if (7 < id) {
                    return "Raphael";
                } else {
                    if (6 < id) {
                        return "Beelzebub";
                    } else {
                        return "Black Hole";
                    }
                }
            }
        } else {
            if (2 < id) {
                if (4 < id) {
                    return "Faerie";
                } else {
                    if (3 < id) {
                        return "Waterweaver";
                    } else {
                        return "Quartz Shot";
                    }
                }
            } else {
                if (1 < id) {
                    return "Compound";
                } else {
                    if (0 < id) {
                        return "Longbow";
                    } else {
                        return "Wooden";
                    }
                }
            }
        }
    }

    function lookupWand(uint8 id) public pure returns (bytes20 name) {
        if (5 < id) {
            if (8 < id) {
                if (9 < id) {
                    require(false, "Value out of bounds");
                } else {
                    return "Yata";
                }
            } else {
                if (7 < id) {
                    return "Gabriel";
                } else {
                    if (6 < id) {
                        return "Original Sin";
                    } else {
                        return "Eclipse";
                    }
                }
            }
        } else {
            if (2 < id) {
                if (4 < id) {
                    return "Sands of Time";
                } else {
                    if (3 < id) {
                        return "Monsoon";
                    } else {
                        return "Chrysoberyl";
                    }
                }
            } else {
                if (1 < id) {
                    return "Antenna";
                } else {
                    if (0 < id) {
                        return "Dream Catcher";
                    } else {
                        return "Elder Staff";
                    }
                }
            }
        }
    }

    function lookupThrown(uint8 id) public pure returns (bytes20 name) {
        if (5 < id) {
            if (8 < id) {
                if (9 < id) {
                    require(false, "Value out of bounds");
                } else {
                    return "Parazonium";
                }
            } else {
                if (7 < id) {
                    return "Heaven";
                } else {
                    if (6 < id) {
                        return "Deception";
                    } else {
                        return "Stars";
                    }
                }
            }
        } else {
            if (2 < id) {
                if (4 < id) {
                    return "Sacrificial";
                } else {
                    if (3 < id) {
                        return "Cinders";
                    } else {
                        return "Cystal Fragments";
                    }
                }
            } else {
                if (1 < id) {
                    return "Syringe";
                } else {
                    if (0 < id) {
                        return "Shuriken";
                    } else {
                        return "Knife";
                    }
                }
            }
        }
    }

    function lookupHair(uint8 id) public pure returns (bytes20 name) {
        if (11 < id) {
            if (17 < id) {
                if (20 < id) {
                    if (22 < id) {
                        require(false, "Value out of bounds");
                    } else {
                        if (21 < id) {
                            return "Short Buzz Cut";
                        } else {
                            return "Short Bob";
                        }
                    }
                } else {
                    if (19 < id) {
                        return "Female Buns";
                    } else {
                        if (18 < id) {
                            return "Villain Hair";
                        } else {
                            return "Buzzcut";
                        }
                    }
                }
            } else {
                if (14 < id) {
                    if (16 < id) {
                        return "Rockstar";
                    } else {
                        if (15 < id) {
                            return "Updo";
                        } else {
                            return "Commander";
                        }
                    }
                } else {
                    if (13 < id) {
                        return "Twintails";
                    } else {
                        if (12 < id) {
                            return "Samurai Cut";
                        } else {
                            return "Emo Midcut";
                        }
                    }
                }
            }
        } else {
            if (5 < id) {
                if (8 < id) {
                    if (10 < id) {
                        return "Antenna";
                    } else {
                        if (9 < id) {
                            return "Bow Hair";
                        } else {
                            return "Overgrown";
                        }
                    }
                } else {
                    if (7 < id) {
                        return "Bed Head";
                    } else {
                        if (6 < id) {
                            return "Preppy";
                        } else {
                            return "Spikehawk";
                        }
                    }
                }
            } else {
                if (2 < id) {
                    if (4 < id) {
                        return "Mid Part Updo";
                    } else {
                        if (3 < id) {
                            return "Soprano";
                        } else {
                            return "Vocaloid";
                        }
                    }
                } else {
                    if (1 < id) {
                        return "Twinkle";
                    } else {
                        if (0 < id) {
                            return "Ponytail";
                        } else {
                            return "Overgrown";
                        }
                    }
                }
            }
        }
    }

    function lookupHairColor(uint8 id) public pure returns (bytes20 name) {
        if (4 < id) {
            if (7 < id) {
                if (8 < id) {
                    require(false, "Value out of bounds");
                } else {
                    return "Brown";
                }
            } else {
                if (6 < id) {
                    return "Blonde";
                } else {
                    if (5 < id) {
                        return "White";
                    } else {
                        return "Black";
                    }
                }
            }
        } else {
            if (2 < id) {
                if (3 < id) {
                    return "Red";
                } else {
                    return "Violet";
                }
            } else {
                if (1 < id) {
                    return "Green";
                } else {
                    if (0 < id) {
                        return "Pink";
                    } else {
                        return "Blue";
                    }
                }
            }
        }
    }

    function lookupBack(uint8 id) public pure returns (bytes20 name) {
        if (10 < id) {
            if (15 < id) {
                if (18 < id) {
                    if (19 < id) {
                        require(false, "Value out of bounds");
                    } else {
                        return "Winter Cloak";
                    }
                } else {
                    if (17 < id) {
                        return "Green Cape";
                    } else {
                        if (16 < id) {
                            return "White Cape";
                        } else {
                            return "Black Tassels";
                        }
                    }
                }
            } else {
                if (13 < id) {
                    if (14 < id) {
                        return "Clock";
                    } else {
                        return "Yellow Balloon";
                    }
                } else {
                    if (12 < id) {
                        return "Pink Balloon";
                    } else {
                        if (11 < id) {
                            return "Blue Balloon";
                        } else {
                            return "Stuntman";
                        }
                    }
                }
            }
        } else {
            if (5 < id) {
                if (8 < id) {
                    if (9 < id) {
                        return "Reaper Cape";
                    } else {
                        return "Dragon Tail";
                    }
                } else {
                    if (7 < id) {
                        return "Syringe";
                    } else {
                        if (6 < id) {
                            return "Danger Coat";
                        } else {
                            return "Red Flag";
                        }
                    }
                }
            } else {
                if (2 < id) {
                    if (4 < id) {
                        return "Yellow Flag";
                    } else {
                        if (3 < id) {
                            return "Windup";
                        } else {
                            return "Best Friend";
                        }
                    }
                } else {
                    if (1 < id) {
                        return "Fairy";
                    } else {
                        if (0 < id) {
                            return "Ribbon";
                        } else {
                            return "None";
                        }
                    }
                }
            }
        }
    }

    function lookupAura(uint8 id) public pure returns (bytes20 name) {
        if (8 < id) {
            if (12 < id) {
                if (14 < id) {
                    if (15 < id) {
                        require(false, "Value out of bounds");
                    } else {
                        return "Moon";
                    }
                } else {
                    if (13 < id) {
                        return "Heart";
                    } else {
                        return "Feathers 2";
                    }
                }
            } else {
                if (10 < id) {
                    if (11 < id) {
                        return "Spotlight";
                    } else {
                        return "Chains";
                    }
                } else {
                    if (9 < id) {
                        return "Tree";
                    } else {
                        return "Gears";
                    }
                }
            }
        } else {
            if (4 < id) {
                if (6 < id) {
                    if (7 < id) {
                        return "Snowflakes";
                    } else {
                        return "Chess";
                    }
                } else {
                    if (5 < id) {
                        return "Flowers";
                    } else {
                        return "Feathers";
                    }
                }
            } else {
                if (2 < id) {
                    if (3 < id) {
                        return "Sun";
                    } else {
                        return "Sword";
                    }
                } else {
                    if (1 < id) {
                        return "Puppet";
                    } else {
                        if (0 < id) {
                            return "IV";
                        } else {
                            return "None";
                        }
                    }
                }
            }
        }
    }

    function lookupTop(uint8 id) public pure returns (bytes20 name) {
        if (28 < id) {
            if (42 < id) {
                if (49 < id) {
                    if (53 < id) {
                        if (55 < id) {
                            require(false, "Value out of bounds");
                        } else {
                            if (54 < id) {
                                return "Admirals Coat";
                            } else {
                                return "Penguin Outfit";
                            }
                        }
                    } else {
                        if (51 < id) {
                            if (52 < id) {
                                return "Edgelord Coat";
                            } else {
                                return "Gold Fancy";
                            }
                        } else {
                            if (50 < id) {
                                return "Bomber Jacket";
                            } else {
                                return "Eagle Coat";
                            }
                        }
                    }
                } else {
                    if (46 < id) {
                        if (48 < id) {
                            return "Bell Robe";
                        } else {
                            if (47 < id) {
                                return "Maid Outfit";
                            } else {
                                return "Future Suit";
                            }
                        }
                    } else {
                        if (44 < id) {
                            if (45 < id) {
                                return "Bubbles";
                            } else {
                                return "Traveler's Armor";
                            }
                        } else {
                            if (43 < id) {
                                return "Bathrobe";
                            } else {
                                return "Mummy Suit";
                            }
                        }
                    }
                }
            } else {
                if (35 < id) {
                    if (39 < id) {
                        if (41 < id) {
                            return "Skeleton Suit";
                        } else {
                            if (40 < id) {
                                return "Oversized Shirt";
                            } else {
                                return "Starry Night Gown";
                            }
                        }
                    } else {
                        if (37 < id) {
                            if (38 < id) {
                                return "Gold Chain";
                            } else {
                                return "Samurai Robe";
                            }
                        } else {
                            if (36 < id) {
                                return "Bowtie Jacket";
                            } else {
                                return "Kimono";
                            }
                        }
                    }
                } else {
                    if (32 < id) {
                        if (34 < id) {
                            return "Stars Hoodie";
                        } else {
                            if (33 < id) {
                                return "Old School Uniform";
                            } else {
                                return "Blue Chainmail";
                            }
                        }
                    } else {
                        if (30 < id) {
                            if (31 < id) {
                                return "Red Chainmail";
                            } else {
                                return "Thrifty Getup";
                            }
                        } else {
                            if (29 < id) {
                                return "Farmer Apron";
                            } else {
                                return "Lab Gear";
                            }
                        }
                    }
                }
            }
        } else {
            if (14 < id) {
                if (21 < id) {
                    if (25 < id) {
                        if (27 < id) {
                            return "Distinguished Coat";
                        } else {
                            if (26 < id) {
                                return "Soccer Jersey";
                            } else {
                                return "Desert Traveler";
                            }
                        }
                    } else {
                        if (23 < id) {
                            if (24 < id) {
                                return "Dojo Casual";
                            } else {
                                return "Olympian's Robe";
                            }
                        } else {
                            if (22 < id) {
                                return "Gunslinger";
                            } else {
                                return "Abstract Hood";
                            }
                        }
                    }
                } else {
                    if (18 < id) {
                        if (20 < id) {
                            return "Bunny T-Shirt";
                        } else {
                            if (19 < id) {
                                return "Heart Tee";
                            } else {
                                return "Star Sweater";
                            }
                        }
                    } else {
                        if (16 < id) {
                            if (17 < id) {
                                return "Casual Suit";
                            } else {
                                return "Sailor Outfit";
                            }
                        } else {
                            if (15 < id) {
                                return "Tank Top";
                            } else {
                                return "Life Jacket";
                            }
                        }
                    }
                }
            } else {
                if (7 < id) {
                    if (11 < id) {
                        if (13 < id) {
                            return "Parka";
                        } else {
                            if (12 < id) {
                                return "Baseball Shirt";
                            } else {
                                return "Black Vest";
                            }
                        }
                    } else {
                        if (9 < id) {
                            if (10 < id) {
                                return "Red Vest";
                            } else {
                                return "Lei";
                            }
                        } else {
                            if (8 < id) {
                                return "Red Archer's Hood";
                            } else {
                                return "Green Archer's Hood";
                            }
                        }
                    }
                } else {
                    if (3 < id) {
                        if (5 < id) {
                            if (6 < id) {
                                return "Red Checker";
                            } else {
                                return "Lover Sweater";
                            }
                        } else {
                            if (4 < id) {
                                return "Bunny Jersey";
                            } else {
                                return "Ab T-Shirt";
                            }
                        }
                    } else {
                        if (1 < id) {
                            if (2 < id) {
                                return "Pink Showstopper";
                            } else {
                                return "Pocket Tee";
                            }
                        } else {
                            if (0 < id) {
                                return "Track Jacket";
                            } else {
                                return "Heart Tank";
                            }
                        }
                    }
                }
            }
        }
    }

    function lookupBottom(uint8 id) public pure returns (bytes20 name) {
        if (9 < id) {
            if (14 < id) {
                if (17 < id) {
                    if (18 < id) {
                        require(false, "Value out of bounds");
                    } else {
                        return "None";
                    }
                } else {
                    if (16 < id) {
                        return "Thrifty Getup";
                    } else {
                        if (15 < id) {
                            return "Farmer Apron";
                        } else {
                            return "Boxers";
                        }
                    }
                }
            } else {
                if (12 < id) {
                    if (13 < id) {
                        return "Martial Arts Pants";
                    } else {
                        return "Tan Sneak Pants";
                    }
                } else {
                    if (11 < id) {
                        return "Black Sneak Pants";
                    } else {
                        if (10 < id) {
                            return "Armored Pants";
                        } else {
                            return "White Skirt";
                        }
                    }
                }
            }
        } else {
            if (4 < id) {
                if (7 < id) {
                    if (8 < id) {
                        return "Gold Sparkle Pleats";
                    } else {
                        return "Disco Pants";
                    }
                } else {
                    if (6 < id) {
                        return "Black Edgy Pants";
                    } else {
                        if (5 < id) {
                            return "Red Training Shorts";
                        } else {
                            return "Blue Training Shorts";
                        }
                    }
                }
            } else {
                if (2 < id) {
                    if (3 < id) {
                        return "White Shorts";
                    } else {
                        return "White Pants";
                    }
                } else {
                    if (1 < id) {
                        return "Blue Skirt";
                    } else {
                        if (0 < id) {
                            return "Ragged Pants";
                        } else {
                            return "Black Slacks";
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