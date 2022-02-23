//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";
import "./Rarities.sol";
import "./Rng.sol";
import "./ChainScoutMetadata.sol";

library Generator {
    using RngLibrary for Rng;

    function getRandom(
        Rng memory rng,
        uint256 raritySum,
        uint16[] memory rarities
    ) internal view returns (uint256) {
        uint256 rn = rng.generate(0, raritySum - 1);

        for (uint256 i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return i;
            }
            rn -= rarities[i];
        }
        revert("rn not selected");
    }

    function makeRandomClass(Rng memory rn)
        internal
        view
        returns (BackAccessory)
    {
        uint256 r = rn.generate(1, 100);

        if (r <= 2) {
            return BackAccessory.NETRUNNER;
        } else if (r <= 15) {
            return BackAccessory.MERCENARY;
        } else if (r <= 23) {
            return BackAccessory.RONIN;
        } else if (r <= 27) {
            return BackAccessory.ENCHANTER;
        } else if (r <= 38) {
            return BackAccessory.VANGUARD;
        } else if (r <= 45) {
            return BackAccessory.MINER;
        } else if (r <= 50) {
            return BackAccessory.PATHFINDER;
        } else {
            return BackAccessory.SCOUT;
        }
    }

    function getAttack(Rng memory rn, BackAccessory sc)
        internal
        view
        returns (uint256)
    {
        if (sc == BackAccessory.SCOUT) {
            return rn.generate(1785, 2415);
        } else if (sc == BackAccessory.VANGUARD) {
            return rn.generate(1105, 1495);
        } else if (sc == BackAccessory.RONIN || sc == BackAccessory.ENCHANTER) {
            return rn.generate(2805, 3795);
        } else if (sc == BackAccessory.MINER) {
            return rn.generate(1615, 2185);
        } else if (sc == BackAccessory.NETRUNNER) {
            return rn.generate(3740, 5060);
        } else {
            return rn.generate(2125, 2875);
        }
    }

    function getDefense(Rng memory rn, BackAccessory sc)
        internal
        view
        returns (uint256)
    {
        if (sc == BackAccessory.SCOUT || sc == BackAccessory.NETRUNNER) {
            return rn.generate(1785, 2415);
        } else if (sc == BackAccessory.VANGUARD) {
            return rn.generate(4250, 5750);
        } else if (sc == BackAccessory.RONIN) {
            return rn.generate(1530, 2070);
        } else if (sc == BackAccessory.MINER) {
            return rn.generate(1615, 2185);
        } else if (sc == BackAccessory.ENCHANTER) {
            return rn.generate(2805, 3795);
        } else if (sc == BackAccessory.NETRUNNER) {
            return rn.generate(3740, 5060);
        } else {
            return rn.generate(2125, 2875);
        }
    }

    function exclude(uint trait, uint idx, uint16[][] memory rarities, uint16[] memory limits) internal pure {
        limits[trait] -= rarities[trait][idx];
        rarities[trait][idx] = 0;
    }

    function getRandomMetadata(Rng memory rng)
        external 
        view
        returns (ChainScoutMetadata memory ret, Rng memory rn)
    {
        uint16[][] memory rarities = new uint16[][](8);
        rarities[0] = Rarities.accessory();
        rarities[1] = Rarities.backaccessory();
        rarities[2] = Rarities.background();
        rarities[3] = Rarities.clothing();
        rarities[4] = Rarities.eyes();
        rarities[5] = Rarities.fur();
        rarities[6] = Rarities.head();
        rarities[7] = Rarities.mouth();

        uint16[] memory limits = new uint16[](rarities.length);
        for (uint i = 0; i < limits.length; ++i) {
            limits[i] = 10000;
        }

        // excluded traits are less likely than advertised because if an excluding trait is selected, the excluded trait's chance drops to 0%
        // one alternative is a while loop that will use wildly varying amounts of gas, which is unacceptable
        // another alternative is to boost the chance of excluded traits proportionally to the chance that they get excluded, but this will cause the excluded traits to be disproportionately likely in the event that they are not excluded
        ret.accessory = Accessory(getRandom(rng, limits[0], rarities[0]));
        if (
            ret.accessory == Accessory.AMULET ||
            ret.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN ||
            ret.accessory == Accessory.FANNY_PACK ||
            ret.accessory == Accessory.GOLDEN_CHAIN
        ) {
            exclude(3, uint(Clothing.FLEET_UNIFORM__BLUE), rarities, limits);
            exclude(3, uint(Clothing.FLEET_UNIFORM__RED), rarities, limits);

            if (ret.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN) {
                exclude(1, uint(BackAccessory.MINER), rarities, limits);
            }
        }
        else if (ret.accessory == Accessory.GOLD_EARRINGS) {
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }

        ret.backaccessory = BackAccessory(getRandom(rng, limits[1], rarities[1]));
        if (ret.backaccessory == BackAccessory.PATHFINDER) {
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }

        ret.background = Background(getRandom(rng, limits[2], rarities[2]));
        if (ret.background == Background.CITY__PURPLE) {
            exclude(3, uint(Clothing.FLEET_UNIFORM__BLUE), rarities, limits);
            exclude(3, uint(Clothing.MARTIAL_SUIT), rarities, limits);
            exclude(3, uint(Clothing.THUNDERDOME_ARMOR), rarities, limits);
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }
        else if (ret.background == Background.CITY__RED) {
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }

        ret.clothing = Clothing(getRandom(rng, limits[3], rarities[3]));
        if (ret.clothing == Clothing.FLEET_UNIFORM__BLUE || ret.clothing == Clothing.FLEET_UNIFORM__RED) {
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }

        ret.eyes = Eyes(getRandom(rng, limits[4], rarities[4]));
        if (ret.eyes == Eyes.BLUE_LASER || ret.eyes == Eyes.RED_LASER) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.BANANA), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.BLUE_SHADES || ret.eyes == Eyes.DARK_SUNGLASSES || ret.eyes == Eyes.GOLDEN_SHADES) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.HUD_GLASSES || ret.eyes == Eyes.HIVE_GOGGLES || ret.eyes == Eyes.WHITE_SUNGLASSES) {
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }
        else if (ret.eyes == Eyes.HAPPY) {
            exclude(6, uint(Head.CAP), rarities, limits);
            exclude(6, uint(Head.LEATHER_COWBOY_HAT), rarities, limits);
            exclude(6, uint(Head.PURPLE_COWBOY_HAT), rarities, limits);
        }
        else if (ret.eyes == Eyes.HIPSTER_GLASSES) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.MATRIX_GLASSES || ret.eyes == Eyes.NIGHT_VISION_GOGGLES || ret.eyes == Eyes.SUNGLASSES) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }
        else if (ret.eyes == Eyes.NOUNS_GLASSES) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.PINCENEZ) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
        }
        else if (ret.eyes == Eyes.SPACE_VISOR) {
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }

        ret.fur = Fur(getRandom(rng, limits[5], rarities[5]));

        ret.head = Head(getRandom(rng, limits[6], rarities[6]));

        if (ret.head == Head.BANDANA || ret.head == Head.DORAG) {
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.head == Head.CYBER_HELMET__BLUE || ret.head == Head.CYBER_HELMET__RED || ret.head == Head.SPACESUIT_HELMET) {
            exclude(7, uint(Mouth.BANANA), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.CIGAR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.PIPE), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.VAPE), rarities, limits);
        }
        // not else. spacesuit helmet includes the above
        if (ret.head == Head.SPACESUIT_HELMET) {
            exclude(7, uint(Mouth.MASK), rarities, limits);
        }

        ret.mouth = Mouth(getRandom(rng, limits[7], rarities[7]));

        ret.attack = uint16(getAttack(rng, ret.backaccessory));
        ret.defense = uint16(getDefense(rng, ret.backaccessory));
        ret.luck = uint16(rng.generate(500, 5000));
        ret.speed = uint16(rng.generate(500, 5000));
        ret.strength = uint16(rng.generate(500, 5000));
        ret.intelligence = uint16(rng.generate(500, 5000));
        ret.level = 1;

        rn = rng;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Accessory {
    GOLD_EARRINGS,
    SCARS,
    GOLDEN_CHAIN,
    AMULET,
    CUBAN_LINK_GOLD_CHAIN,
    FANNY_PACK,
    NONE
}

