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
            uint256 trait = traitSeed % 18;
            if (
                traitSeed >> 8 <
                [
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256
                ][trait]
            ) return trait;
            return
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0][trait];
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
            return "Yellow";
        }

        if (gene == 3) {
            return "Hyper Wave";
        }

        if (gene == 4) {
            return "Red";
        }

        if (gene == 5) {
            return "Green";
        }

        if (gene == 6) {
            return "Blue";
        }

        if (gene == 7) {
            return "Brown";
        }

        if (gene == 8) {
            return "Smoke";
        }

        if (gene == 9) {
            return "Red smoke";
        }

        if (gene == 10) {
            return "Maroon";
        }

        if (gene == 11) {
            return "Purple";
        }

        if (gene == 12) {
            return "Salmon";
        }

        if (gene == 13) {
            return "Navy";
        }

        if (gene == 14) {
            return "Graffiti";
        }

        if (gene == 15) {
            return "Cyber Safari";
        }

        if (gene == 16) {
            return "Moon";
        }

        if (gene == 17) {
            return "Flames";
        }
        return "";
    }

    function getBackground(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 5);
    }

    function seedToSkin(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 32) & 0xFFFF;
            uint256 trait = traitSeed % 20;
            if (
                traitSeed >> 8 <
                [
                    11,
                    27,
                    27,
                    256,
                    205,
                    138,
                    41,
                    82,
                    165,
                    165,
                    118,
                    82,
                    99,
                    246,
                    215,
                    44,
                    25,
                    82,
                    16,
                    5
                ][trait]
            ) return trait;
            return
                [
                    3,
                    4,
                    12,
                    0,
                    3,
                    4,
                    12,
                    13,
                    13,
                    14,
                    5,
                    14,
                    10,
                    12,
                    13,
                    14,
                    15,
                    14,
                    14,
                    16
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
            return "Chocolate striped";
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
            return "Black bear";
        }

        if (gene == 16) {
            return "Red panda";
        }

        if (gene == 17) {
            return "Robot";
        }

        if (gene == 18) {
            return "Void";
        }

        if (gene == 19) {
            return "Negative tiger";
        }
        return "";
    }

    function getSkin(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 4);
    }

    function seedToHead(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 48) & 0xFFFF;
            uint256 trait = traitSeed % 75;
            if (
                traitSeed >> 8 <
                [
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256
                ][trait]
            ) return trait;
            return
                [
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0
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
            return "Retro headphones";
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
            return "Cyber rice hat";
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
            return "Shaved Sides";
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
            return "Shaved top";
        }

        if (gene == 72) {
            return "Vault Bear";
        }

        if (gene == 73) {
            return "Tied hair";
        }

        if (gene == 74) {
            return "None";
        }
        return "";
    }

    function getHead(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 3);
    }

    function seedToEyes(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 64) & 0xFFFF;
            uint256 trait = traitSeed % 16;
            if (
                traitSeed >> 8 <
                [
                    255,
                    121,
                    165,
                    113,
                    207,
                    175,
                    153,
                    92,
                    15,
                    30,
                    123,
                    46,
                    61,
                    61,
                    61,
                    61
                ][trait]
            ) return trait;
            return [0, 0, 1, 2, 3, 4, 0, 1, 1, 3, 3, 3, 3, 4, 4, 5][trait];
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
            return "Ghost Eyes";
        }

        if (gene == 7) {
            return "Snake";
        }

        if (gene == 8) {
            return "GN";
        }

        if (gene == 9) {
            return "GM";
        }

        if (gene == 10) {
            return "Worried";
        }

        if (gene == 11) {
            return "Ok.";
        }

        if (gene == 12) {
            return "Cyber Eyes";
        }

        if (gene == 13) {
            return "Lizard Eyes";
        }

        if (gene == 14) {
            return "Brown Eyes";
        }

        if (gene == 15) {
            return "Bloodshot Eyes";
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
                [256, 242, 97, 97, 97, 97, 114, 97, 97, 242, 48][trait]
            ) return trait;
            return [0, 0, 0, 0, 6, 6, 0, 6, 6, 6, 6][trait];
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
            return "Ramen Mouth";
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
            return "Bloody fangs";
        }
        return "";
    }

    function getMouth(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 1);
    }

    function seedToOutfit(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 96) & 0xFFFF;
            uint256 trait = traitSeed % 70;
            if (
                traitSeed >> 8 <
                [
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256,
                    256
                ][trait]
            ) return trait;
            return
                [
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0
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
            return "Blue Paw Hoodie";
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
            return "Read Bearz Hoodie";
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
            return "Red Flame Pull-Over";
        }

        if (gene == 38) {
            return "Blue Flame Pull-Over";
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
            return "Red 10-Plate Armor";
        }

        if (gene == 43) {
            return "Blue 10-Plate Armor";
        }

        if (gene == 44) {
            return "Orange 10-Plate Armor";
        }

        if (gene == 45) {
            return "Green 9-Plate Armor";
        }

        if (gene == 46) {
            return "Orange 9-Plate Armor";
        }

        if (gene == 47) {
            return "Blue 9-Plate Armor";
        }

        if (gene == 48) {
            return "Red 9-Plate Armor";
        }

        if (gene == 49) {
            return "Forester Band";
        }

        if (gene == 50) {
            return "Purple Striped Band";
        }

        if (gene == 51) {
            return "Green Striped Band";
        }

        if (gene == 52) {
            return "Green Bandana";
        }

        if (gene == 53) {
            return "Blue Striped Band";
        }

        if (gene == 54) {
            return "Red Striped Band";
        }

        if (gene == 55) {
            return "Red Bandana";
        }

        if (gene == 56) {
            return "Red Arm Band";
        }

        if (gene == 57) {
            return "Blue Arm Band";
        }

        if (gene == 58) {
            return "Black Arm Band";
        }

        if (gene == 59) {
            return "Black T-Shirt";
        }

        if (gene == 60) {
            return "White T-Shirt";
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
            return "Bearz T-Shirt";
        }

        if (gene == 65) {
            return "Graphic Tee";
        }

        if (gene == 66) {
            return "Black Graphic Tee";
        }

        if (gene == 67) {
            return "Dark piratez suit";
        }

        if (gene == 68) {
            return "Vault shirt";
        }

        if (gene == 69) {
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