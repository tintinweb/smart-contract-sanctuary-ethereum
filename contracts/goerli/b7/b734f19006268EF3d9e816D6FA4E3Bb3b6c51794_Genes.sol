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
            uint256 trait = traitSeed % 21;
            if (
                traitSeed >> 8 <
                [
                    77,
                    77,
                    77,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    256,
                    200,
                    144,
                    89,
                    211,
                    155,
                    122,
                    189,
                    178,
                    166
                ][trait]
            ) return trait;
            return
                [
                    14,
                    16,
                    17,
                    17,
                    18,
                    18,
                    19,
                    19,
                    20,
                    20,
                    20,
                    0,
                    11,
                    12,
                    13,
                    14,
                    15,
                    16,
                    17,
                    18,
                    19
                ][trait];
        }
    }

    function getBackgroundValue(uint256 chromosome)
        public
        view
        returns (string memory)
    {
        uint256 gene = getBackground(chromosome);

        if (gene == 0) {
            return "Background 1";
        }

        if (gene == 1) {
            return "Background 2";
        }

        if (gene == 2) {
            return "Background 3";
        }

        if (gene == 3) {
            return "Background 4";
        }

        if (gene == 4) {
            return "Background 5";
        }

        if (gene == 5) {
            return "Background 6";
        }

        if (gene == 6) {
            return "Background 7";
        }

        if (gene == 7) {
            return "Background 8";
        }

        if (gene == 8) {
            return "Background 9";
        }

        if (gene == 9) {
            return "Background 10";
        }

        if (gene == 10) {
            return "Background 11";
        }

        if (gene == 11) {
            return "Background 12";
        }

        if (gene == 12) {
            return "Background 13";
        }

        if (gene == 13) {
            return "Background 14";
        }

        if (gene == 14) {
            return "Background 15";
        }

        if (gene == 15) {
            return "Background 16";
        }

        if (gene == 16) {
            return "Background 17";
        }

        if (gene == 17) {
            return "Background 18";
        }

        if (gene == 18) {
            return "Background 19";
        }

        if (gene == 19) {
            return "Background 20";
        }

        if (gene == 20) {
            return "Background 21";
        }
        return "";
    }

    function getBackground(uint256 chromosome) internal view returns (uint256) {
        return getGene(chromosome, 5);
    }

    function seedToSkin(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 32) & 0xFFFF;
            uint256 trait = traitSeed % 21;
            if (
                traitSeed >> 8 <
                [
                    77,
                    77,
                    77,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    256,
                    200,
                    144,
                    89,
                    211,
                    155,
                    122,
                    189,
                    178,
                    166
                ][trait]
            ) return trait;
            return
                [
                    14,
                    16,
                    17,
                    17,
                    18,
                    18,
                    19,
                    19,
                    20,
                    20,
                    20,
                    0,
                    11,
                    12,
                    13,
                    14,
                    15,
                    16,
                    17,
                    18,
                    19
                ][trait];
        }
    }

    function getSkinValue(uint256 chromosome)
        public
        view
        returns (string memory)
    {
        uint256 gene = getSkin(chromosome);

        if (gene == 0) {
            return "Skin 1";
        }

        if (gene == 1) {
            return "Skin 2";
        }

        if (gene == 2) {
            return "Skin 3";
        }

        if (gene == 3) {
            return "Skin 4";
        }

        if (gene == 4) {
            return "Skin 5";
        }

        if (gene == 5) {
            return "Skin 6";
        }

        if (gene == 6) {
            return "Skin 7";
        }

        if (gene == 7) {
            return "Skin 8";
        }

        if (gene == 8) {
            return "Skin 9";
        }

        if (gene == 9) {
            return "Skin 10";
        }

        if (gene == 10) {
            return "Skin 11";
        }

        if (gene == 11) {
            return "Skin 12";
        }

        if (gene == 12) {
            return "Skin 13";
        }

        if (gene == 13) {
            return "Skin 14";
        }

        if (gene == 14) {
            return "Skin 15";
        }

        if (gene == 15) {
            return "Skin 16";
        }

        if (gene == 16) {
            return "Skin 17";
        }

        if (gene == 17) {
            return "Skin 18";
        }

        if (gene == 18) {
            return "Skin 19";
        }

        if (gene == 19) {
            return "Skin 20";
        }

        if (gene == 20) {
            return "Skin 21";
        }
        return "";
    }

    function getSkin(uint256 chromosome) internal view returns (uint256) {
        return getGene(chromosome, 4);
    }

    function seedToHead(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 48) & 0xFFFF;
            uint256 trait = traitSeed % 21;
            if (
                traitSeed >> 8 <
                [
                    77,
                    77,
                    77,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    155,
                    256,
                    200,
                    144,
                    89,
                    211,
                    155,
                    122,
                    189,
                    178,
                    166
                ][trait]
            ) return trait;
            return
                [
                    14,
                    16,
                    17,
                    17,
                    18,
                    18,
                    19,
                    19,
                    20,
                    20,
                    20,
                    0,
                    11,
                    12,
                    13,
                    14,
                    15,
                    16,
                    17,
                    18,
                    19
                ][trait];
        }
    }

    function getHeadValue(uint256 chromosome)
        public
        view
        returns (string memory)
    {
        uint256 gene = getHead(chromosome);

        if (gene == 0) {
            return "Head 1";
        }

        if (gene == 1) {
            return "Head 2";
        }

        if (gene == 2) {
            return "Head 3";
        }

        if (gene == 3) {
            return "Head 4";
        }

        if (gene == 4) {
            return "Head 5";
        }

        if (gene == 5) {
            return "Head 6";
        }

        if (gene == 6) {
            return "Head 7";
        }

        if (gene == 7) {
            return "Head 8";
        }

        if (gene == 8) {
            return "Head 9";
        }

        if (gene == 9) {
            return "Head 10";
        }

        if (gene == 10) {
            return "Head 11";
        }

        if (gene == 11) {
            return "Head 12";
        }

        if (gene == 12) {
            return "Head 13";
        }

        if (gene == 13) {
            return "Head 14";
        }

        if (gene == 14) {
            return "Head 15";
        }

        if (gene == 15) {
            return "Head 16";
        }

        if (gene == 16) {
            return "Head 17";
        }

        if (gene == 17) {
            return "Head 18";
        }

        if (gene == 18) {
            return "Head 19";
        }

        if (gene == 19) {
            return "Head 20";
        }

        if (gene == 20) {
            return "Head 21";
        }
        return "";
    }

    function getHead(uint256 chromosome) internal view returns (uint256) {
        return getGene(chromosome, 3);
    }

    function seedToEyes(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 64) & 0xFFFF;
            uint256 trait = traitSeed % 11;
            if (
                traitSeed >> 8 <
                [56, 84, 140, 256, 230, 204, 179, 153, 128, 102, 76][trait]
            ) return trait;
            return [10, 10, 10, 0, 3, 4, 5, 6, 7, 8, 9][trait];
        }
    }

    function getEyesValue(uint256 chromosome)
        public
        view
        returns (string memory)
    {
        uint256 gene = getEyes(chromosome);

        if (gene == 0) {
            return "Eyes 1";
        }

        if (gene == 1) {
            return "Eyes 2";
        }

        if (gene == 2) {
            return "Eyes 3";
        }

        if (gene == 3) {
            return "Eyes 4";
        }

        if (gene == 4) {
            return "Eyes 5";
        }

        if (gene == 5) {
            return "Eyes 6";
        }

        if (gene == 6) {
            return "Eyes 7";
        }

        if (gene == 7) {
            return "Eyes 8";
        }

        if (gene == 8) {
            return "Eyes 9";
        }

        if (gene == 9) {
            return "Eyes 10";
        }

        if (gene == 10) {
            return "Eyes 11";
        }
        return "";
    }

    function getEyes(uint256 chromosome) internal view returns (uint256) {
        return getGene(chromosome, 2);
    }

    function seedToMouth(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 80) & 0xFFFF;
            uint256 trait = traitSeed % 11;
            if (
                traitSeed >> 8 <
                [56, 84, 140, 256, 230, 204, 179, 153, 128, 102, 76][trait]
            ) return trait;
            return [10, 10, 10, 0, 3, 4, 5, 6, 7, 8, 9][trait];
        }
    }

    function getMouthValue(uint256 chromosome)
        public
        view
        returns (string memory)
    {
        uint256 gene = getMouth(chromosome);

        if (gene == 0) {
            return "Mouth 1";
        }

        if (gene == 1) {
            return "Mouth 2";
        }

        if (gene == 2) {
            return "Mouth 3";
        }

        if (gene == 3) {
            return "Mouth 4";
        }

        if (gene == 4) {
            return "Mouth 5";
        }

        if (gene == 5) {
            return "Mouth 6";
        }

        if (gene == 6) {
            return "Mouth 7";
        }

        if (gene == 7) {
            return "Mouth 8";
        }

        if (gene == 8) {
            return "Mouth 9";
        }

        if (gene == 9) {
            return "Mouth 10";
        }

        if (gene == 10) {
            return "Mouth 11";
        }
        return "";
    }

    function getMouth(uint256 chromosome) internal view returns (uint256) {
        return getGene(chromosome, 1);
    }

    function seedToClothes(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 96) & 0xFFFF;
            uint256 trait = traitSeed % 36;
            if (
                traitSeed >> 8 <
                [
                    40,
                    40,
                    40,
                    81,
                    81,
                    81,
                    81,
                    81,
                    81,
                    81,
                    81,
                    162,
                    162,
                    162,
                    162,
                    162,
                    243,
                    243,
                    243,
                    243,
                    243,
                    243,
                    243,
                    243,
                    255,
                    106,
                    171,
                    236,
                    86,
                    152,
                    177,
                    201,
                    226,
                    223,
                    219,
                    228
                ][trait]
            ) return trait;
            return
                [
                    25,
                    26,
                    28,
                    29,
                    30,
                    31,
                    32,
                    32,
                    33,
                    33,
                    34,
                    34,
                    34,
                    35,
                    35,
                    35,
                    35,
                    35,
                    35,
                    35,
                    35,
                    35,
                    35,
                    35,
                    0,
                    24,
                    25,
                    26,
                    27,
                    28,
                    29,
                    30,
                    31,
                    32,
                    33,
                    34
                ][trait];
        }
    }

    function getClothesValue(uint256 chromosome)
        public
        view
        returns (string memory)
    {
        uint256 gene = getClothes(chromosome);

        if (gene == 0) {
            return "Clothes 1";
        }

        if (gene == 1) {
            return "Clothes 2";
        }

        if (gene == 2) {
            return "Clothes 3";
        }

        if (gene == 3) {
            return "Clothes 4";
        }

        if (gene == 4) {
            return "Clothes 5";
        }

        if (gene == 5) {
            return "Clothes 6";
        }

        if (gene == 6) {
            return "Clothes 7";
        }

        if (gene == 7) {
            return "Clothes 8";
        }

        if (gene == 8) {
            return "Clothes 9";
        }

        if (gene == 9) {
            return "Clothes 10";
        }

        if (gene == 10) {
            return "Clothes 11";
        }

        if (gene == 11) {
            return "Clothes 12";
        }

        if (gene == 12) {
            return "Clothes 13";
        }

        if (gene == 13) {
            return "Clothes 14";
        }

        if (gene == 14) {
            return "Clothes 15";
        }

        if (gene == 15) {
            return "Clothes 16";
        }

        if (gene == 16) {
            return "Clothes 17";
        }

        if (gene == 17) {
            return "Clothes 18";
        }

        if (gene == 18) {
            return "Clothes 19";
        }

        if (gene == 19) {
            return "Clothes 20";
        }

        if (gene == 20) {
            return "Clothes 21";
        }

        if (gene == 21) {
            return "Clothes 22";
        }

        if (gene == 22) {
            return "Clothes 23";
        }

        if (gene == 23) {
            return "Clothes 24";
        }

        if (gene == 24) {
            return "Clothes 25";
        }

        if (gene == 25) {
            return "Clothes 26";
        }

        if (gene == 26) {
            return "Clothes 27";
        }

        if (gene == 27) {
            return "Clothes 28";
        }

        if (gene == 28) {
            return "Clothes 29";
        }

        if (gene == 29) {
            return "Clothes 30";
        }

        if (gene == 30) {
            return "Clothes 31";
        }

        if (gene == 31) {
            return "Clothes 32";
        }

        if (gene == 32) {
            return "Clothes 33";
        }

        if (gene == 33) {
            return "Clothes 34";
        }

        if (gene == 34) {
            return "Clothes 35";
        }

        if (gene == 35) {
            return "Clothes 36";
        }
        return "";
    }

    function getClothes(uint256 chromosome) internal view returns (uint256) {
        return getGene(chromosome, 0);
    }

    function seedToChromosome(uint256 seed)
        internal
        view
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

        chromosome |= seedToClothes(seed);
    }
}