enum BackAccessory {
    NETRUNNER,
    MERCENARY,
    RONIN,
    ENCHANTER,
    VANGUARD,
    MINER,
    PATHFINDER,
    SCOUT
}

enum Background {
    STARRY_PINK,
    STARRY_YELLOW,
    STARRY_PURPLE,
    STARRY_GREEN,
    NEBULA,
    STARRY_RED,
    STARRY_BLUE,
    SUNSET,
    MORNING,
    INDIGO,
    CITY__PURPLE,
    CONTROL_ROOM,
    LAB,
    GREEN,
    ORANGE,
    PURPLE,
    CITY__GREEN,
    CITY__RED,
    STATION,
    BOUNTY,
    BLUE_SKY,
    RED_SKY,
    GREEN_SKY
}

enum Clothing {
    MARTIAL_SUIT,
    AMETHYST_ARMOR,
    SHIRT_AND_TIE,
    THUNDERDOME_ARMOR,
    FLEET_UNIFORM__BLUE,
    BANANITE_SHIRT,
    EXPLORER,
    COSMIC_GHILLIE_SUIT__BLUE,
    COSMIC_GHILLIE_SUIT__GOLD,
    CYBER_JUMPSUIT,
    ENCHANTER_ROBES,
    HOODIE,
    SPACESUIT,
    MECHA_ARMOR,
    LAB_COAT,
    FLEET_UNIFORM__RED,
    GOLD_ARMOR,
    ENERGY_ARMOR__BLUE,
    ENERGY_ARMOR__RED,
    MISSION_SUIT__BLACK,
    MISSION_SUIT__PURPLE,
    COWBOY,
    GLITCH_ARMOR,
    NONE
}

