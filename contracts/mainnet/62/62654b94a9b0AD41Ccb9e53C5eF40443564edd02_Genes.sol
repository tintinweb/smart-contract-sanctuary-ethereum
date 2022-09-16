// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// GENERATED CODE DO NOT MODIFY!

/*******************************************************************************
 * Genes
 * Developed By: @ScottMitchell18
 * Each of those seedTo{Group} function select 4 bytes from the seed
 * and use those selected bytes to pick a trait using the A.J. Walker
 * algorithm O(1) complexity. The rarity and aliases are calculated off-chain.
 *******************************************************************************/

library Genes {
    function getGene(uint256 chromosome, uint32 position)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint32 shift = 8 * position;
            return (chromosome & (0xFF << shift)) >> shift;
        }
    }

    function seedToBackground(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 16) & 0xFFFF;
            uint256 trait = traitSeed % 14;
            if (
                traitSeed >> 8 <
                [
                    255,
                    122,
                    215,
                    133,
                    250,
                    130,
                    117,
                    107,
                    71,
                    235,
                    133,
                    120,
                    35,
                    17
                ][trait]
            ) return trait;
            return [0, 0, 0, 1, 3, 4, 5, 1, 3, 6, 9, 10, 6, 11][trait];
        }
    }

    function getBackgroundValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getBackground(chromosome);

        if (gene == 0) {
            return "Gray";
        }

        if (gene == 1) {
            return "Moss";
        }

        if (gene == 2) {
            return "Orange";
        }

        if (gene == 3) {
            return "Red";
        }

        if (gene == 4) {
            return "Green";
        }

        if (gene == 5) {
            return "Blue";
        }

        if (gene == 6) {
            return "Brown";
        }

        if (gene == 7) {
            return "Smoke";
        }

        if (gene == 8) {
            return "Red Smoke";
        }

        if (gene == 9) {
            return "Maroon";
        }

        if (gene == 10) {
            return "Purple";
        }

        if (gene == 11) {
            return "Navy";
        }

        if (gene == 12) {
            return "Graffiti";
        }

        if (gene == 13) {
            return "Cyber Safari";
        }
        return "";
    }

    function getBackground(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 5);
    }

    function seedToSkin(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 32) & 0xFFFF;
            uint256 trait = traitSeed % 21;
            if (
                traitSeed >> 8 <
                [
                    34,
                    16,
                    69,
                    256,
                    94,
                    215,
                    131,
                    188,
                    162,
                    98,
                    188,
                    255,
                    212,
                    92,
                    212,
                    218,
                    75,
                    147,
                    53,
                    205,
                    173
                ][trait]
            ) return trait;
            return
                [
                    9,
                    13,
                    13,
                    0,
                    14,
                    14,
                    14,
                    14,
                    3,
                    8,
                    19,
                    19,
                    9,
                    12,
                    13,
                    14,
                    19,
                    20,
                    20,
                    15,
                    19
                ][trait];
        }
    }

    function getSkinValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getSkin(chromosome);

        if (gene == 0) {
            return "Plasma";
        }

        if (gene == 1) {
            return "Sun Breaker";
        }

        if (gene == 2) {
            return "Negative";
        }

        if (gene == 3) {
            return "Mash";
        }

        if (gene == 4) {
            return "Grey Tiger";
        }

        if (gene == 5) {
            return "Polar Bear";
        }

        if (gene == 6) {
            return "Tan Tiger";
        }

        if (gene == 7) {
            return "Tiger";
        }

        if (gene == 8) {
            return "Chocolate Striped";
        }

        if (gene == 9) {
            return "Ripper";
        }

        if (gene == 10) {
            return "Brown Panda";
        }

        if (gene == 11) {
            return "Panda";
        }

        if (gene == 12) {
            return "Brown";
        }

        if (gene == 13) {
            return "Grey";
        }

        if (gene == 14) {
            return "Tan";
        }

        if (gene == 15) {
            return "Black Bear";
        }

        if (gene == 16) {
            return "Toxic";
        }

        if (gene == 17) {
            return "Green Chalk";
        }

        if (gene == 18) {
            return "Negative Tiger";
        }

        if (gene == 19) {
            return "Metal";
        }

        if (gene == 20) {
            return "Orange";
        }
        return "";
    }

    function getSkin(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 4);
    }

    function seedToHead(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 48) & 0xFFFF;
            uint256 trait = traitSeed % 72;
            if (
                traitSeed >> 8 <
                [
                    196,
                    196,
                    18,
                    204,
                    130,
                    149,
                    138,
                    154,
                    201,
                    138,
                    206,
                    238,
                    188,
                    180,
                    167,
                    112,
                    122,
                    125,
                    156,
                    170,
                    78,
                    117,
                    183,
                    130,
                    183,
                    256,
                    156,
                    209,
                    143,
                    156,
                    159,
                    235,
                    209,
                    198,
                    235,
                    151,
                    143,
                    196,
                    222,
                    170,
                    23,
                    104,
                    130,
                    104,
                    130,
                    78,
                    26,
                    167,
                    189,
                    218,
                    91,
                    170,
                    225,
                    220,
                    239,
                    182,
                    243,
                    235,
                    177,
                    145,
                    31,
                    78,
                    130,
                    173,
                    209,
                    237,
                    252,
                    136,
                    250,
                    179,
                    220,
                    170
                ][trait]
            ) return trait;
            return
                [
                    33,
                    33,
                    33,
                    34,
                    35,
                    35,
                    35,
                    47,
                    47,
                    47,
                    47,
                    47,
                    48,
                    48,
                    48,
                    49,
                    52,
                    52,
                    52,
                    52,
                    52,
                    52,
                    52,
                    53,
                    53,
                    0,
                    53,
                    53,
                    53,
                    53,
                    53,
                    53,
                    53,
                    25,
                    33,
                    34,
                    54,
                    54,
                    54,
                    54,
                    54,
                    55,
                    55,
                    59,
                    63,
                    63,
                    64,
                    35,
                    47,
                    48,
                    65,
                    66,
                    49,
                    52,
                    53,
                    54,
                    55,
                    56,
                    57,
                    58,
                    67,
                    69,
                    70,
                    59,
                    63,
                    64,
                    65,
                    66,
                    67,
                    68,
                    69,
                    70
                ][trait];
        }
    }

    function getHeadValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getHead(chromosome);

        if (gene == 0) {
            return "Green Soda Hat";
        }

        if (gene == 1) {
            return "Orange Soda Hat";
        }

        if (gene == 2) {
            return "Golden Gladiator Helmet";
        }

        if (gene == 3) {
            return "Gladiator Helmet";
        }

        if (gene == 4) {
            return "Bone Head";
        }

        if (gene == 5) {
            return "Holiday Beanie";
        }

        if (gene == 6) {
            return "Pan";
        }

        if (gene == 7) {
            return "Snow Trooper";
        }

        if (gene == 8) {
            return "Bearlympics Headband";
        }

        if (gene == 9) {
            return "Sea Cap";
        }

        if (gene == 10) {
            return "Green Goggles";
        }

        if (gene == 11) {
            return "Red Goggles";
        }

        if (gene == 12) {
            return "Society Cap";
        }

        if (gene == 13) {
            return "Fireman Hat";
        }

        if (gene == 14) {
            return "Vendor Cap";
        }

        if (gene == 15) {
            return "Banana";
        }

        if (gene == 16) {
            return "Cake";
        }

        if (gene == 17) {
            return "Rabbit Ears";
        }

        if (gene == 18) {
            return "Party Hat";
        }

        if (gene == 19) {
            return "Rice Hat";
        }

        if (gene == 20) {
            return "None";
        }

        if (gene == 21) {
            return "Alarm";
        }

        if (gene == 22) {
            return "Karate Band";
        }

        if (gene == 23) {
            return "Butchered";
        }

        if (gene == 24) {
            return "Green Bear Rag";
        }

        if (gene == 25) {
            return "Red Bear Rag";
        }

        if (gene == 26) {
            return "Wizard Hat";
        }

        if (gene == 27) {
            return "Ninja Headband";
        }

        if (gene == 28) {
            return "Sombrero";
        }

        if (gene == 29) {
            return "Blue Ice Cream";
        }

        if (gene == 30) {
            return "Red Ice Cream";
        }

        if (gene == 31) {
            return "Viking Helmet";
        }

        if (gene == 32) {
            return "Snow Hat";
        }

        if (gene == 33) {
            return "Green Bucket Hat";
        }

        if (gene == 34) {
            return "Blue Bucket Hat";
        }

        if (gene == 35) {
            return "Red Bucket Hat";
        }

        if (gene == 36) {
            return "Chef Hat";
        }

        if (gene == 37) {
            return "Bearz Police";
        }

        if (gene == 38) {
            return "Cowboy Hat";
        }

        if (gene == 39) {
            return "Straw Hat";
        }

        if (gene == 40) {
            return "Kings Crown";
        }

        if (gene == 41) {
            return "Halo";
        }

        if (gene == 42) {
            return "Jester Hat";
        }

        if (gene == 43) {
            return "Dark Piratez";
        }

        if (gene == 44) {
            return "Santa Hat";
        }

        if (gene == 45) {
            return "Cyber Rice hat";
        }

        if (gene == 46) {
            return "Wulfz";
        }

        if (gene == 47) {
            return "Two Toned Cap";
        }

        if (gene == 48) {
            return "Black Cap";
        }

        if (gene == 49) {
            return "Green Cap";
        }

        if (gene == 50) {
            return "Trainer Cap";
        }

        if (gene == 51) {
            return "Horn";
        }

        if (gene == 52) {
            return "Green Punk Hair";
        }

        if (gene == 53) {
            return "Blue Punk Hair";
        }

        if (gene == 54) {
            return "Red Punk Hair";
        }

        if (gene == 55) {
            return "Purple Punk Hair";
        }

        if (gene == 56) {
            return "Grey Poof";
        }

        if (gene == 57) {
            return "Blue Beanie";
        }

        if (gene == 58) {
            return "Orange Beanie";
        }

        if (gene == 59) {
            return "Red Beanie";
        }

        if (gene == 60) {
            return "Green Flames";
        }

        if (gene == 61) {
            return "Blue Flames";
        }

        if (gene == 62) {
            return "Flames";
        }

        if (gene == 63) {
            return "Grey Headphones";
        }

        if (gene == 64) {
            return "Blue Headphones";
        }

        if (gene == 65) {
            return "Red Headphones";
        }

        if (gene == 66) {
            return "Black Snapback";
        }

        if (gene == 67) {
            return "Green Snapback";
        }

        if (gene == 68) {
            return "Blue Snapback";
        }

        if (gene == 69) {
            return "Two Tones Snapback";
        }

        if (gene == 70) {
            return "Red Snapback";
        }

        if (gene == 71) {
            return "Vault Bear";
        }
        return "";
    }

    function getHead(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 3);
    }

    function seedToEyes(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 64) & 0xFFFF;
            uint256 trait = traitSeed % 13;
            if (
                traitSeed >> 8 <
                [255, 242, 241, 231, 197, 68, 166, 58, 124, 13, 58, 67, 74][
                    trait
                ]
            ) return trait;
            return [0, 0, 1, 2, 3, 4, 0, 1, 1, 3, 11, 5, 11][trait];
        }
    }

    function getEyesValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getEyes(chromosome);

        if (gene == 0) {
            return "Real Green";
        }

        if (gene == 1) {
            return "Black";
        }

        if (gene == 2) {
            return "Black Side Eye";
        }

        if (gene == 3) {
            return "Real Black";
        }

        if (gene == 4) {
            return "Real Blue";
        }

        if (gene == 5) {
            return "Honey";
        }

        if (gene == 6) {
            return "Ghost";
        }

        if (gene == 7) {
            return "Snake";
        }

        if (gene == 8) {
            return "Worried";
        }

        if (gene == 9) {
            return "Cyber";
        }

        if (gene == 10) {
            return "Lizard";
        }

        if (gene == 11) {
            return "Brown";
        }

        if (gene == 12) {
            return "Bloodshot";
        }
        return "";
    }

    function getEyes(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 2);
    }

    function seedToMouth(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 80) & 0xFFFF;
            uint256 trait = traitSeed % 11;
            if (
                traitSeed >> 8 <
                [255, 211, 42, 70, 254, 211, 138, 174, 197, 140, 14][trait]
            ) return trait;
            return [0, 0, 0, 6, 0, 6, 4, 6, 6, 6, 7][trait];
        }
    }

    function getMouthValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getMouth(chromosome);

        if (gene == 0) {
            return "Serious";
        }

        if (gene == 1) {
            return "Tongue";
        }

        if (gene == 2) {
            return "Ramen";
        }

        if (gene == 3) {
            return "Lollipop";
        }

        if (gene == 4) {
            return "Orge";
        }

        if (gene == 5) {
            return "Tiger";
        }

        if (gene == 6) {
            return "Smile";
        }

        if (gene == 7) {
            return "Angry";
        }

        if (gene == 8) {
            return "Worried";
        }

        if (gene == 9) {
            return "Rage";
        }

        if (gene == 10) {
            return "Bloody Fangs";
        }
        return "";
    }

    function getMouth(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 1);
    }

    function seedToOutfit(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 96) & 0xFFFF;
            uint256 trait = traitSeed % 75;
            if (
                traitSeed >> 8 <
                [
                    74,
                    24,
                    248,
                    198,
                    256,
                    124,
                    186,
                    149,
                    223,
                    111,
                    213,
                    171,
                    216,
                    153,
                    123,
                    80,
                    207,
                    152,
                    97,
                    151,
                    187,
                    192,
                    174,
                    24,
                    94,
                    248,
                    124,
                    223,
                    211,
                    223,
                    248,
                    248,
                    223,
                    186,
                    223,
                    124,
                    99,
                    233,
                    227,
                    192,
                    171,
                    136,
                    223,
                    174,
                    186,
                    198,
                    186,
                    174,
                    223,
                    198,
                    136,
                    144,
                    194,
                    141,
                    139,
                    198,
                    198,
                    198,
                    176,
                    196,
                    179,
                    250,
                    240,
                    197,
                    174,
                    249,
                    157,
                    248,
                    194,
                    226,
                    161,
                    213,
                    219,
                    129,
                    74
                ][trait]
            ) return trait;
            return
                [
                    15,
                    18,
                    18,
                    18,
                    0,
                    19,
                    19,
                    19,
                    19,
                    20,
                    4,
                    10,
                    20,
                    11,
                    13,
                    14,
                    15,
                    16,
                    17,
                    18,
                    19,
                    20,
                    21,
                    24,
                    22,
                    24,
                    25,
                    24,
                    24,
                    25,
                    25,
                    25,
                    25,
                    25,
                    25,
                    26,
                    26,
                    26,
                    37,
                    38,
                    37,
                    37,
                    37,
                    38,
                    39,
                    39,
                    39,
                    60,
                    60,
                    61,
                    63,
                    66,
                    69,
                    69,
                    70,
                    70,
                    70,
                    71,
                    71,
                    39,
                    59,
                    60,
                    61,
                    62,
                    72,
                    63,
                    65,
                    72,
                    72,
                    66,
                    69,
                    70,
                    71,
                    72,
                    73
                ][trait];
        }
    }

    function getOutfitValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getOutfit(chromosome);

        if (gene == 0) {
            return "Dark Space Suit";
        }

        if (gene == 1) {
            return "Golden Space Suit";
        }

        if (gene == 2) {
            return "Space Suit";
        }

        if (gene == 3) {
            return "Rugged Jacket";
        }

        if (gene == 4) {
            return "Multi Jacket";
        }

        if (gene == 5) {
            return "Plated Suit";
        }

        if (gene == 6) {
            return "T16 Jacket";
        }

        if (gene == 7) {
            return "Sand Raider Armor";
        }

        if (gene == 8) {
            return "Raider Armor";
        }

        if (gene == 9) {
            return "Tuxedo";
        }

        if (gene == 10) {
            return "Blue Don Jacket";
        }

        if (gene == 11) {
            return "Green Don Jacket";
        }

        if (gene == 12) {
            return "Purple Don Jacket";
        }

        if (gene == 13) {
            return "Red Don Jacket";
        }

        if (gene == 14) {
            return "Hunter Jacket";
        }

        if (gene == 15) {
            return "Brawler Bearz Hoodie";
        }

        if (gene == 16) {
            return "Quartz Paw Hoodie";
        }

        if (gene == 17) {
            return "Cyan Paw Hoodie";
        }

        if (gene == 18) {
            return "Blue Two Tone Hoodie";
        }

        if (gene == 19) {
            return "Red Two Tone Hoodie";
        }

        if (gene == 20) {
            return "Purple Two Tone Hoodie";
        }

        if (gene == 21) {
            return "Orange Paw Hoodie";
        }

        if (gene == 22) {
            return "Green Paw Hoodie";
        }

        if (gene == 23) {
            return "MVHQ Hoodie";
        }

        if (gene == 24) {
            return "Green Bearz Hoodie";
        }

        if (gene == 25) {
            return "Red Bearz Hoodie";
        }

        if (gene == 26) {
            return "Street Hoodie";
        }

        if (gene == 27) {
            return "Ranger Trench Jacket";
        }

        if (gene == 28) {
            return "Night Rider Jacket";
        }

        if (gene == 29) {
            return "Blue Utility Jacket";
        }

        if (gene == 30) {
            return "Orange Utility Jacket";
        }

        if (gene == 31) {
            return "Red Utility Jacket";
        }

        if (gene == 32) {
            return "Brown Neo Jacket";
        }

        if (gene == 33) {
            return "Green Neo Jacet";
        }

        if (gene == 34) {
            return "Forester Jacket";
        }

        if (gene == 35) {
            return "Robe";
        }

        if (gene == 36) {
            return "Champions Robe";
        }

        if (gene == 37) {
            return "Red Flame Pullover";
        }

        if (gene == 38) {
            return "Blue Flame Pullover";
        }

        if (gene == 39) {
            return "Leather Jacket";
        }

        if (gene == 40) {
            return "Chain";
        }

        if (gene == 41) {
            return "Tech Suit";
        }

        if (gene == 42) {
            return "Red 10 Plate Armor";
        }

        if (gene == 43) {
            return "Blue 10 Plate Armor";
        }

        if (gene == 44) {
            return "Orange 10 Plate Armor";
        }

        if (gene == 45) {
            return "Green 9 Plate Armor";
        }

        if (gene == 46) {
            return "Orange 9 Plate Armor";
        }

        if (gene == 47) {
            return "Blue 9 Plate Armor";
        }

        if (gene == 48) {
            return "Red 9 Plate Armor";
        }

        if (gene == 49) {
            return "Forester Bandana";
        }

        if (gene == 50) {
            return "Purple Striped Bandana";
        }

        if (gene == 51) {
            return "Green Striped Bandana";
        }

        if (gene == 52) {
            return "Green Bandana";
        }

        if (gene == 53) {
            return "Blue Striped Bandana";
        }

        if (gene == 54) {
            return "Red Striped Bandana";
        }

        if (gene == 55) {
            return "Red Bandana";
        }

        if (gene == 56) {
            return "Red Arm Bandana";
        }

        if (gene == 57) {
            return "Blue Arm Bandana";
        }

        if (gene == 58) {
            return "Black Arm Bandana";
        }

        if (gene == 59) {
            return "Black Tee";
        }

        if (gene == 60) {
            return "White Tee";
        }

        if (gene == 61) {
            return "Two Toned Tee";
        }

        if (gene == 62) {
            return "Two Tone Long Sleeve";
        }

        if (gene == 63) {
            return "Bearz Long Sleeve";
        }

        if (gene == 64) {
            return "Bearz Tee";
        }

        if (gene == 65) {
            return "Graphic Tee";
        }

        if (gene == 66) {
            return "Black Graphic Tee";
        }

        if (gene == 67) {
            return "Dark Piratez Suit";
        }

        if (gene == 68) {
            return "Green Arm Bandana";
        }

        if (gene == 69) {
            return "Black Bearz Hoodie";
        }

        if (gene == 70) {
            return "White Futura Jacket";
        }

        if (gene == 71) {
            return "Orange Futura Jacket";
        }

        if (gene == 72) {
            return "Red Futura Jacket";
        }

        if (gene == 73) {
            return "Damaged Shirt";
        }

        if (gene == 74) {
            return "None";
        }
        return "";
    }

    function getOutfit(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 0);
    }

    function seedToChromosome(uint256 seed)
        internal
        pure
        returns (uint256 chromosome)
    {
        chromosome |= seedToBackground(seed);
        chromosome <<= 8;

        chromosome |= seedToSkin(seed);
        chromosome <<= 8;

        chromosome |= seedToHead(seed);
        chromosome <<= 8;

        chromosome |= seedToEyes(seed);
        chromosome <<= 8;

        chromosome |= seedToMouth(seed);
        chromosome <<= 8;

        chromosome |= seedToOutfit(seed);
    }
}