enum Eyes {
    SPACE_VISOR,
    ADORABLE,
    VETERAN,
    SUNGLASSES,
    WHITE_SUNGLASSES,
    RED_EYES,
    WINK,
    CASUAL,
    CLOSED,
    DOWNCAST,
    HAPPY,
    BLUE_EYES,
    HUD_GLASSES,
    DARK_SUNGLASSES,
    NIGHT_VISION_GOGGLES,
    BIONIC,
    HIVE_GOGGLES,
    MATRIX_GLASSES,
    GREEN_GLOW,
    ORANGE_GLOW,
    RED_GLOW,
    PURPLE_GLOW,
    BLUE_GLOW,
    SKY_GLOW,
    RED_LASER,
    BLUE_LASER,
    GOLDEN_SHADES,
    HIPSTER_GLASSES,
    PINCENEZ,
    BLUE_SHADES,
    BLIT_GLASSES,
    NOUNS_GLASSES
}

enum Fur {
    MAGENTA,
    BLUE,
    GREEN,
    RED,
    BLACK,
    BROWN,
    SILVER,
    PURPLE,
    PINK,
    SEANCE,
    TURQUOISE,
    CRIMSON,
    GREENYELLOW,
    GOLD,
    DIAMOND,
    METALLIC
}

enum Head {
    HALO,
    ENERGY_FIELD,
    BLUE_TOP_HAT,
    RED_TOP_HAT,
    ENERGY_CRYSTAL,
    CROWN,
    BANDANA,
    BUCKET_HAT,
    HOMBURG_HAT,
    PROPELLER_HAT,
    HEADBAND,
    DORAG,
    PURPLE_COWBOY_HAT,
    SPACESUIT_HELMET,
    PARTY_HAT,
    CAP,
    LEATHER_COWBOY_HAT,
    CYBER_HELMET__BLUE,
    CYBER_HELMET__RED,
    SAMURAI_HAT,
    NONE
}

enum Mouth {
    SMIRK,
    SURPRISED,
    SMILE,
    PIPE,
    OPEN_SMILE,
    NEUTRAL,
    MASK,
    TONGUE_OUT,
    GOLD_GRILL,
    DIAMOND_GRILL,
    NAVY_RESPIRATOR,
    RED_RESPIRATOR,
    MAGENTA_RESPIRATOR,
    GREEN_RESPIRATOR,
    MEMPO,
    VAPE,
    PILOT_OXYGEN_MASK,
    CIGAR,
    BANANA,
    CHROME_RESPIRATOR,
    STOIC
}

library Enums {
    function toString(Accessory v) external pure returns (string memory) {
        if (v == Accessory.GOLD_EARRINGS) {
            return "Gold Earrings";
        }

        if (v == Accessory.SCARS) {
            return "Scars";
        }

        if (v == Accessory.GOLDEN_CHAIN) {
            return "Golden Chain";
        }

        if (v == Accessory.AMULET) {
            return "Amulet";
        }

        if (v == Accessory.CUBAN_LINK_GOLD_CHAIN) {
            return "Cuban Link Gold Chain";
        }

        if (v == Accessory.FANNY_PACK) {
            return "Fanny Pack";
        }

        if (v == Accessory.NONE) {
            return "None";
        }
        revert("invalid accessory");
    }

    function toString(BackAccessory v) external pure returns (string memory) {
        if (v == BackAccessory.NETRUNNER) {
            return "Netrunner";
        }

        if (v == BackAccessory.MERCENARY) {
            return "Mercenary";
        }

        if (v == BackAccessory.RONIN) {
            return "Ronin";
        }

        if (v == BackAccessory.ENCHANTER) {
            return "Enchanter";
        }

        if (v == BackAccessory.VANGUARD) {
            return "Vanguard";
        }

        if (v == BackAccessory.MINER) {
            return "Miner";
        }

        if (v == BackAccessory.PATHFINDER) {
            return "Pathfinder";
        }

        if (v == BackAccessory.SCOUT) {
            return "Scout";
        }
        revert("invalid back accessory");
    }

    function toString(Background v) external pure returns (string memory) {
        if (v == Background.STARRY_PINK) {
            return "Starry Pink";
        }

        if (v == Background.STARRY_YELLOW) {
            return "Starry Yellow";
        }

        if (v == Background.STARRY_PURPLE) {
            return "Starry Purple";
        }

        if (v == Background.STARRY_GREEN) {
            return "Starry Green";
        }

        if (v == Background.NEBULA) {
            return "Nebula";
        }

        if (v == Background.STARRY_RED) {
            return "Starry Red";
        }

        if (v == Background.STARRY_BLUE) {
            return "Starry Blue";
        }

        if (v == Background.SUNSET) {
            return "Sunset";
        }

        if (v == Background.MORNING) {
            return "Morning";
        }

        if (v == Background.INDIGO) {
            return "Indigo";
        }

        if (v == Background.CITY__PURPLE) {
            return "City - Purple";
        }

        if (v == Background.CONTROL_ROOM) {
            return "Control Room";
        }

        if (v == Background.LAB) {
            return "Lab";
        }

        if (v == Background.GREEN) {
            return "Green";
        }

        if (v == Background.ORANGE) {
            return "Orange";
        }

        if (v == Background.PURPLE) {
            return "Purple";
        }

        if (v == Background.CITY__GREEN) {
            return "City - Green";
        }

        if (v == Background.CITY__RED) {
            return "City - Red";
        }

        if (v == Background.STATION) {
            return "Station";
        }

        if (v == Background.BOUNTY) {
            return "Bounty";
        }

        if (v == Background.BLUE_SKY) {
            return "Blue Sky";
        }

        if (v == Background.RED_SKY) {
            return "Red Sky";
        }

        if (v == Background.GREEN_SKY) {
            return "Green Sky";
        }
        revert("invalid background");
    }

    function toString(Clothing v) external pure returns (string memory) {
        if (v == Clothing.MARTIAL_SUIT) {
            return "Martial Suit";
        }

        if (v == Clothing.AMETHYST_ARMOR) {
            return "Amethyst Armor";
        }

        if (v == Clothing.SHIRT_AND_TIE) {
            return "Shirt and Tie";
        }

        if (v == Clothing.THUNDERDOME_ARMOR) {
            return "Thunderdome Armor";
        }

        if (v == Clothing.FLEET_UNIFORM__BLUE) {
            return "Fleet Uniform - Blue";
        }

        if (v == Clothing.BANANITE_SHIRT) {
            return "Bananite Shirt";
        }

        if (v == Clothing.EXPLORER) {
            return "Explorer";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__BLUE) {
            return "Cosmic Ghillie Suit - Blue";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__GOLD) {
            return "Cosmic Ghillie Suit - Gold";
        }

        if (v == Clothing.CYBER_JUMPSUIT) {
            return "Cyber Jumpsuit";
        }

        if (v == Clothing.ENCHANTER_ROBES) {
            return "Enchanter Robes";
        }

        if (v == Clothing.HOODIE) {
            return "Hoodie";
        }

        if (v == Clothing.SPACESUIT) {
            return "Spacesuit";
        }

        if (v == Clothing.MECHA_ARMOR) {
            return "Mecha Armor";
        }

        if (v == Clothing.LAB_COAT) {
            return "Lab Coat";
        }

        if (v == Clothing.FLEET_UNIFORM__RED) {
            return "Fleet Uniform - Red";
        }

        if (v == Clothing.GOLD_ARMOR) {
            return "Gold Armor";
        }

        if (v == Clothing.ENERGY_ARMOR__BLUE) {
            return "Energy Armor - Blue";
        }

        if (v == Clothing.ENERGY_ARMOR__RED) {
            return "Energy Armor - Red";
        }

        if (v == Clothing.MISSION_SUIT__BLACK) {
            return "Mission Suit - Black";
        }

        if (v == Clothing.MISSION_SUIT__PURPLE) {
            return "Mission Suit - Purple";
        }

        if (v == Clothing.COWBOY) {
            return "Cowboy";
        }

        if (v == Clothing.GLITCH_ARMOR) {
            return "Glitch Armor";
        }

        if (v == Clothing.NONE) {
            return "None";
        }
        revert("invalid clothing");
    }

    function toString(Eyes v) external pure returns (string memory) {
        if (v == Eyes.SPACE_VISOR) {
            return "Space Visor";
        }

        if (v == Eyes.ADORABLE) {
            return "Adorable";
        }

        if (v == Eyes.VETERAN) {
            return "Veteran";
        }

        if (v == Eyes.SUNGLASSES) {
            return "Sunglasses";
        }

        if (v == Eyes.WHITE_SUNGLASSES) {
            return "White Sunglasses";
        }

        if (v == Eyes.RED_EYES) {
            return "Red Eyes";
        }

        if (v == Eyes.WINK) {
            return "Wink";
        }

        if (v == Eyes.CASUAL) {
            return "Casual";
        }

        if (v == Eyes.CLOSED) {
            return "Closed";
        }

        if (v == Eyes.DOWNCAST) {
            return "Downcast";
        }

        if (v == Eyes.HAPPY) {
            return "Happy";
        }

        if (v == Eyes.BLUE_EYES) {
            return "Blue Eyes";
        }

        if (v == Eyes.HUD_GLASSES) {
            return "HUD Glasses";
        }

        if (v == Eyes.DARK_SUNGLASSES) {
            return "Dark Sunglasses";
        }

        if (v == Eyes.NIGHT_VISION_GOGGLES) {
            return "Night Vision Goggles";
        }

        if (v == Eyes.BIONIC) {
            return "Bionic";
        }

        if (v == Eyes.HIVE_GOGGLES) {
            return "Hive Goggles";
        }

        if (v == Eyes.MATRIX_GLASSES) {
            return "Matrix Glasses";
        }

        if (v == Eyes.GREEN_GLOW) {
            return "Green Glow";
        }

        if (v == Eyes.ORANGE_GLOW) {
            return "Orange Glow";
        }

        if (v == Eyes.RED_GLOW) {
            return "Red Glow";
        }

        if (v == Eyes.PURPLE_GLOW) {
            return "Purple Glow";
        }

        if (v == Eyes.BLUE_GLOW) {
            return "Blue Glow";
        }

        if (v == Eyes.SKY_GLOW) {
            return "Sky Glow";
        }

        if (v == Eyes.RED_LASER) {
            return "Red Laser";
        }

        if (v == Eyes.BLUE_LASER) {
            return "Blue Laser";
        }

        if (v == Eyes.GOLDEN_SHADES) {
            return "Golden Shades";
        }

        if (v == Eyes.HIPSTER_GLASSES) {
            return "Hipster Glasses";
        }

        if (v == Eyes.PINCENEZ) {
            return "Pince-nez";
        }

        if (v == Eyes.BLUE_SHADES) {
            return "Blue Shades";
        }

        if (v == Eyes.BLIT_GLASSES) {
            return "Blit GLasses";
        }

        if (v == Eyes.NOUNS_GLASSES) {
            return "Nouns Glasses";
        }
        revert("invalid eyes");
    }

    function toString(Fur v) external pure returns (string memory) {
        if (v == Fur.MAGENTA) {
            return "Magenta";
        }

        if (v == Fur.BLUE) {
            return "Blue";
        }

        if (v == Fur.GREEN) {
            return "Green";
        }

        if (v == Fur.RED) {
            return "Red";
        }

        if (v == Fur.BLACK) {
            return "Black";
        }

        if (v == Fur.BROWN) {
            return "Brown";
        }

        if (v == Fur.SILVER) {
            return "Silver";
        }

        if (v == Fur.PURPLE) {
            return "Purple";
        }

        if (v == Fur.PINK) {
            return "Pink";
        }

        if (v == Fur.SEANCE) {
            return "Seance";
        }

        if (v == Fur.TURQUOISE) {
            return "Turquoise";
        }

        if (v == Fur.CRIMSON) {
            return "Crimson";
        }

        if (v == Fur.GREENYELLOW) {
            return "Green-Yellow";
        }

        if (v == Fur.GOLD) {
            return "Gold";
        }

        if (v == Fur.DIAMOND) {
            return "Diamond";
        }

        if (v == Fur.METALLIC) {
            return "Metallic";
        }
        revert("invalid fur");
    }

    function toString(Head v) external pure returns (string memory) {
        if (v == Head.HALO) {
            return "Halo";
        }

        if (v == Head.ENERGY_FIELD) {
            return "Energy Field";
        }

        if (v == Head.BLUE_TOP_HAT) {
            return "Blue Top Hat";
        }

        if (v == Head.RED_TOP_HAT) {
            return "Red Top Hat";
        }

        if (v == Head.ENERGY_CRYSTAL) {
            return "Energy Crystal";
        }

        if (v == Head.CROWN) {
            return "Crown";
        }

        if (v == Head.BANDANA) {
            return "Bandana";
        }

        if (v == Head.BUCKET_HAT) {
            return "Bucket Hat";
        }

        if (v == Head.HOMBURG_HAT) {
            return "Homburg Hat";
        }

        if (v == Head.PROPELLER_HAT) {
            return "Propeller Hat";
        }

        if (v == Head.HEADBAND) {
            return "Headband";
        }

        if (v == Head.DORAG) {
            return "Do-rag";
        }

        if (v == Head.PURPLE_COWBOY_HAT) {
            return "Purple Cowboy Hat";
        }

        if (v == Head.SPACESUIT_HELMET) {
            return "Spacesuit Helmet";
        }

        if (v == Head.PARTY_HAT) {
            return "Party Hat";
        }

        if (v == Head.CAP) {
            return "Cap";
        }

        if (v == Head.LEATHER_COWBOY_HAT) {
            return "Leather Cowboy Hat";
        }

        if (v == Head.CYBER_HELMET__BLUE) {
            return "Cyber Helmet - Blue";
        }

        if (v == Head.CYBER_HELMET__RED) {
            return "Cyber Helmet - Red";
        }

        if (v == Head.SAMURAI_HAT) {
            return "Samurai Hat";
        }

        if (v == Head.NONE) {
            return "None";
        }
        revert("invalid head");
    }

    function toString(Mouth v) external pure returns (string memory) {
        if (v == Mouth.SMIRK) {
            return "Smirk";
        }

        if (v == Mouth.SURPRISED) {
            return "Surprised";
        }

        if (v == Mouth.SMILE) {
            return "Smile";
        }

        if (v == Mouth.PIPE) {
            return "Pipe";
        }

        if (v == Mouth.OPEN_SMILE) {
            return "Open Smile";
        }

        if (v == Mouth.NEUTRAL) {
            return "Neutral";
        }

        if (v == Mouth.MASK) {
            return "Mask";
        }

        if (v == Mouth.TONGUE_OUT) {
            return "Tongue Out";
        }

        if (v == Mouth.GOLD_GRILL) {
            return "Gold Grill";
        }

        if (v == Mouth.DIAMOND_GRILL) {
            return "Diamond Grill";
        }

        if (v == Mouth.NAVY_RESPIRATOR) {
            return "Navy Respirator";
        }

        if (v == Mouth.RED_RESPIRATOR) {
            return "Red Respirator";
        }

        if (v == Mouth.MAGENTA_RESPIRATOR) {
            return "Magenta Respirator";
        }

        if (v == Mouth.GREEN_RESPIRATOR) {
            return "Green Respirator";
        }

        if (v == Mouth.MEMPO) {
            return "Mempo";
        }

        if (v == Mouth.VAPE) {
            return "Vape";
        }

        if (v == Mouth.PILOT_OXYGEN_MASK) {
            return "Pilot Oxygen Mask";
        }

        if (v == Mouth.CIGAR) {
            return "Cigar";
        }

        if (v == Mouth.BANANA) {
            return "Banana";
        }

        if (v == Mouth.CHROME_RESPIRATOR) {
            return "Chrome Respirator";
        }

        if (v == Mouth.STOIC) {
            return "Stoic";
        }
        revert("invalid mouth");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

library Rarities {
    function accessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](7);
        ret[0] = 1200;
        ret[1] = 800;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 400;
        ret[5] = 400;
        ret[6] = 6000;
    }

    function backaccessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](8);
        ret[0] = 200;
        ret[1] = 1300;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 1100;
        ret[5] = 700;
        ret[6] = 500;
        ret[7] = 5000;
    }

    function background() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](23);
        ret[0] = 600;
        ret[1] = 600;
        ret[2] = 600;
        ret[3] = 600;
        ret[4] = 500;
        ret[5] = 500;
        ret[6] = 500;
        ret[7] = 500;
        ret[8] = 500;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 600;
        ret[14] = 600;
        ret[15] = 600;
        ret[16] = 100;
        ret[17] = 100;
        ret[18] = 400;
        ret[19] = 400;
        ret[20] = 500;
        ret[21] = 500;
        ret[22] = 500;
    }

    function clothing() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](24);
        ret[0] = 500;
        ret[1] = 500;
        ret[2] = 300;
        ret[3] = 300;
        ret[4] = 500;
        ret[5] = 400;
        ret[6] = 300;
        ret[7] = 250;
        ret[8] = 250;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 500;
        ret[12] = 300;
        ret[13] = 500;
        ret[14] = 500;
        ret[15] = 500;
        ret[16] = 100;
        ret[17] = 400;
        ret[18] = 400;
        ret[19] = 250;
        ret[20] = 250;
        ret[21] = 250;
        ret[22] = 150;
        ret[23] = 2000;
    }

    function eyes() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](32);
        ret[0] = 250;
        ret[1] = 700;
        ret[2] = 225;
        ret[3] = 350;
        ret[4] = 125;
        ret[5] = 450;
        ret[6] = 700;
        ret[7] = 700;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 450;
        ret[12] = 250;
        ret[13] = 350;
        ret[14] = 350;
        ret[15] = 225;
        ret[16] = 125;
        ret[17] = 350;
        ret[18] = 200;
        ret[19] = 200;
        ret[20] = 200;
        ret[21] = 200;
        ret[22] = 200;
        ret[23] = 200;
        ret[24] = 50;
        ret[25] = 50;
        ret[26] = 450;
        ret[27] = 450;
        ret[28] = 400;
        ret[29] = 450;
        ret[30] = 25;
        ret[31] = 25;
    }

    function fur() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](16);
        ret[0] = 1100;
        ret[1] = 1100;
        ret[2] = 1100;
        ret[3] = 525;
        ret[4] = 350;
        ret[5] = 1100;
        ret[6] = 350;
        ret[7] = 1100;
        ret[8] = 1000;
        ret[9] = 525;
        ret[10] = 525;
        ret[11] = 500;
        ret[12] = 525;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 50;
    }

    function head() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 200;
        ret[1] = 200;
        ret[2] = 350;
        ret[3] = 350;
        ret[4] = 350;
        ret[5] = 150;
        ret[6] = 600;
        ret[7] = 350;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 600;
        ret[12] = 600;
        ret[13] = 200;
        ret[14] = 350;
        ret[15] = 600;
        ret[16] = 600;
        ret[17] = 50;
        ret[18] = 50;
        ret[19] = 100;
        ret[20] = 3000;
    }

    function mouth() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 1000;
        ret[1] = 1000;
        ret[2] = 1000;
        ret[3] = 650;
        ret[4] = 1000;
        ret[5] = 900;
        ret[6] = 750;
        ret[7] = 650;
        ret[8] = 100;
        ret[9] = 50;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 100;
        ret[16] = 100;
        ret[17] = 600;
        ret[18] = 600;
        ret[19] = 50;
        ret[20] = 1000;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A pseudo random number generator
 *
 * @dev This is not a true random number generator because smart contracts must be deterministic (every node a transaction goes to must produce the same result).
 *      True randomness requires an oracle which is both expensive in terms of gas and would take a critical part of the project off the chain.
 */
struct Rng {
    bytes32 state;
}

/**
 * @title A library for working with the Rng struct.
 *
 * @dev Rng cannot be a contract because then anyone could manipulate it by generating random numbers.
 */
library RngLibrary {
    /**
     * Creates a new Rng.
     */
    function newRng() internal view returns (Rng memory) {
        return Rng(getEntropy());
    }

    /**
     * Creates a pseudo-random value from the current block miner's address and sender.
     */
    function getEntropy() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.coinbase, msg.sender));
    }

    /**
     * Generates a random uint256.
     */
    function generate(Rng memory self) internal view returns (uint256) {
        self.state = keccak256(abi.encodePacked(getEntropy(), self.state));
        return uint256(self.state);
    }

    /**
     * Generates a random uint256 from min to max inclusive.
     *
     * @dev This function is not subject to modulo bias.
     *      The chance that this function has to reroll is astronomically unlikely, but it can theoretically reroll forever.
     */
    function generate(Rng memory self, uint min, uint max) internal view returns (uint256) {
        require(min <= max, "min > max");

        uint delta = max - min;

        if (delta == 0) {
            return min;
        }

        return generate(self) % (delta + 1) + min;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

struct KeyValuePair {
    string key;
    string value;
}

struct ChainScoutMetadata {
    Accessory accessory;
    BackAccessory backaccessory;
    Background background;
    Clothing clothing;
    Eyes eyes;
    Fur fur;
    Head head;
    Mouth mouth;
    uint24 attack;
    uint24 defense;
    uint24 luck;
    uint24 speed;
    uint24 strength;
    uint24 intelligence;
    uint16 level;
}