//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTokenURIProvider.sol";
import "./Enums.sol";
import "./IRenderer.sol";
import "./OpenSeaMetadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ChainScoutMetadata.sol";
import "./Sprites.sol";
import "./StringBuffer.sol";

contract ChainScoutsTokenURIProvider is BaseTokenURIProvider {
    using StringBufferLibrary for StringBuffer;
    using Enums for *;

    IRenderer public renderer;

    constructor(IRenderer _renderer) BaseTokenURIProvider("Chain Scout", "6000 Chain Scouts stored 100% on the Ethereum Blockchain\\n\\nChain Scouts is an on-chain project of that aims to implement P2E game theory mechanics, cross-project utility, and metaverse integrations with the goal of developing a robust token ecosystem and diverse community.") {
        renderer = _renderer;
    }

    function extensionKey() public override pure returns (string memory) {
        return "tokenUri";
    }

    function adminSetRenderer(IRenderer _renderer) external onlyAdmin {
        renderer = _renderer;
    }

    function tokenBgColor(uint) internal pure override returns (uint24) {
        return 0xFFFFFF;
    }

    function tokenSvg(uint tokenId) public view override returns (string memory) {
        ChainScoutMetadata memory sm = chainScouts.getChainScoutMetadata(tokenId);

        bytes[] memory sprites = new bytes[](8);
        sprites[0] = BackgroundSprites.getSprite(sm.background);
        sprites[1] = FurSprites.getSprite(sm.fur);
        sprites[2] = ClothingSprites.getSprite(sm.clothing);
        sprites[3] = BackAccessorySprites.getSprite(sm.backaccessory);
        sprites[4] = AccessorySprites.getSprite(sm.accessory);
        sprites[5] = EyesSprites.getSprite(sm.eyes);
        sprites[6] = MouthSprites.getSprite(sm.mouth);
        sprites[7] = HeadSprites.getSprite(sm.head);

        return renderer.render(sprites);
    }

    function scaleStat(uint24 stat, uint16 level) internal pure returns (uint24) {
        uint intermediate = stat;
        for (uint i = 1; i < level; ++i) {
            intermediate = intermediate * 11 / 10;
        }
        return uint24(intermediate);
    }

    function tokenAttributes(uint tokenId) internal view override returns (Attribute[] memory ret) {
        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(tokenId);

        ret = new Attribute[](15);
        ret[0] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Accessory",
            md.accessory.toString()
        );
        ret[1] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Back Accessory",
            md.backaccessory.toString()
        );
        ret[2] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Background",
            md.background.toString()
        );
        ret[3] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Clothing",
            md.clothing.toString()
        );
        ret[4] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Eyes",
            md.eyes.toString()
        );
        ret[5] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Fur",
            md.fur.toString()
        );
        ret[6] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Head",
            md.head.toString()
        );
        ret[7] = OpenSeaMetadataLibrary.makeStringAttribute(
            "Mouth",
            md.mouth.toString()
        );
        ret[8] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Attack",
            scaleStat(md.attack, md.level),
            0,
            3
        );
        ret[9] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Defense",
            scaleStat(md.defense, md.level),
            0,
            3
        );
        ret[10] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Luck",
            scaleStat(md.luck, md.level),
            0,
            3
        );
        ret[11] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Speed",
            scaleStat(md.speed, md.level),
            0,
            3
        );
        ret[12] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Strength",
            scaleStat(md.strength, md.level),
            0,
            3
        );
        ret[13] = OpenSeaMetadataLibrary.makeFixedPointAttribute(
            NumericAttributeType.NUMBER,
            "Intelligence",
            scaleStat(md.intelligence, md.level),
            0,
            3
        );
        ret[14] = OpenSeaMetadataLibrary.makeUintAttribute(
            NumericAttributeType.NUMBER,
            "Level",
            md.level,
            6
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenURIProvider.sol";
import "./OpenSeaMetadata.sol";
import "./ChainScoutsExtension.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract BaseTokenURIProvider is ITokenURIProvider, ChainScoutsExtension {
    string private baseName;
    string private defaultDescription;
    mapping (uint => string) private names;
    mapping (uint => string) private descriptions;

    constructor(string memory _baseName, string memory _defaultDescription) {
        baseName = _baseName;
        defaultDescription = _defaultDescription;
    }

    modifier stringIsJsonSafe(string memory str) {
        bytes memory b = bytes(str);
        for (uint i = 0; i < b.length; ++i) {
            uint8 char = uint8(b[i]);
            //              0-9                         A-Z                         a-z                   space
            if (!(char >= 48 && char <= 57 || char >= 65 && char <= 90 || char >= 97 && char <= 122 || char == 32)) {
                revert("BaseTokenURIProvider: All chars must be spaces or alphanumeric");
            }
        }
        _;
    }

    function setDescription(uint tokenId, string memory description) external canAccessToken(tokenId) stringIsJsonSafe(description) {
        descriptions[tokenId] = description;
    }

    function setName(uint tokenId, string memory name) external canAccessToken(tokenId) stringIsJsonSafe(name) {
        names[tokenId] = name;
    }

    function tokenBgColor(uint tokenId) internal view virtual returns (uint24);

    function tokenSvg(uint tokenId) public view virtual returns (string memory);

    function tokenAttributes(uint tokenId) internal view virtual returns (Attribute[] memory);

    function tokenURI(uint tokenId) external view override returns (string memory) {
        string memory name = names[tokenId];
        if (bytes(name).length == 0) {
            name = string(abi.encodePacked(
                baseName,
                " #",
                Strings.toString(tokenId)
            ));
        }

        string memory description = descriptions[tokenId];
        if (bytes(description).length == 0) {
            description = defaultDescription;
        }

        return OpenSeaMetadataLibrary.makeMetadata(OpenSeaMetadata(
            tokenSvg(tokenId),
            description,
            name,
            tokenBgColor(tokenId),
            tokenAttributes(tokenId)
        ));
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
    SCOUT,
    MERCENARY,
    RONIN,
    ENCHANTER,
    VANGUARD,
    MINER,
    PATHFINDER,
    NONE
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
    ARGUS,
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
    BITCOIN_GLASSES,
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
    BUNNY_EARS,
    SPACESUIT_HELMET,
    PARTY_HAT,
    CAP,
    LEATHER_COWBOY_HAT,
    CYBER_HELMET__BLUE,
    CYBER_HELMET__RED,
    SAMURAI_HAT,
    CATEAR_HEADPHONES,
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
    STOIC,
    UNEASY
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
    
        if (v == BackAccessory.SCOUT) {
            return "Scout (Backpack)";
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
    
        if (v == BackAccessory.NONE) {
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
    
        if (v == Background.ARGUS) {
            return "Argus";
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
    
        if (v == Eyes.BITCOIN_GLASSES) {
            return "Bitcoin Glasses";
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
    
        if (v == Head.BUNNY_EARS) {
            return "Bunny Ears";
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
    
        if (v == Head.CATEAR_HEADPHONES) {
            return "Cat-Ear Headphones";
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
    
        if (v == Mouth.UNEASY) {
            return "Uneasy";
        }
        revert("invalid mouth");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRenderer {
    function render(bytes[] memory sprites) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "./Integer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

enum NumericAttributeType {
    NUMBER,
    BOOST_PERCENTAGE,
    BOOST_NUMBER,
    DATE
}

struct Attribute {
    string displayType;
    string key;
    string serializedValue;
    string maxValue;
}

struct OpenSeaMetadata {
    string svg;
    string description;
    string name;
    uint24 backgroundColor;
    Attribute[] attributes;
}

library OpenSeaMetadataLibrary {
    using Strings for uint;

    struct ObjectKeyValuePair {
        string key;
        string serializedValue;
    }

    function uintToColorString(uint value, uint nBytes) internal pure returns (string memory) {
        bytes memory symbols = "0123456789ABCDEF";
        bytes memory buf = new bytes(nBytes * 2);

        for (uint i = 0; i < nBytes * 2; ++i) {
            buf[nBytes * 2 - 1 - i] = symbols[Integer.bitsFrom(value, (i * 4) + 3, i * 4)];
        }

        return string(buf);
    }

    function quote(string memory str) internal pure returns (string memory output) {
        return bytes(str).length > 0 ? string(abi.encodePacked(
            '"',
            str,
            '"'
        )) : "";
    }

    function makeStringAttribute(string memory key, string memory value) internal pure returns (Attribute memory) {
        return Attribute("", key, quote(value), "");
    }

    function makeNumericAttribute(NumericAttributeType nat, string memory key, string memory value, string memory maxValue) private pure returns (Attribute memory) {
        string memory s = "number";
        if (nat == NumericAttributeType.BOOST_PERCENTAGE) {
            s = "boost_percentage";
        }
        else if (nat == NumericAttributeType.BOOST_NUMBER) {
            s = "boost_number";
        }
        else if (nat == NumericAttributeType.DATE) {
            s = "date";
        }

        return Attribute(s, key, value, maxValue);
    }

    function makeFixedPoint(uint value, uint decimals) internal pure returns (string memory) {
        bytes memory st = bytes(value.toString());

        while (st.length < decimals) {
            st = abi.encodePacked(
                "0",
                st
            );
        }

        bytes memory ret = new bytes(st.length + 1);

        if (decimals >= st.length) {
            return string(abi.encodePacked("0.", st));
        }

        uint dl = st.length - decimals;

        uint i = 0;
        uint j = 0;

        while (i < ret.length) {
            if (i == dl) {
                ret[i] = '.';
                i++;
                continue;
            }

            ret[i] = st[j];

            i++;
            j++;
        }

        return string(ret);
    }

    function makeFixedPointAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue, uint decimals) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, makeFixedPoint(value, decimals), maxValue == 0 ? "" : makeFixedPoint(maxValue, decimals));
    }

    function makeUintAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, value.toString(), maxValue == 0 ? "" : maxValue.toString());
    }

    function makeBooleanAttribute(string memory key, bool value) internal pure returns (Attribute memory) {
        return Attribute("", key, value ? "true" : "false", "");
    }

    function makeAttributesArray(Attribute[] memory attributes) internal pure returns (string memory output) {
        output = "[";
        bool empty = true;

        for (uint i = 0; i < attributes.length; ++i) {
            if (bytes(attributes[i].serializedValue).length > 0) {
                ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](4);
                kvps[0] = ObjectKeyValuePair("trait_type", quote(attributes[i].key));
                kvps[1] = ObjectKeyValuePair("display_type", quote(attributes[i].displayType));
                kvps[2] = ObjectKeyValuePair("value", attributes[i].serializedValue);
                kvps[3] = ObjectKeyValuePair("max_value", attributes[i].maxValue);

                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    makeObject(kvps)
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "]"));
    }

    function notEmpty(string memory s) internal pure returns (bool) {
        return bytes(s).length > 0;
    }

    function makeObject(ObjectKeyValuePair[] memory kvps) internal pure returns (string memory output) {
        output = "{";
        bool empty = true;

        for (uint i = 0; i < kvps.length; ++i) {
            if (bytes(kvps[i].serializedValue).length > 0) {
                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    '"',
                    kvps[i].key,
                    '":',
                    kvps[i].serializedValue
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "}"));
    }

    function makeMetadataWithExtraKvps(OpenSeaMetadata memory metadata, ObjectKeyValuePair[] memory extra) internal pure returns (string memory output) {
        /*
        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            string(Base64.encode(bytes(metadata.svg)))
        ));
        */

        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;utf8,",
            metadata.svg
        ));

        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](5 + extra.length);
        kvps[0] = ObjectKeyValuePair("name", quote(metadata.name));
        kvps[1] = ObjectKeyValuePair("description", quote(metadata.description));
        kvps[2] = ObjectKeyValuePair("image", quote(svgUrl));
        kvps[3] = ObjectKeyValuePair("background_color", quote(uintToColorString(metadata.backgroundColor, 3)));
        kvps[4] = ObjectKeyValuePair("attributes", makeAttributesArray(metadata.attributes));
        for (uint i = 0; i < extra.length; ++i) {
            kvps[i + 5] = extra[i];
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(makeObject(kvps)))
        ));
    }

    function makeMetadata(OpenSeaMetadata memory metadata) internal pure returns (string memory output) {
        return makeMetadataWithExtraKvps(metadata, new ObjectKeyValuePair[](0));
    }

    function makeERC1155Metadata(OpenSeaMetadata memory metadata, string memory symbol) internal pure returns (string memory output) {
        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](1);
        kvps[0] = ObjectKeyValuePair("symbol", quote(symbol));
        return makeMetadataWithExtraKvps(metadata, kvps);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

library AccessorySprites {
    function getSprite(Accessory v) external pure returns (bytes memory) {
        if (v == Accessory.NONE) {
            return hex"";
        }

        if (v == Accessory.SCARS) {
            return hex"B12002CD2002B14002CD4002B56002C96002B58002C980025D16800A9A0009532A002509B000ACB000A8B8009532E002A70002B3000254BC800ACC800C";
        }

        if (v == Accessory.GOLDEN_CHAIN) {
            return hex"9F2004A32E82A72004DB2004DF2E82E320049F4004A34B1EA74004DB4004DF4B1EE340049F6004A373A3A76004DB6004DF7483E36004A38004A7948354BE0011A578004DB93A3DF8004A7A004ABAE82AFB3A3593E80134EBA0B5ED20F6E801152FC004B3CE82B7D483BBD3A35F0F3A0B1F2C7994FD3A3695F001164FE004";
        }

        if (v == Accessory.AMULET) {
            return hex"4E8C80137CA69B8C80127D00128D4E8E9D00136D00137D32F78D00128D80129DD20D52F6004695D80136DCE8F7D80129E0012AE3A0ABE4E8D64F8004D38E82D79483DB800454BE8012CEBA0ADED20EEE8012FEBF7F0E80131EAC7994FB3A3695E8011637C004BBCA3CBFCFDFC3CA3C633F0012DF8011743EC68C7E0040";
        }

        if (v == Accessory.CUBAN_LINK_GOLD_CHAIN) {
            return hex"A33483A72004DB2004DF34839F4B29A349A6A753A3AB4004D74004DB53A3DF49A6E34B299B60049F7118A369A6A76004DB6004DF69A6E37118E760044C7E00128E2CA69E3EDAAE520EBE00134E00135E520F6E3EDB7E2CA5C6780049FA004A3B3A352AE8012BECE8ECE8012DECE8EEED20D7C3A004C7B483CBB3A3CFA004D3B3A36B6E80137ECE8F8E80128F00129F3A0AAF4462BF0012CF3A096BBC004BFD3A3C3CE82632F00133F3A0B4F00135F44636F3A0B7F00114B3E004B7F118BBEE825F0F80131FC4632FBA099DBE0040";
        }

        if (v == Accessory.FANNY_PACK) {
            return hex"719C00137C80138CB37F9C80136D00137D337F8D50139D00135D80136DB37F7DD0138D80119538004D78CDFDB9404DF8004C7A004CBAFE6CFA004D3B404D7AA7CDBA004C3C004C7CFE6CBD12BCFCCDFD3D404D7CCDFDBC004BFE004C3EFE6C7E004CBECEECFECDFD3F404D7ECDFDBE0040";
        }

        if (v == Accessory.GOLD_EARRINGS) {
            return hex"9200048E20049232D59620049240048E60049272D5966004928004";
        }

        revert("invalid accessory");
    }
}

library BackAccessorySprites {
    function getSprite(BackAccessory v) external pure returns (bytes memory) {
        if (v == BackAccessory.NONE) {
            return hex"";
        }

        if (v == BackAccessory.SCOUT) {
            return hex"4A6B8011CEAE004930004970A549B00049F0C92A30903DF0903E30C92E70004EB0A54EF00048F2004932A549720054C7CA8468CB24A9CA40F6CA40F7CB249C672A11EB2005EF2A54F320048F400593481497481D9B40044E8D28469D324AAD240F5D240F6D3249BE34A11E74004EB481DEF4004F340058B60048F6A269368469F6004509DA846ADB24B5DB249B5F6A11E36004EF6004F36A26F760048B80048F889193882AA38004A78A11AB8C92D78C92DB8A11DF8004EF8004F38891F78004443E80128E80114ABAA11AFAC92B3A903CFA903D3AC926B6EA8477E8011E77A0048BC0058FC82AA7C004ABCA11AFCC92B3C903CFC903D3CC92D7CA11DBC004F3C82AF7C0058BE004A7E004ABEA11AFEC92B3E903CFE903D3EC92D7EA11DBE004F7E004";
        }

        if (v == BackAccessory.MERCENARY) {
            return hex"8220048257C38640048278888660048280048698888A800482A00486B8888AB7C38EA004424B00126B00122B80123BE2A9216E0049AF8888F00049314EC4A6C001108B20048F3888485C80126CB9C53A32004834004422D5F0D1934004974B759B40049F4B31A34004837888422D801129B60049F6C9EA360048380049F8004A38EFF52AE0011427A004ABB888AFA004A3C004A7D7C7ABC004AFD7C758DF00114AFE004B3EEFFB7EC9E5CFF80100";
        }

        if (v == BackAccessory.RONIN) {
            return hex"822004FE200440190011F7E4004826E148677D98A6004F66004FA77D9FE6E2C828824422A21923A0013CA0011EFA8864FE882486A8648AAE148EB7EF92A004EEA004F2B7D9F6AE2CFAA864444B21925B0013AB0011DF6C8648EE86492EE1496F7EF9AE004E6E004EAF7D9EEEE2CF2E864485C21926C20927C2D938C2D91CEF08649728249B2B649F2004E32004E72B64EB2864934004974B649B4004E74004EB4B64EF4824485D8013AD8013BDA190";
        }

        if (v == BackAccessory.ENCHANTER) {
            return hex"8174D54235D359E7D73248194D88594D98994D88D94D7E99325ED9326F193287BE64CA7F64C9E06D369089B4DC8DB4DBE9B327EDB32AF1B32CF5B32EF9B32FFDB32D81D4DD85D4E089D4DF8DD4DDE9D32BF1D330F5D332F9D333FDD33181F4E24227D39637D38FC7CCD3D7CCDBE7CCDFF7CCD608539D08A14EB8E14E7F21338F6133AFA133BFE13398234E94228D3B238D3ABC8CCF1EFA3340FE333D8254E8422953B239577BC94CF9EFA5340FE533F8274E48674E68A738B8E71D9F26DB7F66F37FA7079FE71BE8294DE8694E18A8DE08E8B91F28392F68BDBFA8E02FE8FE282B4DC86AA578AA6478EA6D092A6EAEEA21EF2A278F6A310FAA9E7FEACCF82C64686C6D98AC7648EC76C92C77296C77D9AC775E2C403E6C241EAC1B9EEC2F8F2C30AF6C21DFAC2A1FEC37182E76386E7788AE77E464B9FE25B9E066B9DDF9B8953AB86E3BB8C0BCB8C2BDB8743EB8817FB892E0C1EAE1C1DF22C1FCD19307F89707809B0776E303CCE70242EB01CFEF01A3F301A2F701AAFB01B7FF01BA8327B38727BA8B27E48F27F29327DB9727DC9B27709F26CAE3237BE721FAEB219BEF219DF3219CF7219AFB2195FF21978347A38747918B478D8F478F93479A97477B9B476F9F46B3E34385E74253EB4193EF4199F34198F74196FB4197FF419483678987678F443D9E2A4D9E265D9E2E6D9DD27D9B04";
        }

        if (v == BackAccessory.VANGUARD) {
            return hex"446A8011D76A00486C0048ACB42464B3B9929ACB4273AB2D09DF2CEE6F6CB42FAC00486E0048AEEE6466BA9EDCF2EA7BF6EEE6FAE0048700048B0B428F0A7B486C3C5A7C2DF78C2DF5CEF0F16F30A7BF70B42FB00048720048B2B428F2A7B932F164A6CADF67C80138C8011CEB2B7DEF2F16F32A7BF72B42FB20048740048B49B18F4A7B934F16974B7D9B40049F4C43A34004DF4004E34C43E74004EB4B7DEF4F16F34A7BF749B1FB40048760048B69B18F6A7B936B7D9760049F6004A36C43A76004DB6004DF6C43E36004EB6004EF6B7DF36A7BF769B1FB60048B80048F8B42938004A38004A78C43AB8004D78004DB8C43DF8004EF8004F38B42F780048BA0048FAB4293A004A7A004ABAC43AFA004D3A004D7AC43DBA004EFA004F3AB42F7A004443F0012AF0012BF310ECF00133F00134F310F5F0011E77C0048BE004AFE004B3EC43B7E004CFEC43D3E004F7E0040";
        }

        if (v == BackAccessory.MINER) {
            return hex"485A8011D6EA0048EC00492D8AA96D8239AC004E6C004EAD823EED8AAF2C0048AE0048EED6A92E00496ED6A9AF8749EE004E2E004E6F874EAED6AEEE8A3F2ED6AF6E0048700048B18AA8F00049318744A6C00127C608E8C00137C00138C608DCEB0004EF1874F30004F718AAFB0004423C80124CB5AA5CE1D26CB5A93A320046F8C80139CB5ABACE1D3BCB5ABCCA28DEFB20048740048B4B168F4A3A486D00127D310E8D00137D00138D310DCEF4004F34A3AF74B16FB40048760048B6B168F6C66936EA59760049F6004A36C43A76004DB6004DF6C43E36004EB6004EF6EA5F36C66F76B16FB60048780048B8B168F8C66938EA5978004A38004A78C43AB8004D78004DB8C43DF8004EB8004EF8EA5F38C66F78B16FB800487A0048BAB168FAC6693A004A7A004ABAC43AFA004D3A004D7AC43DBA004EFA004F3AC66F7AB16FBA0048BC0048FCC6693C004ABC004AFCC43B3C004CFC004D3CC43D7C004EFC004F3CC66F7C004443F8012BF8012CFB10EDF80132F80133FB10F4F8011E77E004";
        }

        if (v == BackAccessory.PATHFINDER) {
            return hex"8416318816348C16379016394A6058FA7058F68058EA9058DAA058D2B058C610D8D220D8E230A3BE40A70A50A7EE60A86A70A7EE80A6BA90D8FAA0D8DEB0D8D2C0D8C61158DE2123E231384641470A5148766132CA71487A813A429127A6A158FAB158DEC158CAD158C611A2CE21B76E31C70A41C96A51B13A61B1E271B10A81C96E91BA42A1A69EB1D8E6C1D8D2D1D8C612238E2238CE3248A242314A523F3A625956723F3A82313A92487AA227C6B258F2C258D6D258C612A3E222AF4A32B32A42B24252D95662DE4272D95682B22A92B2CAA2A86AB2D8FAC2D8DAD2D8C61323BE2338CE3348E64331C653402A63595673402A8331769348A2A327EEB358F2C358D96B8D63184E8B388EDFC8CF1DC90F28494EC7898ECC99CEC78A0F285A4EEA6A8E9C2ACF63BB0F634B4F6318516378908F88D0E2A9111EA95125C990CEA9D1243A10EBCA509FBA91640AD1637B11632B516318536348936388D290A9129E9952A2C992A5D9D2A2CA129E1A53640A93638AD3634B136318556318956348D563891563C9556409956419D563FA1563CA55638A9563356C558C625D8C635D8CE45D8D255D8D931D7637A17634A5763254B5D8C521596319996324E9658C40";
        }

        if (v == BackAccessory.NETRUNNER) {
            return hex"8C0004900A29940004E80004EC0A29F000048C2004902A29942004E82004EC2A29F020048C4004904C23944004E84004EC4C23F040048C6004906B6E946004E86004EC6B6EF060048C80049083E7948004E88004EC83E7F080048CA00490A3E794A004E8A004ECA3E7F0A00490C00494CC4898C004E4C004E8CC48ECC00490E00494EC4898E004E4E004E8EC48ECE004810004910004950F4F990004E50004E90F4FED0004FD0004812A294224801254801264B1213A520046D84801394B123A48011EF92004FD2A2981400442250C723500126500127531228528A77528A7853123950013C50011EF9431CFD40044225801235BD3E458012758013858013B58013C5BD3DEF960048D8004918C48958004E98004ED8C48F1800491A00495AA2999A004E5A004E9AA29EDA00481C00495C00499CA29E5CA29E9C004FDC00481EA2985E004F9E004FDEA2982000486031C44480011DF60004FA031CFE00048620048A2F4F8E2A29F22A29F62F4FFA200444390011E76400482C0049AC004E6C004FEC00482EA2986E00496E0049AEA29E6EA29EAE004FAE004FEEA29830004870C48444C00125C2DBA6C00139C0013AC2DB9DF70004FB0C48FF00048720048B231C464CBD3E5C8013AC8011DF32F4FF7231CFB2004444D0011DF740040";
        }

        revert("invalid back accessory");
    }
} 

library BackgroundSprites {
    function getSprite(Background v) external pure returns (bytes memory) {
        if (v == Background.STARRY_YELLOW) {
            return hex"80107684106B4430417521C105050A04106B0454D63C1041617040D9C68102CEC1143F011AFF411437DF040B200C47A10C44620C24519030834A70C1D9424306BA8317CAC31C8B0316D5AF0C17584C30506990C105D6C3036F031527BF0C0DA01462211483621454119051429451364C7144A5424511EA85111AC51AEB051105AF142458445083653141DB414215AD8506BDC505DE0505C73C14141EFC504180729F8472A08872638C71BC9071AD9471AB9871979C71895091C5ED52C716B58D1C582E1C542F1C53B01C50B11C4DB21C4D331C4A5A54711E6D71C44781C24791C23FA1C20DDF070767BE1C1AFF1C176024ADE124B962249FE32498A42492D298923C9C921F50924882A2482EB247D563491E2B891C6BC91C7611246F32246AD9D09189D4917BD8916BDC9160E09150E49142E8913677C244A7D2447BE24447F2424602CE5E12CDAA22CD4A32CC4E42CB8E52CB9131CB2D5A0B2CA52A2CABAB2CABEC2CA22D2CA7AE2C9FAF2C9C5844B2626532C8B742C88352C82F62C7D772C78B82C74DCE8B1BCECB189F0B188F4B17BF8B160FCB15080D44E84D42C88D4148CD3EA48534F42634F3E734EFE834EA6934EAAA34E26B34DEAC34DE56B8D36BBCD352C0D2FE63234B8F334B57434B2B534ABB634A237349FB8349FF934987A3492FB348B7C34883D347D7E3478BF3474E03E1BA13E1AA23D34E33D2D5214F4B498F4B69CF4975093D19D52CF43BB0F43AB4F4155CF3CFF9844F3D0C8F3CFCCF3A9D0F3AAD4F396D8F379DCF351E0F352E4F314E8F2FFECF2CAF0F2B7F4F29DF8F29EFCF24C81188385187A443461E644620529918784E9461C6A461C2B461BAC461B56B91867BD14D3611452D32452019D11467D5143A6D745057844FFB944FABA44F43B44EA7C44E5FD44DE7E44DABF44D4A04E21614E21911138844A64E1FE74E1F942D387DB1387BB53882B9387ABD3881C13876C538736534E1C744E1C354E1BB64E1AF74E19F84D34F94D2DBA4D25FB4D1FFC4D13BD4D0EBE4CFFFF4CFAE05623A15623625623235623645623129958879D588650A5621EB5621AC56212D5621AE562157C55884C9587F674561F9AD95883DD587BE15879E55876E95871ED5872F1586EF5586BF954D3FD54B64015E24225E24635E241219788F9D74695095E23D535788EB9788DBD788CC1788D6335E23345E22F55E219B5D7885E1788473A5E1FFB5E227C5E1EFD5E1EBE5E1E7F5E1E20651A909198924AB66246C662416BD98916136624346623DAD9988E6F866235CE9988C77C6621BD66217E66213F66251009B89446C6E24D6C5B8926576E245C65B890E9B88F77C6E23BD6E237E6E25FF6E265025D8945527624D9D1D892D5D8936D776249C71D8917BE76243F7626E07E24D0C1F8946327E24F37E251A61F89373A7E24BB7E24DE75F8927DF7E24500A189347686251BFA1893FE18928238918638924458E24D3723894F6346B7DF8E24E09623E19624229624639624927A5893FE589482788C8678988A788F4649E24129A78914E99E24952E789358F9E24984A78936759E249B627893E6789275F9E24E0A62561A62722A625A3A6239216988F4C8A62414BA98915F1A624994E9891697A6249C6A989177FA624A0AE1EA1AE24E2AE2163AE21A4AE21E5AE2326AE2353AAB88EAEB88FB2B88E5B0AE23F1AE24194EB88FD2B8906B6AE23DBF6B8907DFAE2460B61C21B61E22B61EA3B62264B61FD29AD8849ED885509B621952ED88758EB6232FB623584AD88CCED88DD2D88C6B8B6235CF6D88E7DFB623E0BD2621BD34E2BE1BA3BE1C64BE1DA5BE1E531EF87AA2F889A6F87EAAF88AAEF87E58EBE1FD7C2F884C6F885CAF884675BE2176BE211BE6F88575BBE21BCBE21DEFAF88CFEF88D8313EB87142B8B14678F14989314D49718679B186F9F186EA31870A71871AB1875AF1873B31878B718735CFC62058471879CB1881CF1879695C61EB6C61EDBE3187AE7187BEB187DEF1889F3187EF7187FFB1481FF18858333518733978B33CF8F33EA93341497342B9B344E4E8CD1FE9CD202ACD25EBCD2D563734D4BB386A5F0CD34D8CF3867D3386DD7386FDB386DDF386F719CE1BBACE1C3BCE1CFCCE1E3DCE207ECE1EBFCE1F60D4ABE1D4B562D4BFA3D4D4A4D4DEA5D4E5E6D4F027D4F3D42753D0AB53DC56DD4FF973F5415C35414C7542BCB543ACF543BD3543A6B7D513B8D519F9D51A3AD5203BD52D3CD52D7DD61ABED61BFFD61C60DC8BE1DC92E2DC9C63DCA224DCAE25DCB266DCB927DCBFE8DCC529DCC8EADCD4ABDCD46CDCDAADDCDAD73F737A611DCE2994F7389D37397D773966D7DCEAB8DCEFF9DCF3FADCF43BDCFABCDCFFFDDD0AFEDD19FFDD2620E46B21E471E2E478A3E482E4E48825E492E6E492A7E49C68E49C14AB9289AF9288B3929D5AFE4ABD84792B8CB92B7675E4B276E4B577E4B938E4B8F9E4BFFAE4C53BE4C8FCE4DEBDE4E5BEE4F3FFE4FAE0EC50A1EC5822EC5EE3EC6264EC6AE5EC6F26EC71E7EC74E8EC78A9EC786AEC7D6BEC7CECEC82EDEC829743B220632EC8BF3EC8B5A57B23CDBB23BDFB24BE3B24AE7B261EBB270EFB29EF3B2AFF7B2C9FBB2FEFFB36B83D11287D11E8BD1298FD13693D14297D1504C7F45828F45AD4AFD17BB3D189B7D197BBD1965F0F465F1F46AD94FD1AD695F46B1B5FD1BCE3D1C7E7D1D3EBD1E2EFD1F5F3D220F7D23BFBD270FFD27283F06B87F0768BF083464FC2465FC4426FC4453A3F11E52BFC4A5647F136653FC50B4FC5435FC539B5FF150E3F160E7F16B75BFC5EFCFC65FDFC6F3EFC78BFFC880";
        }

        if (v == Background.STARRY_PURPLE) {
            return hex"800D01840CF8443033AD21C0CE150A03356B038D163C0CD56170332DC680CC1EC0E12F00F02F40E127DF0330600B4D610B4AA20B4891902D134A70B4054242CF8A82E52AC2F0FB02E515AF0B3AD84C2CE16990B355D6C2CCBF02E2B7BF0B32E013602113AFE21359D1904D57944D4E4C7134FD4244D35A84D2AAC4E85B04D025AF134898444D13653134074136CDAD84CF8DC4CEBE04CD673C13385EFC4CD5806F35846FD3886EF88C6DCC906DB2946D99986DA49C6D985091B62952C6D7F58D1B5D6E1B59EF1B53F01B55F11B53B21B4DB31B4FDA546D356D71B4AB81B48B91B3E7A1B44DDF06D017BE1B3E3F1B3AE023A82123E422239EA32398642393D2988E439C8E10509238A2A2383EB238216348DFBB88DBFBC8DD9611237332236659D08D98D48D8AD88D7FDC8D75E08D67E48D57E88D4E77C234FFD234D7E234ABF2348A02BCFA12BC0622BC0232BB5A42BAFA52BB2131CAEBDA0AEB452A2BA4AB2BA7EC2B9EED2BA46E2B9BAF2B9B5844AE616532B8A742B8A352B83F62B82372B7EF82B7ADCE8ADCCECAD98F0AD80F4AD8AF8AD75FCAD6780CF9C84CFA888CF7C8CCF6148533DC2633D82733CFE833CD2933D32A33C82B33C7EC33C396B8CF0DBCCF00C0CEC963233AFB333AF7433AD3533A4B6339EF7339BB8339EB933943A3393FB338A7C338A3D33823E337EFF337AE03C07E13C04E23BFE633BFBD214EFDE98EFF89CEFD15093BECD52CEFB2B0EF8FB4EF9B5CF3BDC5844EF70C8EF60CCEF34D0EF4CD4EF2AD8EF0EDCEEF6E0EF00E4EEE3E8EED5ECEEB4F0EEA0F4EE84F8EE91FCEEF781108C8510664434416644419529910584E9440D6A440AEB4407EC440796B91001BD0FF961143F7B243F759D10FB3D50F8F6D743E6F843DC7943D87A43DC3B43CD3C43CFBD43C3BE43C07F43C0204C49614C4C9111311A4A64C43274C23542D3081B13074B53073B93066BD3065C1304CC5303D6534C0D744C0AF54C07F64C05374C00784BFE794BFE3A4BF47B4BF0FC4BE73D4BE3FE4BE3BF4BE1205459A15457A25453235457A454531299513D9D513250A544F6B544CAC5446AD544CAE544957C5511AC9510C67454235AD9508CDD5074E15059E5504CE95035ED503CF1501FF55014F94FF9FD4FF84015C61225C64635C61121971769D71685095C5D95357166B9715EBD714CC1715E6335C53345C52F55C4C9B5D7125E1711A73A5C433B5C42FC5C1D3D5C19BE5C167F5C16206464D09191A54AB64646C646116BD9191613646134645D9AD991666F86457B964533A64575DF19132F59125F9911AFD91A74026C70D1B1B1B75B16C69595DB1917196C613A6C5D9DF1B166F5B15EF9B1ECFDB2464097470D549D1B7674746975746DDB5DD1A571C74645EF9D184FDD20581F1B74307C70D8C9F1B7CDF1C36987C6DDCE9F1A5EDF1B779D7C695F7DF191402846DD1DA11C36FE846DFF8469608C64618C69511631B74DC8C70FD8C69DF7E31B78251768651848A51918E51A549E946DFF9470E09C53219C7B629C5D919271844A69C6453A671A554B9C6DD63E71A56129C6DD9D671A56D89C6DF99C695D7E71B78291B98692458A91DE8E9166485A45D9322918452EA46457C691A5653A4645A5E91A571AA4645DFE91A582B06686B1948AB1258EB13292B13D96B14C9AB15E4EAAC59ABAC5DACAC5996C2B176C6B184653AC5DB4AC611ADAB1766FDAC611F7EB19182D02B86D0588AD0668ED10B92D10C4A6B446A7B4495426D13254BB44F6CB45756BAD14CBED15E612B45333B457B4B4531AE2D15E73DB4599F7ED17682EFEE86EFF98AF01F8EF03592F04C96F0594C7BC19A8BC42E9BC236ABC466BBC23563AF10C5F0BC46B1BC4972BC4699D6F125DAF11A6F9BC495D6EF132F2F13DF6F15DFAF14CFEF15E830F84870F858B0FB38F0FEE9310009710019B102A9F101FA3102BA71035AB104BAF103DB31058B7103D5CFC41958471059CB1065CF1059695C419B6C41D1BE31066E71074EB1081EF110BF3108DF7110CFB1126FF1125832EF6872F3E8B2F608F2F61932F7C972F859B2F9C4E8CBF0E9CBF76ACBF46BCBFBD6373000BB30135F0CBFE58CF3001D3301ED7302ADB301EDF302A719CC07FACC0AFBCC0F7CCC163DCC197ECC19BFCC2060D3A7E1D3AF62D3B263D3C024D3C7E5D3CFA6D3D567D3D814274F70AB4F7B56DD3DC573F4F9BC34F7CC74F85CB4F8FCF4FB2D34F8F6B7D3E738D3ECF9D3F43AD3F77BD3F7BCD3FBFDD404FED40ABFD40D60DB8C61DB93E2DB9B63DB9EE4DBA9E5DBAA26DBB227DBB568DBB8E9DBB92ADBC02BDBBDACDBC06DDBC3573F6F1F611DBCCD94F6F20D36F3ED76F2A6D7DBD338DBCFF9DBD83ADBDC3BDBD87CDBE3BDDBE17EDBECFFDBFBA0E36961E37662E37EE3E383E4E38A25E393E6E39127E39B68E39894AB8E83AF8E7BB38E845AFE3A7D8478EA7CB8EA0675E3AA36E3AF77E3B238E3AFB9E3B57AE3B8FBE3B93CE3C7FDE3CABEE3D83FE3E120EB55E1EB5D62EB62A3EB6624EB6665EB7326EB7667EB7AE8EB7EE9EB76AAEB822BEB7B2CEB83EDEB825743AE28632EB8C73EB8A5A57AE43DBAE32DFAE4FE3AE44E7AE50EBAE62EFAE91F3AE9FF7AEA8FBAEC9FFAF0D83CDCE87CD358BCD3F8FCD4E93CD5797CD674C7F35D68F35FD4AFCD8AB3CD98B7CDA4BBCD8B5F0F36931F366594FCDB2695F3695B5FCDCCE3CDD9E7CDEBEBCDFBEFCE08F3CE28F7CE32FBCE62FFCF2183ECF887ED018BED13464FB48A5FB40A6FB4A93A3ED3552BFB4FD647ED4E653FB55F4FB59F5FB53DB5FED67E3ED75E7ED7F75BFB62BCFB693DFB733EFB7EFFFB8A00";
        }

        if (v == Background.STARRY_GREEN) {
            return hex"80039D84039044300E0921C037750A00DB6B02AA163C036D61700D85C68035AEC0AA7F00C2FF40AA77DF00D6A008F0E108EEE208ECD19023A84A708E754242390A82AD9AC2C50B02ABB5AF08E0984C237769908DB5D6C2361F02A9F7BF08D86010FE6112D1A210F8519043D39443D24C710F2D42443C3A843BBAC4AF958F10ECD84443A865310E7741293DAD84390DC438271C10DDDEFC436D806BAC846CD9886B888C641E9064134A61902A71900942463F954B18FB963463E4B863E15F018F4F118F4994C63CB69518F0DB5C63BBE063B373A18EA1DF0639D7BE18E43F18E0A02271A12302222221E3220C242120529884754E92117AA2114EB2112563484405CF210C1844841EC8840A6742100B520FE7620FBB720F93820F87920F4FA20F49DF083CBF483C3F883BBFC83B380AA6784AA5988AA238CAA2290AA0194A9D54C72A6FA82A6914A8A9ADACA901B0A909B4A8E1B8A8EDBCA8606112A0C194CA46AD0A45ED4A453D8A449DCA440E0A43973A2907BB29009E74A3F9F8A3E4FCA3E180CB2584CAFD88CAFC8CCADC48532ACE632A86732ACA832A829329E2A32A0AB3290EC329996B8CA34BCCA23C0CA0E632328073326FB4326935326B76324277323B783221F93223FA31207B311ABC3117BD31127E31103F310E603AE7E13ADB623ADC633ADB1214EB5E98EB4A9CEB495093ACB952CEB0EB0EB13B4EAE85CF3AB9D844EAB3C8EAA1CCEAA0D0EA78D4EA92D8EA66DCEA42E0EA23E4E9F8E8E9E8ECE9A4F0E9C6F4E91CF8E8E1FCEB6A810BFD850BFC44342FA2442F392990BB74E942EDAA42EB6B42E7EC42DC96B90B81BD0B7161142D7B242CBD9D10B2ED50B136D742BA3842B9F942B73A42ACFB42A83C4299FD4299BE42967F4288E04B0FE14B12D1112C304A64B0A274B09542D2C16B12C0CB52BDDB92BFCBD2BCEC12BDCC52BCD6534AEDB44AEB754AE7F64AE2B74AE0784ADC794AD2BA4AD27B4ACF3C4AC97D4AC4FE4AB77F4AB2E0531B61531922531663531924531652994C519D4C4B50A53146B5312EC530C2D5312EE530FD7C54C30C94C2867453095AD94BFDDD4C0CE14BE8E54BDCE94BB6ED4BA0F14B9FF54B8AF94B71FD4B4A4015B20225B23635B2012196C769D6D5C5095B1D95356C6DB96C64BD6C59C16C646335B16745B10355B12DB5D6C3FE16C3073A5B0A3B5B037C5B033D5AFF3E5AFA3F5AEDE06367D0918C984AB63236C632016BD8C8D613632034631D9AD98C6D6F863193963167A63131DF18C4BF58C3FF98C30FD8DAA4026B2BD1B1ACA75B16B26195DAC8D7196B203A6B1D9DF1AC6DF5AC64F9ADD3FDAEE9409732BD549CCA76747326357329DB5DCC9871C73235EF9CC80FDCDF181ECA74307B2BD8C9ECA7CDECAF6987B29DCE9EC98EDECA779D7B261F7DEC8D4028329D1DA0CAF6FE8329FF8326208B23618B2611162CA74DC8B2BFD8B649F7E2CA7824C76864C808A4C8D8E4C9849E9329FF932BE09B16619B78A29B1D91926C804A69B2353A66C9854B9B29D63E6C986129B29D9D66C986D89B29F99B261D7E6CA7828DAB868EDD8A8DD28E8C6D485A31D93228C8052EA32357C68C98653A3235A5E8C9871AA3235DFE8C9882ABFC86AD918AAC3F8EAC4B92AC5196AC599AAC644EAAB1B6BAB1DACAB1B56C2AC76C6AC80653AB1DB4AB201ADAAC766FDAB201F7EAC8D82CBAD86CBB78ACBFC8ECC0D92CC284A6B30C27B30FD426CC4B54BB3146CB31316BACC59BECC64612B31673B31934B3165AE2CC6473DB31B5F7ECC7682EB3D86EB718AEB9F8EEBB692EBDC96EBE84C7BAFF28BB0369BB096ABB076BBB09563AEC285F0BB0C31BB0FF2BB0C19D6EC3FDAEC306F9BB0FDD6EEC4BF2EC51F6EC4CFAEC59FEEC64830ACB870B0D8B0B2E8F0B3D930B5F970B819B0B829F0B9FA30BADA70BB6AB0BAEAF0BCDB30BB7B70BCD5CFC2F398470BE8CB0BCECF0BE8695C2FF36C3031BE30BFCE70C0CEB0C16EF0C0DF30C25F70C28FB0D1EFF0C3F832A42872A678B2AA18F2ADC932AFC972B0D9B2B254E8CACF29CACBEACAD26BCADB16372B5FBB2B6D5F0CADC58CF2B81D32B72D72B82DB2B72DF2B82719CAE7FACAEB7BCAF37CCAEDFDCAF3BECAFF3FCB05A0D24061D26FA2D283A3D288E4D290E5D299E6D2A4E7D2A854274AB3AB4AB856DD2B9D73F4AE8C34AFCC74B0DCB4B13CF4B0ED34B136B7D2C978D2CBB9D2C9BAD2CBFBD2D7BCD2DB3DD2DB7ED2E0BFD2EDA0D91AA1D92062DA1823DA4264DA4765DA7526DA7567DA7A28DA7E29DA8CEADA88EBDA90ACDA966DDA8D173F6A43611DA96994F6A82D36A67D76A926D7DA9E38DAACB9DAA87ADAACFBDAB73CDAB77DDAC37EDACBBFDACF60E104E1E10C22E11023E114E4E117A5E12066E21AA7E21828E23014AB88AEAF8909B3891C5AFE2405847891DCB89C6675E27536E26FB7E27578E28079E27A3AE27E3BE28CFCE290FDE2A4BEE2A87FE2B2E0E8F4E1E8F922E8FE63E900A4E902A5E907A6E90C27E90E5427A44054BE9125637A4535D0E91798CFA46A695E91D76EA0EB7E92078EA1AB9EA23FAEA303BEA387CEA407DEA753EEA83BFEA8D20F29D61F0F0E2F0F2E3F0F4A4F0F4E5F0F8531FC3E4A3C3EE52BF0FE6CF100ADF102AEF10097C7C40A655F104DB5FC41EE3C430E7C439EBC440EFC449F3C45EF7C83AFBC8C0FFCB9283E39087E39D8BE3A8465F8ECE6F8EED3A3E3C352BF8F2D647E3D2653F8F4F4F8F875F8F4DB5FE3E1E3E3E4E7E3EE75BF8FE7CF902BDF907BEF9103FF91780";
        }

        if (v == Background.NEBULA) {
            return hex"40A02412B02C61648090467A02A9BB0309BC0345BD03099F7C0A4C4020AA991A42904A82B18AC2C3BB02B185AE0A4117D42AA66DB0A933C0AF59EFC2A4C804B83844CD744312E0D2284AA6AC4C2658E12A997CC4A4CD04B686BD12931F7C4B1F806C26846D16886C264651AA9A61A9313A86B1FAC6A4C5991A195D7C6A4C808A4C848BD6888A4C46D22C7D73C8A4C61522195B7C8A4C4142AC7DAFCAA4C80CA4C42F32C7D860CBC973A32E0DDF0CAA67BF32E0D004E8654463A9313ACEB1F5913AF25978EC4DFCED12403424112150865990A4C4E842C7E942E0D5710C4D7BF42E0E04A4110A52AA654B4AE0D6612C4D73F4AE0D0354AA65D052E0D8D14C4D6BC52E0DEFD4AA64065AA9A75AEF14496AA66745A411AD96AA66F85AE0DCFD6AA6818C7342E62E0D7D18AA66BC62413D62A9BE62E0FF6335D02DAB835926AA999F5A904F9AB18FDAD1640672E0D3B9CAA65FE72413F72C6100DEB1F4887A9314FDE86541F8219501A28654FC882BBD88465F7E20AE40C929316CA486567E902BBF9219609A93219AF591566A4CDA68656FF9A9320A2F5A1A345A2A30991B68AA65DEA2933FA2C7E0AAA9A1AB09913AAAA65F6AA931BFEAB1F404B24112B2CAA65AFB2E0D87ECB1F401B810D122E90452EBAA997CAEB8367FBAC7D0470904656C2A99BE30A4C73DC2C7FEC309FFC2C7D05B2AA66FACAE0DDFF2B1F41DD2A99F7F4A4C41FDAA990178AA64CCE24116E78AA675FE241107FA90483CAB543EF2413FF2AD507FE904";
        }

        if (v == Background.STARRY_RED) {
            return hex"800CC8840CB0443032C521C0CAC50A03272B0383963C0C9C61703275C680C82EC0DEAF00EE2F40DEA7DF0320A00B3C610B37620B3791902CC74A70B3214242CB0A82E25AC2F1EB02E265AF0B2C584C2CAC6990B271D6C2C9DF02E0E7BF0B276013526113A7A2134351904D0E944CFF4C7133C14244CF1A84CDDAC4E6CB04CDD5AF133798444CC765313323413625AD84CB0DC4CB171C132B1EFC4C9C806F28846FC1886EE08C6D6E4851B58261B58671B5254246D3B54B1B4996346D275CF1B43701B43B11B3FD94C6CF06951B3C5B5C6CDDE06CDE73A1B31DDF06CC87BE1B2C3F1B2C6023932123DE222387232381242379D2988DD44E9236E6A236EAB236816348DA1B88D79BC8D7A611235BB2235819D08D49D48D3BD88D26DC8D27E08D0DE48D0EE88CFF77C233C3D233C7E23377F2337A02BB7A12BAE222BAE632BA6242B9FA52B9FD31CAE77A0AE6852B2B8F2C2B86ED2B8F6E2B86EF2B80D844AE046532B75342B6E752B6EB62B68372B68782B5E5CE8AD6E77C2B527D2B4EFE2B49FF2B436033D9E133D42233CE2333CB9214CF1498CF154E833BB2933BB6A33B315B0CEC55AE33AE2F33AE5848CE7ECCCE77D0CE68D4CE3C6D73386F83387393380FA3379FB33753C336E7D33683E33687F335E603BF5E13BEFA23BE89198EF949CEF7F5093BD9D52CEF68B0EF50B4EF445CF3BCB9844EF14C8EF15CCEEECD0EEEDD4EEDED8EEC5DCEEB8E0EEB9E4EE99E8EE7EECEE68F0EE4CF4EE3CF8EE3DFCEED18110398510304444408929910074E943FC952D0FD7B10FCB5AE43EF6F43E898450F94C90F7F67443D9F543D41B5D0F4471943CBBA43C53B43BB3C43B7BD43B17E43AE3F43AE604C1EE14C21D111306D4A64C14674C11142D3038B1302FB53031B93030BD3022C130166334BFC9A552FD7D92FCBDD2FBDE12FA2E52F9475B4BDFFC4BD9FD4BD43E4BCE3F4BCBA05447E15444E25441235444E45441129951059D508750A54416B5421EC541B6D5421EE541ED7C5506DC9505167454111AD95039DD502FE15022E55016E94FF2ED4FF3F14FD7F54FCBF94FA2FD4F944015C51A25C55235C519219712C9D71705095C4B1535711FB97113BD7104C171136335C41345C41B55C21DB5D707BE1706D73A5C147B5C117C5C0BFD5C0C3E5C08BF5C01E06463109191624AB64552C645196BD91546136451B4644B1AD9911F6F86444F964413A64415DF19087F5907BF9906DFD91B44026C5FD1B1B16F5B16C58995DB1547196C51BA6C4B1DF1B11FF5B113F9B1E5FDB267409745FD549D16F6747458B5745BDB5DD16271C74551EF9D146FDD22581F16F4307C5FD8C9F16FCDF17F6987C5BDCE9F162EDF16F79D7C589F7DF154402845BD1DA117F6FE845BFF8458A08C55218C589116316F4DC8C5FFD8C679F7E316F82512C8651468A51548E516249E945BFF945FE09C41219C85A29C4B119271464A69C5513A6716254B9C5BD63E71626129C5BD9D671626D89C5BF99C589D7E716F8291CD8692688A91D88E911F485A44B1322914652EA45517C69162653A4551A5E916271AA4551DFE916282B03086B19F8AB07B8EB08792B10596B1049AB1134EAAC47EBAC4B2CAC47D6C2B12CC6B146653AC4B34AC519ADAB12C6FDAC519F7EB15482CFD786D0078AD0308ED04592D0514A6B41B67B41ED426D08754CB44156BAD104BED113612B44133B444F4B4411AE2D11373DB447DF7ED12C82EF9586EFA28AEFD78EEFF292F01696F0224C7BC0C28BC1169BC112ABC14ABBC11163AF0515F0BC1B71BC1EF2BC1B59D6F07BDAF06D6F9BC1EDD6EF08779DBC417EBC413FBC44E0C3CBA1C3D0E2C3D9E3C3E564C3E8A5C3EF66C3F613A30FD752BC3FCACC401EDC3FC974F1022695C40C36C40BDBE31030E7102FEB1038EF1045F31044F71051FB1121FF107B832EB8872EDE8B2F158F2F2E932F38972F439B2F674EACBDFEBCBE516372FA2BB2FBE5F0CBE898CF2FBDD32FCBD72FD8DB2FCBDF2FD871ACBF5FBCBFCBCCC01FDCC08BECC0C3FCC0E20D38F21D39DE2D39FA3D3AE64D3B165D3B7A6D3BB27D3C554274F14AB4F2F56DD3CB973F4F44C34F38C74F43CB4F50CF4F68D34F506B8D3D9F9D3E03AD3DFDDF34F94F74FBEFB4FD8FF4FF2836DD5876DE78B6E038F6E1B936E4C976E679B6E7F9F6E7EA36E99A76E98AB6EB956DDBAE173F6EC5611DBB3594F6ECC695DBB79B5F6EEDE36EECE76F15EB6F14EF6F2EF36F38F76F43FB6F67FF6F95838D60878D7A8B8DA18F8DBA938DB94A6E379D3A38E0352BE386D63F8E3C612E39319D78E67DB8E77DF8E7F719E39FBAE3A67BE3A63CE3B17DE3B7BEE3C57FE3CBA0EB43A1EB49E2EB4EE3EB5264EB5825EB5BA6EB5EA7EB5E68EB6854AFADA0B3ADBA5B0EB6E58CBADD5676EB751BE3ADE773AEB80FBEB8F7CEB8F3DEB99FEEB9FBFEBAE20F371E1F33C62F33C23F33FE4F343A5F343531FCD27A3CD2652BF34EECF3526DF3586EF35257C3CD61635F3581B5FCD6EE3CD7AE7CD79EBCDA1EFCDA0F3CDB9F7CDD4FBCE03FFCEEF83ECB087ECC88BECC7464FB37929BECDD4E8FB3C54AFECF0591FB3FD94FED0E697FB4378FB49F9FB499D6FED3BF3ED61F7ED6EFBEDA1FFEDB90";
        }

        if (v == Background.STARRY_BLUE) {
            return hex"8002688402604430096921C024F50A00916B0282D63C0245617008F9C680235EC0A18F00BC1F40A187DF008D6008A42108A222089F519022734A7089A14242260A82A4EAC2BDAB02A305AF0896984C224F69908915D6C223EF02A1F7BF088FA010B6A112B2A210AD119042AA94429F4C710A654244290A84288AC4A65B042875AF109F58444273653109A34126F1AD84260DC425AE0425973C1093DEFC4245806B35846C6B886B048C62FE9062F39462F29862E89C62DB50918B4952C62C958D18AF6E18AD2F18ACF018AAB118A7F218A7B318A65A5462906D718A238189F79189F3A189CDDF062687BE18983F1896A020E8A122DBE220DAE320D56420D3929883439C833A50920CCEA20CB2B20C85634831BB88311BC830661120BFB220BC99D082DBD482D2D882C9DC82BDE082B4E482AAE8829F77C20A67D20A43E20A23F209F602A68A12A2FE22A34232A102428EFA52A0A531CA3B0A0A3A352A28E5EB28E2AC28DF6D28DFAE28DCEF28D79844A35565328D0B428CCF528CB3628C87728C6F828C49CE8A2FEECA2DBF0A2DAF4A2D2F8A2BDFCA2B480CA4184CA4088CA0D8CC9EE485327B663277A7326D683268E9326F6A32402B32422C323816B8C8ECBCC8D0C0C82263230EFB330EC3430E8F530E5F630DF7730DCF830DAF930D77A30D3BB30D0BC30CCFD30C87E30C6FF30C4A03AB4613AAF223AAAA33AA61214EA9198EAA99CEA775093A94152CEA58B0EA32B4EA315CF3A801844E9EDC8E9DECCE9A3D0E9BDD4E914D8E8E0DCE88EE0E8D0E4E876E8E855ECE3A3F0E3A2F4E389F8E37EFCEAF8810B47850B2444342C4A442C692990B114E942BC2A42B6EB42B46C42B416B90AB0BD0AAA61142A47242A419D10A50D50A326D7428C78428039427BBA427B7B4268FC4268BD42383E422FFF4234204ADC214ADE51112B6B4A64AD5274AD2142D2B36B12B2DB52B2CB92B24BD2B1AC12B0CC52AFB6534ABC344AB6F54AB4764AAF774AAC384AAAB94AAA7A4A9DFB4A983C4A907D4A8CBE4A883F4A832052ED6152E7A252E52352E7A452E512994B899D4B7950A52E26B52DE6C52DAED52DE6E52DC17C54B6BC94B5467452D21AD94B47DD4B2DE14B12E54B0CE94AF0ED4AFAF14AD1F54ABDF94AAAFD4AA94015AF2E25AF9E35AF2D2196BC29D6CC45095AF095356BB5B96B9EBD6B94C16B9E6335AE5345AE4F55ADE5B5D6B70E16B6B73A5AD53B5AD4FC5ACB7D5AC93E5AC4BF5AC460633690918BEE4AB62F9EC62F2D6BD8BE761362F2F462F09AD98BB56F862E7B962E53A62E75DF18B79F58B70F98B6BFD8CE84026B0251B1ABFB5B16AFB995DABE77196AF2FA6AF09DF1ABB5F5AB9EF9AD24FDAE5740973025549CBFB67472FBB572FEDB5DCBEE71C72F9DEF9CBCBFDCD3981EBFB4307B0258C9EBFBCDEC096987AFEDCE9EBEEEDEBFB79D7AFB9F7DEBE740282FED1DA0C096FE82FEFF82FBA08AF9E18AFB91162BFB4DC8B027D8B3A1F7E2BFB824BC2864BCB8A4BE78E4BEE49E92FEFF9302609AE5219B4BA29AF091926BCB4A69AF9D3A66BEE54B9AFED63E6BEE6129AFED9D66BEE6D89AFEF99AFB9D7E6BFB828CFD868E4B8A8D1D8E8BB5485A2F093228BCB52EA2F9D7C68BEE653A2F9DA5E8BEE71AA2F9DDFE8BEE82AB2486ACD08AAB708EAB7992AB8996AB949AAB9E4EAAAED6BAAF0ACAAED56C2ABC2C6ABCB653AAF0B4AAF2DADAABC26FDAAF2DF7EABE782CADB86CB118ACB248ECB5392CB544A6B2DAE7B2DC1426CB7954BB2E26CB2E756BACB94BECB9E612B2E533B2E7B4B2E51AE2CB9E73DB2ED5F7ECBC282EA9786EAAA8AEAD18EEAF092EB0C96EB124C7BAC928BAD4E9BAD22ABAD76BBAD2163AEB545F0BADAF1BADC32BADAD9D6EB70DAEB6B6F9BADC1D6EEB79F2EB89F6EB9DFAEB94FEEB9E830A0C870A218B0A508F0A97930AAF970AB09B0ADA9F0AD1A30ADBA70AF0AB0B0BAF0AFBB30B11B70AFB5CFC2C698470B12CB0B1ACF0B12695C2C936C2CB5BE30B24E70B2DEB0B36EF0B53F30B48F70B54FB0C86FF0B7083288E8729A28B29DE8F29EE932A0D972A219B2A414E8CA9829CAA42ACA9DEBCAA616372AAFBB2ABC5F0CAAA98CF2AB0D32AD0D72ADADB2AD0DF2ADA719CAB47ACAB6FBCABEFCCAC47DCAC6BECAC93FCACDA0D0E2A1D0EC22D208A3D23424D24225D268A6D27367D277942749EDAB49FF56DD280173F4A31C34A0DC74A21CB4A32CF4A58D34A326B7D29078D29439D29DBAD2A43BD2A47CD2A63DD2AF3ED2B6BFD2BC20D8CEE1D8D3A2D8D7A3D8DF64D8E625D8EBE6DA0A67DA1568DA1DA9DA1BEADA342BDA23ACDA2FEDDA3B173F6908611DA46D94F6900D369A2D769146D7DA6F78DA6D79DA77BADA7B7BDA7BBCDA883DDA887EDA943FDAA5E0E0BF61E0C1A2E0C6E3E0CB24E0CCE5E0D3A6E0D527E0D7A8E0DA94AB8374AF837DB383895AFE0E298478398CB83A2675E0EBF6E0EC37E20A78E0EFB9E2157AE21DBBE21BFCE2423DE2453EE277BFE28320E8AAA1E8AF62E8B4A3E8B6E4E8BCA5E8BFA6E8C1A7E8C4A8E8C6E9E8C82AE8C86BE8CAECE8CB2DE8CC9743A333632E8CEF3E8D09A57A343DBA34DDFA34EE3A354E7A35DEBA36AEFA37EF3A38AF7A3AFFBA822FFA8EC83C9B487C2908BC2998FC29F93C2AA97C2B44C7F0AF68F0B254AFC2D2B3C2DBB7C2E8BBC2E75F0F0BA31F0BC994FC2F3695F0BF5B5FC2FEE3C306E7C312EBC31BEFC321F3C333F7C34DFBC36AFFCB0A83E26087E2688BE273464F89F65F8A1E6F8A213A3E29052BF8A65647E29F653F8AAB4F8AD35F8ACDB5FE2B4E3E2BDE7E2C975BF8B4BCF8BA3DF8BFBEF8C6FFF8CCC0";
        }

        if (v == Background.SUNSET) {
            return hex"800DC9840DB0880D968C0D88900D7D940D74980D739C0D665090355552C0D4BB00D4AB40D3D5CF034F18540D346D7034CDC640D2175C03441EFC0D0F802E24842DF9882DE98C2DC8902DBD942DA3982DAF9C2D95A02D7CA42D7BA82D70AC2D6FB02D71B42D655CF0B5918442D4B6530B529A542D3C6D70B06380B4CDCE82C18EC2D3379F0B4CA013A3E1139AE21393A31390A4138C251388A6137DE71381E8137A2913762A136F2B136EEC136B56B84DAEBC4DA26111361994C4D87D04D636B61358B713553813061CE84D4AEC4D3CF04D4AF44D337DF134F201BC750886C188C6EB34861B06271B9A94246E5FA86E4156C1B8BED1B88573C6E06C06DF6C46DD76531B711A546DC56D71B6B781B689CE86D85EC6D87F06D6FF46D62F86D63FC6D54808FA7848F8D888F6F8C8C18908F32948F29988F1B9C8EF4A08EF5A48EF3A88ED3AC8EBBB08EB2B48EB0B88E8DBC8E8EC08E81C48E80C88E69674238FF523901B5C8E20E08DF5E48DF6E88DD777C23713D2371BE236B7F236BA02C12A12C07222C03632BFA242BF3E52BF0262BE9A72BE6A82BE3292BDB6A2BDB2B2BD72C2BCF2D2BD76E2BCEEF2BC65844AF1AC8AEF0CCAEF1D0AED2D4AEBAD8AEAFDCAEA4E0AE8CE4AE8075B2B063C2B935EF8AC18FCAE0C80D15C84D13C88D1248CD08B90D07294D06498D0579CD03AA0D034A4D028A8D00CACCFFEB0CFF55AE33F9EF33F73033E618C8CF8BCCCF82D0CF77D4CF5BD8CF49DCCF3BE0CF31E4CF18E8CF0BECCEF2F0CC18F4CEBBF8CEB1FCCE9C80F21B84F1E988F1B68CF1A290F19094F18F98F1839CF15AA0F13BA4F13AA8F130ACF123B0F116B4F08A5CF3C1C703C15B13C12323C0CF33C06743C06B53C02F63BFD773BF9F83BF7393BEC7A3BE67B3BE0FC3BDE7D3BD7BE3BD4BF3BD2A044AA6144A0D10D126B9112599512589912369D121AA11219A511FFA911DAAD11CEB111C0B511A1B911A0BD118E611445CF2445299D11122D51116D91109DD108AE11071E51070E91049ED1027F1101BF50FFFF90FF6FD0FF78132F18532EE8932C18D32C09132BF9532B49932A79D3292A13282A5327554B4C99AC4C952D4C95EE4C956F4C8D304C89B14C7FB24C7A334C79DA5531CED931C0DD31B5E13183E53174E9315AED3159F1313AF53131F9310AFD308B81536185531D89531C8D531B9153089552F09952DC9D52DBA152D1A552DBA952D9AD52CFB152B1B552BDB952B0BD52A661154A4F254A519D15276D5526AD95269DD5256E15257E55235E9521AED5200F151DBF551CFF951B6FD51A381739F4225CE4635CE0E45CD8655CD8265CD2675CD7A85CD1E95CD22A5CC6AB5CC1D6357319B972ED5F15CBB194D72DAD172D2D572D0D972BFDD72BEE172B373A5CACBB5CAA3C5CA57D5CA5BE5C9DFF5C9B2064F4E164F1E264ED6364EC6464EBE564E7E664E4A764E46864E154A99384AD9372B193715AE64E0AF64DC3064D7D8C9935DCD935CD193466B664C69BE19309E592EFE9930A77C64BC1EF992DDFD92D381B3F285B3F189B3E38DB3D791B3D64A66CF513A1B3C852C6CECED6CEBEE6CE797C5B39DC9B392CDB390D1B3856B66CE1376CE1786CDD396CE0FA6CDCFB6CD87C6CDC5EF9B362FDB36481D40C85D42289D4098DD40891D3F64A674FD2774FC9425D3F1A9D3D756C74F5AD74F2573DD3D5C1D3D4C5D3D5C9D3D267474F1F574F23674F1F774F1B874ECB974ED3A74ECBB74ED3C74EDFD74E83E74ED3F74E8A07D121089F4268DF43391F42595F4234C77D031425F422A9F420ADF409B1F4075AF7CFDB07D01B17CFDF27CFD737CFD9A61F3F373A7CF87B7CF97C7CF87D7CF8BE7CF93F7CF9A08516E18517628512D19214594A68512A78512688511D4AA143456E850997CE1432D21424D61423DA140C6FB8502FC85037D8502BE85037F8508608D1DE18D22228D22519234769634609A345F9E3474A23471A63473AA345C56E8D1697C2344CC63458CA3459CE34586958D165B5E3458E2344A73A8D125DF234477BF8D12209529A1951F229523519654A49A548B9E548AA2547BA65489AA547AAE5489B2547AB65489BA54795F1951E32951E59D65476DA5460DE545EE2547673C9517BD951CBE951D7F951D209D2BD08A74AC8E74BF9274A99674C09A74BE9E74A7A274AAA674A8AA74ABAE7490B274A7B674A8BA74A5BE74A46129D23F39D29349D23B59D22F69D23DBE2748CE6748BEA74A4EE748A79D9D233E9D293F9D2320A60221A532A2A5FFE3A531E4A60025A60266A60067A53228A5FF54AA980256EA5316FA531B0A53131A530B2A52B73A530F4A53075A53136A52BB7A530B8A52F9CEA94C0EE94AEF294C27BEA5307FA52BA0AE05E1AE0622AE0663AE0464AE06A5AE06E6AE0327AE071426B813AAB80DAEB814B2B80D5AEAD32EFAE08B0AD32F1AE0572AE0533AD3274AE03DADAB4C9DEB7FDE2B80EE6B7FDEAB80AEEB80179DAE015F7EB80682D49186D82D8AD82B8ED83492D82C96D83E9AD8379ED830A2D831A6D82454BB609ECB60E56BAD828BED829C2D825C6D81FCAD825CED826D2D825D6D826DAD812DED826E2D82073DB6085F7ED82A82F42786F4618AF4B08EF4CC92F83B96F8434C7BE0CE8BE1429BE0F2ABE0F6BBE0D5636F836BAF82EBEF847C2F82FC6F838CAF837CEF838695BE0FF6BE0DDBE6F838EAF848EEF840F2F839F6F841FAF832FEF83A8313A58713D88B14108F14369314629714929B14B29F14B1A314CE52AC6126BC613ECC6156DC60EEEC615AFC616F0C612B1C615F2C61873C612B4C61135C61176C611B7C61178C61139C612FAC611BBC6147CC6133DC6137EC6177FC61620CCB7E1CCD2E2CCE523CCEEE4CCF665CCF9E6CCFE27CD0A68CD0A29CD0DEACD0D6BCD18ECCD252DCD1FAECD2CD7C3347DC73493CB3492CF3493D334D1D734D0DB34B3DF34B2E334CFE734CDEB3849EF3855F3385AF73863FB385CFF38628352868752AB8B52C58F53119353219753679B53789F5395A353A6A75395AB53BDAF53DAB353CCB753DABB53E8BF53E9C353DAC753E7CB53F9CF53FDD353FAD75412DB53FBDF5411E35429E75438EB544DEF5464F35465F75495FB54D2FF586083720787722C8B72498F726E93729B9772AA4C7DCB228DCB869DCBF2ADCC46BDCC42CDCC82DDCC4973F7350C3734EC77368CB734CCF734FD37369D77366DB7387DF7388E37395E773A7EB73BEEF73CEF373DBF773E8FB742AFF74668391878791AA8B91D08F91F19392094A6E48EA7E497E8E49794AB927DAF926EB39286B7929A5CFE4A1F0E4AB31E4AB72E4AB33E4AD74E4AAF5E4AD76E4AD9BE392D4E792E2EB92FDEF9310F39350F79378FB93A8FF93DB83B13587B14F8BB16A8FB17A93B19597B1BB9BB1C59FB1D1A3B1E0A7B1DFABB1E0AFB1DFB3B1F1B7B1F25CFEC7D30EC8258CBB21FCFB22AD3B22FD7B22BDBB22CDFB22EE3B23AE7B247EBB260EFB29CF3B2ADF7B2C7FBB2FDFFB32283D08E87D11D8BD1288FD13493D13397D14E9BD15F9FD151A3D169A7D179ABD16AAFD179B3D188B7D195BBD186BFD195C3D196C7D195653F46AF4F46A75F46A1B5FD1BBE3D1C6E7D1D1EBD1D2EFD1E1F3D20AF7D22CFBD26FFFD29D83F05E87F06C8BF0778FF08493F08F97F0909BF1104E8FC4754AFF128B3F12A5AEFC4D2FFC4AB0FC4D18CFF140D3F15FD7F13FDBF14EDFF15F719FC5A7AFC5B3BFC5E7CFC65BDFC6EFEFC74BFFC87C0";
        }

        if (v == Background.MORNING) {
            return hex"8001F98401E88801D48C01CD9001C59401BE9801BD9C01B6509006B952C01A8B001A7B401A05CF0067D854018F6D700639C64018375C00601EFC017F80222484220C8822008C21F29021E79421DE9821DD9C21D3A021C4A421C354B086F2C086F6D086D573C21B4613086A1A54219F6D708457808639CE82115EC218E79F0863601097A1109122108D23108BE41088E51086A61082E71082A8107FE9107E2A1079AB10796C1076D6B841DCBC41D26111070594C41C2D041B36B6106CB7106B7810455CE841A8EC419FF041A8F4418E7DF1067E018AE908861158C62724861845671890D424623CA8622E56C1888AD1886573C6209C061FEC461F7653187BDA5461F06D71876F818749CE861C1EC61C2F061BCF461B2F861B3FC61AD8083298483198882FC8C81159082C89482B99882B19C829750920A62A20A3EB209ED6348271B88257BC8258C0824EC4824DC8823B674208B35208B5B5C8218E081FDE481FEE881F777C207BFD207C7E2076FF20772028E7E128DC2228DA2328D26428CE2528CC6628C7A728C62828C3E928BBEA28BC2B28B8AC28B42D28B92E28B1AF28ABD844A2B0C8A295CCA296D0A286D4A27AD8A26FDCA265E0A256E4A24D75B28457C288CDEF8A115FCA21480C3FB84C3E688C3D88CC3C690C3B494C3AC98C39E9CC386A0C379A4C36FA8C35CACC352B0C3485AE30D06F30CDF030C5D8C8C30ECCC305D0C2FAD4C2E2D8C2CFDCC2C6E0C2C7E4C2AFE8C2A7ECC297F0C115F4C27BF8C270FCC25D80E46D84E45688E4328CE4214853905A639036738FC9424E3E2A8E3D6ACE3D5B0E3CDB4E3BD5CF38EAF038E4F138E13238DEB338D97438D9B538D6F638D23738D07838CDF938CA3A38C5FB38C17C38BEFD38B8FE38B97F38B660413C614134910D04B991049695048D9904829D0461A10460A50455A90441AD043AB104315AE41056F4103184503FAC903E567440F53540F37640F17740EF7840EAF940EABA40E53B40DBBC40D9FD40D4BE40D23F40D4E0495021494F910D250B9124FD9524F09924DB9D24CEA124BEA524B854B49252C4922AD49236E49232F491DF0491B314915324913334912DA55243AD92431DD2420E1240DE52405E923F2ED23F1F123E2F523D7F923CEFD23C681460C85457989456B8D456C91455595453F99452F9D451CA1451D52A51472B51426C513BED513EEE513BAF5136984544CDC944CF674512DDAD94495DD448BE1448DE54476E94461ED4462F1444DF54442F94432FD442281664D422598E235988D215660C9965F59D65F4A16577A56578A9656A56D59552E594F57C5652E6535946F45947B55942B6593F77593F1C6964EFED64DCF164D0F564D1F964BFFD64BA81867185867089865B4646196A56193531D8638A1862552A61892B61862C618656B98618BD860BC185F3632617CB3617C74615D9AD9856A6F86155B9614F7A6155DDF1853F7BE614C3F6147E069A22169A56269A1E3699724699C9299A6854E8699C14B1A66EB5A65AB9A64C5F16992F2698E33698DF469895AD9A624DDA625E1A619E5A623E9A61AEDA60CF1A6197BE69837F6983A0719DE171A2E2719DA371A2A471A25299C6749DC68850971A56A719715B1C672B5C6715CF71A1B071A17171A1B271A159D9C670DDC684E1C66FE5C65BE9C66F77C7196FD7193BE7196FF718E6079981089E65F8DE67991E67895E68C4C7799DD425E68BA9E697ADE676B1E6965B079A258C9E675CDE689698799D1CF5E673F9E65DFDE64F82065186063A8A0650464819ED29A06609E067AA2068F52A81A395BA065F5F081A63181A37281A63381A374819E3581A31B6E067779E8197BF819DE0898A108A26544648994E5898EE68998E7899928899F698998EA899895BA267C5F089987189A432899EF389A41A56267B6D789A43889981CEA267A77C89A3DEFE266082461086460F8A4629465918FE6918FA7919568918F6991952A918F6B91952C918F6D9195174A463C6759194F6918EF79194B89194DCF24652F64663FA4653FE4664826558422997DE3998724998425998726998AD3A2662AA66640AA662AAE6629B2662A5AE999017CE663FD26629D6663EDA663F6F9998FBA998FFB99955E76663EFA663FFE663E8285328685438A856E8E857B9286119685F84C7A184542A861E56EA18757C2862CC68641CA861CCE861DD2862BD6862CDA861CDE8641E2862B73BA1873CA1905EFA862BFE861C82A4E086A5008AA5338EA544485A95666A95BE7A95F5426A5F9AAA57CAEA5F958EA95F2FA95F70A95F31A984F2A97E73A95EF4A97E1ADAA57BDEA61EE2A5F8E6A61EEAA612EEA61179DA9849F7EA61F82C48486C49A8AC4E18EC4F492C50E96C5249AC50E9EC523A2C53452BB1516CB15196BAC55ABEC570C2C55AC6C559CAC55ACEC570D2C55AD6C570DAC57DDEC570E2C559E6C5FAEAC57D77DB17E9F7EC83B82E43486E4588AE47A8EE49992E49B96E4BB4C7B938A8B934E9B9406AB93D2BB943D636E524BAE50EBEE50FC2E50EC6E535653B9439A56E5246D7B9439C6EE535F2E55CF6E861FAE55BFEE83C8303E88704088B042A8F043593044F9704649B04659F0473A3048552AC121ABC1242CC1272DC126D73F049CC304C4C704C5CB049DCF04C4D304C3D704E3DB04F5DF04E3E304C3E704E3EB04E2EF04F5F30502F70510FB0511FF053683238D8723B88B23DB8F23E99323F59723FE9B24184E8C90AE9C90B2AC90F6BC9116CC9146DC911AEC91697C32450C72459CB2464CF2459D32466D72474DB245ADF2465E3247CE7247BEB2486EF2487F32491F7249EFB24F6FF24E48343448743568B43758F438F93439A9743BA9B43C99F43DCA343DDA743DCAB43DEAF43F5B343EAB743F5BB43FFBF43F6C343F5C743FECB440F674D10275D1065B5F4410E3442BE7441BEB442DEF443EF34446F74452FB4467FF447D8362F48763008B63148F632E9363459763564C7D8D7E8D8DFE9D8E3AAD8E3EBD8E66CD8E9ADD8E3D73F63A7C363B1C763B2CB63B9CF63B1D363B2D763C1DB63CADF63C2E363DCE763D0EB63DEEF63EBF363ECF763FFFB641AFF64368382A28782AB8B82D48F82DD9382E94A6E0C4E7E0C928E0CB54AB8334AF832EB38344B783455CFE0CF30E0D3F1E0D1B2E0D3F3E0D5F4E0D59ADB83576F8E0DB39E0DDBAE0E03BE0E67CE0E9FDE0F27EE0F47FE0FB20E89861E89D62E8A2A3E8A464E8A8E5E8ADE6E8AFA7E8B328E8B569E8B72AE8B56BE8B71637A2DD5D0E8BA58CBA2F5CFA308D3A2F66B6E8C037E8C278E8C4F9E8C8FAE8C77BE8CF7CE8D1BDE8D7FEE8E03FE8E6E0F08FE1F091E2F09423F096E4F09865F09AE6F09DA7F09B28F0A2A9F0A2EAF0A2ABF0A2ECF0A4ADF0A8EEF0A8AFF0A8F0F0A6B1F0A8D94FC2A4D3C2ABD7C2B66D7F0ADF8F0AFF9F0B33AF0B37BF0B5BCF0BABDF0C03EF0C97FF0CFA0F88561F88722F889E3F88C24F88DE5F88FE6F89013A3E24752BF8942CF89456BBE25BBFE251C3E25B633F898B4F89DB5F89AB6F89AF7F89D9C67E27FEBE280EFE28BF3E29AF7E2B7FBE2CDFFE2F5";
        }

        if (v == Background.INDIGO) {
            return hex"41F0237907C28DE41F1237907C68DE41F226E907CA9BA41F326E907CE9BA41F426E907D2A1441F5285107D6A1441F6285107DAA1441F7285107DEA7041F829C107E2A7041F929C107E6A7041FA2B2107EAAC841FB2B2107EEAC841FC2B2107F2AC841FD2C2507F6B0941FE2C2507FAB0941FF2C2507FEB09";
        }

        if (v == Background.CITY__PURPLE) {
            return hex"8000068400078800088C000990000A4A60003270003942C000FB000105B10004594C0010D000116B70003DC64000E75B00031E74000BF80009FC000880200884200988200B8C200C90200D4A60803E7080428080454A82012AC201358D08052E080557C02014C4201565308051A542013D831B1DC2012E031B173A08041DF0200FF4200EF8200BFC200A804025844810884B61464146C651204261004A7100528100569110F2A12D86B110F2C12D86D110F17404019C4401AC840196741006351005F61005B7146C7810057910053A1004DDF04011F44010F8400FFC400D8060258462C38868104641C6C651A04131C6018A0601AA461D6A86810AC61D6B06810B461D65D21807B3180774180735180EB61AD8771C6C781AD87918097A18063B1805FC18055EF86B61FC60258080258482C38891B18C88109091B19482C398801B4E82007A920096A2204AB2204EC22062D20096E220617C48823C88819674220635200E9B608B61E48025E8801BEC801AF080187BE246C7F20096028096128B0D10CB1B190A81094A2C398A8124E928095538A05C5F02A13312A15B22A13332A12DA54A1D6D8A43CDCA810E0A43C73A2875BB2A047C2807BD2C6C7E2AD87F28096030096132D85110D1B194CB6198C8339CC025A0C810A4C025A8C05CACC228B0C05CB4C810B8C05CBCC8E2C0C8B2C4C8DAC8C8B1CCC89AD0C1D6D4C43C6D8320439310F3A3075BB3208FC32063D346C7E32D87F30096038095094E81098E8789CE025A0E810A4E025A8E05CACE22858E381717C8E005CCE9986953875B6390F373A0438390F1CE8E1D6ECE84CF0E8337BE3C6C7F38096040096140B0D11111B1950B619909024E940096A401715B500255D440017540095B5D003A71940097A4238BB4226BC421E1EF90B61FD002581202542248B0D19128109522C39929F09D2025A12181A52025A9205C57548015B6D205CF120257BE4C6C7F48096050096150B0D11151B1954B61994A849D4025A14181A54025A9405C57550017650097752B078501739504AFA50173B52043C50097D546C7E52D87F5009605809615AD8511171B1956B61996B064E8580954D960056F8581739584AFA58173B5A043C58097D5AD87E5C6C7F580960600950958810998B964E8600954D580056DB60173C60095EF991B1FD802581A02585AB6189B1B18DA81091B1B195AB6199AC384E8680954DDA005E1A05CE5A228E9A05CEDA228F1A0257BE6AD87F68096070096172D862746C63720424746C6572D866732E13A1C025537700178701739708A3A70173B708A3C70095EF9C810FDC02581E02585EB6189F1B18DE2C391F1B195E05C99E0054E8780954D9E0056FB78173C78095EF9E810FDE025820025425801726800153A2002553680015BEE005CF20025F60F8AFA0DE6FE00258220258621D68A28108E21D64858817131E2005A2202553688015BEE205CF220257BE88173F88096090095096405C4C7900168900954DA40056FB90173C90097D93E2BE9379BF9009609809619875A29A04119261D696605C4C7980168980954DA60056FB98173C98095EFA605CFE6025828025425A017131E8005A28025537A0015C6E805CF28025F68F8AFA8DE6FE802582A02586A1D68AA8108EA1D692A42996A05C4C7A80168A80954DEA00571BA8173CA8095EFAA05CFEA02582C025425B01726B3EB27B00168B00954DEC005E2C05CE6CDF4EAC05CEEC228F2C025F6CF8AFACDE6FEC02582E02586E1D68AE8108EE1D692E42996E1D69AEF899EE005A2E025537B80178B81739BB6E3AB8171DF2E0257BEB8173FB809501700259B0F744E8C00954DF0005719C0173AC0095DF7005C7DFC00960C80961CA0422C90F23CA0424C90F25CA0426CBC9D3A32025537C80178C81739C88A3AC8097BC8173CCC6C7DC8173EC8097FCAD860D009508F481093443C9748104D7D0015C67405CEB4025EF405CF351B1F7405CFB4025FF4B618360258768108B643C8F681093643C4B8D80179D8173AD8095DF7605C7DFD809501380254B8E0015CEF805CF38F8AF7805CFB8025FF8B6183A02587A1D68BA810464E87592E7A00575BE8173CEBE2BDE8173EE8097FEAD860F0095093C05C4B9F0015D77C05C7DFF00960F80961F875A2FA0423F80164F81712E7E00575BF8173CF8097DF8173EF8097FFAD84";
        }

        if (v == Background.CONTROL_ROOM) {
            return hex"8009078408AC8800A88C00579008D59409BB9809DB9C0BAAA00BF752A03052B03086C03012D02C0AE02746F0278F0027D3102723202DDF302EAB402E6B502DE3602D9F702CCF8028BF902297A0243BB02277C02057D02687E0243FF0271600A20E1088E220853630824A4084B25084CA60AB6270B6DA80B85A90B922A0B956B0B922C0B85AD0B252E0AB5EF0A3AB00A36310AB1720B6A330B77F40B74350B67760B5AF70B4B380AE6790A6E7A083E7B0841FC081F3D0A267E08847F0A65A010A4E110BAE21076231038E4103125129CE612E3A7139CA813B6A913C8EA13CB2B13C4AC13AB2D13506E12E62F12D3F012CE7112F53213A23313B6B413B0F513A8B6139F771385B8131879128FBA126CFB1029BC102EFD10A4FE10B03F1098E018B7A1195D22188DE3184424185DA51A3FE61AFE671BA8A81C75291BD66A1BDFAB1BD06C1C752D1B5DEE1AFDAF1AADF01AB2711B11B21BB9731C75341BCDB51BCB361BC1371C75381B39B91AAEBA184D3B18533C183A3D18B7BE195A7F18AE2020A0A120B7E22076632039E420352522ABA622FE2723A26823BEE923D06A23D62B23C8EC23AD6D23506E22EA6F22D03022D9B122FDB223AAF323C4B423C93523C4B623C13723AAF82339F922B1BA22773B202AFC20323D20A9BE20B7BF20A0602A17E12854A22851E32A0CA42A1CE52A85A62AF2A72B3EE82B56A92B69EA2B63EB2B54AC2B416D2B2BAE2ADDAF2A8BB02A98B12B0BB22B30F32B48F42B50B52B4AF62B46F72B2FB82B11F92AD6FA2AADBB2A74FC2842FD2851BE2856FF284E20336C6133536233286332936432252532676632E6E73441E8323AE9344BAA3228AB34456C30596D34186E32CEAF32647032673132D43233B1F333B87433B535337BB63363B73346B8335A3933457A3340FB333CFC3308BD32FAFE32F5FF3308A03C22613CDFE23B7EA33AC2243A2D653A31663ABB673844E83A3F293A39AA3A326B3A29AC3A1C6D383DAE3AB1EF3A46303A64F13AB1F2387D333881343909353910F6391BB738C1F838C8B938BFFA38B07B3913BC390EFD390A3E3901FF38FD20451461450FA243CEA342E1244236E5421F2642A76743F2684207A943F5AA43F215B100D8B5002DB90A71BD08F2C108F1C50A80C901C8CD03FCD10427D50470D9033CDD038CE103A4E503A5E904FEED04C2F1048FF50457F90428FD01E281349D8531CC892F758D2BDF9128F9952870992A729D20D0A12023A52FADA9202456C4809ED480A2E4A98D7C128E5C52A64C92A55CD2A05D1243BD52335D923A5DD23B9E123C0E5252175B49437C49433D4937FE48B5FF4892A0547F215475E253D223530424524465521C265298E753EB68500914B54028B94A635F05239715299325292B3527974504BB550787650ECB750F07851489CF14521F543B2F94381FD42EC81721585749E896F6B8D6C20916911956870996A634E85832D4B560285D05A98F15A99325A92B35A79B45848B5587AF658EE9BED652279D58F07E58ECBF58D820652E6165272263DAE36306646245A5621C266298E763EB68605D14B580285D06298D8C98A64CD8A08D180FED58188D98248DD8521E1852273A614CBB60F6BC60F21EF983C1FD84FF81B4BA85B49C89AFCC8DAC2C91A91695A86799AA634E8685D14B5A0285D16A98F26A99336A8E346A6AB5684D766871F7694338694879694C9D71A3DAF5A3C9F9A522FDA3B181D4B885D21489CFD98DCC2B91C91695C87099CA634E8705D14B5C0285D27298F37299347287B5726876704E377130B871437970F69D71C3DBF5C532F9C3C8FDC3B181F24285F21489EFD98DEC2C91E99995E90599EA634ED780A174DEA63D1EA64D5EA1ED9E907DDE471E1E358E5E3C175B78F6FC794CBD78F6BE78F07F78E6A08490A184856283D1E38306648244658244D3520A63D60A49DA0A1EDE08D6E202ECE6038F75B814CBC80F6BD80F23E80EC7F8137E08C85218D27E28BC5E38AF7A48A44658A44D3562A63DA2A49DE2A08E22816E622F7EA24F377C88EC7D88E9FE8937FF891E20950FE19514A293B1A392EC249237259244D3564A63DA4A64DE4A4BE241F5E6443BEA42C2EE4301F24326F64498FA4472FE424A826ED0866E9D8A6E278E6B329268A49668F34D69A98F79A993898727998FF7A9885FB9B17FC9ADA7D9AD73E9B153F9B2F20A2EEE1A2D8E2A2B9A3A2A524A237E5A23526A29913E28A63E68A4AEA8A1EEE89CCF28898F6811CFA8126FE810882A99F86A0E58AA0E48EA08492A82796A89E9AAA494F8AA98F9AA993AAA2A3BAA09BCA8253DA846FEA84F3FA84460B05721B064A2B06223B03264B02A65B21CA6B21267B2991462CA63E6C852EAC88BEEC093F2C0B7F6C191FAC1D8FEC19182E27786E52D8AE1D98EE0EF92E14E96E0FA9AE8499EEC1A517BA98F8BB06B9BA14BAB83A7BB8497CB82F3DB8A4FEB94B7FB8A4E0C094A1C0A962C06463C033A4C02B25C21CA6C21267C301545F0A63E30A6FE70852EB089EEF0085F300A5F70249FB026DFF02498329968722168B213D8F208E9321129720E99B28474E8CB0694DF2A63E32C1AE72851EB20D6EF20F2F3206FF729EBFB28F7FF29EB8348828748218B408F8F405893487F9748CE9B48514F8D298F9D2147AD239FBD22F7CD0137DD2287ED21BBFD22860DAEFA1DAE722DA8763DA0BE4D835E5D83293676A63EB68E5EF60CFF36848F76BBDFB6BBEFF6BBD401E214A2E21523E214A4E21452EF885079EE214BFE21460EABDE1EA7DA2EAB963EA7D9273AAF6F7A9FEFBAAF6FFA9FE83C9FE87CAF68BC9FE466F2BD93E3CA6373BF2BDBCF27FBDF2BDBEF27FBFF2BDA0FABDA1FA7F9117EAF64D9FA98FAFA397BFA98FCFABDBDFA7FBEFABDBFFA7F8";
        }

        return BackgroundSprites2.getSprite(v);
    }
} 

library BackgroundSprites2 {
    function getSprite(Background v) external pure returns (bytes memory) {
        if (v == Background.LAB) {
            return hex"800E97422002D51A80E97AC00B558D03A5EE02F02F03E7F0029D310315B2029D330315B4029D350315B6029D3703E7F802F03903A5FA002D5DFC0E97802E97422085291942E974C90B98EA082D55B42E97B82BC0BC2F9FC02A96C42BC0C82A96CC2BC0D02A96D42BC0D82A96DC2F9FE02BC0E42E97E820B5EC2E97F022E6F4275C7DF0BA5D01040B5944E97984E634E8149129102D6A1398D5B44E97B84BC0BC4F9FC04C56C44F9FC84C56CC4F9FD04C56D44F9FD84C56DC4F9FE04BC0E44E97E840B5EC4E97F040B5F442E67DF13A5D00C614A9060B5946E97986E634E8182D691D61EA1B98D5B46E97B868E95F71AF0381A3A791BA5FA182D5DFC6E97403202D642052929880B54E924912A2398D5B88E975F7223A5C688E97EC80B579F23A5D00CA75C90A0B594AE9798AE634E92D61EA2B98EB2BA5D674AB517DF2BA5E030AB213131110CC2AC90C75C94CE9798CE634E934912A3398EB33A5EC32D46D33D36E3561D7F0CF4DF4CB51F8CE97FCC0B540338AB2439D7253BA5E63B98D3A4F587A8EE63ACEE97B0EB515B23BA5D9DCE699E0F58773B39A67C3BD37D3AD47E3BA5FF382D604131108D02AC91075C950E97990E634E94561EA4398EB43A5EC402D56C10E9763241A659D10E976B641A6774561F841A6794561DD6D0699F10F4DF50B51F900B5FD0E9740248AB2349312449D7254BA5E64B98D3A53587A92E635714BA5D9552699D935876F849A6794D61DD6D2699F13587F52B517DF4BA5D00D42AC91475C954E97994E634E854912953E7D5554E976D851A6795561FA51A67B5561FC53D37D52D47E53A5FF502D6058AB215931110D62AC91675C956E97996E639D7587A17244A56F9F5555BA5DB656699E97587ED6699F16F4DF56B51F960B5FD6E9740360AB2461D72563A5E66398D3A1924453663A5DBF18F4DF58B517DF63A5D009A2AC8DA4C491A75C4A66BA5E76BE7D461AE97E5AAB175D6AD45F7DAE9781C4C442370AB2471D712FDCE9740378AB2479D712E9EE9777E782D7F7BA5D00A02AC8E04C492075C4BB83A5FC81B4FD83707E802D7F83A5D00E22AC92275C4BB8BA5FC89B4FD8B707E882D7F8BA5E090AB219131110E42AC92475C4BB93A5DE7A40B5FE4E9740398AB2499D712EE6E97F260B57BF9BA5E0A131108E82AC92875C4BAA3A5DDFE8B3B401A8AB22A93123A8AB24A9D712E6AE9775FA82D500EC75C92C0B54B8B3A5F9B02D5D7ACE97FEC0B5403B82D64B85292E2EE97E6E0B575BBBA5FCB82D5EFAEE97FEE0B5403C052A4C02D52DF0B3B719C02D5D6F0B3BF300B57BEC2CEFFC02D501320B54B8CA6579C82D5D6F2995F320B57BECA657FC82D60D2CEE1D02D512F4B3B595D3A5DB734B3BF740B57DFD2CEE0DACEE1D82D51276B3BAB6E9756DDACED75F6E9771DDACEDF7F60B58389958780B5444E26552A78B3B54BE26556638B3B73FE26560E82D50ABAB3B578EBA5DCFFAB3B408F2CED4E3CE9773FF2CED01BEB3B4FAFBA5DDFFEB3B";
        }

        if (v == Background.GREEN) {
            return hex"41F004E507C213941F104E507C613941F207F107CA1FC41F307F107CE1FC41F407F107D22F941F50BE507D62F941F60BE507DA2F941F70BE507DE3F041F80FC107E23F041F90FC107E63F041FA146907EA51A41FB146907EE51A41FC146907F251A41FD1B5907F66D641FE1B5907FA6D641FF1B5907FE6D6";
        }

        if (v == Background.ORANGE) {
            return hex"41F0313D07C2C4F41F1313D07C6C4F41F2372D07CADCB41F3372D07CEDCB41F4372D07D2F5F41F53D7D07D6F5F41F63D7D07DAF5F41F73D7D07DF15B41F8456D07E315B41F9456D07E715B41FA4BA907EB2EA41FB4BA907EF2EA41FC4BA907F32EA41FD5B3107F76CC41FE5B3107FB6CC41FF5B3107FF6CC";
        }

        if (v == Background.PURPLE) {
            return hex"41F02CF907C2B3E41F12CF907C6B3E41F2307D07CAC1F41F3307D07CEC1F41F4307D07D2CBA41F532E907D6CBA41F632E907DACBA41F732E907DED7E41F835F907E2D7E41F935F907E6D7E41FA398107EAE6041FB398107EEE6041FC398107F2E6041FD3BF907F6EFE41FE3BF907FAEFE41FF3BF907FEEFE";
        }

        if (v == Background.CITY__GREEN) {
            return hex"80005A8400618800648C006890007294007E98007D9C008D50B0025EC002796C400B0653002AB4002C1ADC009771900237A001F7B001F9E740077F80068FC00648020648420688820778C207E9020834A60825E7082AA8082C29082F6A08302B0831563420D1B820DC5F00834710837194C20D169508317609FE77082F7809FE5CE820AA77C0825FD08237E081DFF081CA01063211629221202919047F99458A49840BD9C40D1A040DCA44ECBA8480AAC4ECBB0480AB44ECB5D01045311049F2104519D04104D440EDD840EBDC47F9E040DCE440D1E840C577C102C3D1027BE1025FF1020E01863211A7E621E29119067F99478A49860F79C6100A0612FA46C07A878A4AC6C07B078A4B46C075CF185D70185F18C86175CC6166D06159D4630DD8680ADC67F9E0680AE4618CE860F7EC60EDF060DC7BE1A02BF186320206321227E6221FE6326292421FE65227E662053E7205D68205F2920632A2072AB2078EC207B6D20632E207B57C4822BC88212674207B7520C35B60880AE4818CE88156EC812FF081007BE21FE7F2063202863212A7E510CA7F990B8A494A9F998A1CA4E928631538A4CC5F028C33128CC3228C33328C11A54AC07D8AECBDCB8A4E0AECB73A2B01FB28627C285D7D29FE7E2A02BF28632030632132029110C7F994C80A98C29C9CC18CA0D8A4A4C18CA8C4CCACCA24B0C4CCB4D8A4B8C4CCBCC46BC0C41FC4C44AC8C414CCC3EFD0CC07D4CECB6D836293933B2FA3301FB308AFC307B7D31FE7E3202BF30632038631094F8A498E3839CE18CA0F8A4A4E18CA8E4CCACEA2458E393317C8E035CCE60A6953B01F63BB2F73E29383BB2DCE8EC07ECE30CF0E29C7BE39FE7F386320406321427E511107F995080A9904ED4E940632A413315B5018C5D4400D7540631B5D030D71940633A411AFB40FBFC40E0DEF9080AFD018C81218C4224A7E519138A49529F99926E09D218CA12A8FA5218CA924CC575480D5B6D24CCF1218C7BE49FE7F486320506321527E511147F995480A9948049D418CA14A8FA5418CA944CC575500D76506337520178513339527B3A51333B56293C50633D51FE7E5202BF5063205863215A02911167F995680A9968074E8586314D960356F85933395A7B3A59333B5E293C58633D5A02BE59FE7F5863206063109598A49988084E8606314D580356DB61333C60631EF987F9FD818C81A18C85A80A89A7F98DB8A491A7F995A80A99A8054E8686314DDA035E1A4CCE5AA24E9A4CCEDAA24F1A18C7BE6A02BF6863207063217202A271FE6376292471FE657202A67200D3A1C18C537700D7871333972893A71333B72893C70631EF9D8A4FDC18C81E18C85E80A89E7F98DE9F991E7F995E4CC99E0354E8786314D9E0356FB79333C78631EF9F8A4FDE18C82018C425813326800D53A2018C536800D5BEE04CCF2018CF607FDFA0801FE018C82218C862C078A38A48E2C074858933131E2035A2218C536880D5BEE24CCF2218C7BE89333F8863209063109644CC4C7900D68906314DA40356FB91333C90633D91FF7E92007F9063209863219B01E29E2911926C079664CC4C7980D68986314DA60356FB99333C98631EFA64CCFE618C82818C425A133131E8035A2818C537A00D5C6E84CCF2818CF687FDFA8801FE818C82A18C86AC078AB8A48EAC0792AFF196A4CC4C7A80D68A86314DEA03571BA9333CA8631EFAA4CCFEA18C82C18C425B13326B1FEA7B00D68B06314DEC035E2C4CCE6C7FFEAC4CCEECA24F2C18CF6C7FDFAC801FEC18C82E18C86EC078AF8A48EEC0792EFF196EC079AE7FA9EE035A2E18C537B80D78B93339BA003AB9331DF2E18C7BEB9333FB8631017018C9B07FB4E8C06314DF0035719C1333AC0631DF704CC7DFC06320C86321CE2922CBB2E3CE2924CBB2E5CE2926C9FF13A3218C537C80D78C93339CA893AC8633BC9333CC9FE7DC9333EC8633FCA02A0D063108F58A4934ECB9758A44D7D00D5C6744CCEB418CEF44CCF347F9F744CCFB418CFF480A83618C8778A48B6ECB8F78A4936ECB4B8D80D79D9333AD8631DF764CC7DFD8631013818C4B8E00D5CEF84CCF387FDF784CCFB818CFF880A83A18C87AC078BB8A4464EB01D2E7A03575BE9333CE9FF7DE9333EE8633FEA02A0F0631093C4CC4B9F00D5D77C4CC7DFF06320F86321FB01E2FE2923F80D64F93312E7E03575BF9333CF8633DF9333EF8633FFA028";
        }

        if (v == Background.CITY__RED) {
            return hex"8009978409B68809BF8C09D79009FA4A6028AE70296D42C0A83B00AA35B102B7994C0ABFD00ADE6B702A0DC640A5B75B028ADE740A0FF809D7FC09BF8029BF8429D7882A0F8C2A2B902A444A60AA0E70AAFE80AB7A90AC72A0AC9EB0ACDD6342B56B82B7B5F00AD5B10ADED94C2B566950ACDF60D61F70AC7380D61DCE82ABF77C0AA0FD0A96FE0A83FF0A7EA013522114EB22155F519055879453AC984B1C9C4B56A04B7BA457E8A8557DAC57E8B0557DB457E85D01307B1131072130799D04BFED44BA1D84B95DC5587E04B7BE44B56E84B3777C12B7BD12A8FE12A0FF1291201B52211DE9621CEB119075879473AC986BD09C6BF0A06C5AA46FB4A873ACAC6FB4B073ACB46FB45CF1B3FB01B47D8C86CFECC6CD3D06CB7D46FBCD8757DDC7587E0757DE46D48E86BD0EC6BA1F06B7B7BE1D5F7F1B522023522125E9622561E324EB242561E525E9662323A7233FA82347E923522A236B2B23792C237CAD23522E237C97C48E66C88E3B674237CB523EF1B60957DE48D48E88CA9EC8C5AF08BF07BE2561FF2352202B52212DE9510CB58790B3AC94B7A598ADAC4E92B521538B3015F02BEE712BFEF22BEE732BEA9A54AFB4D8B7E8DCB3ACE0B7E873A2BED3B2B51BC2B3FBD2D61FE2D5F7F2B5220335221355F5110D58794D57D98CF269CCD48A0D3ACA4CD48A8D301ACD431B0D301B4D3ACB8D301BCD28BC0D210C4D24EC8D1F7CCD1B0D0CFB4D4D7E86D834EB3935FA3A33ED3B3399BC337CBD3561FE355F7F3352203B521094F3AC98F07A9CED48A0F3ACA4ED48A8F301ACF43158E3CC057C8E86BCCF4166953BED363DFA373CEB383DFA1CE8EFB4ECEFB9F0EF267BE3D61FF3B522043522145E95111158795157D9913544E943522A44C055B50D485D4421AF543521B5D0FBC71943523A44A2FB446C3C441E9EF9157DFD0D48812D484224DE9519133AC9537A59935069D2D48A13080A52D48A933015754A1ADB6D3301F12D487BE4D61FF4B522053522155E95111558795557D9955079D4D48A15080A54D48A95301575521AF653523755427854C07953773A54C07B54EB3C53523D5561FE555F7F5352205B52215D5F5111758795757D99750A4E85B5214D9686B6F85CC0795B773A5CC07B5CEB3C5B523D5D5F7E5D61FF5B52206352109593AC99957C4E8635214D5886B6DB64C07C63521EF99587FD8D4881AD4885B57D89B5878DB3AC91B58795B57D99B57E4E86B5214DDA86BE1B301E5B431E9B301EDB431F1AD487BE6D5F7F6B5220735221755F627561E374EB247561E5755F66755FD3A1CD48537721AF874C079750C7A74C07B750C7C73521EF9D3ACFDCD4881ED4885F57D89F5878DF7A591F58795F30199E86B4E87B5214D9E86B6FB7CC07C7B521EF9F3ACFDED48820D4842584C066821AD3A20D48536821ADBEE1301F20D48F61587FA1585FE0D48822D48862FB48A33AC8E2FB44858CC0531E286BA22D485368A1ADBEE3301F22D487BE8CC07F8B52209352109653014C7921AE8935214DA486B6FB94C07C93523D9561FE95617F9352209B52219BED229CEB11926FB49673014C79A1AE89B5214DA686B6FB9CC07C9B521EFA7301FE6D48828D48425A4C0531E886BA28D48537A21ADC6E9301F28D48F69587FA9585FE8D4882AD4886AFB48AB3AC8EAFB492B1BD96B3014C7AA1AE8AB5214DEA86B71BACC07CAB521EFAB301FEAD4882CD48425B4C066B56127B21AE8B35214DEC86BE2D301E6D581EAD301EED431F2CD48F6D587FAD585FECD4882ED4886EFB48AF3AC8EEFB492F1BD96EFB49AF5849EE86BA2ED48537BA1AF8BCC079BD603ABCC05DF2ED487BEBCC07FBB5210170D489B15834E8C35214DF086B719C4C07AC3521DF713017DFC35220CB5221CCEB22CDFA23CCEB24CDFA25CCEB26CD6093A32D48537CA1AF8CCC079CD0C7ACB523BCCC07CCD61FDCCC07ECB523FCD5F60D352108F53AC9357E89753AC4D7D21ADC675301EB4D48EF5301F35587F75301FB4D48FF557D836D488773AC8B77E88F73AC9377E84B8DA1AF9DCC07ADB521DF773017DFDB5210138D484B8E21ADCEF9301F39587F79301FB8D48FF957D83AD4887AFB48BB3AC464EBED12E7A86B75BECC07CED61FDECC07EEB523FED5F60F3521093D3014B9F21ADD77D3017DFF35220FB5221FBED22FCEB23FA1AE4FCC052E7E86B75BFCC07CFB523DFCC07EFB523FFD5F40";
        }

        if (v == Background.STATION) {
            return hex"41F0271107C29C4405103FD32049C4A4421054C11AB6D1084174049C463A103FDDF049C4F442107DF11AB501069929460FF4D01A7131183FD9646992E860FF77F1A711008880F8C899290880F9480FF4D0227131203FD94C8992D0880FD48992D8880FDC8992E0880FE48992E880FF77F2271202A64A12A03D10CA99290A80F94A0FF98A9C44EB2AA95640A9C4C4A0FFC8A992CCA80FD0A992D4A80FD8A9926F82A03F92A64BA283FFB2A711E7CAAA54043264A5303FE632712732A9683382A933916A33B6EB32A95640C9C4C4C0FF6593264BA303FFB32713C32A97D3382BE33917F33B6D014E0FF98E9C49CEAA5A0EE45A4EEDBA8EE45ACEAA55903A7131383FF23A6499E8E0FFECE9C4F0EAA5F4EE45F8EEDBFCEE4540642712742A968426B2943916A426B2B42A9566D09C4F10AA5F509ACF90E45FD09AC4054819A64A71274AA9684B91694AA06A4B916B4AA9565529C4D920666FB4A713C4AA97D4B917E4AA07F4B91501540669949C49D4AA5A14F40A54E45A94DCA575502B5B5D49C4E148FEE54A9EE948FEED49C4F14AA5F54F40F94E45FD4DCA405582B665A7113A96AA55775A71385AA7B95A3FBA5AA7BB5A711E7D6AA58180AD423627124602B529989C49D8AA5A189C452A62A955D980ADDD89C4E188FEE58A9EE988FEED89C479F62A95029ABB25786B18DCFDABB241F72D0D07DEA9E41F821A101628684D98B18DD7E2868404921A12E24C6373F921A100E68684989B18DCFE686841FA2A7902AAB43576AAFB1BFEAB4340CB2EC96D6CC636DFB2EC907EEB43409C2EC95470A9E65FC2EC902B2B43573CAFB1A7F2B4340AD2EC95C34C6363FD2EC901F6BB2513DB18DA7F6BB240CE2D0D6E38BEC73FE2D0D027ABB255BEB18DE7FABB2408F2EC94E7CC6375FF2EC900FEBB2486FB18E7FAEC9463EC6373FFAEC8";
        }

        if (v == Background.ARGUS) {
            return hex"800B00840A518809D8465000126027613A00A51A40004A809B7AC000458D0008AE0007D7C40004C8001FCC0022D00026D40004D809B7DC00047190008BA0007DDF40004F8001FFC00224020801119428C24C8080114AC29B758E080117C428C265408011ADC29B771A08011DF428C27DF0801100849B74651230A6126DE71230942C49B758D1230AE126DD7C448C2C849B767412309AE049B7E448C2E849B777D12309F7C49B740918012A1A6DD5D46004D869B76FF18011004803188802C8C80049088C294800498802C4E8200C6920012A226DEB200116388BC4BC8004C088C2C4800465422F135200136226DF720011C688BF2EC8004F088C2F480047DF22FCA0280B1088A02B8CA02190A00494A0214C7280AE8280C6928012A2A6DEB28012C2AF116B8AAECBCA9CEC0A004C4A9CE6532ABB342AF1352801362A6DF72801382AFC9CE8AB10ECA9E0F0A004F4A9E07DF2AC4203009A13008A23007D194C00498C01F9CC022A0C026A4C004A8C9B7ACC004B0CAECB4CA45B8C9CE5F13001323273B332917432BB35300136326DF730013832C43932973A32781DF4C004F8C9E0FCCA5C40238011194E8C24C8380114ACE9B758E380117C4E9B765438011ADCE9B771A38011DF0E8C2F4E02A7DF3801100909B74654230A6426DE74230944109B7C508C2658426DF94230BA426DDDF508C27DF426DD0252004A929B75754801364A6DDBFD200440252FA635001245230A5500113214BE9A54004A949B7AD400458E52F12F5001305230B1500119514BC4D54004D949B7DD400471A52F13B50013C526DFD50011F7D4BC4816BE94225AC0235A76245801255A76131D6B00A16BE9A56004A969B7AD6004B16BC45AE5ABB2F5A73B05801315A73994D6AECD16BC4D56004D969B7DD6004E16BC473A5ABB3B5A73BC58013D5A739F7D6AEC818B00858A518989D846560012662762762946862C02960012A626DEB60012C62BB2D62916E627397C58004C989CECD8A45D18AECD58004D989B7DD8004E18AECE58A45E989CE77D60013E6273BF62915009A0044656A6DD321A00452B6A6DD639A0045F16A6DD951A0046B66A6DF76A309C69A00477D6A6DDF7DA004402726DD195C8C299C9B79DC8C2516726DDBE1C8C2E5C9B775C72309EFDC9B740978012A7A6DD5D5E004D9E9B76FF7801100A0BE98E00049208C29600044C882FA6980012A826DEB800116360031BA002CBE0004C208C2C60004CA002C674800C75800136826DF780011C6A0BC4EE0004F208C2F600047DF82F1208AFA508A2B008E29D89220049629D84C88AC02988012A8A6DEB88012C880B16BA202BBE2021C22004C62021653880AF4880C758801368A6DF78801388AF11CEA2AECEE29CEF22004F629CE7DF8ABB2092C0219294629276119640049A49D89E4A51A24B00A64004AA49B7AE4004B24026B64022BA401F5F19001329007F39008B49009B5900136926DF790013892BB3992917A92739DF64004FA49CEFE4A454029801119669B74C8980114AE69B758E980117C668C265498011ADE69B771A98011DF668C27DF9801100A89B7465A230A6A26DE7A230942E89B758DA230AEA26DD7C688C2CA89B7674A2309AE289B7E688C2EA89B777DA2309F7E89B7409A8012AAA6DD5D6A004DAA9B76FFA8011006C0318AC02C8EC00492C8C296C0049AC02C4E8B00C69B0012AB26DEBB001163ACBC4BEC004C2C8C2C6C004654B2F135B00136B26DF7B0011C6ACBF2EEC004F2C8C2F6C0047DFB2FCA0B80B108AE02B8EE02192E00496E0214C7B80AE8B80C69B8012ABA6DEBB8012CBAF116BAEAECBEE9CEC2E004C6E9CE653BABB34BAF135B80136BA6DF7B80138BAFC9CEAEB10EEE9E0F2E004F6E9E07DFBAC420C009A1C008A2C007D19700049B001F9F0022A30026A70004AB09B7AF0004B30AECB70A45BB09CE5F1C00132C273B3C29174C2BB35C00136C26DF7C00138C2C439C2973AC2781DF70004FB09E0FF0A5C402C801119728C24C8C80114AF29B758EC80117C729B7654C8011ADF29B771AC8011DF328C2F7202A7DFC801100B49B7465D230A6D26DE7D230944349B7C748C2658D26DF9D230BAD26DDDF748C27DFD26DD0276004AB69B7575D80136DA6DDBFF6004402E2FA63E00124E230A5E00113238BE9A78004AB89B7AF800458EE2F12FE00130E26DF1E00119538BC4D78004DB88C2DF800471AE2F13BE0013CE26DFDE0011F7F8BC483ABE9422EAC023EA7624E80125EA761323AB00A7A004ABA9B7AFA00458EEABB2FEA73B0E80131EA739953AAECD7A004DBA9B7DFA00471AEABB3BEA73BCE8013DEA739F7FAAEC83CB0087CA518BC9D8465F00126F27627F29468F2C029F0012AF26DEBF0012CF2BB2DF2916EF27397C7C004CBC9CECFCA45D3CAECD7C004DBC9B7DFC004E3CAECE7CA45EBC9CE77DF0013EF273BFF291500BE004465FA6DD323E00452BFA6DD63BE0045F1FA6DD953E0046B7FA6DDC6BE00477DFA6DDF7FE0040";
        }

        if (v == Background.BOUNTY) {
            return hex"8000DD4220037A3021724002025001893300080B400625CF002030002E71000A720575D9D40029D815D7DC002971A0575FB000A7C0575DEF80029FC15D78020DD4220837A30A1ED23C2062C020B9C42029C835D7CC2029D035D7D42029D835D7DC202971A0D75FB080A5E7435D7F82029FC35D78040698440B88840A48C485C4881020291018953C4080C040B9632100A731575F4100A751575DB5C4029E055D7E44029E855D7EC4029F055D7F440297DF1575E01837508860DE8C685C4881820291818953C6080C060B863E180A7F1B83602037508880DE8C887B4882020292018953C8080C080B8C48F3DC88F53CC8FA5D095D7D4907ED88FFDDC8F7A71A2575FB23E5FC24157D2455BE2575FF23F6E0281A61282E222829232A171220A080A4A06254F282030282E312BCF722BDBB32C061A54B5D7D8B06FDCAF97E0AF53E4AF3DE8AF54ECAFDBF0B1397BE2D75FF2C092030375088C0DE8CC85C4883018A9320E153CC062C0C0D5C4CF3DC8CF6ECCCFF4D0D12FD4D5D7D8D047DCC84EE0C9D0E4C9C9E8C9CAECC879F0D108F4D5D7F8D139FCCFF480E0DD4223837A33A1EE43820253818933CE080C0E0D5C4F149C8F165CCF182D0F1E6D4F217D8EACEDCEAE2E0EA47E4EAE3E8EA46ECEAE2F0EAE0F4F233F8F218FCF1828100698500B88900A48D085C9100809500624CF402030403558C91149CD15D7D1118DD50890D90B8BDD142FE10C0FE50C11E90C01ED141AF10AD5F50866F91172FD15D78120DD4224837A34A17244820254818933D2080C120D56324C52734C55F44C60754AC7764D15F74BEFDC6536ACE936B5ED2FA4F13444F52AC2F93171FD31588140DD4225037A3521EE45020255018933D4080C140D5C5538FC9538ECD482CD15237D54BBAD95442DD4C6FE14D0CE55661E94D20ED4C70F15443F54B3FF9521CFD48248160698560B88960A48D685C9160629568384C75818943D6080C160D5C56824C9738ECD682CD16D29D56AADD96BD1DD72E6E1776CE57658E97761ED72E6F16BC3F56A35F96CE0FD682B8180DD4226037A36217123D8080C180D5C59888C9938ECD882CD18D11D58A88D99456DD92E6E19771E5965AE99765ED92E6F19455F58A25F98CE0FD882481A0DD4226837A36A1ED23DA080C1A0D5C5A824C9B7CBCDB6C3D1A862D5ABB8D9AAEBDDB693E1AC39E5AC5CE9AC5BEDB68EF1AAD4F5AB62F9A844FDB6CC81C06985C0B889C0A48DC85C48F70203070357175B4994DC824D1D86CD5C87AD9CD5FDDCC0EE1CC34E5D19BE9CC34EDCC00F1CD3AF5C862F9D6C3FDD6D281E0DD4227837A37A17123DE080C1E0D5C5F6D26547A09357B2AF67A11777ABAB87AC5397ACA3A7B3DFB7AB7FC7A0FBD7B2ABE7A093F7DB4A08037508A00DE8E087B48F80203080357186223282093383BAB4820935831DF68323F78326F8829EB982A1DD6E0C9BF20C8FF60C77FA0EEBFE0EEA8220698620B88A20A48E285C48F8820308835718DB8F28A09338BBAB48B2FDADA2824DE2BA571A8A093B8AEE7C8A093D8A9B3E8B2FFF8BBAA09037508A40DE8E485C48F902030903558CA56E3CE519AD24EEAD64A6CDA4824DE503B71C92093D929B3E93BABF9466A09837508A60DE8E687B48F9820187E60D58280698680B88A80A48E885C48FA020187680D57DFA02E20A837508AA0DE8EA85C49FA82020B022508AC08A8EC86C499B018BAB20E1DFEC06282E06986E0B88AE0A48EE85C499B8203AB8189DFEE0808300DD422C037A3C21712670080EB006277FC02020C837508B20DE8F287B499C8203AC8189DFF20808340698740B88B40A48F485C499D0203AD0189DFF4080836089422D822A3DA1712676062EB683877FD818A0E037508B80DE8F887B49CE0203DE0189F7F808083A06987A0B88BA0A48FA85C49CE8203DE8189F7FA08083C0DD422F037A3F2171273C080F7C0627DFF02020F837508BE0DE8FE87B49CF8203DF8189F7FE080";
        }

        if (v == Background.BLUE_SKY) {
            return hex"40E02306F0038187C08C14050A3066083813D828C1DC20E071F0A30507C48C141F1A3060203810F888C1FC80E040B2A306C286A56FCA8C141F32305068E8C1ECE1A979F3A30503108C15AE4230D7FD08C14064A3053A128C3A528C1A928C356F4A2DB04A3118C928D2CD28C4D128D26B64A2DB74A30DC7D28C14035230645230E55234931D48B650952312A5231AB5231EC5231AD5231EE5231AF522E185148C8D548CBD948B8DD48C7E148C673A52313B5234BC5230DEFD48C18168C18562B58968D28D68C49168C69568C49968C69D68C7A168CC52A5A2E6B5A332C5A2EAD5A2FAE5A27EF5A29D849689C6745A2FB55A27365A2FB75A2F1C6568CDE968CCED68C779D5A313E5A30FF58AD60622DA16231226231E36233246232E5622EE6622F93A1889FA588A9A988AAAD8895B18897B58885B988745F0622171621D32622033621D746212B5621D7662207762217860C69CE988A0ED88A7F188BAF588CCF988B8FD88C481A8C885A8BA89A8BB8DA89C91A8AA95A88C99A8809DA875A1A85EA5A869A9A831ADA828B1A81FB5A0B1B9A0AFBDA0B4C1A0BAC5A0CDC9A0BECDA0C1D1A0BED5A0BAD9A0B4DDA81FE1A828E5A839E9A84AEDA875F1A885F5A8AAF9A8A7FDA8B981C8CD85C89C89C8968DC87491C84A95C82099C0B49DC0C1A1C0CDA5C0E054B703BAC7040AD7042AE7043EF7046B0704AB1704932705133705034704CF57049367048777046B8703D797036BA7031FB702C7C720E7D7217BE72217F7225607A23617A1B627A0E63782DA47834E5783D66784867784DE878512978592A785A6B785ED635E187B9E1B0BDE1C0C1E1C6C5E1D7C9E1EACDE1D7D1E1E0D5E1CED9E1C0DDE1A1E1E170E5E15FE9E137EDE0FDF1E0E6F5E0BEF9E828FDE86D8208288600B68A00E68E011A92014496016D9A01A19E01E0A2020FA60246AA0269AE0289B202A0B602CBBA02F3BE02FEC202F3C60311CA031ACE031BD20306D602F3DA02D3DE02B5E20274E6021BEA01EAEE0184F20155F603CFFA00DFFE00B68220F58621248A24068E21B09222039622699A22CA9E231BA2234CA62369AA23A1AE232AB22339B6234BBA237CBE238761188E57288EB7388E83488E5758909B688FCF788F67888E5B988D33A88BFBB889FBC8880FD8861FE8852FF8843E0905621906A62908DA390A82490CAE590E22690F8E79109A890ED94E24CE9E6446FEA43F3EE43AEF2431AF6427EFA41F3FE416D82620F8662A08A633A8E63C792643396648E9A65314F79B3A7899A6F99989BA9950BB9920FC9905FD98DCBE98B4FF9889A0A0C1A1A0EDE2A11123A137A4A15EA5A19966A1AEA7A1B328A1B5E9A1B715568CE9DA86E9DE86E4E286DCE686D4EA86BBEE8665F28531F68463FA83CFFE831182A62786A4978AA56D8EA69192A6C896A6DB9AA6E19EA6E9A2A6ECA6A6ED555AB3A76A9D7F7A9D6F8A9BB79A9BB3AA9B93BA9B53CA9AD7DA95EBEA923BFA986E0B13CA1B189A2B1AEE3B1B6E4B1B9A5B1BB66B1D6D3A2C75F538B33A79B1D7FAB1BB7BB1BA7CB1B73DB1AEFEB186FFB125E0B99961B9B322B9B863B9BB526EECE9F2E6EDF6E6DFFAE6BBFEE5F68306CE8706E4443C33A521F0FBA517C33A5C6F0FBA79DC33A7EC1B73FC1ABA0C9B921CB3A51272FBA558CB3A5CF72FBAFB2CE9FF26CE834CE9427D3EE94634CE973ED3EEBFD33A501B6FBA4FADB3A5DFF6FBA406E3EE93EB8CE977FE3EE901BAFBA4EFEB3A70E9A698EBACE977FEBEE901BCFBA4EEF33A57C7C69A65BF33A5E7FCFBA405FBEE9337ECE95D1F9A6996FECE979FFBEE8";
        }

        if (v == Background.RED_SKY) {
            return hex"40E0375AF0459187C0DD64050B75A60C5913D82DD6DC316471F0B75907C4DD641F1B75A0245910F88DD6FC916440B2B75AC2CB9D6FCADD641F33759068EDD6ECF2E779F3B7590310DD65AE438757FD0DD64064B7593A12E1DA52DD6A92E1D56F4B87B04B8F98C92E1FCD2E3ED12E1F6B64B87B74B875C7D2DD64035375A45387655387D31D4E1E509538FAA539E2B53A2AC539E2D53A2AE539E2F53A2D8514E9AD54EAED94E8BDD4E8AE14E7873A538FBB5387FC53875EFD4DD6816DD685743D896E1F8D6E3E916E78956E3E996E789D6E8A50B5BB3AC5BB7ED5BCE6E5BDA6F5BD158496F516745BCE755BD4765BCE775BCC1C656EFDE96ECEED6E8A79D5B8FBE5B877F5D0F606387A1638FA263A2A363B3A463ABA563C2A663CE53A18F69A58F6AA98F81AD8FA3B18FB0B58FDAB990085F063F6B164023263FF33640274640C9AD99009DD8FDAE1949A73A63E5BB63D17C63B7FD63B3BE63A2FF638FA06BA6A16BB7E26BC2A36BD4646BE0656BEBE66BFF276C02686C08E96C11AA6C14EB6C18AC6C18ED6C1F2E6C1F6F6C22306C48316C4DF26C48336C4B5A55B120D9B088DDB063E1B062E5B054E9B032EDB009F1AFDAF5AF81F9AF45FDAECE81CEFD85CF5189CFAE8DD00891D03295D06E99D0889DD12DA1D137A5D16454B7462EC746CAD7472D73DD1D6C1D213C5D1FB653748FB47488F5747EF6747EB77475B874673974557A744E3B741F3C74153D7408FE73F6BF73E8E07BF3617C05E27C15237C45247C51E57C67267C7EA77C8C287C8FA97CA32A7CA3EB7CAE9635F2CCB9F302BDF315C1F341C5F355C9F36C6747CD5757CD0B67CC5777CB5F87CA8797CA3BA7C8C3B7C6CFC7C603D7C483E7C18BF7C05E08418A18445228460238475A4848FA584A36684B5E784D56884DF2984F46A84F76B85006C8505ED851BAE85212F8526B08521318526728526B3852DF48526B5852136851B77850F7884FB7984E63A84DB3B84B2FC8493FD8582FE8458FF8445208C67218C7EE28D81638CC0A48CDF658CF7668D13E78D2DE88D82698D80EA8D812B8D26EC8D896D8D89AE8D89EF8D86D8463627CA3628CE361ED23627D63612DA360CDE360BE23604E63609EA349AEE3400F2337DF632CCFA323FFE31D68252648652E78A53C28E541792560296560A9A56119E5612A2562853892C5F995837A95833B95813C9526BD95003E94DB3F94A3609CDF219D05E29D82239D82E49D86259D86669D8753DE6B17E27628E6761BEA761DEE7614F27612F67603FA746DFE739982949A86960B8A96138E96159296274A6A587E7A5881426962A555A2C5F6A5885BE2962AE69629EA9628EE961FF2961DF69613FA960BFE949982B61E86B6198AB6278EB62892B6294A6AD8AA7AD885426B62B555AAC5F6AD8C1BE6B62BEAB62AEEB629F2B61FF6B627FAB619FEB61E82D61A86D61B8AD6288ED62A92D62F4A6B58AD3A2D630538B2C5F9B58C3AB58AFBB5887CB58ABDB58A3EB587BFB58660BD87E1BD8822BD8AA3BD8AD26EEB17F2F62BF6F62AFAF628FEF61B83162087162A443C2C5D21F0145517C2C5DC6F014579DC2C5FEC58ABFC58A20CD8AA1CAC5D1272145558CAC5DCF72145FB2B17FF3620834B17427D05154634B1773ED0517FD2C5D01B61454FADAC5DDFF6145406E05153EB8B1777FE051501BA1454EFEAC5F0ED9098EBAB1777FE851501BC1454EEF2C5D7C7D64265BF2C5DE7FC145405F8515337EB175D1FD90996FEB1779FF8514";
        }

        if (v == Background.GREEN_SKY) {
            return hex"40E003D2F007B987C00F4405083D26087B93D820F4DC21EE71F083D107C40F441F183D20207B90F880F4FC81EE40B283D2C28C596FCA0F441F303D1068E0F4ECE31679F383D103100F45AE403F17FD00F4406483D13A120FCA520F454F483F30484158C92101CD2105D121016B7483F1C7D20F4403503D24503F255040531D40FC50950416A50426B50432C50426D50432E50426F504318514116D5411D6D750433850425CE94105ED4101F140FC7BF503D20583D2158FB625840635841645842655841665842675843285847D4A9611EAD611FB16123B56131B9613ABD6130612584D99D16131D56136D96131DD612D719584A7A5847FB58431E756105F960FCFD63ED8180FC85810589810C8D811F91811D9581289981314E9604EAA604FEB60506C60546D6055EE605757C18157C5815DC9815ACD8162D1816ED58162D98163DD8157E1843773A6050BB604C3C6048FD6047FE60433F6041606845A16848E2684A23684DA4684FE56854666856A76858A8685B29685C6A685E2B685FAC6860AD6862AE6862EF6867B0686B316872F2686C73686EF4686C75686B366867B76860B8685FB9685E7A685BBB6858BC6855FD684FFE684C3F6847A0704A61704DA2705263705764705BA57061667067A7706EE87072E9707B952DC1FBB1C220B5C232B9C23ABDC239C1C25CC5C255C9C284CDC279D1C264D5C255D9C24CDDC239E1C213E5C1DAE9C1CCEDC18AF1C179F5C16CF9C157FDC14181E15485E16789E1798DE1A691E1D195E21399E24C9DE26EA1E284A5E2ADA9E2C5ADE2E158D78C0EE78C56F78C9F078CBF178D03278D1F378D03478CFF578CDB678C9F778C2F878B3B978ABBA789BBB78887C787DBD786C7E785FBF7859E0805FA18069A2807DA3808E6480A12580B12680C2E780CFE880D8A980EA6A80EF2B80F4AC80F82D81006E8104AF8107708104B1810BB2810DF3810FF4810BF58104B681003780FB7880F13980DE3A80D1FB80BB7C80A53D813E7E80793F8069A08884E18895628954E388C56488D8E588EF2688FE27890FE8891A6989226A892F2B890E2C89122D89176E89202F891FD8462493CA24B6CE2492D22493D625EFDA253CDE2508E224B4E62469EA241DEE23CBF22363F62303FA228DFE223A82429B8643168A43918E43E09244479644B59A45199E45EFA244BD538929B7991923A914F3B9132FC910DFD90F2FE90D47F90B12098D8A198F822991723993B2499826599A0E699B1D3DE6A6DE266E8E666DAEA66CBEE666DF26575F66488FA6400FE637882842F8684D98A86178E86AC9286D29686E29A87599E8762A28769A6876D555A29B76A1DCF7A1DC78A1DB79A1DA3AA1D7BBA1B8BCA1B1FDA18DBEA13E7FA10BA0A9B7A1A9A522A9B363A9B9E4A9D865A9DAA6A9DBA7A9DCE8A9DE69A9DE9556AA6DDAA782DEA77FE2A77AE6A779EAA771EEA768F2A6EBF6A6D2FAA683FEA6DA82C6B486C6DA8AC75E8EC76A92C77396C77A9AC77F4E8B1E094E2CA6DE6C782EAC77AEEC773F2C76DF6C75EFAC6DAFEC69482E6E286E7628AE76E8EE77A49BBA9B7CB9DEBDB9DB7EB9D7BFB9B460C1D961C1DC510F0A6D487C2A9145F0A6D71BC2A91E770A6DFB076DFF06EB832771872A6D449CAA915632A6D73DCAA93ECA9B7FC9D960D29B509F4AA4518D29B5CFB4AA4FF4A6D406DAA913EB6A6D77FDAA9101B8AA44FAE29B5DFF8AA4406EAA913BFAA6DC3A6E363AEA9B5DFFAAA4406F2A913BBCA6D5F1F1B8D96FCA6D79FF2A91017EAA44CDFA9B5747E6E365BFA9B5E7FEAA40";
        }

        if (v == Background.STARRY_PINK) {
            return hex"8012318412244430484921C11F850A04792B04A9563C11E461704729C6811BFEC1291F012EBF412917DF046FE00C9D210C99620C94119032404A70C8C54243224A832CEAC3318B032BC5AF0C84984C31F86990C791D6C31CAF032A47BF0C72A014BA6114E72214AED19052A29452904C714A014245274A85265AC5305B052515AF149418445240653148C74148C9AD85224DC5212E051F973C147E1EFC51E48074458474308873F08C73579073439473179873169C73035091CBA152C72D858D1CB36E1CAEEF1CA8F01CA8B11CA4321CA0731CA01A5472746D71C99781C94391C907A1C901DF072317BE1C893F1C84A025286125B5622510232506242500929893EE9C93C450924F0EA24EB6B24E69634938CB8936EBC936D61124D5F224C5D9D09303D492E8D892D8DC92CDE092BBE492A2E8929077C24A03D249D3E24997F2494202DA1212D9EE22D9DE32D9D642D9BA52D9B531CB66CA0B4BB52A2D21AB2D216C2D152D2D1BEE2D106F2D0B5844B4186532CF7F42CF0F52CEB762CE6B72CE3382CDF9CE8B357ECB303F0B2E9F4B2E8F8B2CDFCB2BB80D6A584D6A288D69B8CD69648535A4A635A42735A36835A26935A22A35A0AB359FAC359FD6B8D67ABCD677C0D673632359BB3359B34352EF53521B635153735107835103935067A3500BB34F7FC34F0FD34E6BE34E33F34DFA03DB1A13DAF623DAEA33DADD214F6B498F6B69CF6B05093DA9952CF6A4B0F6A3B4F69E5CF3DA65844F692C8F690CCF689D0F688D4F685D8F67FDCF678E0F677E4F674E8F672ECF4BBF0F4A1F4F470F8F46FFCF3E081175F8516E644345B86445B8129916DA4E945B46A45B2AB45B1AC45B056B916BEBD16BA61145AD3245ABD9D116A6D516A36D745A7B845A67945A5BA45A4BB45A27C45A13D459FFE459EFF459DE04DDD614DDE111137704A64DDA674DD9D42D3760B1375BB536E5B936E6BD36E0C136DBC536D76534DB4744DB2B54DB1B64DB0B74DAFB84DAEB94DADBA4DAC3B4DAAFC4DA97D4DA8FE4DA6BF4DA62055E2E155E1A255E06355E1A455E05299577E9D577850A55DFAB55DE2C55DC2D55DE2E55DD57C55770C9576967455D9DAD9575FDD575BE156E1E556DBE956D1ED56D0F156C6F556C2F956BAFD56B64015DE6225DE6E35DE6121977929D77A85095DE49535778BB97786BD7781C177866335DE0745DDF755DDE1B5D7775E1777073A5DDA7B5DD9BC5DD6FD5DB9BE5DB87F5DB6A065EC5091979F4AB65E6EC65E616BD979B61365E63465E49AD9978B6F865E1B965E07A65E01DF19778F59775F99770FD97A44026DE911B1B7A05B16DE7D95DB79B7196DE63A6DE49DF1B78BF5B786F9B7B6FDB7CE40975E91549D7A067475E7F575E81B5DD79F71C75E6DEF9D798FDD7BD81F7A04307DE918C9F7A0CDF7A46987DE81CE9F79FEDF7A079D7DE7DF7DF79B40285E811DA17A46FE85E83F85E7E08DE6E18DE7D11637A04DC8DE93D8DED5F7E37A08257928657988A579B8E579F49E95E83F95E9209DE0619DEEE29DE4919277984A69DE6D3A6779F54B9DE8163E779F6129DE819D6779F6D89DE8399DE7DD7E77A08297AB8697CD8A97B38E978B485A5E49322979852EA5E6D7C6979F653A5E6DA5E979F71AA5E6DDFE979F82B6E686B7A18AB7758EB77892B77E96B7819AB7864EAADE2EBADE4ACADE2D6C2B792C6B798653ADE4B4ADE61ADAB7926FDADE61F7EB79B82D6CA86D6DA8AD6E68ED76692D7694A6B5DC27B5DD5426D77854BB5DFACB5E016BAD781BED786612B5E073B5E1B4B5E05AE2D78673DB5E2DF7ED79282F6B386F6BA8AF6C68EF6D192F6DB96F6E14C7BDB9A8BDD9A9BDD9EABDDA2BBDD9D63AF7695F0BDDC31BDDD72BDDC19D6F775DAF7706F9BDDD5D6EF778F2F77EF6F780FAF781FEF78683169887169F8B16A68F16B39316B99716BE9B16C59F16C6A316CAA716D1AB16D6AF16D7B316DAB716D75CFC5B8184716E1CB16E0CF16E1695C5B9B6C5D6DBE316E6E7175BEB1760EF1766F31767F71769FB1795FF17758336788736848B36908F369693369B97369F9B36A54E8CDAAE9CDABEACDAC2BCDADD63736B9BB36BD5F0CDAE98CF36BED336C1D736C5DB36C1DF36C5719CDB1BACDB2BBCDB5FCCDB6BDCDB83ECDB9BFCDD820D52161D59B22D59CE3D59DE4D59FA5D5A126D5A327D5A414275692AB569556DD5A6573F569EC3569BC7569FCB56A3CF56A4D356A36B7D5A978D5A9B9D5AABAD5ABFBD5AD3CD5ADFDD5AF7ED5B17FD5B460DCF7A1DD00A2DD0B63DD1524DD2825DD2F26DD9B67DD9CA8DD9D29DD9DAADD9DEBDD9E2CDD9EEDDD9E973F767E611DDA0594F7682D37684D776856D7DDA238DDA379DDA43ADDA4BBDDA5BCDDA6BDDDA7FEDDA9BFDDACE0E4D121E4DB62E4E323E4EB64E4F0E5E500A6E500E7E50B68E50B94AB9453AF9454B394705AFE521584794A0CB94A1675E52F36E59B37E59B78E59BB9E59CBAE59D3BE59DBCE59FBDE5A17EE5A43FE5A620ECA8A1ECB362ECBA23ECC0E4ECC5E5ECD5E6ECDB67ECDFA8ECE329ECE36AECE6ABECE6ECECEB6DECEB9743B3C3632ECF7B3ECF7DA57B3EEDBB3EFDFB402E3B403E7B419EBB42EEFB46FF3B485F7B4BCFBB673FFB67A83D25387D2748BD2808FD29093D2A297D2BB4C7F4B368F4B614AFD2E8B3D303B7D316BBD3045F0F4C5B1F4C5D94FD343695F4D11B5FD357E3D36DE7D37EEBD38CEFD39AF3D3C3F7D3EFFBD42EFFD40583F22487F2318BF240464FC9425FC9466FC9953A3F27452BFCA01647F290653FCA8B4FCAEF5FCA8DB5FF2BBE3F2CDE7F2D875BFCBA3CFCC5BDFCD5FEFCE33FFCF0C0";
        }

        revert("invalid background");
    }
}

library ClothingSprites {
    function getSprite(Clothing v) external pure returns (bytes memory) {
        if (v == Clothing.NONE) {
            return hex"";
        }

        if (v == Clothing.AMETHYST_ARMOR) {
            return hex"81159AA32004DF20049F4004A34A86A74004DB4004DF4A86E340049B60049F6A86509DB37152F6004695D8011B5F6CDCE36A86E760049780049B8A864E8E33729E001152F8CDC593E0011A578CDCDB80046F8E33739E2A1BAE00124E801129BAA869FACDCA3A004A7ACDCABB5D5AFB8AAB3B5D5B7ACDCBBA0045F0EAA1B1E80132EAA1B3ED7574EE2A9ADBB5D5DFA004719EB373AEAA1BBE801121BC0049FD5D5A3D8AA52AF3372BF5756CF62AADF3496EF23657C3CD25C7C004CBCAACCFCD06D3D5D56B6F33737F62AB8F5755CEFC0048FE004485FAA1931FECDCA3F5D5A7F8AAABF5D5AFECDC58DF8012EFB4957C3ED06C7ED25653F80134FAA1B5FD7576FE2AB7FD755C67ECDC75BFAA1BCF8010";
        }

        if (v == Clothing.THUNDERDOME_ARMOR) {
            return hex"445B8011D76E0048F0004485C451131F0004719C0011D6F1144F30004932004972C1B4C7CC5128C80137C8011C673144EB2C1BEF20049740044C7D306E8D33F29D00136D00137D33F1C674C1BEB4004428D80129D8AA6AD80135D80136D9095BFB60048B8004465E45126E00113A38425A782A9AB80D9AF8004D38004D780D9DB82A96F8E10979E0011D739144F780048FA004485EB06E6E80127E90968E8AA54ABA0D9AFA004D3A0046B6E83677E8AA78E90979E8011D6FAC1BF3A004485F00126F10967F0AA5427C0D9555F0011B5FC0D9E3C2A9E7C42575BF00123F801121BE2A94E8F83669F8012AF8366BF8012CF8366DF8012EF83657C3E004C7E0D9CBE004CFE0D9D3E004D7E0D9DBE0046F8F8365CEFE2A9F3E0040";
        }

        if (v == Clothing.FLEET_UNIFORM__BLUE) {
            return hex"4C7B8011C66E0049B00049F00D2A30004DF0004E300D2E700049B20049F205BA321E9A72004DB2004DF220EE3205BE720049B40044E8D016E9D0D2952F4004695D00136D0D29BE3405BE740049B60044E9D816EAD8D2ABD9D7D6376004653D80134D9D7F5D8D29B63605BE76004467E001142F805BB3875FB7834ABB8004C78004CB834ACF875F697E016DC7380048BA0048FA75F486E843A7E816E8E80114B3A05BB7A75FBBA004C7A004CBA75F676E816F7E80138E816DCEFA10EF3A75FF7A00487C0048BC75F8FC10E93C1AF4A8F016D4ABC00456CF016EDF1D7D747C004CBC75F674F016DADBC0046FAF016FBF06BFCF043BDF1D7FEF00121F80122F816E3F8D2A4F816E5F86BD323E10E52AF816D5B3E004B7E75F5D1F80132F9D7D9D3E0046B6F816DBE7E10EEBE1AFEFE05BF3E34AF7E05BFBE004";
        }

        if (v == Clothing.BANANITE_SHIRT) {
            return hex"4E8C8011BE320049B40049F5823A34B7CA74004DB4004DF4B7CE35823E740049760049B6B7C4E8DE08E9DADF152F6004695D8011B676B7CEB60049780049B8B7C4E8E608D4AF8B7CB38004CF8004695E2DF1B5F9823719E2DF3AE00124E801129BAB7C4E8EE08D4B3AB7CB7A004CBA004676EADF1BE3B82373AEADF3BE80124F00125F2DF131FD82350AF2DF15B3D823B7CB7C5D1F00132F608D9DBCB7C6F8F608DCEBCB7CEFC0048FE004488FADF29F801152FEB7C58DFE08D747EB7C653FE08DA57EB7CDBE0046F8FE08DCEBEB7CEFF823F3E004";
        }

        if (v == Clothing.EXPLORER) {
            return hex"4E8C8011BE320049B40044E8D297A9D00136D0011BE34A5EE740049B690B4E9DAD5D52F6004695D8011B636B57E768889780049B8B579F8A06509E32EEAE0012BE2DD564F8004D38B75D780046D7E32EF8E281B9E2D5FAE00124E80125EA97A6EAD5E7EB2EE8EA81A9EB2EEAE8012BEBD92CEB33ADED0E6EEB3397C3B8AAC7ACCECBB439CFACCED3AF64D7A004DBACBBDFAA06E3ACBB73AEAD5FBE80124F00125F2D5D31FCCBBA3CA06A7CCBBABC004AFCF64B3D439B7CCCEBBD4395F0F333B1F50E72F333B3F50E74F3D935F00136F32EF7F2819C67CCBBEBCB57EFC0048FE00493EA5E97EB574C7FB2EE8FA81A9F8012AFBD915B3F439B7EF64BBECCEBFF439611FB33B2FBD919D3F439D7EF64DBE004DFEA06719FB2EDD6FEB57F3E0040";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__BLUE) {
            return hex"4E8C8011BE320049B40049F4E2DA34005A74004DB4004DF4A09E34E2DE740049760049B6C3D9F6005A36004A762B254BD8011A576004DB62B2DF6004E36005E76C3DEB60044A7E00128E2C0E9E030EAE0012BE22AD6538004D78B036D7E030DC6B800493A00497AE2D9BAA099FA004A3A0C3A7A004ABAF13AFA004B3AA95B7A906BBA004BFAEC4C3A004C7AA09CBA004CFAA09D3AEDCD7A004DBA0C36F8E80139EA827AEB8B7BE80123F00124F28265F00166F00127F28268F00129F27DEAF01455B3C004B7CA95BBCC97BFC9ABC3C004C7C0C3CBCB03CFC004D3C0C3D7CC7DDBC004DFCB03E3C2B2E7C004EBC005EFCA09F3C0048FE00493E00597E0049BEE649FE0C3A3E00452AF8146BF8012CFB802DFA6AEEF8012FFA6AD847E004CBED90CFE004D3E0C3D7EB036D7F80138FBAB79F8017AF8013BF8017CF8010";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__GOLD) {
            return hex"4E8C8011BE320049B40049F54A3A34020A74004DB4004DF4C84E354A3E740049760049B711B9F6020A36004A774A254BD8011A576004DB74A2DF6004E36020E7711BEB60044A7E00128E37769E3452AE0012BE30496538004D78DDD6D7E3451C6B800493A00497B4A39BAC849FA004A3AD14A7A004ABB40FAFA004B3AD18B7ACCCBBA004BFB30EC3A004C7AC84CBA004CFAC84D3B3A4D7A004DBAD146F8E80139EB213AED28FBE80123F00124F32125F00826F00127F32128F00129F35DAAF28495B3C004B7CD18BBD069BFCDEDC3C004C7CD14CBCDDDCFC004D3CD14D7D04EDBC004DFCDDDE3D4A2E7C004EBC020EFCC84F3C0048FE00493E02097E0049BF2989FED14A3E00452AFA84ABF8012CFC976DFB7B6EF8012FFB7B5847E004CBF1C4CFE004D3ED14D7EDDD6D7F80138FCB7B9F8083AF8013BF8083CF8010";
        }

        if (v == Clothing.CYBER_JUMPSUIT) {
            return hex"4E8C8011BE320044A6D00113A3499EA74004DB40046F8D2679CEB4004485D80126DA0B53A36893A76A1754BD8011A576004DB6A176F8DA24F9DA0B7ADA24FBD80124E001129B899E4E8E20B54AF8A17593E0011A5B8A176F8E20B5CEB899EEF8004464E801129BA8939FA99EA3AA1752CEA24D6BBAA175F1E801194FAA17696EA24F7EA85F8EA679CEFA893F3A0048FC00493C99E4A7F20B5433CA175AEF224EFF108F0F00118CFC893697F285DC6BC82DEFC99EF3C0048FE00448AFA24D5BBEA17BFED2DC3E004C7E893654FA85DAEFE893F3E004";
        }

        if (v == Clothing.ENCHANTER_ROBES) {
            return hex"9EE004E2E0049B00049F0095A30004DF0004E30095E700049B20049F205FA32004DF2004E3205FE720049740049B405F9F4004A34095A74004DB4004DF4095E34004E7405FEB40049760049B60309F6045A36004A7609554BD8011A576004DB6095DF6004E36045E76843EB60049780049B80459F8E70A3806AA78004AB8095AF802F593E00134E00BF5E02576E00137E60438E391F9E0117AE00124E80125E80C26E81167EB925427A06A54BE8012CE8256DE817D747A039CBA05FCFA095695E80136E82577EBAAB8E81A9CEBA045EFA00493C00497C0459BC05F9FC06AA3CE87A7CE49ABC095AFC05FB3C004B7CB415D1F00132F2D073F00134F017DADBC095DFC05FE3C06AE7C05FEBC045EFC0048FE00493E03097EE479BE02E9FE06AA3E049A7E06A54BF817ECFBB0ADFE02EEFBB097C3E05FC7EEC2CBF80BCFEEC2695F817F6F82577F81278F81AB9F80BBAFB91FBF8117CF8010";
        }

        if (v == Clothing.HOODIE) {
            return hex"4E8C8011BE320049B40044E8D29AE9D00136D0011BE34A6BE740049760049B60504E9DADE952F6004695D8011B636B7AE7603EEB60049780049B8B7A9F8A19509E334AAE3652BE2DE964F8004D38B7AD78D946D7E334B8E28679E2DEBAE00124E80125EA9AE6EADEA7EB34A8EA8669EB34952FAD94B3AAC0B7AD945D1EAB032EB6533EAB01A5BAD94DFAA19E3ACD273AEADEBBE80124F00125F2DE931FCCD2A3CA19A7CCD254CF3652DF2B02EF36517C3CC32C7CD94CBCAC0676F36537F2865C67CCD2EBCB7AEFC0048FE00493EA6B97EB7A4C7FB34A8FA8669F801153BED945F0FB0C98DBED94DFEA19719FB349D6FEB7AF3E0040";
        }

        if (v == Clothing.SPACESUIT) {
            return hex"9B40049F4B5AA34B34DF4B34E34B5AE740044A6D80113A36FD5A76B34DB6B346F8DBF55CEB60049380044A6E41E27E00114278FD554BE2CD1A578B346D7E3F578E0011CEB9078EF80048FA004486EB2827EC1E28E80114AFAFD5593EACD1A5BAFD5DFA004E3B07873BEB283CE80123F001121BD0789FCCA0A3C00452AF3F555B3C8CF5AEF3F56FF2CD30F37FD8CBCFE1674F33CB5F3F876F3F577F00138F3281CEFD078F3C0048FE004486FB2827FC1E28F80129FAD6AAFA33EBFA8FECFBF56DFA33EEFBF56FFACD30FB7FF1FBF872FB3C99D3F446D7ECF2DBEB5ADFE004E3F07873BFB283CF8010";
        }

        if (v == Clothing.MECHA_ARMOR) {
            return hex"4A8D0011BEB40049360414A8D8A754AB60416B6D8105BEB629DEF60418F804193829D4A8E2EAD4AB829DAF8041D380416B6E0A75BEB8BABEF829DF380418BA0418FA29D485EAEAD31FA6D8509EAEAEAEA35EBE8A76CE80DADE8222EE80117C3A8ADC7A004CBA088CFA036D3A29DD7A8D76D7EAEADC67A6D875BEAEAFCE8A77DE81062F01063F0A764F2EAE5F150531FCBABA3C54152AF2EAEBF235ECF07556BBC0045F0F1B618CBC004CFC1D5D3C8D76B6F2EAF7F1505C67CBABEBC541EFCBABF3C29DF7C0418BE0418FE29D486FAEAE7FA2B68F95069FAEAEAF8A76BFA35ECF87556BBE0045F0F9B618CBE004CFE1D5D3E8D76B6FAEAF7F95078FA2B5CEFEBABF3E29DF7E0410";
        }

        if (v == Clothing.LAB_COAT) {
            return hex"4E8C8011BE320049B40044E8D3F169D00136D0011BE34FC5E740049760049B6EE74E8DC24A9DC00952F6004695D8011B637092E76E56EB60049780049B90929F8F91A391F6A7900254BE49CECE00133E0011A5792736D7E47DB8E3E479E424BAE00124E80125EBF166EC24A7EC7DA8EBE469EC7DAAEC0095B3B273B7A004CBA004676EC9CF7EBE478EC7D9CEBB092EFA00493C00497D0924C7F47DA8F3E469F47DAAF49CEBF4009637D2735D1F001194FD273D3D0026B6F49CF7F3E45C67D1F6EBD092EFC0048FE00493EFC597F0924C7FC7DA8FBE469F801152FF273B3F002B7F2735D1F80132FC9CF3FC009A5BF273DFEF91719FC7D9D6FF092F3E0040";
        }

        if (v == Clothing.FLEET_UNIFORM__RED) {
            return hex"4C7B8011C66E0049B00049F0C79A30004DF0004E30C79E700049B20049F2A7DA32F46A72004DB2004DF2F76E32A7DE720049B40044E8D29F69D472552F4004695D00136D4725BE34A7DE740049B60044E9DA9F6ADC726BDD7B56376004653D80134DD7B75DC725B636A7DE76004467E001142F8A7DB395EDB791C9BB8004C78004CB91C9CF95ED697E29F5C7380048BA0048FB5ED486EB4A27EA9F68E80114B3AA7DB7B5EDBBA004C7A004CBB5ED676EA9F77E80138EA9F5CEFAD28F3B5EDF7A00487C0048BD5ED8FCD2893CECF4A8F29F54ABC00456CF29F6DF57B5747C004CBD5ED674F29F5ADBC0046FAF29F7BF3B3FCF34A3DF57B7EF00121F80122FA9F63FC7264FA9F65FBB3D323ED2852AFA9F55B3E004B7F5ED5D1F80132FD7B59D3E0046B6FA9F5BE7ED28EBEECFEFEA7DF3F1C9F7EA7DFBE004";
        }

        if (v == Clothing.GOLD_ARMOR) {
            return hex"4C8C8011BE72004485D001131F546CA352FAA74004DB4004DF52FA719D51B1D6F40048F6004486DD1B13A36CA2A7746CAB6004D76004DB746C6F8DB289CEF746CF360048B80048F946C485E4BEA6E328A7E51B142B92FAAF8004D380046B7E4BEB8E51B39E3289D6F92FAF3946CF780048BA004464ECBEA5EB28A6ED1B13A3B2FAA7ACA2ABA004AFAB7F593EAE334EADFF5E80136EB289BE3B2FAE7B46CEBACA277CECBEBDE80122F00111A3CCA2A7C004ABCA5F56DF3D8EEF37FAFF26430F37FB1F2E19953CF63D7CA5FDBC0046FCF328BDF0011123E004A7EB7FABECA2AFF3C158DFD1B2EFBD8EFFA76B0FCC031FB28994FF46CD3F3C1D7ECA2DBEB7F6FDF80100";
        }

        if (v == Clothing.ENERGY_ARMOR__BLUE) {
            return hex"4C8C0011BE70004485C801131F2BE6A32004DF2004719CAF99D6F20048F4004486D2F9A7D221A8D2F9A9D00136D00137D2F9B8D2219CEF4BE6F340048B60048F6BE6485DA82A6DA21A7DC7554276A0AAB6004D760046D7DA82B8DC7579DA219D6F6A0AF36BE6F760048B8004464E282A5E221A6E15D13A38A0AA78886AB8004AF885D593E00134E21775E00136E2219BE38A0AE78574EB888677CE282BDE00122E80111A3A886A7A004ABA82E56DEA682EEA3A2FE95D30EC7571EA175953A9A0D7A82EDBA0046FCEA21BDE8011123C004A7C85DABC88656DF2F9AEF2682FF15D30F47571F2219953CBE6D7C886DBC85D6FDF00123F80124FAF9A5FA68131FEA0AA3E9A0A7E886ABEBD9AFEBE6B3EA0AB7EBE6BBE9A0BFE574C3F1D5C7E886CBEBE6CFEA0AD3EBE6D7EBB3DBE886DFE9A0719FA82BAFA683BFAF9BCF80100";
        }

        if (v == Clothing.MISSION_SUIT__BLACK) {
            return hex"4C8C0011BE700049720044C7CABBE8C80137C8011C672AEFEB2004934004974AEF4C8D27929D00136D0011BE749E4EB4AEFEF40048F6004487DA7928DA2269DA18D52F6004695D80136DA18F7DA225C6F69E4F360048B80048F8AEF485E27913278889AB8004AF8863593E00134E218F5E0011B67888975BE2793CE2BBFDE00122E8011193A9E44A6EA2253A3A825A7A004ABA9E4AFA889593EA18F4EA2275EA7936E8011BE3A82573AEA225DF3A9E4F7A004448F00129F206EAF27915BBCAEF5F1F279194FCAEFD3C9E4D7CAEFDBC81B6FDF00123F80124FABBE5FA18E6FA7927FA2268FA0954DBE004DFE825E3E889E7E9E4EBE863EFEAEFF3E004";
        }

        if (v == Clothing.COWBOY) {
            return hex"4E8C8011BE320049B40049F4BE2509D0011B5F4004E34BE2E740049760049B6CB69F6BE2A36004A76C2A54BD8011A576004DB6C2ADF6004E36BE2E76CB6EB60049780049B8CB69F9029A3800452AE2842BE30A964F8004D38E05D78C2ADB8A10DF8004E39029E78CB6EB800493A00497ACB69BB37B9FB1EEA3ABE2A7A004ABAC2A56CEA8416C7AE05653EB0A9A57AA10DBA004DFABE2E3B1EEE7B37BEBACB6EFA00493C00497CCB69BD37B4E8F40A69F2F8AAF0012BF2842CF30AADF284174BCAF3CFCE05D3CAF3D7C004DBCBE26F8F40A79F4DEFAF32DBBF00123F80124FB2D929BF37B9FF1EE509FC0A6AFAF895B3E0045B2FB0A99D3E004D7EBE26D7FC0A78FC7B9CEBF37BEFECB6F3E0040";
        }

        if (v == Clothing.GLITCH_ARMOR) {
            return hex"4E8C8011BE320049B40049F4802A34186A74004DB4004DF4186E34802E740049760049B68024E8D861A9DA00952F6004695D80136DA009BE36186E76802EB60049780044C8E20094AB8186AF8802593E00134E2009ADB81866F9E200BAE00124E80125EA00931FA05EA3A06C52AEA0095D3A1866B6EA00B7E81B1C67A034EBA802EFA00493C00497C8029BC0C29FC2EEA3C0C2A7C065ABC05EAFC802B3C2EE5AEF20097C3C2EE632F200B3F0BBB4F200B5F00D36F01977F030B8F0BBB9F030BAF200BBF00123F80124FA00A5F817A6F830A7F8BBA8F830A9F8A3AAF830ABFA00ACF85F56BBE40B5F0F85F58CBE40BCFE17DD3E802D7E0C2DBE28EDFE0C2E3E2EEE7E0C2EBE05EEFE802F3E0040";
        }

        if (v == Clothing.SHIRT_AND_TIE) {
            return hex"4E8C8011BE320049B40049F40D9A34893A74004DB4004DF4893E340D9E740049760049B68939F6004A360D9A76A1754BD8011A576004DB6A17DF60D9E36004E76893EB60049780044C7E224E8E00129E318952F8A17593E0011A578A17DB8C62DF8004719E224FAE00124E801129FA893A3AA17A7A00454BEB18ACE80116BBB8AA5F0EBC218CBB8AACFA004695EB18B6E80137EA85DC6BA893EFA00493C0044A6F224D3A7CA17ABC00456CF318ADF0012EF3E457C3CB55C7CF91CBC004674F318B5F0011B63CA1773AF224FBF00123F801121BE8934EAFA85EBF8012CFB18ADF8012EFE2A97C3EF08C7F8AACBE004CFEC62D3E0046B8FA85DCEFE893F3E004";
        }

        if (v == Clothing.MARTIAL_SUIT) {
            return hex"448C8011BF720048F40049340739742014C7D20368D040E9D00136D00137D040DC67480DEB4201EF4073F3400493600497603D9B60744E8D841A9D81CD52F6004695D80136D81CF7D8419C676074EB6073EF60049780049B80739F8106509E0E2D52F8103593E0011A578103DB838B6F8E041B9E01CFAE001121BA0049FA073A3A10652AE8E2D5B3A103B7A0045D1EAFCF2E80119D3A103D7A38B6D7E841B8E81CDCEFA00493C00497C9FC4C7F00128F00F69F01D152FC106B3C073B7C1035D1F001194FC073D3C1066B6F01D37F00F5C67C004EBC9FCEFC0048FE00493EBF397E0049BEBF34E8F80129F80F6AF81D2BF841ACF8E2D6BBE1035F0F80118CBE103CFE38BD3E106D7E074DBE03D6F8F80139FAFCFAF8013BFAFCFCF80100";
        }

        if (v == Clothing.ENERGY_ARMOR__RED) {
            return hex"4C9D0011B674004485D801131F6D69A36004A76D6954BD8011A576004DB6D69DF6004719DB5A5D6F60048F8004486E35A67E294E8E35A69E001152F8D69593E0011A578D69DB8004DF8D69E38A5373BE35A7CE00122E80123EB5A5217AC919BAA539FB864509EB24552FA004593EB5A5A57A0046D7EB2478EE1939EA94DD6FAC91F3AD69F7A0048BC004464F32465F294E6F54153A3CC91A7CA53ABC004AFC9C7593F00134F271F5F00136F294DBE3CC91E7D505EBCA5377CF3247DF00122F80111A3EA53A7E004ABE8B456DFADCEEFAB86FFD4170FE1931FA71D953EB73D7E8B4DBE0046FCFA94FDF8010";
        }

        if (v == Clothing.MISSION_SUIT__PURPLE) {
            return hex"4C8C0011BE700049720044C7CBD9A8C80137C8011C672F66EB2004934004974F664C8D354E9D00136D0011BE74D53EB4F66EF40048F6004487DB54E8DAFC69DABC952F6004695D80136DABCB7DAFC5C6F6D53F360048B80048F8F66485E354D3278BF1AB8004AF8AF2593E00134E2BCB5E0011B678BF175BE354FCE3D9BDE00122E8011193AD534A6EAFC53A3A9EFA7A004ABAD53AFABF1593EABCB4EAFC75EB54F6E8011BE3A9EF73AEAFC5DF3AD53F7A004448F00129F2456AF354D5BBCF665F1F354D94FCF66D3CD53D7CF66DBC9156FDF00123F80124FBD9A5FABCA6FB54E7FAFC68FA7BD4DBE004DFE9EFE3EBF1E7ED53EBEAF2EFEF66F3E004";
        }

        revert("invalid clothing");
    }
} 

library EyesSprites {    
    function getSprite(Eyes v) external pure returns (bytes memory) {
        if (v == Eyes.ADORABLE) {
            return hex"56E780118D1E004AA0004AE18AAB20177B618AABA0177C60177CA18AACE0177D218AAD60004AA2004AE38AAB22004B638AABA2004C62004CA38AACE2004D238AAD62004AE58AA58D90012E962AB1962A994E4004D258AAAE78AAB26177B678AABA6177C66177CA78AACE6177D278AA";
        }

        if (v == Eyes.VETERAN) {
            return hex"D54004D16004CD8004C9A004A1C004C5C004A5E004C1E00454F800118D2000454F8801318E2A994E24C1D238AAD6200454F900131962AB291B759D258AA56E9801319E2A994E66DDD278AAAA8004A6A004A2C004";
        }

        if (v == Eyes.SUNGLASSES) {
            return hex"4F88001288801298AC8AA88012B8AC8AC880116BA2B225F0880118CE2B226958801368AC8B788012990012A92C8AB900116364B225D190013292C899D24004D64B22DA4004AA600456C9AC896BA60046339801349AC8B5980115B68004654A0010";
        }

        if (v == Eyes.WHITE_SUNGLASSES) {
            return hex"4F8862AA88E2A94BA2FCA5F08E2A98DA2FCADE38AAA258AA52D94846E962AB1962A995A5211DE58AAA678AA54D9D756E9E2AB19E2A995675D5DA78AA54DA62A995698AA0";
        }

        if (v == Eyes.RED_EYES) {
            return hex"54B78011A55E00456C80012E800131800119D20004AA2004AE38AAB234EC5AE880118CA2004CE34ECD238AAD62004AA400456C962AAD953B2E962AB1962AB2953B19D258AAD64004AE78AA58D9D3B2E9E2AB19E2A994E74ECD278AA0";
        }

        if (v == Eyes.WINK) {
            return hex"6348001318E2A994E20CCD238AAD6200454E900131962AB2906959D258AAC678AA6539869749E2A8";
        }

        if (v == Eyes.CASUAL) {
            return hex"56E800118D20004AA2004AE38AA58D88332E8E2AB18E2A994E20CCD238AAD62004AE58AAB241A55AE962AB1962AB2906959D258AAAE78AA58D98696E9E2AB19E2A994E61A5D278AA";
        }

        if (v == Eyes.CLOSED) {
            return hex"54E900118D640040";
        }

        if (v == Eyes.DOWNCAST) {
            return hex"B9E004C5E00454D80012E80003180001956000454E880018D62000AA400456D90002E900131900119524000D6400456D980119526004";
        }

        if (v == Eyes.HAPPY) {
            return hex"56D880119522004AA4004BA4004C64004D640040";
        }

        if (v == Eyes.BLUE_EYES) {
            return hex"54C800119D60004AE38AAB2275F5AE880118CA2004CE275FD238AAAE58AAB242255AE962AB1962AB2908959D258AAAE78AA58D98B82E9E2AB19E2A994E62E0D278AA";
        }

        if (v == Eyes.HUD_GLASSES) {
            return hex"A1F8A652B7D209635F8A6B9F482C5F4826537E299A59F482DDF8A6A218A652A85AFD5BA10265F0852098D210266B685AFF78629A88D20A98DAFEA8C09AB8DEDD6363662BA37B75F08DAFF18DEDD94E3662D237B7D63026DA36BFDE3482A65482AA5787AE57D2B2568A5AE95F497C25482C657D2CA568A67495F4B595E1F69520AA9D20AB9DF49636768ABA7482C674826539DA2B49DF4B59D2095B69482654A52080";
        }

        if (v == Eyes.DARK_SUNGLASSES) {
            return hex"517800114262004AA29C056C880116BA29C05F18801194E29C06958801368A7037880128900129929E552E400458D929E57424004632929E59D24004D64A796D79001142A600456C9A9E56CE6004D26A796B7980114AA8004AE8A7958EA00118CA8004CE8A79696A0011536A004655A80100";
        }

        if (v == Eyes.NIGHT_VISION_GOGGLES) {
            return hex"5747801143600045D1801FD95E0004A22004A6207FAA2004AE22D858D893E17462004653893E3488B635880136881FF7880114AA4004AE42D858D91D82E900117C2407FC6400465391D83490B61ADA4004AA600456D98B61746600465498B635980115BA8004634A0010";
        }

        if (v == Eyes.BIONIC) {
            return hex"56E800118D20004AA200456E8B79718E2A994E239CD238AAD62004AE4DE5B25586B658AABA4DE5C658AACA439C674962A95BA6DE5C678AA65399FE349E2A80";
        }

        if (v == Eyes.HIVE_GOGGLES) {
            return hex"5936801152DC004593701FDA55C00450978011531E07F5B2781099D5E07F6D7780128800114AE0042B20D6D5AF8010B0835B58CA0042CE0D6D6968010B7800128880114DA2042DE2004A24004A64042AA506056C9010AD9565D7464042CA55976749010B59418369010B7900128980114AA607F56E981097C2607F63498109ADA607FDE600452AA00115BA807F5F0A00118D2807F6B6A00115BAA004634A8010";
        }

        if (v == Eyes.MATRIX_GLASSES) {
            return hex"5177801288001298598EA817C2B805AAC80D92D84096E80D917C20004C61025CA0364CE016AD20364D61025DA05F0DE0004A22004A63663AA2364AE247EB22766B63663BA2806BE23DFC225F0C637B2CA2766CE2767D22806D63025DA25F0DE2004A64004AA4649AE43DFB247FCB657D0BA48095F090013195F43291FF3390F7F49202759598F690012A98012B98F7EC99FF2D9DA2EE98013198013299FF339A03B49A0275980115B68004654A0010";
        }

        if (v == Eyes.BITCOIN_GLASSES) {
            return hex"ADA004B5A004C9A004D1A004A9C004ADCFEDB1C004B5CFEDB9C004C5C004C9CFEDCDC004D1CFEDD5C004A5E00454E7C7AD7C1E0046357C7AF678012A80012B84E8D6360004BA13A3BE0004C60004CA13A367480013584E8F680012A880115B633FCBA2004C62004CA33FC6748CE8F588012A90012B950F16364004BA5483BE4004C64004CA548367490013594FF369001299801153A74835F0980118D67483DA6004AA8004AE9483B28004B69483BA8004C68004CA9483CE8004D29483D68004AEA004B6A004CAA004D2A004";
        }

        if (v == Eyes.GREEN_GLOW) {
            return hex"B8C785D0C78554B39E12C39E156BCE784C0E785C4E786CCE784D0E785D4E784990785A1078452A41E16B41E1AC41E22D41E26E41E1D7C50786C9078867541E1B641E17741E13841E153A12785A5278854B49E2AC49E2ED49E31741278DC5278BC9278ACD278969549E23649E17749E13849E1BA49E12651E16751E1E851E26951E32A51E3EB51E4EC51E496B94795BD4797C14795C54793C94792CD478F69551E37651E27751E23851E1F951E17A51E12559E16659E22759E2E859E42959E4EA59E62B59E76C59E86D59E8AE59E96F59E93059E8F159E7D94D679CD16797D56793D9678EDD678CE16788E56785E96786ED6784F1678591878595878899878C9D8791A18797A5879FA987A6AD87ADB187B1B587B45CF61EDB061ED7161ECF261EBF361EA7461E93561E7B661E5F761E43861E37961E23A61E1FB61E17C61E1110DA78591A78695A78A99A78F9DA798A1A7A1A5A7AAA9A7B6ADA7BFB1A7C4B5A7C85CF69F2B069F27169F1F269F0F369EFB469ED7569EAF669E8B769E5F869E47969E2FA69E21DF1A7858DC78591C78895C78E99C7969DC79FA1C7ACA5C7B8A9C7C5ADC7CDB1C7D4B5C7D95D071F7B171F6F271F5F371F3F471F17571EF3671EBB771E87871E5B971E3FA71E27B71E19E75C7848DE78591E78A95E78F99E79A9DE7A6A1E7B4A5E7C2A9E7D1ADE7DCB1E7E3B5E7E8B9E7E9BDE7EAC1E7EBC5E7E9C9E7E7CDE7E1D1E7D6D5E7C8D9E7BBDDE7ABE1E79DE5E792E9E78DEDE788F1E7858A07858E078892078B9607939A079D9E07ADA207BDA607CCAA07DAAE016BB201A4B601ECBA021FBE07F0C207F1C60231CA0207CE01ABD20161D607D5DA07C4DE07B2E207A3E60796EA078DEE0789F20785F607848627848A27858E278892278C9627959A27A09E27B0A227C2A627D0AA2148AE2F5A58D89D76E8B866F89FD7089FDB18B64D94E275DD22F42D6213EDA27CADE27B9E227A7E62799EA2790EE278AF227867BE89E12291E16391E22491E32591E52691E86791EC6891F0A991F4AA91F7AB93CB6C91D76D9396EE93862F91FDB091FDF19370F291D773938EB493C1B591F7F691F33791EE7891EA7991E67A91E43B91E27C91E1BD91E12299E16399E22499E32599E52699E7E799EBE899F02999F3AA99F72B9BE4D636675DBA6E5ABE67F4C267F5C66DE365399D7749BCB7599F6F699F27799EDB899E9B999E67A99E43B99E27C99E1E2A1E163A1E1A4A1E2A5A1E466A1E6E7A1EA68A1EE69A1F1EAA1F56BA1F82CA1F9ADA1FAEEA1FB2FA1FB70A1FBF1A1FBB2A1FB33A1FA74A1F8B5A1F4B6A1F0F7A1ECB8A1E8F9A1E57AA1E3BBA1E23CA1E17EA1E123A9E1A4A9E2A5A9E3E6A9E5A7A9E8A8A9EC69A9EF6AA9F26BA9F52CA9F76DA9F8AEA9F96FA9F9F0A9FA31A9F9B2A9F933A9F7F4A9F4F5A9F1B6A9EE77A9EA38A9E739A9E4FAA9E2FBA9E21E76A7848AC7848EC78592C78696C78B9AC7919EC79BA2C7A6A6C7B1AAC7BBAEC7C4B2C7CBB6C7D0BAC7D5BEC7D7C2C7D8C6C7D5CAC7CFCEC7CAD2C7C4D6C7B9DAC7ACDEC7A2E2C795E6C78FEAC78877CB1E17DB1E124B9E1A5B9E226B9E367B9E4E8B9E6E9B9E92AB9EB2BB9ECECB9EE6DB9EFAEB9F06FB9F030B9F0B1B9F032B9EF73B9EDF4B9ECB5B9EA36B9E877B9E5B8B9E3F9B9E2FAB9E1DDF2E7849307859707869B078A9F078BA30792A70797AB079EAF07A3B307A8B707ACBB07ABBF07ADC307B0C707ACCB07A9CF07A7D307A2D7079BDB0794DF078FE3078B73AC1E1FBC1E126C9E1A7C9E228C9E2E9C9E3AAC9E52BC9E5ACC9E62DC9E6AEC9E6EFC9E730C9E771C9E732C9E6F3C9E5F4C9E575C9E4B6C9E3B7C9E2B8C9E21CEB27859B47859F4786A3478852AD1E2EBD1E3ACD1E36DD1E42ED1E46FD1E4B0D1E471D1E432D1E473D1E3B4D1E2F5D1E2B6D1E1DBE3478573AD1E113A3678452AD9E1EBD9E1963B67895F0D9E2B1D9E272D9E233D9E274D9E235D9E1F6D9E19BE36784E76785A78785AB878656CE1E12DE1E16EE1E12FE1E170E1E231E1E1995387856B6E1E12BE9E12EE9E16FE9E131E9E133E9E174E9E135E9E140";
        }

        if (v == Eyes.ORANGE_GLOW) {
            return hex"B8D6EAD0D6EA54B3DBA6C3DBA96BCF6E9C0F6EAC4F6EBCCF6E9D0F6EAD4F6E99916EAA116E952A45BAAB45BAEC45BB6D45BBAE45BB17C516EBC916ED67545BAF645BAB745BA7845BA93A136EAA536ED54B4DBBEC4DBC2D4DBC574136F2C536F0C936EFCD36EE6954DBB764DBAB74DBA784DBAFA4DBA6655BAA755BB2855BBA955BC6A55BD2B55BE2C55BDD6B956FABD56FCC156FAC556F8C956F7CD56F469555BCB655BBB755BB7855BB3955BABA55BA655DBAA65DBB675DBC285DBD695DBE2A5DBF6B5DC0AC5DC1AD5DC1EE5DC2AF5DC2705DC2315DC1194D7701D176FCD576F8D976F3DD76F1E176EDE576EAE976EBED76E9F176EA9196EA9596ED9996F19D96F6A196FCA59704A9970BAD9712B19716B597195CF65C6F065C6B165C63265C53365C3B465C27565C0F665BF3765BD7865BCB965BB7A65BB3B65BABC65BA510DB6EA91B6EB95B6EF99B6F49DB6FDA1B706A5B70FA9B71BADB723B1B728B5B72C5CF6DCBB06DCB716DCAF26DC9F36DC8B46DC6B56DC4366DC1F76DBF386DBDB96DBC3A6DBB5DF1B6EA8DD6EA91D6ED95D6F399D6FB9DD704A1D711A5D71DA9D729ADD731B1D738B5D73D5D075D0B175CFF275CEF375CCF475CA7575C83675C4F775C1B875BEF975BD3A75BBBB75BADE75D6E98DF6EA91F6EF95F6F499F6FF9DF70BA1F719A5F726A9F735ADF740B1F747B5F74CB9F74DBDF74EC1F74FC5F74DC9F74BCDF745D1F73AD5F72CD9F71FDDF710E1F702E5F6F7E9F6F2EDF6EDF1F6EA8A16EA8E16ED9216F09616F89A17029E1712A21721A61730AA173EAE0CC0B20D3EB60DBEBA0E23BE1754C21755C60E4ECA0DF8CE0D4CD20CB3D61739DA1728DE1717E21708E616FBEA16F2EE16EEF216EAF616E98636E98A36EA8E36ED9236F19636FA9A37059E3715A23726A63734AA2C72AE37F158D8DBA2E8DF6AF8DD5F08DD6318DF5594E36E8D237EDD62C5EDA372EDE371EE2370CE636FEEA36F5EE36EFF236EB7BE8DBA6295BAA395BB6495BC6595BE6695C1A795C5A895C9A995CDAA95D0AB95FC2C95BA2D95F86E95F5AF95D63095D67195F3F295BA3395F8B495FB3595D0F695CC3795C7B895C3B995BFBA95BD7B95BBBC95BAFD95BA629DBAA39DBB649DBC659DBE669DC1279DC5289DC9299DCCAA9DD02B9DFCD63676E8BA77DFBE7756C27757C677D36539DBA349DFC359DCFF69DCB779DC6F89DC2F99DBFBA9DBD7B9DBBBC9DBB22A5BAA3A5BAE4A5BBE5A5BDA6A5C027A5C3A8A5C7A9A5CAEAA5CE6BA5D12CA5D2ADA5D3EEA5D42FA5D470A5D4F1A5D4B2A5D433A5D374A5D1B5A5CDB6A5C9F7A5C5F8A5C239A5BEBAA5BCFBA5BB7CA5BABEA5BA63ADBAE4ADBBE5ADBD26ADBEE7ADC1E8ADC5A9ADC86AADCB6BADCE2CADD06DADD1AEADD26FADD2F0ADD331ADD2B2ADD233ADD0F4ADCDF5ADCAB6ADC7B7ADC378ADC079ADBE3AADBC3BADBB5E76B6E98AD6E98ED6EA92D6EB96D6F09AD6F69ED700A2D70BA6D716AAD71FAED728B2D72FB6D734BAD739BED73BC2D73CC6D739CAD733CED72ED2D728D6D71EDAD711DED707E2D6FAE6D6F4EAD6ED77CB5BABDB5BA64BDBAE5BDBB66BDBCA7BDBE28BDC029BDC26ABDC46BBDC62CBDC7ADBDC8AEBDC96FBDC930BDC9B1BDC932BDC873BDC734BDC5F5BDC376BDC1B7BDBEF8BDBD39BDBC3ABDBB1DF2F6E99316EA9716EB9B16EF9F16F0A316F7A716FCAB1703AF1708B3170DB71711BB1710BF1712C31715C71711CB170ECF170CD31707D71700DB16F9DF16F4E316F073AC5BB3BC5BA66CDBAE7CDBB68CDBC29CDBCEACDBE6BCDBEECCDBF6DCDBFEECDC02FCDC070CDC0B1CDC072CDC033CDBF34CDBEB5CDBDF6CDBCF7CDBBF8CDBB5CEB36EA9B56EA9F56EBA356ED52AD5BC2BD5BCECD5BCADD5BD6ED5BDAFD5BDF0D5BDB1D5BD72D5BDB3D5BCF4D5BC35D5BBF6D5BB1BE356EA73AD5BA53A376E952ADDBB2BDDBAD63B76EE5F0DDBBF1DDBBB2DDBB73DDBBB4DDBB75DDBB36DDBADBE376E9E776EAA796EAAB96EB56CE5BA6DE5BAAEE5BA6FE5BAB0E5BB71E5BAD95396EA6B6E5BA6BEDBA6EEDBAAFEDBA71EDBA73EDBAB4EDBA75EDBA80";
        }

        if (v == Eyes.RED_GLOW) {
            return hex"B8D50CD0D50C54B3D42EC3D4316BCF50BC0F50CC4F50DCCF50BD0F50CD4F50B99150CA1150B52A45432B45436C4543ED45442E454397C5150DC9150F6754543764543374542F8454313A1350CA5350F54B4D446C4D44AD4D44D7413514C53512C93511CD35106954D43F64D43374D42F84D437A4D42E65543275543A85544295544EA5545AB5546AC554656B9551CBD551EC1551CC5551AC95519CD55166955545365544375543F85543B955433A5542E55D43265D43E75D44A85D45E95D46AA5D47EB5D492C5D4A2D5D4A6E5D4B2F5D4AF05D4AB15D49994D7523D1751ED5751AD97515DD7513E1750FE5750CE9750DED750BF1750C91950C95950F9995139D9518A1951EA59526A9952DAD9534B19538B5953B5CF654F70654F31654EB2654DB3654C34654AF56549766547B76545F86545396543FA6543BB65433C6542D10DB50C91B50D95B51199B5169DB51FA1B528A5B531A9B53DADB545B1B54AB5B54E5CF6D54306D53F16D53726D52736D51346D4F356D4CB66D4A776D47B86D46396D44BA6D43DDF1B50C8DD50C91D50F95D51599D51D9DD526A1D533A5D53FA9D54BADD553B1D55AB5D55F5D07559317558727557737555747552F57550B6754D77754A387547797545BA75443B75435E75D50B8DF50C91F51195F51699F5219DF52DA1F53BA5F548A9F557ADF562B1F569B5F56EB9F56FBDF570C1F571C5F56FC9F56DCDF567D1F55CD5F54ED9F541DDF532E1F524E5F519E9F514EDF50FF1F50C8A150C8E150F92151296151A9A15249E1534A21543A61552AA1560AE0CDBB20D5EB60DF3BA0E5CBE1576C21577C60E75CA0E1ACE0D6CD20CC5D6155BDA154ADE1539E2152AE6151DEA1514EE1510F2150CF6150B86350B8A350C8E350F92351396351C9A35279E3537A23548A63556AA2C88AE379D58D8D422E8DD72F8D5E708D5EB18DB7594E3508D23799D62C6EDA3550DE3540E2352EE63520EA3517EE3511F2350D7BE8D42E29543239543E49544E59546E6954A27954E2895522995562A95592B95E72C95422D95DAEE95B9EF955EB0955EF195B2F295423395DAB495E4F59559769554B7955038954C3995483A9545FB95443C95437D9542E29D43239D43E49D44E59D46E69D49A79D4DA89D51A99D552A9D58AB9DE896367508BA7764BE7578C27579C676E26539D42349DE7359D58769D53F79D4F789D4B799D483A9D45FB9D443C9D43A2A54323A54364A54465A54626A548A7A54C28A55029A5536AA556EBA559ACA55B2DA55C6EA55CAFA55CF0A55D71A55D32A55CB3A55BF4A55A35A55636A55277A54E78A54AB9A5473AA5457BA543FCA5433EA542E3AD4364AD4465AD45A6AD4767AD4A68AD4E29AD50EAAD53EBAD56ACAD58EDAD5A2EAD5AEFAD5B70AD5BB1AD5B32AD5AB3AD5974AD5675AD5336AD5037AD4BF8AD48F9AD46BAAD44BBAD43DE76B50B8AD50B8ED50C92D50D96D5129AD5189ED522A2D52DA6D538AAD541AED54AB2D551B6D556BAD55BBED55DC2D55EC6D55BCAD555CED550D2D54AD6D540DAD533DED529E2D51CE6D516EAD50F77CB5433DB542E4BD4365BD43E6BD4527BD46A8BD48A9BD4AEABD4CEBBD4EACBD502DBD512EBD51EFBD51B0BD5231BD51B2BD50F3BD4FB4BD4E75BD4BF6BD4A37BD4778BD45B9BD44BABD439DF2F50B93150C97150D9B15119F1512A31519A7151EAB1525AF152AB3152FB71533BB1532BF1534C31537C71533CB1530CF152ED31529D71522DB151BDF1516E3151273AC543BBC542E6CD4367CD43E8CD44A9CD456ACD46EBCD476CCD47EDCD486ECD48AFCD48F0CD4931CD48F2CD48B3CD47B4CD4735CD4676CD4577CD4478CD43DCEB350C9B550C9F550DA3550F52AD544ABD5456CD5452DD545EED5462FD54670D54631D545F2D54633D54574D544B5D54476D5439BE3550C73AD542D3A3750B52ADD43ABDD43563B75105F0DD4471DD4432DD43F3DD4434DD43F5DD43B6DD435BE3750BE7750CA7950CAB950D56CE542EDE5432EE542EFE54330E543F1E5435953950C6B6E542EBED42EEED432FED42F1ED42F3ED4334ED42F5ED4300";
        }

        if (v == Eyes.PURPLE_GLOW) {
            return hex"B8D094D0D09454B3C24EC3C2516BCF093C0F094C4F095CCF093D0F094D4F093991094A1109352A44252B44256C4425ED44262E442597C51095C910976754425764425374424F8442513A13094A5309754B4C266C4C26AD4C26D741309CC5309AC93099CD30986954C25F64C25374C24F84C257A4C24E65425275425A85426295426EA5427AB5428AC542856B950A4BD50A6C150A4C550A2C950A1CD509E6955427365426375425F85425B954253A5424E55C25265C25E75C26A85C27E95C28AA5C29EB5C2B2C5C2C2D5C2C6E5C2D2F5C2CF05C2CB15C2B994D70ABD170A6D570A2D9709DDD709BE17097E57094E97095ED7093F1709491909495909799909B9D90A0A190A6A590AEA990B5AD90BCB190C0B590C35CF6431706431316430B2642FB3642E34642CF5642B766429B76427F86427396425FA6425BB64253C6424D10DB09491B09595B09999B09E9DB0A7A1B0B0A5B0B9A9B0C5ADB0CDB1B0D2B5B0D65CF6C36306C35F16C35726C34736C33346C31356C2EB66C2C776C29B86C28396C26BA6C25DDF1B0948DD09491D09795D09D99D0A59DD0AEA1D0BBA5D0C7A9D0D3ADD0DBB1D0E2B5D0E75D0743B31743A727439737437747434F57432B6742F77742C387429797427BA74263B74255E75D0938DF09491F09995F09E99F0A99DF0B5A1F0C3A5F0D0A9F0DFADF0EAB1F0F1B5F0F6B9F0F7BDF0F8C1F0F9C5F0F7C9F0F5CDF0EFD1F0E4D5F0D6D9F0C9DDF0BAE1F0ACE5F0A1E9F09CEDF097F1F0948A10948E109792109A9610A29A10AC9E10BCA210CBA610DAAA10E8AE0B60B20BA3B60BFFBA0C29BE10FEC210FFC60C33CA0C17CE0BA4D20B4DD610E3DA10D2DE10C1E210B2E610A5EA109CEE1098F21094F610938630938A30948E309792309B9630A49A30AF9E30BFA230D0A630DEAA2B0FAE33B858D8C17EE8CD6AF8C40708C40B18CD6194E305FD233A1D62B05DA30D8DE30C8E230B6E630A8EA309FEE3099F230957BE8C24E29425239425E49426E59428E6942C2794302894342994382A943B2B94EDAC9417ED94DBEE94D66F9440B09440F194C1B29417F394E07494EC35943B769436B7943238942E39942A3A9427FB94263C94257D9424E29C25239C25E49C26E59C28E69C2BA79C2FA89C33A99C372A9C3AAB9CEE5636705FBA735BBE7100C27101C673456539C17F49CEDB59C3A769C35F79C31789C2D799C2A3A9C27FB9C263C9C25A2A42523A42564A42665A42826A42AA7A42E28A43229A4356AA438EBA43BACA43D2DA43E6EA43EAFA43EF0A43F71A43F32A43EB3A43DF4A43C35A43836A43477A43078A42CB9A4293AA4277BA425FCA4253EA424E3AC2564AC2665AC27A6AC2967AC2C68AC3029AC32EAAC35EBAC38ACAC3AEDAC3C2EAC3CEFAC3D70AC3DB1AC3D32AC3CB3AC3B74AC3875AC3536AC3237AC2DF8AC2AF9AC28BAAC26BBAC25DE76B0938AD0938ED09492D09596D09A9AD0A09ED0AAA2D0B5A6D0C0AAD0C9AED0D2B2D0D9B6D0DEBAD0E3BED0E5C2D0E6C6D0E3CAD0DDCED0D8D2D0D2D6D0C8DAD0BBDED0B1E2D0A4E6D09EEAD09777CB4253DB424E4BC2565BC25E6BC2727BC28A8BC2AA9BC2CEABC2EEBBC30ACBC322DBC332EBC33EFBC33B0BC3431BC33B2BC32F3BC31B4BC3075BC2DF6BC2C37BC2978BC27B9BC26BABC259DF2F0939310949710959B10999F109AA310A1A710A6AB10ADAF10B2B310B7B710BBBB10BABF10BCC310BFC710BBCB10B8CF10B6D310B1D710AADB10A3DF109EE3109A73AC425BBC424E6CC2567CC25E8CC26A9CC276ACC28EBCC296CCC29EDCC2A6ECC2AAFCC2AF0CC2B31CC2AF2CC2AB3CC29B4CC2935CC2876CC2777CC2678CC25DCEB30949B50949F5095A3509752AD426ABD4276CD4272DD427EED4282FD42870D42831D427F2D42833D42774D426B5D42676D4259BE3509473AD424D3A3709352ADC25ABDC25563B70985F0DC2671DC2632DC25F3DC2634DC25F5DC25B6DC255BE37093E77094A79094AB909556CE424EDE4252EE424EFE42530E425F1E425595390946B6E424EBEC24EEEC252FEC24F1EC24F3EC2534EC24F5EC2500";
        }

        if (v == Eyes.BLUE_GLOW) {
            return hex"B8C91FD0C91F54B3A47AC3A47D6BCE91EC0E91FC4E920CCE91ED0E91FD4E91E99091FA1091E52A4247EB42482C4248AD4248EE424857C50920C909226754248364247F74247B84247D3A1291FA5292254B4A492C4A496D4A4997412927C52925C92924CD29236954A48B64A47F74A47B84A483A4A47A65247E75248685248E95249AA524A6B524B6C524B16B9492FBD4931C1492FC5492DC9492CCD49296955249F65248F75248B85248795247FA5247A55A47E65A48A75A49685A4AA95A4B6A5A4CAB5A4DEC5A4EED5A4F2E5A4FEF5A4FB05A4F715A4E594D6936D16931D5692DD96928DD6926E16922E5691FE96920ED691EF1691F91891F9589229989269D892BA18931A58939A98940AD8947B1894BB5894E5CF6254306253F16253726252736250F4624FB5624E36624C77624AB86249F96248BA62487B6247FC6247910DA91F91A92095A92499A9299DA932A1A93BA5A944A9A950ADA958B1A95DB5A9615CF6A58F06A58B16A58326A57336A55F46A53F56A51766A4F376A4C786A4AF96A497A6A489DF1A91F8DC91F91C92295C92899C9309DC939A1C946A5C952A9C95EADC966B1C96DB5C9725D0725DF1725D32725C33725A347257B5725576725237724EF8724C39724A7A7248FB72481E75C91E8DE91F91E92495E92999E9349DE940A1E94EA5E95BA9E96AADE975B1E97CB5E981B9E982BDE983C1E984C5E982C9E980CDE97AD1E96FD5E961D9E954DDE945E1E937E5E92CE9E927EDE922F1E91F8A091F8E092292092596092D9A09379E0947A20956A60965AA0973AE0841B2084DB60857BA0859BE0989C2098AC6085ACA0858CE0842D2083DD6096EDA095DDE094CE2093DE60930EA0927EE0923F2091FF6091E86291E8A291F8E292292292696292F9A293A9E294AA2295BA62969AA2835AE2ED958D8A706E8B6D2F8A63308A63718B60594E29C1D22EC1D62834DA2963DE2953E22941E62933EA292AEE2924F229207BE8A47A29247E39248A49249A5924BA6924EE79252E89256E9925AEA925DEB93B2AC92706D9377AE9366EF9263709263B1934E32927073937BF493AA75925E369259779254F89250F9924CFA924ABB9248FC92483D9247A29A47E39A48A49A49A59A4BA69A4E679A52689A56699A59EA9A5D6B9BBE963669C1BA6DC2BE698BC2698CC66D826539A70749BB2B59A5D369A58B79A54389A50399A4CFA9A4ABB9A48FC9A4862A247E3A24824A24925A24AE6A24D67A250E8A254E9A2582AA25BABA25E6CA25FEDA2612EA2616FA261B0A26231A261F2A26173A260B4A25EF5A25AF6A25737A25338A24F79A24BFAA24A3BA248BCA247FEA247A3AA4824AA4925AA4A66AA4C27AA4F28AA52E9AA55AAAA58ABAA5B6CAA5DADAA5EEEAA5FAFAA6030AA6071AA5FF2AA5F73AA5E34AA5B35AA57F6AA54F7AA50B8AA4DB9AA4B7AAA497BAA489E76A91E8AC91E8EC91F92C92096C9259AC92B9EC935A2C940A6C94BAAC954AEC95DB2C964B6C969BAC96EBEC970C2C971C6C96ECAC968CEC963D2C95DD6C953DAC946DEC93CE2C92FE6C929EAC92277CB247FDB247A4BA4825BA48A6BA49E7BA4B68BA4D69BA4FAABA51ABBA536CBA54EDBA55EEBA56AFBA5670BA56F1BA5672BA55B3BA5474BA5335BA50B6BA4EF7BA4C38BA4A79BA497ABA485DF2E91E93091F9709209B09249F0925A3092CA70931AB0938AF093DB30942B70946BB0945BF0947C3094AC70946CB0943CF0941D3093CD70935DB092EDF0929E3092573AC2487BC247A6CA4827CA48A8CA4969CA4A2ACA4BABCA4C2CCA4CADCA4D2ECA4D6FCA4DB0CA4DF1CA4DB2CA4D73CA4C74CA4BF5CA4B36CA4A37CA4938CA489CEB291F9B491F9F4920A3492252AD2496BD24A2CD249EDD24AAED24AEFD24B30D24AF1D24AB2D24AF3D24A34D24975D24936D2485BE3491F73AD24793A3691E52ADA486BDA48163B69235F0DA4931DA48F2DA48B3DA48F4DA48B5DA4876DA481BE3691EE7691FA7891FAB892056CE247ADE247EEE247AFE247F0E248B1E2481953891F6B6E247ABEA47AEEA47EFEA47B1EA47B3EA47F4EA47B5EA47C0";
        }

        if (v == Eyes.SKY_GLOW) {
            return hex"B8C57FD0C57F54B395FAC395FD6BCE57EC0E57FC4E580CCE57ED0E57FD4E57E99057FA1057E52A415FEB41602C4160AD4160EE416057C50580C90582675416036415FF7415FB8415FD3A1257FA5258254B49612C49616D496197412587C52585C92584CD25836954960B6495FF7495FB849603A495FA6515FE75160685160E95161AA51626B51636C516316B9458FBD4591C1458FC5458DC9458CCD45896955161F65160F75160B8516079515FFA515FA5595FE65960A75961685962A959636A5964AB5965EC5966ED59672E5967EF5967B05967715966594D6596D16591D5658DD96588DD6586E16582E5657FE96580ED657EF1657F91857F9585829985869D858BA18591A58599A985A0AD85A7B185ABB585AE5CF616C30616BF1616B72616A736168F46167B56166366164776162B86161F96160BA61607B615FFC615F910DA57F91A58095A58499A5899DA592A1A59BA5A5A4A9A5B0ADA5B8B1A5BDB5A5C15CF6970F06970B1697032696F33696DF4696BF56969766967376964786962F969617A69609DF1A57F8DC57F91C58295C58899C5909DC599A1C5A6A5C5B2A9C5BEADC5C6B1C5CDB5C5D25D07175F1717532717433717234716FB5716D76716A377166F871643971627A7160FB71601E75C57E8DE57F91E58495E58999E5949DE5A0A1E5AEA5E5BBA9E5CAADE5D5B1E5DCB5E5E1B9E5E2BDE5E3C1E5E4C5E5E2C9E5E0CDE5DAD1E5CFD5E5C1D9E5B4DDE5A5E1E597E5E58CE9E587EDE582F1E57F8A057F8E058292058596058D9A05979E05A7A205B6A605C5AA05D3AE0118B2013BB6015EBA0173BE05E9C205EAC6017ACA0168CE0143D2010DD605CEDA05BDDE05ACE2059DE60590EA0587EE0583F2057FF6057E86257E8A257F8E258292258696258F9A259A9E25AAA225BBA625C9AA20F8AE2AE958D891E6E89B56F897B30897B7189B3D94E2479D22AA2D620F0DA25C3DE25B3E225A1E62593EA258AEE2584F225807BE895FA2915FE39160A49161A59163A69166E7916AE8916EE99172EA9175EB92AFAC911E6D91B76E91B56F917B70917BB191B3F2911E7391B634928E75917636917177916CF89168F99164FA9162BB9160FC91603D915FA2995FE39960A49961A59963A6996667996A68996E699971EA99756B9AD316366479BA66D8BE65EBC265ECC666D5653991E749AAFB59975369970B7996C389968399964FA9962BB9960FC996062A15FE3A16024A16125A162E6A16567A168E8A16CE9A1702AA173ABA1766CA177EDA1792EA1796FA179B0A17A31A179F2A17973A178B4A176F5A172F6A16F37A16B38A16779A163FAA1623BA160BCA15FFEA15FA3A96024A96125A96266A96427A96728A96AE9A96DAAA970ABA9736CA975ADA976EEA977AFA97830A97871A977F2A97773A97634A97335A96FF6A96CF7A968B8A965B9A9637AA9617BA9609E76A57E8AC57E8EC57F92C58096C5859AC58B9EC595A2C5A0A6C5ABAAC5B4AEC5BDB2C5C4B6C5C9BAC5CEBEC5D0C2C5D1C6C5CECAC5C8CEC5C3D2C5BDD6C5B3DAC5A6DEC59CE2C58FE6C589EAC58277CB15FFDB15FA4B96025B960A6B961E7B96368B96569B967AAB969ABB96B6CB96CEDB96DEEB96EAFB96E70B96EF1B96E72B96DB3B96C74B96B35B968B6B966F7B96438B96279B9617AB9605DF2E57E93057F9705809B05849F0585A3058CA70591AB0598AF059DB305A2B705A6BB05A5BF05A7C305AAC705A6CB05A3CF05A1D3059CD70595DB058EDF0589E3058573AC1607BC15FA6C96027C960A8C96169C9622AC963ABC9642CC964ADC9652EC9656FC965B0C965F1C965B2C96573C96474C963F5C96336C96237C96138C9609CEB257F9B457F9F4580A3458252AD1616BD1622CD161EDD162AED162EFD16330D162F1D162B2D162F3D16234D16175D16136D1605BE3457F73AD15F93A3657E52AD9606BD960163B65835F0D96131D960F2D960B3D960F4D960B5D96076D9601BE3657EE7657FA7857FAB858056CE15FADE15FEEE15FAFE15FF0E160B1E1601953857F6B6E15FABE95FAEE95FEFE95FB1E95FB3E95FF4E95FB5E95FC0";
        }

        if (v == Eyes.RED_LASER) {
            return hex"B8D4F2D0D4F254B3D3C6C3D3C96BCF4F1C0F4F2C4F4F3CCF4F1D0F4F2D4F4F19914F2A114F152A453CAB453CEC453D6D453DAE453D17C514F3C914F5675453CF6453CB7453C78453C93A134F2A534F554B4D3DEC4D3E2D4D3E574134FAC534F8C934F7CD34F66954D3D764D3CB74D3C784D3CFA4D3C66553CA7553D28553DA9553E6A553F2B55402C553FED5563EE55406F5540F0554071554032556533553F1A5554FAD954F6DD54F5E154F4E554F2E954F19574F29974F59D74F8A174FDA57500A97504AD758BB17591B57592B97588BD758AC17589C5758CC97599CD7596D1758DD57500D974FBDD74F9E174F5E574F2E974F3ED74F1F174F29194F29594F59994F99D94FEA19503A595D9A995DFAD95EBB195F7B595E5B995E7BD95DAC195DBC595ECC995F1CD9601D195FCD595F0D995E1DD94FDE194FAE594F5E994F4ED94F2F194F14436D3CA46D3CE56D3DE66D3F276D63A86D77296D7D6A6D88EB6D936C6D942D6D926E6D952F6D89306D8BB16D95F26D94F36D97346D96F56D91F66D81F76D7CF86D65796D3E3A6D3D5DF1B4F28DD4F291D4F595D4FB99D5029DD5D9A1D5F8A5D652A9D66FADD69DB1D6C0B5D6B8B9D69C5F075A53175A83275AEF375B23475ACB575A0F67599F7758B387578F9753F3A753DBB753CDE75D4F18DF4F291F4F795F4FC99F5DD9DF5F6A1F64FA5F697A9F6DCADF772B1F78FB5F78CB9F783BDF773C1F774C5F77FC9F78ACDF789D1F777D5F75DD9F6A8DDF664E1F622E5F5FBE9F4FAEDF4F5F1F4F28A14F28E14F59214F89615009A15E69E162DA21687A616DEAA1788AE1238B2130BB61375BA1365BE17A9C217AAC61363CA1386CE131ED21227D61791DA1762DE16A7E2164CE615F9EA14FAEE14F6F214F2F614F18634F18A34F28E34F59234F99635019A36109E365FA236B1A6377CAA31C1AE37E5B237CCB637DDBA37E9BE37C9C237C4C637E9CA37DBCE37CAD237E4D631C1DA3782DE36D4E23679E63646EA34FDEE34F7F234F37BE8D3C62953CA3953D64953E659564269581A7959A6895B66995E52A95F02B95FDEC9601ED9613AE95FFAF95F7B095F7319600F29613B396013495FD7595F03695E6B795D7B895A0399591BA95663B953DBC953CFD953C629D3CA39D3D649D3E659D64269D85E79D99689DB3E99DE5EA9DF06B9DEBEC9E14AD9E05AE9DFEAF9DF6309DF5F19DFE729E07739E13B49DEBF59DF0769DE7B79DD6B89D9F799D91BA9D663B9D3DBC9D3D22A53CA3A53CE4A53DE5A53FA6A57EA7A59C68A5AF29A5E16AA5EE6BA5DEECA5FE2DA5EE2EA5F52FA5F170A5F1B1A5F472A5EB73A5FDB4A5DEF5A5EEB6A5E377A5B7F8A5A1B9A585BAA53EFBA53D7CA53CBEA53C63AD3CE4AD3DE5AD3F26AD7A67AD9228ADA869ADD8EAAD95ABADEF2CADB4EDADF0AEADED2FADE9F0ADE9B1ADEC32ADEFB3ADB374ADEF35AD95B6ADDB77ADB278AD97B9AD7D3AAD3E3BAD3D5E76B4F18AD4F18ED4F292D4F396D4F89AD5E29ED60EA2D668A6D6AEAAD5F2AED7E0B2D64EB6D78EBAD77ABED76FC2D76EC6D779CAD78ECED64BD2D7E0D6D5F2DAD6C4DED67CE2D644E6D5EEEAD4F577CB53CBDB53C64BD3CE5BD3D66BD3EA7BD64E8BD9169BD3BEABDE5ABBD762CBDB62DBDB1EEBDAA6FBDA470BDA3F1BDAB72BDB3B3BDB934BD7635BDE5B6BD3BF7BD9778BD75B9BD3E3ABD3D1DF2F4F19314F29714F39B14F79F14F8A315E0A714EEAB17C8AF14F0B3166BB71651BB1666BF164AC31643C71660CB1659CF1670D314F0D717C8DB14EEDF15EEE314F873AC53D3BC53C66CD3CE7CD3D68CD3B69CDEFEACD3BABCD7F6CCD83EDCD802ECD7BEFCD7AB0CD7A31CD7AB2CD7FB3CD8734CD7FF5CD3BB6CDEFF7CD3B78CD3D5CEB34F29B54F29F54F3A354EDA757BFAB54EDAF54FBB354FAB75598BB54FEBF54FFC354FEC754FDCB5595CF54FBD354F8D754EDDB57BFDF54EDE354F273AD53C67DD3B68DDEFE9DD3B6ADD3D2BDD3CD63B74F65F0DD3DF1DD3DB2DD3D73DD3DB4DD3D75DD3D36DD3B77DDEFF8DD3B79DD3CA7E53B68E5EFE9E53B6AE53CD5B394F1B794F2BB94F1BF94F2C394F5C794F3654E53CB5E53C76E53B77E5EFF8E53B66ED3B67EDEFE8ED3B6BED3C6EED3CAFED3C71ED3C73ED3CB4ED3C75ED3CB7ED3B78EDEFF9ED3B66F53B67F5EFE8F53B77F53B78F5EFF9F53B65FD3B66FDEFE7FD3B78FD3B79FDEFFAFD3B4";
        }

        if (v == Eyes.BLUE_LASER) {
            return hex"B8C4A0D0C4A054B3927EC392816BCE49FC0E4A0C4E4A1CCE49FD0E4A0D4E49F9904A0A1049F52A41282B41286C4128ED41292E412897C504A1C904A36754128764128374127F8412813A124A0A524A354B49296C4929AD4929D74124A8C524A6C924A5CD24A46954928F64928374927F849287A4927E65128275128A85129295129EA512AAB512BAC512B6D51356E512BEF512C70512BF1512BB25139F3512A9A5544A8D944A4DD44A3E144A2E544A0E9449F9564A09964A39D64A6A164ABA564AEA964B2AD64C658D59362E5932AF5932705932315931F2593A73593AB45935B5592BB6592A775929F85928F959283A59287B5927FC5928246128256128E66129E7612B28612C696140EA61416B614AEC61546D614B2E61462F6141F06141B1614EB2614E736153F4615375614AB6614577612AF8612A396128FA6128BB61283C6127D10DA4A091A4A195A4A599A4AA9DA4D7A1A504A5A550A9A567ADA606B1A607B5A608B9A616BDA573C1A568C5A622C9A607CDA621D1A620D5A603D9A565DDA527E1A4E6E5A4A6E9A4A377C6928237128247128E5712A66712C277140E8714E2971816A718D6B71A02C71A86D71A4EE719B17C5C681C9C6A2CDC6AAD1C6A0D5C659D9C634DDC565E1C514E5C4AAE9C4A4EDC4A179D7127E3792824792965792AA67945A77953A8798129799AEA79AAEB79B02C7AA6ED7AAAEE7A80EF79B13079B1717A75B27A9AB37A9A747A1DF579AE76799FF7798CB87958B97951FA792A3B7928FC7928228128238128E48129A5812BA68145E78159A8819A2981AAAA829A2B82D16C830DED8315EE82FB6F8302B08302F182ED32830FB383093482D4B582B33681AE37819FB8817FF98152BA812A3B81293C81283D8127E18927E28928238928E48929E5892BE68958E789856889A7E98A442A8AC8EB8BADAC8B612D8B962E8BBA2F8B51308B4BF18BBA328B99738B5E348BA8F58AC8F68A80B789AA38899639897F3A892AFB89297C89285EFA249F8A44A08E44A39244A79644D49A45649E4645A246B1A64AD2AA4CF6AE4F88B25004B65161BA4FC6BE4E39C24E38C64FE3CA5161CE4FE4D24F73D64CF6DA4B30DE46BDE24667E645FCEA44E5EE44A4F244A1F6449F8A64A08E64A39264A79664D49A65729E6633A266A9A66AFEAA6D0AAE6C58B2716EB67037BA6FA1BE6E2EC26E0BC66FA0CA7043CE7161D26C58D66D0ADA6B4BDE66B7E26657E665FCEA64E5EE64A4F264A28A84A08E84A19284A59684AC9A854C9E8644A286A5A68A2AAA8C75AE89A5B28F92B68CA5BA8DF0BE8D30C28D31C68DE1CA8C49CE8F88D289A5D68C87DA8A99DE86B6E28666E6855EEA84A9EE84A3F284A0FA849F8EA4A192A4A596A4AA9AA5269EA5FEA2A69CA6A6BEAAA569AEACA6B2A682B6ACEFBAAC6CBEABEFC2ABCCC6AC4ACAACD1CEA682D2ACA6D6A569DAA6C2DEA6A3E2A62EE6A548EAA4A6EEA4A379DA927E2B127E3B12824B12865B129A6B144A7B15868B190A9B1A76AB13AEBB3966CB154ADB2A6AEB22BEFB1AFF0B1B0F1B23BB2B2A6B3B14EF4B39675B13AF6B1A937B195B8B17EF9B1497AB128DDF2C4A0F6C49F92E4A196E4A39AE4A89EE4E8A2E5FDA6E45BAAEAFFAEE4B3B2E6B0B6E6A7BAE69EBEE669C2E66AC6E692CAE6A6CEE6AFD2E4B3D6EAFFDAE45BDEE62DE2E4F7E6E4A6EAE4A277CB927E4C12825C12866C12967C129A8C144E9C1072AC356EBC11A2CC18BEDC1806EC18C2FC18030C180B1C18C72C18533C190F4C11A35C356F6C10737C14978C1299CEB04A2EF049F9B24A19F24A3A323F7A72D09AB2411AF2549B3255FB72560BB2528BF2529C32537C72529CB254BCF2571D3255DD72411DB2D09DF23F7E324A373AC92826D12827D12868D0FDE9D3426AD0FDEBD12A6CD12A2DD1396ED12B2FD12B70D12B31D12AF2D139B3D12A74D129B5D0FDF6D34277D0FDF8D1281CEB449F9F63F7A36D09A763F7AB64A2AF64A158ED92917C364A5C764A4CB64A3CF64A4D364A3D764A2DB63F7DF6D09E363F7E764A09F83F7A38D09A783F7AB84A156CE127EDE1282EE127EFE12830E128F1E128595384A0D7849FDB83F7DF8D09E383F79BA3F79FAD09A3A3F7AFA49FBBA4A0BFA49FC7A49FCFA4A0D3A49FD7A4A0DFA3F7E3AD09E7A3F79BC3F79FCD09A3C3F7DFC3F7E3CD09E7C3F797E3F79BED099FE3F7E3E3F7E7ED09EBE3F70";
        }

        if (v == Eyes.GOLDEN_SHADES) {
            return hex"4F88001288801298DFD2A8DF9AB8CDDEC8C64AD8BB62E8801318801328BB6338CD2B48D03B58DF9B68DFBB788012890012995F8EA94C7EB94436C93B62D9366AE9320D7C24004C64C83CA4F86CE5020D25167D6530DDA54BDDE4004A26004A672C2AA7068AE6E53B26CB4B66BA6BA6AE45F09801319AB9329AF8F39B63349BA4F59C08369CA5F7980129A0012AA3952BA327ECA2E5EDA2B92EA00131A00132A2B933A2EC74A32B75A38D76A0011536A004655A8010";
        }

        if (v == Eyes.HIPSTER_GLASSES) {
            return hex"4CE680118E5A00495C00499D85E9DD17550975F9EA745D55B1D85E5AE745D57C1C004C5D7E7C9D85E674745D5ADDD85EE1D175E5D85EE9C00499E0049DF85E5097801152DE8B058D78012E7A2C17C1F7E76337A2C1A55E0046D77A2C387DF9F97801268001278617A8800114AA0A8556C8272ED82BD2E8272D7C2185E63282BD19D209CB6B682A177822C38845D798001268801278C5D688A2C298AA16A8A72EB8B6A6C8BADED8B51EE8B6A57C2385EC62F4E6538B51F48BD3B58ABD368AA1778801388E17B9880126900127945D68922C14AA4001AE4F4EB24E76B64DA9BA4F4E5F0945D71936A72939D99D24F4ED64A85DA4001DE4004E2585EE640049A60049E77E7A26004A66001AA6A85AE6DA9B26E76B66FC7BA6F4E5F09C5D719B6A594E6FC7D26F4E6B69800779A2C389DF9F9980127A00128A5F9E9A22C152E800458DA22C2EA5F9D7C28004C697E7653A22C1A568004DA88B0DE97E7E28004A2A004A6B85E54BAC5D6CAE17ADADF9F2ADF9F3AE179A56B175DAB7E7DEA004";
        }

        if (v == Eyes.PINCENEZ) {
            return hex"56E800118D20004AA2004AE38AA58D88D66E8E2AB18E2A994E2359D238AAD6200453690012998012A9D3A2B9DDD96366E5EBA7776C677766539B97B49DDDB59D3A369801153A8004635A0010";
        }

        if (v == Eyes.BLUE_SHADES) {
            return hex"4F88001288801298829EA88272B88242C881EED88182E8801318801328818338821F48825B58827368828F78801289001299026AA90232B901DAC90182D9013EE901197C24004C64046CA4067CE4070D2407AD64086DA4099DE4004A26004A66082AA6071AE6059B26048B66038BA60325F0980131980CB2980F339813B4981775981C36982077980129A0012AA015ABA012ACA00DEDA00CAEA00131A00132A00CB3A00EF4A011F5A01576A0011536A004655A8010";
        }

        if (v == Eyes.BLIT_GLASSES) {
            return hex"4F8780127800114260CD4AA000456C84FB16BA07F85F0800118CA13EC67481FE3580011B5E0207E2000450A880115B233EC5AE89FE17C220046328CFB19D227F86B788012A900115B247F85AE94FB17C2400463291FE19D253ECD64004AA600456C99FE16BA73EC5F0980118CA67F86749CFB35980115BA8004634A00100";
        }

        if (v == Eyes.NOUNS_GLASSES) {
            return hex"9DE00452E7C0198D9F006E1E0049A00049E1006A20004A6100654B862A963A00045F0840198CA18AA6758001368401B78001388401B980012788011426300654B8E2A963A20045F08C0198CA38AA67588011B5E3006E22004A6500654B962A963A40045F0940198CA58AA6759001369401A99C01952E78AA58E980117C270066329E2A99D66004DA7006A6900654BA62A963A80045F0A40198CA98AA675A00136A40194BAB006636AC0180";
        }

        if (v == Eyes.SPACE_VISOR) {
            return hex"5177E29A8862994AA0FBB56E832E57C20FBB634832E5ADA0FBBDE18A6A238A6A62FBBAA2CB9AE31FD58D8B19EE8C7F57C22FBBC631FD6538B19F48C7F758B2E768BEEF78E29A8962994AA51E3AE5380B24D375AE94E017C251E3C65380CA4D3767494E01ADA51E3DE58A6A278A652A9C78EB9CE016366D37BA73805F09C78F19CE0194E6D37D273806B69C78F79E29A9A629953E95D4C295D3635A57536A6299556B8A60";
        }

        revert("invalid eyes");
    }
} 

library FurSprites {    
    function getSprite(Fur v) external pure returns (bytes memory) {
        if (v == Fur.BLUE) {
            return hex"5B2380115B100045B2402459D10004A9200456F482470483871482472483859D12091D52004A5400454B50246C503856BD4091C140E163250247350385A554091D94004A1600452A582455B160E15AE58246F5838584560916535838745824755838765824775801286001296024552D80E158D6480D74580E16536480F460385AD98091DD80049DA00450968246A68386B6CBD9635B41E5D06CBDB16C80D94DB41ED1B2F66B668387768247868012770012870246970386A7480D5B5CCE45D175079951CCE4D5D203D9C0E1DDC091E1C0044A778012878246978386A7C80D5D1F41ED5F203D9E0E1DDE09171A7801248001129A10119E0004A2009152A8480D5D2141E6B68480F780247880011CEA1011EE00049220049630119A2BC79E3011A22004A632035558D07B68C80F78801388C04798AF1FA8C047B8801249001259404531E4BC7A24004A652035559507B69480F790011C664BC7EA5011EE40049260049670119A6BC79E7011A26004A660E1AA72035749D07B59C80F69838779801389C04799AF1FA9C047B980124A001129E9011A2800452AA0386BA507964E9203D2941E6B6A03877A0011C6A9011EE80044A7A80128A82454AAA0E156CACBDADAD07AEABFAD7C2B27AC6AFEBCAB41E674ACBD9ADAA0E1DEA09171AA80127B00128B02469B038552ED2F658DB507AEB00117C2D2F7C6C004654B507B5B4BDB6B03877B02478B00127B80128B82469B8386ABCBD95D2F41ED6F2F6DAE0E1DEE091E2E004A30004A700E1AB1203AF12F6593C507B4C4BDB5C480F6C03877C00113A32004A72091AB20E1AF3203593CD07B4CC80F5C83876C8245BE320049B40044E8D02469D0012AD0246BD0386CD480D6CB541ECF5203D340E1D74091DB40046F8D02479D00125D8011327609154BD8012CD83856CB7203CF60E1695D8011B676091EB60049780044C8E02469E038552F8091593E0011A578091DB80E16F9E0247AE00124E801129BA0919FA0E1A3A09152AE8386BEC80D64FAFEBD3B2036B6E83877E82478E8385CEBA091EFA00493C00497C0919BC0E14E8F02454ABC0E156CF4BD96CBD41E674F4BD9ADBC0E16F8F02479F0387AF0247BF00123F8011217E0914CAF8386BFCBD964FF41ED3F2F66B7F83878F82479F8385D6FE091F3E004";
        }

        if (v == Fur.GREEN) {
            return hex"5B2380115B100045B2403A99D10004A9200456F483AB0485DF1483AB2485DD9D120EAD52004A5400454B503AAC505DD6BD40EAC14177632503AB3505DDA5540EAD94004A1600452A583A95B161775AE583AAF585DD84560EA653585DF4583AB5585DF6583AB7580128600129603A952D817758D645057458177653645074605DDAD980EADD80049DA004509683AAA685DEB6C83D635B2D65D06C83F16C50594DB2D6D1B20F6B6685DF7683AB8680127700128703AA9705DEA745055B5CC8B5D174B59951CC8BD5D141D9C177DDC0EAE1C0044A7780128783AA9785DEA7C5055D1F2D6D5F141D9E177DDE0EA71A7801248001129A0F659E0004A200EA52A845055D212D66B6845077803AB880011CEA0F65EE0004922004962F659A2B809E2F65A22004A631415558CB5B68C50778801388BD9798AE03A8BD97B88012490012593D9531E4B80A24004A6514155594B5B694507790011C664B80EA4F65EE4004926004966F659A6B809E6F65A26004A66177AA71415749CB5B59C5076985DF79801389BD9799AE03A9BD97B980124A001129E8F65A2800452AA05DEBA4B5964E9141D292D66B6A05DF7A0011C6A8F65EE80044A7A80128A83A94AAA17756CAC83EDACB5AEABDC97C2B198C6AF72CAB2D6674AC83DADAA177DEA0EA71AA80127B00128B03AA9B05DD52ED20F58DB4B5AEB00117C2D20EC6C004654B4B5B5B483F6B05DF7B03AB8B00127B80128B83AA9B85DEABC83D5D2F2D6D6F20FDAE177DEE0EAE2E004A30004A70177AB1141AF120F593C4B5B4C483F5C45076C05DF7C00113A32004A720EAAB2177AF3141593CCB5B4CC5075C85DF6C83A9BE320049B40044E8D03AA9D0012AD03AABD05DECD45056CB52D6CF5141D34177D740EADB40046F8D03AB9D00125D801132760EA54BD8012CD85DD6CB7141CF6177695D8011B6760EAEB60049780044C8E03AA9E05DD52F80EA593E0011A5780EADB81776F9E03ABAE00124E801129BA0EA9FA177A3A0EA52AE85DEBEC50564FAF72D3B1416B6E85DF7E83AB8E85DDCEBA0EAEFA00493C00497C0EA9BC1774E8F03A94ABC17756CF483D6CBD2D6674F483DADBC1776F8F03AB9F05DFAF03ABBF00123F8011217E0EA4CAF85DEBFC83D64FF2D6D3F20F6B7F85DF8F83AB9F85DDD6FE0EAF3E004";
        }

        if (v == Fur.RED) {
            return hex"5B2380115B100045B2432659D10004A9200456F4B26704BC2314B26724BC219D12C99D52004A5400454B53266C53C216BD4C99C14F0863253267353C21A554C99D94004A1600452A5B2655B16F085AE5B266F5BC218456C996535BC2345B26755BC2365B26775801286001296326552D8F0858D645057458F0865364507463C21AD98C99DD80049DA0045096B266A6BC22B6C83D635B2D65D06C83F16C50594DB2D6D1B20F6B66BC2376B267868012770012873266973C22A745055B5CC8B5D174B59951CC8BD5D141D9CF08DDCC99E1C0044A77801287B26697BC22A7C5055D1F2D6D5F141D9EF08DDEC9971A7801248001129A0F659E0004A20C9952A845055D212D66B684507783267880011CEA0F65EE0004922004962F659A2B809E2F65A22004A631415558CB5B68C50778801388BD9798AE03A8BD97B88012490012593D9531E4B80A24004A6514155594B5B694507790011C664B80EA4F65EE4004926004966F659A6B809E6F65A26004A66F08AA71415749CB5B59C50769BC2379801389BD9799AE03A9BD97B980124A001129E8F65A2800452AA3C22BA4B5964E9141D292D66B6A3C237A0011C6A8F65EE80044A7A80128AB2654AAAF0856CAC83EDACB5AEABDC97C2B198C6AF72CAB2D6674AC83DADAAF08DEAC9971AA80127B00128B32669B3C2152ED20F58DB4B5AEB00117C2D20EC6C004654B4B5B5B483F6B3C237B32678B00127B80128BB2669BBC22ABC83D5D2F2D6D6F20FDAEF08DEEC99E2E004A30004A70F08AB1141AF120F593C4B5B4C483F5C45076C3C237C00113A32004A72C99AB2F08AF3141593CCB5B4CC5075CBC236CB265BE320049B40044E8D32669D0012AD3266BD3C22CD45056CB52D6CF5141D34F08D74C99DB40046F8D32679D00125D80113276C9954BD8012CDBC216CB7141CF6F08695D8011B676C99EB60049780044C8E32669E3C2152F8C99593E0011A578C99DB8F086F9E3267AE00124E801129BAC999FAF08A3AC9952AEBC22BEC50564FAF72D3B1416B6EBC237EB2678EBC21CEBAC99EFA00493C00497CC999BCF084E8F32654ABCF0856CF483D6CBD2D6674F483DADBCF086F8F32679F3C23AF3267BF00123F8011217EC994CAFBC22BFC83D64FF2D6D3F20F6B7FBC238FB2679FBC21D6FEC99F3E004";
        }

        if (v == Fur.BLACK) {
            return hex"5B2380115B100045B2423F59D10004A9200456F4A3F704A7D714A3F724A7D59D128FDD52004A5400454B523F6C527D56BD48FDC149F5632523F73527D5A5548FDD94004A1600452A5A3F55B169F55AE5A3F6F5A7D584568FD6535A7D745A3F755A7D765A3F77580128600129623F552D89F558D6480574589F5653648074627D5AD988FDDD80049DA0045096A3F6A6A7D6B6CBC9635B41C5D06CBCB16C80594DB41CD1B2F26B66A7D776A3F78680127700128723F69727D6A748055B5CCE25D175071951CCE2D5D201D9C9F5DDC8FDE1C0044A77801287A3F697A7D6A7C8055D1F41CD5F201D9E9F5DDE8FD71A7801248001129A100F9E0004A208FD52A848055D2141C6B6848077823F7880011CEA100FEE000492200496300F9A2BC59E300FA22004A632015558D07368C80778801388C03F98AF17A8C03FB8801249001259403D31E4BC5A24004A6520155595073694807790011C664BC5EA500FEE400492600496700F9A6BC59E700FA26004A669F5AA72015749D07359C80769A7D779801389C03F99AF17A9C03FB980124A001129E900FA2800452AA27D6BA507164E9201D2941C6B6A27D77A0011C6A900FEE80044A7A80128AA3F54AAA9F556CACBCADAD072EABFA57C2B278C6AFE9CAB41C674ACBC9ADAA9F5DEA8FD71AA80127B00128B23F69B27D552ED2F258DB5072EB00117C2D2F3C6C004654B50735B4BCB6B27D77B23F78B00127B80128BA3F69BA7D6ABCBC95D2F41CD6F2F2DAE9F5DEE8FDE2E004A30004A709F5AB1201AF12F2593C50734C4BCB5C48076C27D77C00113A32004A728FDAB29F5AF3201593CD0734CC8075CA7D76CA3F5BE320049B40044E8D23F69D0012AD23F6BD27D6CD48056CB541CCF5201D349F5D748FDDB40046F8D23F79D00125D801132768FD54BD8012CDA7D56CB7201CF68FD695D8011B6768FDEB60049780044C8E23F69E27D552F88FD593E0011A5788FDDB89F56F9E23F7AE00124E801129BA8FD9FA9F5A3A8FD52AEA7D6BEC80564FAFE9D3B2016B6EA7D77EA3F78EA7D5CEBA8FDEFA00493C00497C8FD9BC9F54E8F23F54ABC9F556CF4BC96CBD41C674F4BC9ADBC9F56F8F23F79F27D7AF23F7BF00123F8011217E8FD4CAFA7D6BFCBC964FF41CD3F2F26B7FA7D78FA3F79FA7D5D6FE8FDF3E004";
        }

        if (v == Fur.BROWN) {
            return hex"5B2380115B100045B242E159D10004A9200456F4AE1704B3B314AE1724B3B19D12B85D52004A5400454B52E16C533B16BD4B85C14CEC63252E173533B1A554B85D94004A1600452A5AE155B16CEC5AE5AE16F5B3B18456B856535B3B345AE1755B3B365AE17758012860012962E1552D8CEC58D648057458CEC653648074633B1AD98B85DD80049DA0045096AE16A6B3B2B6CBC9635B41C5D06CBCB16C80594DB41CD1B2F26B66B3B376AE17868012770012872E169733B2A748055B5CCE25D175071951CCE2D5D201D9CCECDDCB85E1C0044A77801287AE1697B3B2A7C8055D1F41CD5F201D9ECECDDEB8571A7801248001129A100F9E0004A20B8552A848055D2141C6B684807782E17880011CEA100FEE000492200496300F9A2BC59E300FA22004A632015558D07368C80778801388C03F98AF17A8C03FB8801249001259403D31E4BC5A24004A6520155595073694807790011C664BC5EA500FEE400492600496700F9A6BC59E700FA26004A66CECAA72015749D07359C80769B3B379801389C03F99AF17A9C03FB980124A001129E900FA2800452AA33B2BA507164E9201D2941C6B6A33B37A0011C6A900FEE80044A7A80128AAE154AAACEC56CACBCADAD072EABFA57C2B278C6AFE9CAB41C674ACBC9ADAACECDEAB8571AA80127B00128B2E169B33B152ED2F258DB5072EB00117C2D2F3C6C004654B50735B4BCB6B33B37B2E178B00127B80128BAE169BB3B2ABCBC95D2F41CD6F2F2DAECECDEEB85E2E004A30004A70CECAB1201AF12F2593C50734C4BCB5C48076C33B37C00113A32004A72B85AB2CECAF3201593CD0734CC8075CB3B36CAE15BE320049B40044E8D2E169D0012AD2E16BD33B2CD48056CB541CCF5201D34CECD74B85DB40046F8D2E179D00125D80113276B8554BD8012CDB3B16CB7201CF6CEC695D8011B676B85EB60049780044C8E2E169E33B152F8B85593E0011A578B85DB8CEC6F9E2E17AE00124E801129BAB859FACECA3AB8552AEB3B2BEC80564FAFE9D3B2016B6EB3B37EAE178EB3B1CEBAB85EFA00493C00497CB859BCCEC4E8F2E154ABCCEC56CF4BC96CBD41C674F4BC9ADBCCEC6F8F2E179F33B3AF2E17BF00123F8011217EB854CAFB3B2BFCBC964FF41CD3F2F26B7FB3B38FAE179FB3B1D6FEB85F3E004";
        }

        if (v == Fur.SILVER) {
            return hex"5B2380115B100045B2445F59D10004A9200456F4C5F704E2AB14C5F724E2A99D1317DD52004A5400454B545F6C562A96BD517DC158AA632545F73562A9A55517DD94004A1600452A5C5F55B178AA5AE5C5F6F5E2A9845717D6535E2AB45C5F755E2AB65C5F77580128600129645F552D98AA58D6481974598AA6536481B4662A9AD9917DDD80049DA0045096C5F6A6E2AAB6CB11635B3BA5D06CB1316C81994DB3BAD1B2C46B66E2AB76C5F78680127700128745F69762AAA748195B5CCE25D174EE9951CCE2D5D206D9D8AADDD17DE1C0044A77801287C5F697E2AAA7C8195D1F3BAD5F206D9F8AADDF17D71A7801248001129A103F9E0004A2117D52A848195D213BA6B68481B7845F7880011CEA103FEE000492200496303F9A2CA49E303FA22004A632065558CEEB68C81B78801388C0FF98B293A8C0FFB880124900125940FD31E4CA4A24004A6520655594EEB69481B790011C664CA4EA503FEE400492600496703F9A6CA49E703FA26004A678AAAA72065749CEEB59C81B69E2AB79801389C0FF99B293A9C0FFB980124A001129E903FA2800452AA62AABA4EE964E9206D293BA6B6A62AB7A0011C6A903FEE80044A7A80128AC5F54AAB8AA56CACB12DACEEAEAC1357C2B26DC6B04DCAB3BA674ACB11ADAB8AADEB17D71AA80127B00128B45F69B62A952ED2C458DB4EEAEB00117C2D2C3C6C004654B4EEB5B4B136B62AB7B45F78B00127B80128BC5F69BE2AAABCB115D2F3BAD6F2C4DAF8AADEF17DE2E004A30004A718AAAB1206AF12C4593C4EEB4C4B135C481B6C62AB7C00113A32004A7317DAB38AAAF3206593CCEEB4CC81B5CE2AB6CC5F5BE320049B40044E8D45F69D0012AD45F6BD62AACD48196CB53BACF5206D358AAD7517DDB40046F8D45F79D00125D8011327717D54BD8012CDE2A96CB7206CF78AA695D8011B67717DEB60049780044C8E45F69E62A952F917D593E0011A57917DDB98AA6F9E45F7AE00124E801129BB17D9FB8AAA3B17D52AEE2AABEC81964FB04DD3B2066B6EE2AB7EC5F78EE2A9CEBB17DEFA00493C00497D17D9BD8AA4E8F45F54ABD8AA56CF4B116CBD3BA674F4B11ADBD8AA6F8F45F79F62ABAF45F7BF00123F8011217F17D4CAFE2AABFCB1164FF3BAD3F2C46B7FE2AB8FC5F79FE2A9D6FF17DF3E004";
        }

        if (v == Fur.PURPLE) {
            return hex"5B2380115B100045B242B359D10004A9200456F4AB3704AFCF14AB3724AFCD9D12ACDD52004A5400454B52B36C52FCD6BD4ACDC14BF363252B37352FCDA554ACDD94004A1600452A5AB355B16BF35AE5AB36F5AFCD8456ACD6535AFCF45AB3755AFCF65AB37758012860012962B3552D8BF358D645057458BF365364507462FCDAD98ACDDD80049DA0045096AB36A6AFCEB6C83D635B2D65D06C83F16C50594DB2D6D1B20F6B66AFCF76AB37868012770012872B36972FCEA745055B5CC8B5D174B59951CC8BD5D141D9CBF3DDCACDE1C0044A77801287AB3697AFCEA7C5055D1F2D6D5F141D9EBF3DDEACD71A7801248001129A0F659E0004A20ACD52A845055D212D66B684507782B37880011CEA0F65EE0004922004962F659A2B809E2F65A22004A631415558CB5B68C50778801388BD9798AE03A8BD97B88012490012593D9531E4B80A24004A6514155594B5B694507790011C664B80EA4F65EE4004926004966F659A6B809E6F65A26004A66BF3AA71415749CB5B59C50769AFCF79801389BD9799AE03A9BD97B980124A001129E8F65A2800452AA2FCEBA4B5964E9141D292D66B6A2FCF7A0011C6A8F65EE80044A7A80128AAB354AAABF356CAC83EDACB5AEABDC97C2B198C6AF72CAB2D6674AC83DADAABF3DEAACD71AA80127B00128B2B369B2FCD52ED20F58DB4B5AEB00117C2D20EC6C004654B4B5B5B483F6B2FCF7B2B378B00127B80128BAB369BAFCEABC83D5D2F2D6D6F20FDAEBF3DEEACDE2E004A30004A70BF3AB1141AF120F593C4B5B4C483F5C45076C2FCF7C00113A32004A72ACDAB2BF3AF3141593CCB5B4CC5075CAFCF6CAB35BE320049B40044E8D2B369D0012AD2B36BD2FCECD45056CB52D6CF5141D34BF3D74ACDDB40046F8D2B379D00125D80113276ACD54BD8012CDAFCD6CB7141CF6BF3695D8011B676ACDEB60049780044C8E2B369E2FCD52F8ACD593E0011A578ACDDB8BF36F9E2B37AE00124E801129BAACD9FABF3A3AACD52AEAFCEBEC50564FAF72D3B1416B6EAFCF7EAB378EAFCDCEBAACDEFA00493C00497CACD9BCBF34E8F2B354ABCBF356CF483D6CBD2D6674F483DADBCBF36F8F2B379F2FCFAF2B37BF00123F8011217EACD4CAFAFCEBFC83D64FF2D6D3F20F6B7FAFCF8FAB379FAFCDD6FEACDF3E004";
        }

        if (v == Fur.PINK) {
            return hex"5B2380115B100045B243EAD9D10004A9200456F4BEAF04C88B14BEAF24C8899D12FABD52004A5400454B53EAEC548896BD4FABC1522263253EAF354889A554FABD94004A1600452A5BEAD5B172225AE5BEAEF5C8898456FAB6535C88B45BEAF55C88B65BEAF758012860012963EAD52D922258D64C31745922265364C33464889AD98FABDD80049DA0045096BEAEA6C88AB6CF29635B4875D06CF2B16CC3194DB487D1B3CA6B66C88B76BEAF868012770012873EAE97488AA74C315B5CF105D17521D951CF10D5D30CD9D222DDCFABE1C0044A77801287BEAE97C88AA7CC315D1F487D5F30CD9F222DDEFAB71A7801248001129A11B89E0004A20FAB52A84C315D214876B684C33783EAF880011CEA11B8EE00049220049631B89A2DFD9E31B8A22004A6330C5558D21F68CC3378801388C6E398B7F7A8C6E3B880124900125946E131E4DFDA24004A6530C5559521F694C33790011C664DFDEA51B8EE40049260049671B89A6DFD9E71B8A26004A67222AA730C5749D21F59CC3369C88B79801389C6E399B7F7A9C6E3B980124A001129E91B8A2800452AA488ABA521D64E930CD294876B6A488B7A0011C6A91B8EE80044A7A80128ABEAD4AAB22256CACF2ADAD21EEAC6917C2B376C6B1A4CAB487674ACF29ADAB222DEAFAB71AA80127B00128B3EAE9B488952ED3CA58DB521EEB00117C2D3CBC6C004654B521F5B4F2B6B488B7B3EAF8B00127B80128BBEAE9BC88AABCF295D2F487D6F3CADAF222DEEFABE2E004A30004A71222AB130CAF13CA593C521F4C4F2B5C4C336C488B7C00113A32004A72FABAB3222AF330C593CD21F4CCC335CC88B6CBEADBE320049B40044E8D3EAE9D0012AD3EAEBD488ACD4C316CB5487CF530CD35222D74FABDB40046F8D3EAF9D00125D80113276FAB54BD8012CDC8896CB730CCF7222695D8011B676FABEB60049780044C8E3EAE9E488952F8FAB593E0011A578FABDB92226F9E3EAFAE00124E801129BAFAB9FB222A3AFAB52AEC88ABECC3164FB1A4D3B30C6B6EC88B7EBEAF8EC889CEBAFABEFA00493C00497CFAB9BD2224E8F3EAD4ABD22256CF4F296CBD487674F4F29ADBD2226F8F3EAF9F488BAF3EAFBF00123F8011217EFAB4CAFC88ABFCF2964FF487D3F3CA6B7FC88B8FBEAF9FC889D6FEFABF3E004";
        }

        if (v == Fur.SEANCE) {
            return hex"5B2380115B100045B242B359D10004A9200456F4AB3704AFCF14AB3724AFCD9D12ACDD52004A5400454B52B36C52FCD6BD4ACDC14BF363252B37352FCDA554ACDD94004A1600452A5AB355B16BF35AE5AB36F5AFCD8456ACD6535AFCF45AB3755AFCF65AB37758012860012962B3552D8BF358D63D897458BF365363D8B462FCDAD98ACDDD80049DA0045096AB36A6AFCEB6C19D635B1DD5D06C19F16BD8994DB1DDD1B0676B66AFCF76AB37868012770012872B36972FCEA73D895B5CC535D174775951CC53D5CF62D9CBF3DDCACDE1C0044A77801287AB3697AFCEA7BD895D1F1DDD5EF62D9EBF3DDEACD71A7801248001129A0ED79E0004A20ACD52A83D895D211DD6B683D8B782B37880011CEA0ED7EE0004922004962ED79A2B389E2ED7A22004A62F625558C77768BD8B78801388BB5F98ACE3A8BB5FB88012490012593B5D31E4B38A24004A64F6255594777693D8B790011C664B38EA4ED7EE4004926004966ED79A6B389E6ED7A26004A66BF3AA6F625749C77759BD8B69AFCF79801389BB5F99ACE3A9BB5FB980124A001129E8ED7A2800452AA2FCEBA477564E8F62D291DD6B6A2FCF7A0011C6A8ED7EE80044A7A80128AAB354AAABF356CAC19EDAC776EAB5017C2AFD2C6AD40CAB1DD674AC19DADAABF3DEAACD71AA80127B00128B2B369B2FCD52ED06758DB4776EB00117C2D05AC6C004654B47775B419F6B2FCF7B2B378B00127B80128BAB369BAFCEABC19D5D2F1DDD6F067DAEBF3DEEACDE2E004A30004A70BF3AB0F62AF1067593C47774C419F5C3D8B6C2FCF7C00113A32004A72ACDAB2BF3AF2F62593CC7774CBD8B5CAFCF6CAB35BE320049B40044E8D2B369D0012AD2B36BD2FCECD3D896CB51DDCF4F62D34BF3D74ACDDB40046F8D2B379D00125D80113276ACD54BD8012CDAFCD6CB6F62CF6BF3695D8011B676ACDEB60049780044C8E2B369E2FCD52F8ACD593E0011A578ACDDB8BF36F9E2B37AE00124E801129BAACD9FABF3A3AACD52AEAFCEBEBD8964FAD40D3AF626B6EAFCF7EAB378EAFCDCEBAACDEFA00493C00497CACD9BCBF34E8F2B354ABCBF356CF419D6CBD1DD674F419DADBCBF36F8F2B379F2FCFAF2B37BF00123F8011217EACD4CAFAFCEBFC19D64FF1DDD3F0676B7FAFCF8FAB379FAFCDD6FEACDF3E004";
        }

        if (v == Fur.TURQUOISE) {
            return hex"5B2380115B100045B2404819D10004A9200456F484830488371484832488359D12120D52004A5400454B50482C508356BD4120C1420D63250483350835A554120D94004A1600452A584815B1620D5AE58482F5883584561206535883745848355883765848375801286001296048152D820D58D64811745820D65364813460835AD98120DD80049DA00450968482A68836B6CBE1635B41F5D06CBE316C81194DB41FD1B2F86B668837768483868012770012870482970836A748115B5CCE55D17507D951CCE5D5D204D9C20DDDC120E1C0044A778012878482978836A7C8115D1F41FD5F204D9E20DDDE12071A7801248001129A10129E0004A2012052A848115D2141F6B684813780483880011CEA1012EE00049220049630129A2BC89E3012A22004A632045558D07F68C81378801388C04B98AF23A8C04BB8801249001259404931E4BC8A24004A652045559507F694813790011C664BC8EA5012EE40049260049670129A6BC89E7012A26004A6620DAA72045749D07F59C81369883779801389C04B99AF23A9C04BB980124A001129E9012A2800452AA0836BA507D64E9204D2941F6B6A08377A0011C6A9012EE80044A7A80128A84814AAA20D56CACBE2DAD07EEABFB17C2B27BC6AFECCAB41F674ACBE1ADAA20DDEA12071AA80127B00128B04829B083552ED2F858DB507EEB00117C2D2F9C6C004654B507F5B4BE36B08377B04838B00127B80128B84829B8836ABCBE15D2F41FD6F2F8DAE20DDEE120E2E004A30004A7020DAB1204AF12F8593C507F4C4BE35C48136C08377C00113A32004A72120AB220DAF3204593CD07F4CC8135C88376C8481BE320049B40044E8D04829D0012AD0482BD0836CD48116CB541FCF5204D3420DD74120DB40046F8D04839D00125D8011327612054BD8012CD88356CB7204CF620D695D8011B676120EB60049780044C8E04829E083552F8120593E0011A578120DB820D6F9E0483AE00124E801129BA1209FA20DA3A12052AE8836BEC81164FAFECD3B2046B6E88377E84838E8835CEBA120EFA00493C00497C1209BC20D4E8F04814ABC20D56CF4BE16CBD41F674F4BE1ADBC20D6F8F04839F0837AF0483BF00123F8011217E1204CAF8836BFCBE164FF41FD3F2F86B7F88378F84839F8835D6FE120F3E004";
        }

        if (v == Fur.CRIMSON) {
            return hex"5B2380115B100045B242C559D10004A9200456F4AC5704B19714AC5724B1959D12B15D52004A5400454B52C56C531956BD4B15C14C6563252C57353195A554B15D94004A1600452A5AC555B16C655AE5AC56F5B1958456B156535B19745AC5755B19765AC57758012860012962C5552D8C6558D630717458C6565363073463195AD98B15DD80049DA0045096AC56A6B196B6B1FD635AD085D06B1FF16B07194DAD08D1AC7F6B66B19776AC57868012770012872C56973196A730715B5CA8E5D173421951CA8ED5CC1CD9CC65DDCB15E1C0044A77801287AC5697B196A7B0715D1ED08D5EC1CD9EC65DDEB1571A7801248001129A0BBF9E0004A20B1552A830715D20D086B683073782C57880011CEA0BBFEE0004922004962BBF9A29DD9E2BBFA22004A62C1C5558B42368B07378801388AEFF98A777A8AEFFB88012490012592EFD31E49DDA24004A64C1C55593423693073790011C6649DDEA4BBFEE4004926004966BBF9A69DD9E6BBFA26004A66C65AA6C1C5749B42359B07369B19779801389AEFF99A777A9AEFFB980124A001129E8BBFA2800452AA3196BA342164E8C1CD28D086B6A31977A0011C6A8BBFEE80044A7A80128AAC554AAAC6556CAB1FEDAB422EAAC657C2AC55C6AB19CAAD08674AB1FDADAAC65DEAB1571AA80127B00128B2C569B319552ECC7F58DB3422EB00117C2CC7EC6C004654B34235B31FF6B31977B2C578B00127B80128BAC569BB196ABB1FD5D2ED08D6EC7FDAEC65DEEB15E2E004A30004A70C65AB0C1CAF0C7F593C34234C31FF5C30736C31977C00113A32004A72B15AB2C65AF2C1C593CB4234CB0735CB1976CAC55BE320049B40044E8D2C569D0012AD2C56BD3196CD30716CB4D08CF4C1CD34C65D74B15DB40046F8D2C579D00125D80113276B1554BD8012CDB1956CB6C1CCF6C65695D8011B676B15EB60049780044C8E2C569E319552F8B15593E0011A578B15DB8C656F9E2C57AE00124E801129BAB159FAC65A3AB1552AEB196BEB07164FAB19D3AC1C6B6EB1977EAC578EB195CEBAB15EFA00493C00497CB159BCC654E8F2C554ABCC6556CF31FD6CBCD08674F31FDADBCC656F8F2C579F3197AF2C57BF00123F8011217EB154CAFB196BFB1FD64FED08D3EC7F6B7FB1978FAC579FB195D6FEB15F3E004";
        }

        if (v == Fur.GREENYELLOW) {
            return hex"5B2380115B100045B24054D9D10004A9200456F4854F048A0F14854F248A0D9D12153D52004A5400454B5054EC50A0D6BD4153C142836325054F350A0DA554153D94004A1600452A5854D5B162835AE5854EF58A0D845615365358A0F45854F558A0F65854F75801286001296054D52D828358D661A57458283653661A7460A0DAD98153DD80049DA0045096854EA68A0EB6E279635B8A35D06E27B16E1A594DB8A3D1B89E6B668A0F76854F86801277001287054E970A0EA761A55B5D0035D17628D951D003D5D869D9C283DDC153E1C0044A77801287854E978A0EA7E1A55D1F8A3D5F869D9E283DDE15371A7801248001129A18A29E0004A2015352A861A55D218A36B6861A778054F880011CEA18A2EE00049220049638A29A2DCF9E38A2A22004A638695558E28F68E1A778801388E28B98B73FA8E28BB8801249001259628931E4DCFA24004A658695559628F6961A7790011C664DCFEA58A2EE40049260049678A29A6DCF9E78A2A26004A66283AA78695749E28F59E1A7698A0F79801389E28B99B73FA9E28BB980124A001129E98A2A2800452AA0A0EBA628D64E9869D298A36B6A0A0F7A0011C6A98A2EE80044A7A80128A854D4AAA28356CAE27ADAE28EEADFAD7C2B87CC6B7EBCAB8A3674AE279ADAA283DEA15371AA80127B00128B054E9B0A0D52ED89E58DB628EEB00117C2D89AC6C004654B628F5B627B6B0A0F7B054F8B00127B80128B854E9B8A0EABE2795D2F8A3D6F89EDAE283DEE153E2E004A30004A70283AB1869AF189E593C628F4C627B5C61A76C0A0F7C00113A32004A72153AB2283AF3869593CE28F4CE1A75C8A0F6C854DBE320049B40044E8D054E9D0012AD054EBD0A0ECD61A56CB58A3CF5869D34283D74153DB40046F8D054F9D00125D8011327615354BD8012CD8A0D6CB7869CF6283695D8011B676153EB60049780044C8E054E9E0A0D52F8153593E0011A578153DB82836F9E054FAE00124E801129BA1539FA283A3A15352AE8A0EBEE1A564FB7EBD3B8696B6E8A0F7E854F8E8A0DCEBA153EFA00493C00497C1539BC2834E8F054D4ABC28356CF62796CBD8A3674F6279ADBC2836F8F054F9F0A0FAF054FBF00123F8011217E1534CAF8A0EBFE27964FF8A3D3F89E6B7F8A0F8F854F9F8A0DD6FE153F3E004";
        }

        if (v == Fur.GOLD) {
            return hex"5B2380115B10004B518775D1462832461DD9D10004A92004AD38A0B13877B53148B937AEBD38776124C52334E1DF44E283548012950012A562815B15148B557AEB958775F15452194D57AED15877D558A0D94004A16004A5787754B5C522C5DEBAD5E1DD74171486325DEB99D17877D577AED97877DD6004A18004A59877A99148AD97AE58D65FF173D914861165EB994D97FC69565EBB6661DF76001276801286E1DE96C522A6DEBAB6E165635B877B9B859BDB8A0C1B859C5B7FCC9B8776746E281AD9B148DDB877E1A0049DC004A1D877A5D7AEA9D7FCADD148B1D7AEB5D148B9D8A05F1761DF274523375EBB474523575FF36745237761DF87001129DE004A1F877A5F148A9F7FC56D78011741F877C5F8A06547801357DFF367DEBB77E1DDC69E0049200044A6862827800128861DD4AA17FCAE1877B218A05AF861DD84A18A0674861DDADA17FCDE1877E2000473A86283B8001248801258E28268B0EA78E28288801298DFF2A8E1DEB8E28163A38775F18E2819523877D638A0DA37FCDE2004E238A0E62C3AEA38A0EE20049240049658534C7930EA890012995FF2A962815B658775D0962818CE5877D258A0D65877DA57FCDE4004719930EBA9614FB9001249801259E14E69B0EA79E14E89801299DEBAA9DFF15B278775AF9E28184A7877CE78A0D27877D677FCDA77AEDE6004E27853E66C3AEA7853EE6004928004968D589A98539E8D58A28004A69148AA97AEAE9877593A5FF34A61DF5A5EBB6A45237A00138A35639A614FAA3563BA001129EA004509AC522AADEBABAE165636B8A0BAB7AE5F0AE07B1ADEBB2AE1DD9D2B859D6B7AE6D7AC521C6AA0049EC004A2D148A6D7AEAAD85956CB6282DB61DEEB00117C2D854C6C004653B61DF4B62835B61676B5EBB7B45238B00127B80128BC5229BDEB952EF8A058EBE1DEFBE28184AF877674BE2835BE1676BDEBB7BC5238B80128C00129C5EBAAC5FF2BC61656371877BB18A05F1C61DD94F18A0D31859D717FCDB17AEDF00044E8C80129CC522ACDEBABCDFF2CCE1DEDCE2817433877632CE2833CE1DF4CDFF35CDEBB6CC521BE320049B40044E8D62829D0012AD4522BD5EBACD5FF16BF5877611D62832D61DF3D5FF34D5EBB5D45236D0011BE358A0E740049760049B78A04E8DDEBA9DC52152F6004B377AE5B2DDFF33DDEB9A576004DB71486F8DDEBB9DE283AD80125E00126E61DE7E5EB94279148AB9877AF97AE593E00134E5EBB5E4521B5F97AE719E61DFAE00124E80125EE1DE6EDEB93A3B148A7B877ABB148AFB00EB3B7AEB7B877BBB1485F0EDEBB1EC5232EE1DF3EDEBB4EC03B5EC5236EDEB9BE3B877E7B148EBB877EFA00493C00497D8774C7F45228F61DD4ABD7AE574F45235F5EB9B5FD877719F4523AF61DFBF00123F80124FE1DD29BF1489FF877509FDEBAAFC522BFE166CFE1DD6BBF8A05F0FE1DD8CFF8A0D3F859D7F148DBF8776F8FC5239FDEBBAFC523BFE1DFCF8010";
        }

        if (v == Fur.DIAMOND) {
            return hex"5B2380115B10004B50F075D1462AB243C1D9D10004A92004AD38AAB12F07B5225FB9240EBD2F076124897F34BC1F44E2AB548012950012A562A95B1425FB5440EB94F075F15097D94D440ED14F07D558AAD94004A16004A56F0754B5897EC5903AD5BC1D741625F632590399D16F07D5640ED96F07DD6004A18004A58F07A9825FAD840E58D61E0D73D825F6116103994D87836956103B663C1F76001276801286BC1E96897EA6903AB6B515635AF07B9AD45BDB8AAC1AD45C5A783C9AF076746E2A9AD9A25FDDAF07E1A0049DC004A1CF07A5C40EA9C783ADC25FB1C40EB5C25FB9D8AA5F173C1F27097F37103B47097F571E0F67097F773C1F87001129DE004A1EF07A5E25FA9E78356D78011741EF07C5F8AA65478013579E0F67903B77BC1DC69E0049200044A6862AA780012883C1D4AA0783AE0F07B218AA5AF83C1D84A18AA67483C1DADA0783DE0F07E2000473A862ABB8001248801258E2AA68828278E2AA888012989E0EA8BC1EB8E2A963A2F075F18E2A99522F07D638AADA2783DE2004E238AAE620A0EA38AAEE20049240049644DD4C790282890012991E0EA962A95B64F075D0962A98CE4F07D258AAD64F07DA4783DE400471990283A91377B9001249801259937669828279937689801299903AA99E0D5B26F075AF9E2A984A6F07CE78AAD26F07D66783DA640EDE6004E264DDE660A0EA64DDEE60049280049681179A84DD9E8117A28004A6825FAA840EAE8F07593A1E0F4A3C1F5A103B6A097F7A00138A045F9A1377AA045FBA001129EA004509A897EAA903ABAB515636B8AABAA40E5F0A9D6B1A903B2ABC1D9D2AD45D6A40E6D7A897DC6AA0049EC004A2C25FA6C40EAACD4556CB62AADB3C1EEB00117C2CD45C6C004653B3C1F4B62AB5B35176B103B7B097F8B00127B80128B897E9B903952EF8AA58EBBC1EFBE2A984AEF07674BE2AB5BB5176B903B7B897F8B80128C00129C103AAC1E0EBC35156370F07BB18AA5F1C3C1D94F18AAD30D45D70783DB040EDF00044E8C80129C897EAC903ABC9E0ECCBC1EDCE2A97432F07632CE2AB3CBC1F4C9E0F5C903B6C897DBE320049B40044E8D62AA9D0012AD097EBD103ACD1E0D6BF4F07611D62AB2D3C1F3D1E0F4D103B5D097F6D0011BE358AAE740049760049B78AA4E8D903A9D897D52F6004B3640E5B2D9E0F3D9039A576004DB625F6F8D903B9DE2ABAD80125E00126E3C1E7E1039427825FAB8F07AF840E593E00134E103B5E097DB5F840E719E3C1FAE00124E80125EBC1E6E90393A3A25FA7AF07ABA25FAFA190B3A40EB7AF07BBA25F5F0E903B1E897F2EBC1F3E903B4E86435E897F6E9039BE3AF07E7A25FEBAF07EFA00493C00497CF074C7F097E8F3C1D4ABC40E574F097F5F1039B5FCF07719F097FAF3C1FBF00123F80124FBC1D29BE25F9FEF07509F903AAF897EBFB516CFBC1D6BBF8AA5F0FBC1D8CFF8AAD3ED45D7E25FDBEF076F8F897F9F903BAF897FBFBC1FCF8010";
        }

        if (v == Fur.METALLIC) {
            return hex"5B2380115B10004B509FDB90B8F5F04367B142E3F2428559D10004A92004AD2B8FB129FDB528B7B92A27BD2C6AC12BFA6324A2DF34A7F744AE3F548012950012A52E3EB526C2C522DED5289EE527F57C548B76535289F4527F7552E3F65001285801295A7F552D68B7B16A27B569FD5D05A2DD8C96A276745A7F755A89F65A7F77580128600129627F6A622DEB6289D6358E965CF622DD8458A2765363A59A558A27D989FDDD80049DA004A1A9FDA5A8B7A9AA27ADB19958D6C936E6C666F6E2AB06C66716BA5B26C9359D1B8AA6B66A2DF76A7F78680127700128727F697289EA73A5AB722DEC7289ED722DEE762A97C5D24DC9C8B7CDCA27D1C8B7D5CE96D9C8B7DDC9FDE1C0044A77801287A7F697A2DEA7BA595B5EF055D07C93717E2A9951EF05D5EE96D9EA27DDE9FD71A7801248001129A102D9E0004A209FD52A83A5AB84936C862A96BE124D612862A99D2124D6B683A5B7827F7880011CEA102DEE0004922004962CED9A28CA9E2CEDA22004A62E96AA324DAE38AA58E8C9357C638AA6548C93758E2AB68BA5B78801388B3B798A32BA8B3B7B88012490012592D6531E48CAA24004A64E96AA58AA56D9493574258AA633949374962AB594937693A5B790011C6648CAEA4B59EE4004926004966B599A68CA9E6B59A26004A66A27AA6E9656C9C9356BE78AA6129C93739E2AB49C93759BA5B69A89F79801389AD6799A32BA9AD67B980124A00125A26526A2D667A26528A00129A22DEAA289EBA493564E8E96D2924DD68A27DA88B7DE8004E28994E68B59EA8994EE80044A7A8011426A8B7AAAA27AEAF2B58DAE2AAEAA89D7C2AC03C6AA27CAB24DCEB199D2AF2BD6AA276D7AA2DDC6AA0049EC004A2C8B7A6CA27AAD19956CB62AADB4936EB00117C2D199C6C004653B49374B62AB5B46676B289F7B22DF8B00127B80128BA2DE9BA89D52EF8AA58EBC936FBE2A984AF24D674BE2AB5BC6676BA89F7BA2DF8B80128C00129C289EAC3A5ABC4665637124DBB18AA5F1C493594F18AAD31199D70E96DB0A27DF00044E8C80129CA2DEACA89EBCBA5ACCC936DCE2A9743324D632CE2AB3CC9374CBA5B5CA89F6CA2DDBE320049B40044E8D40B69D206AAD22DEBD289ECD3A596BF524D611D62AB2D49373D3A5B4D289F5D22DF6D0011BE3502DE740049760044C8DC0B69DB3B552F6004B36A275B2DBA5B3DA89DA576004DB6CED6F9DC0B7AD80125E00126E40B53A78CEDAB88B7AF8A27593E00134E289F5E22DDB638CEDE7902DEB800493A00497B02D4C8EB3B54ABA8B7AFA87DB3AA27B7A9FDBBA8B75F0EA89F1EA2DF2EA7F73EA89F4EA1F5ADBA8B76F9EB3B7AEC0B7BE80124F00125F27F5323C8B752AF289D5D3C8B7D7CA27DBC9FD6F9F22DFAF27F7BF00123F801121FEBD5A3E8B7A7EA27ABE8B7AFEC95B3EA8B5AEFB3B57C3EA8BC7ECEDCBEBE5CFECEDD3EE73D7E8B7DBE9FDDFE8B771BFAF57CF8010";
        }

        if (v == Fur.MAGENTA) {
            return hex"5B2380115B100045B2432699D10004A9200456F4B26B04BC2714B26B24BC259D12C9AD52004A5400454B5326AC53C256BD4C9AC14F096325326B353C25A554C9AD94004A1600452A5B2695B16F095AE5B26AF5BC258456C9A6535BC2745B26B55BC2765B26B75801286001296326952D8F0958D648097458F096536480B463C25AD98C9ADD80049DA0045096B26AA6BC26B6CBD1635B41D5D06CBD316C80994DB41DD1B2F46B66BC2776B26B86801277001287326A973C26A748095B5CCE35D175075951CCE3D5D202D9CF09DDCC9AE1C0044A77801287B26A97BC26A7C8095D1F41DD5F202D9EF09DDEC9A71A7801248001129A10109E0004A20C9A52A848095D2141D6B68480B78326B880011CEA1010EE00049220049630109A2BC69E3010A22004A632025558D07768C80B78801388C04398AF1BA8C043B8801249001259404131E4BC6A24004A652025559507769480B790011C664BC6EA5010EE40049260049670109A6BC69E7010A26004A66F09AA72025749D07759C80B69BC2779801389C04399AF1BA9C043B980124A001129E9010A2800452AA3C26BA507564E9202D2941D6B6A3C277A0011C6A9010EE80044A7A80128AB2694AAAF0956CACBD2DAD076EABFA97C2B279C6AFEACAB41D674ACBD1ADAAF09DEAC9A71AA80127B00128B326A9B3C2552ED2F458DB5076EB00117C2D2F5C6C004654B50775B4BD36B3C277B326B8B00127B80128BB26A9BBC26ABCBD15D2F41DD6F2F4DAEF09DEEC9AE2E004A30004A70F09AB1202AF12F4593C50774C4BD35C480B6C3C277C00113A32004A72C9AAB2F09AF3202593CD0774CC80B5CBC276CB269BE320049B40044E8D326A9D0012AD326ABD3C26CD48096CB541DCF5202D34F09D74C9ADB40046F8D326B9D00125D80113276C9A54BD8012CDBC256CB7202CF6E79695D8011B676C9AEB60049780044C8E326A9E3C2552F8C9A593E0011A578C9ADB8F096F9E326BAE00124E801129BAC9A9FAF09A3AC9A52AEBC26BEC80964FAFEAD3B2026B6EBC277EB26B8EBC25CEBAC9AEFA00493C00497CC9A9BCF094E8F32694ABCF0956CF4BD16CBD41D674F4BD1ADBCF096F8F326B9F3C27AF326BBF00123F8011217EC9A4CAFBC26BFCBD164FF41DD3F2F46B7FBC278FB26B9FBC25D6FEC9AF3E004";
        }

        revert("invalid fur");
    }
} 

library HeadSprites {    
    function getSprite(Head v) external pure returns (bytes memory) {
        if (v == Head.NONE) {
            return hex"";
        }

        if (v == Head.ENERGY_FIELD) {
            return hex"8C359A90359B94359D98359E4E80D67E90D67AA0D676B0D66F30D66B40D66F50D67F60D685BE035A2E435A0E8359DEC359CF0359A8C559C90559F9455A29855A64E81569E915696A15686B1567AC1566F21566F3156774156835156976156AB7156B38156AF9156A3A15697B1567BC1567211D66A21D67231D67E41D68E51D6AE61D6C271D6D681D6D291D6BEA1D6A6B1D68EC1D676D1D66B21D67731D68341D69F51D6BF61D6E5BE075BDE475B6E875ADEC75A6F0759FF4759CF8759A84959A88959C8C95A29095AA9495B59895D54E8257169256FAA256CAB256A2C256816C895D5CC95A5D095AFD495BED895C9DC95CDE095CCE495D5E895BAEC95ACF095A4F4959DF8959A84B59B88B59F8CB5A590B5B094B5BF4C72D75682D73E92D72AA2D6F55B0B5D5B4B59DB8B59BC0B59AC4B59B6742D75752D72762D74772D749C64B5D5E8B5C3ECB5B1F0B5A6F4B59FF8B59A84D59B88D59F8CD5A890D5B494D5C598D5D59CD8AAA0D5D5A4D5CEA8D5C3ACD5B1B0D5A5B4D59EB8D59BC0D59AC4D59BC8D5A1CCD5ACD0D5BCD4D5CCD8D5D2DCD5D5E0D8AAE4D5D5E8D5C9ECD5B7F0D5A9F4D5A0F8D59A84F59B88F59F8CF5A790F5B394F5C498F5D09CF5D5A0F8AAA4F5D5A8F5C1ACF5B1B0F5A4B4F59EB8F59BC4F59BC8F5A0CCF5ABD0F5BAD4F5CBD8F5D5DCF8AAE0F5D5E4F5D1E8F5C7ECF5B5F0F5A7F4F5A0F8F59C85159B89159E8D15A59115AF9515BE9915CA4E945756A456EEB456B6C4568ED45676E4566B04566B14566F24567F3456A74456D3545715B6115D5E515CCE915C0ED15AFF115A5F5159EF9159A85359A89359C8D35A19135A99535B29935BD9D35C3A135C1A535BBA935B0AD35A7B135A0B5359BB9359AC5359AC9359ECD35A3D135ACD535B8D935C2DD35C8E135C6E535BFE935B3ED35AAF135A2F5359D89559B8D559D9155A29555D59955AE4E8556C29556B6A556A2B55686C55672D5566B15566B25566F35567B4556975556AF6556C37556D38556D79556BFA55757B5568BC55677D5566A25D66A35D67245D75655D68665D69275D69A85D69695D68EA5D67EB5D676C5D66F25D66B35D66F45D67F55D68F65D69B75D69F85D69B95D693A5D68BB5D757C5D673D5D66A36566A465756565675325959EA9959CAD959A6746566B565675B5D959F71965677A65673B65757C6566A56D669325B59B54B6D66B56D66DB65B59AEDB59A";
        }

        if (v == Head.BLUE_TOP_HAT) {
            return hex"555220DD554A837536320DD4D8E837536420DD4D92837536520DD4D96837489620DEA61012B62032C61012D62032E61012F62033061013162033261013362033461013562031B6D883748A6A0DEB6A13D66DA8374BA720DD4D9E8370";
        }

        if (v == Head.RED_TOP_HAT) {
            return hex"555220DD554A837536320DD4D8E837536420DD4D92837536520DD4D96837489620DD5558F086DB620DD26DA8374BA720DD4D9E8370";
        }

        if (v == Head.ENERGY_CRYSTAL) {
            return hex"56C300117C0C00467430012B38012C3C5116B8E0045F03E2A98C8E004CCF144D0E004B10004B50425B9080BBD18AA6114202F241097340012B48012C483656B924255F04A02D8C92425CD20D9D12004B14004B540D95D151097250367350012D58012E583657C16425C560D9C96004B980045F0603671600117C1A0040";
        }

        if (v == Head.CROWN) {
            return hex"A4A004B0A0045F0280133280136280114ACC004B0CBE05AE30012F3416F03627D8C8C004CCCBE069630012938012A3CA2AB38012C3AF82D3801173CF05BC0F89FC4F28AC8E004CCEBE0D0E004D4F28AD8E004A50004A90BAFAD189FB100045AE4416EF42EBF0402FD8C9128ACD0004D1189FD50BAFD9000452A480115B1389F5AE4C16EF482FF04AEBD8C9328ACD305BD1389F6B648012950012A54A295B1589F5AE5416D7C1400463254A2B35416F45627F554A2B650012958012A5B1F15B1789F5AF5C16F05E27D8C9728ACD705BD1789FD56C7CD96004A9800456C634716BD8BF5C18D1C632631F3362FD74634735600115D1A004";
        }

        if (v == Head.BANDANA) {
            return hex"574500114A96004AD6EEE5935CD5B45BBB9AD96004A18004A58C8954B63BB964D935669563BBB663225BE180049DA0045096B225531AEEE5B26CD599D5AEEE6D76B227868012770011425CC89A9CEEE57470013573BB9B5DCC89E1C0049DE004A1EC8952A78011AD9E004DDEC89E1E0044E880011BE200049AA004A2A0049AC0049ECC89A2C0049AE0049EEC89A2E0049B00049F0C89A300049B20049F2EEEA320049F4004A34EEEA740049F6004A37356A760049B80049F9356A38004A78EEEAB80049BA0049FB356A3A004A7B356ABA0049BC0049FD35650AF001131FE0040";
        }

        if (v == Head.BUCKET_HAT) {
            return hex"574320DEA3A0DD5B4E0545D1381B5950E054D4E837A5083754C401516B9006D5F04026D8C9006D675401536420DE94A0DD52D205458D481B6E4826EF48AEF049D7F14826D94D206D6954815364A0DE8520DD4AD405458D501B6E5026EF51D7F050AEF15026D94D406D696501537520DE85A0DE9581515556837D96054DD68374E9620DD55580546D8620DD31DA837A1A05452A681B55D1A09B6B6681B7768151C65A83795C8374C7701528701B54A9C09B574720DDAD9C09BDDC06D71970153A720DD2A9E8376BA7A0DC";
        }

        if (v == Head.HOMBURG_HAT) {
            return hex"574220DEA2A0DD5B0A8845B42A3D352A0DE9320DD554C884D8C837A4E8375553A21363A0DE9420DD52D0884593423D1A550884D90837A5283754B4A21164D28F46954A21364A0DE9520DD52D4884593523D1A554884D94837A568D3A968535735A22B45ABBB55A14F65A34D2258837A988D3AD89D259262BBB36077F461D7F562BB9B6D88374436A0DD225A8F45536A0DF46ABBB56A0DDB6DA8F479D6A0DD121C837536723D1BF5C8375367A0DC0";
        }

        if (v == Head.PROPELLER_HAT) {
            return hex"B06004B46075B860B2BC6053C06004C46053C860B2CC6075D060045B3200130280116C8C00456C38012D381E6E382C97C0F4ECC4F7FBC8EFB567438012A40012B40102C401E6D402C974514ECC917FBCD0FB5D10BA7D50004A52004A92040AD207958D482C974534EC6534DFEF44BED754AE9F64801295001152D4079B140B25B2553B3355FEDA554FB5D94004A16004A5604054C581E56C9717E6755BED765AE9F7580128600114B180405B2630C59D98BA7DD8004517680100";
        }

        if (v == Head.HEADBAND) {
            return hex"5B2480115B140045AF55E13055FC98C9578467450012A58012B5B65D6357117B97784BD71176135B65F45C45F558012960012A6365EB6445EC65FC96C99784CD97F2D19117D58BF4D98004A1A004A5AD9754B6C45D641AD976326C45F36B65F46AFD356C45F66AB0F76801277001287365E973E7552DCD97B1D1175AE75E12F75FC9849D7846747445F57365F67443B772FD3870012778011425EBF4A9F1175747801357C45DB5DED97E1E0049E0004A20D9752A80011ADA0004DE0D97E200044E888011BE220040";
        }

        if (v == Head.DORAG) {
            return hex"5B2380116C9028556C48A156C924FA67448A1552D4285593513E9A554285A5615055558A1765854296031952D8150593613E9A558150D980C6A1A0C6A5A15054B68A1564DA4FA69568A1766854376831A770011425C15055570A15B5DC150E1C0049DE00450978542A78A155D1E004D5E2856D7785438780127800128805414AA00046B6800137805438800113A220046F8880126A80128A80126B00127B05428B00126B80127B85428B80126C00127C05428C00126C80127C8A168C80127D00128D0A167D80128D93EA9D80126E00127E13EA8E00129E0A16AE00126E80127E93EA8E80129E93EAAE80126F00127F13E942BC0044C7F80100";
        }

        if (v == Head.PURPLE_COWBOY_HAT) {
            return hex"58E180118CC6004AC8004B08B215AE231A57C08004632231A7322C87420012A280115B0AB215AE2B1A57C0AB216322B1A59D0AB21D4A004A8C00456C32C856B8CC695F0331118C8CC6967432C8753001293801152CEB215933B1A5A54EB21D8E004A50004A90B21574431A7542C8764001110D2004A520045554B1A7648011E7520048940048D4C69914004A1400452A528F6B531A6C52D3AD531A6E52D3AF531A7052D3B1531A7253C0F3531A7453C0DAD94A3DDD4004ED4004F14C69F540048960044645B1A52A560045515A8F725C8F735BC0F45C8F755A8F5B69600477C5B1A7D58012260012362C852218C69A58B4E55560013662D39BED8C69F18B21F580048DA00491AB214AA6B1A6B6AD3AC6B1A6D6AD3AE6B1A6F6AD3B06B1A716AD3B26B1A736AD3B46B1A756AD39B69AC69EDAB21F1A00491C0044A872C854D9CC696FA72C87B700112A1E0045367AC85BE9E00453680010";
        }

        if (v == Head.BUNNY_EARS) {
            return hex"50A08011ADC20049C400450A14AE6B10013410011ADC52B9E040049C6004A072B9A4766AA872B9AC6004D06004D472B9D8766ADC72B9E060049C8004A08FC4A4966AA895E4AC92B9B08004CC8004D092B96B6259AB723F1382001282801292CAE6A2D9AAB2CAE6C2801332801342CAE752D9AB62CAE7728012830012933F12A3506EB359AAC34AE6D30013230013334AE74359AB53506F633F13730012938012A3CAE6B3D06EC3CAE6D3801323801333CAE743D06F53CAE7638012940012A43F12B4506EC44AE56C90004CD12B9D1141BD50FC4D90004A92004AD341B5934CAE744D06F548012A50012B54AE6C53F116C94004CD4FC4D152B9D54004A56004A96FC456C580119D16004D56FC4D96004A18004A58FC4A98004D58004D98FC4DD800450968011B5DA004";
        }

        if (v == Head.SPACESUIT_HELMET) {
            return hex"5933801152D000458D44D4EE421F97C1028AC5087E65344D4DA550004A5200454B4C886C4BF56D4B41EE4A1F97C126BCC5287EC92D07CD2FD56954C88764801285001295488552D4D0758D53F56E521F97C14520C5487E65353F55A554D07D95221DD40049D6004A1722152A5BF555B56D07B9687E5F058AA315A1F99516D076B65BF5775C88785801266001276341D4298FD556D60012E621F97C18160C5887E6546001356341DB5D8FD5E18D07E5800499A0049DAD07A1AFD5A5AD07A9A004B9A0045F06A1FB16801356801366B41F76BF5786B41F96801257001267341E774886873F5697341EA700117C1C004D5C004D9CD07DDCFD5E1D221E5CD07E9C00495E00499EA8D9DEFD5A1ED07A5E004D9E004DDED07E1EFD5E5EA8DE9E00492000496028A9A08F64E882E42980013680011BE20B90E608F6EA028AEE00049220049626BC9A28F69E3221A22D07A62004DA2004DE2D07E23221E628F6EA26BCEE20049240049645209A487E9E5221A24D07A64004DA4004DE4D07E25221E6487EEA4520EE40049260049662A89A68F69E6B90A26A8DA66004DA6004DE6A8DE26B90E668F6EA62A8EE60049280049681609A88F69E8FD5A28D07A68004DA8004DE8D07E28FD5E688F6EA8160EE800496A0049AAD079EAFD5A2AD07A6A004DAA004DEAD07E2AFD5E6AD07EAA00496C0049ACD079ECFD5A2CD07A6C004DAC004DECD07E2CFD5E6CD07EAC0049AE0049EED07A2EFD5A6E004DAE004DEEFD5E2ED07E6E0049B00044E8C341E9C3F56AC00135C00136C3F55BE30D07E700049F2004A32D0752ACAE42BC80134C8011ADB2B90DF2D07E32004A34004A74D0754BD3F56CD00133D0011A574FD5DB4D07DF4004A76004AB6D0756CDBF56DD80132D80119D36FD5D76D07DB600454BE00116378D075D1E001194F8D07695E0012CEA436DE8011747AD07CBA004CFA90D5D1F24340";
        }

        if (v == Head.PARTY_HAT) {
            return hex"C00004BC2004C03587C42004BC4004C044C0C44004B86004BC606BC06350C46266C86004B88004BC8266C0809DC4806BC88004B4A004B8A06BBCA09D6112930322899B328012D30012E3099AF30819844C09DC8C06BCCC004B0E004B4E06BB8E09D5F1393032382773381AF438012C40012D4099AE40276F40819845009DC904C0CD0266D10004B12004B5206B5D04930314881B2482773481AF4480115B140045B35561F450012A580116556004A58004D98004";
        }

        if (v == Head.CAP) {
            return hex"5F0320D95D0E836A90836AD0892B10836B50E94B9103E5F04224B1440FB243D5B3420DB44224B5420DA94A0D952D2892B12836B52F225D04A24B14BC8B24A24B34A0D9A552892D92836A1483652A5224AB520DAC52392D533097454892C94F22CD48E4D148366B65224B7520DA85A0D94A96892AD6836B168E4B56CD8B96CC25F05A2498C96CC2CD68E4D168366B65A24B75A0D945D8836A1A8365366A24B76A0DA9720DAA726A55B1C9F25AE728ED7C1CA89632728ED9D1C9F2D5C9A9D9C836A5E836A9E8E45747A6A757A39367A0D955608360";
        }

        if (v == Head.LEATHER_COWBOY_HAT) {
            return hex"58E180118CC6004AC8004B08D505AE240A57C08004632240A7323543420012A280115B0AD505AE2C0A57C0AD506322C0A59D0AD50D4A004A8C00456C335416B8D0295F033F098C8D0296743354353001293801152CED505933C0A5A54ED50D8E004A50004A90D50574440A754354364001110D2004A520045554C0A7648011E7520048940048D5029914004A1400452A52F8AB540A6C53736D540A6E53736F540A70537371540A72547BB3540A74547B9AD94BE2DD4004ED4004F15029F540048960044645C0A52A560045515AF8B25CDEF35C7BB45CDEF55AF89B69600477C5C0A7D580122600123635412219029A58DCD55560013663735BED9029F18D50F580048DA00491AD504AA6C0A6B6B736C6C0A6D6B736E6C0A6F6B73706C0A716B73726C0A736B73746C0A756B735B69B029EDAD50F1A00491C0044A8735414D9D0296FA73543B700112A1E0045367B541BE9E00453680010";
        }

        if (v == Head.CYBER_HELMET__BLUE) {
            return hex"57438012A400115B10A28B50004B90A285F0423D71428A32400119D10A28D50004A52004A92A2856C4A3D6D48012E4A8A17C128F5C52A28C920046744A3D754A8A36480114254004A94A2856C523D6D50012E528A17C148F5C54A28C94004674523D75528A1B5D400450958012A5A8A15B168F5B56004B96A285F05A3D715A8A32580119D168F5D56A286D7580127600128628A2960012A628A15B188F5B58004B98A285F0623D71628A32600119D188F5D58A28D98004DD8A28E180049DA004A1AA28A5A004A9AA2856D6A3D6E680117C1A783C5A0046546A3D756A8A366801376A8A38680127700128728A2970012A728A15B5C8F5B9C0045F07080B170011951C8F5D5CA28D9C004DDCA28E1C0044A77801287A8A14A9E00456C7A8A2D7A3D6E780117C1E202C5E004C9E8F56747A8A1AD9E004DDEA2871A7801248001129A0A289E0004A208F5A60004AA078356C800116BA0A285F0800118CA0A2867480013581E0F6800137823D7880011CEA0A28EE00044878801288A3D698A8A2A88012B8880AC89E0D6CA2004CE2783D22202D62004DA2A28DE28F571B88012490012591E0E69080A7900128923D69928A15324004B642025D191E0F2908099D64004DA4A28DE48F5E24004E64202EA4783EE40044879801289A3D699A8A2A980115B268F55B2980119D268F5D66004DA6A28DE68F571B980124A001129A88F59E8004A288F5A68A28AA8004AE8202B287835B2A23D73A1E0F4A080B5A00136A28A37A23D78A0011CEA88F5EE80044A7A8011426A8F5AAAA2856CA80116BAA2025F0A9E0D8CAA202674A80135AA8A1B5EA8F571AA80113A6C004AACA28AEC004B2C8F55B2B00133B23D74B00135B28A1B62C0049EE004509BA3D552EE004B2EA285B2BA3D73BA8A1A56E0046D7BA3D78B80128C00129C23D6AC28A15D30004D70A28DB08F5DF0004A32004A728F5AB2A28AF2004B32A285B2CA3D73CA8A34C80135CA8A36CA3D77C80129D0012AD28A15D34004D74A28DB400454BD8012CDA8A16CB68F5CF6A28695D801164F80040";
        }

        if (v == Head.CYBER_HELMET__RED) {
            return hex"57438012A400115B10A28B50004B90A285F0423D71428A32400119D10A28D50004A52004A92A2856C4A3D6D48012E4A8A17C128F5C52A28C920046744A3D754A8A36480114254004A94A2856C523D6D50012E528A17C148F5C54A28C94004674523D75528A1B5D400450958012A5A8A15B168F5B56004B96A285F05A3D715A8A32580119D168F5D56A286D7580127600128628A2960012A628A15B188F5B58004B98A285F0623D71628A32600119D188F5D58A28D98004DD8A28E180049DA004A1AA28A5A004A9AA2856D6A3D6E680117C1B4ECC5A0046546A3D756A8A366801376A8A38680127700128728A2970012A728A15B5C8F5B9C0045F073817170011951C8F5D5CA28D9C004DDCA28E1C0044A77801287A8A14A9E00456C7A8A2D7A3D6E780117C1EE05C5E004C9E8F56747A8A1AD9E004DDEA2871A7801248001129A0A289E0004A208F5A60004AA14EC56C800116BA0A285F0800118CA0A28674800135853B36800137823D7880011CEA0A28EE00044878801288A3D698A8A2A88012B8B816C8D3B16CA2004CE34ECD22E05D62004DA2A28DE28F571B880124900125953B26938167900128923D69928A15324004B64E055D1953B32938159D64004DA4A28DE48F5E24004E64E05EA54ECEE40044879801289A3D699A8A2A980115B268F55B2980119D268F5D66004DA6A28DE68F571B980124A001129A88F59E8004A288F5A68A28AA8004AE8E05B294EC5B2A23D73A53B34A38175A00136A28A37A23D78A0011CEA88F5EE80044A7A8011426A8F5AAAA2856CA80116BAAE055F0AD3B18CAAE05674A80135AA8A1B5EA8F571AA80113A6C004AACA28AEC004B2C8F55B2B00133B23D74B00135B28A1B62C0049EE004509BA3D552EE004B2EA285B2BA3D73BA8A1A56E0046D7BA3D78B80128C00129C23D6AC28A15D30004D70A28DB08F5DF0004A32004A728F5AB2A28AF2004B32A285B2CA3D73CA8A34C80135CA8A36CA3D77C80129D0012AD28A15D34004D74A28DB400454BD8012CDA8A16CB68F5CF6A28695D801164F80040";
        }

        if (v == Head.SAMURAI_HAT) {
            return hex"5F018012E20012F20C2B0203C71200117C0A0045AE30012F30C2B0303C58C8C00456C38012D380FEE381E17C0E004C4E078C8E052674380114A90004AD008BB10052B50078B900B3BD0078611402CF2401E334014B44022DAD900044E84801294814952D2078B12052B52078B920B3BD2078611482CF2481E3348149A552078D9203F6F84801129940049D4063A1405252A501E2B5014AC501E16B940B3BD4078612502CF3501E3450149AD94078DD403FE1406373A5001119160049560639960529D603F50A581E2B5814AC581E16B960B3BD6078612582CF3581E3458149ADD6078E1603FE56052E9606377C5801108980048D80444856014A6600FD3A18052A58078A98052AD807858E602CEF601E184D80B3D18078D58052D980786F86014B9600FDD6D8052F180447BE60012068011091A06E95A30A4C8682854A9A05256E681E2F68149851A0786B668149BE5A0A1E9A30A77E681BBF68011021C004A5C30AA9C0A156E703C6F70C29851C0F1D5C0A1D9C30A6FF700114D9E004";
        }

        if (v == Head.CATEAR_HEADPHONES) {
            return hex"9C4004E040044E818011BE060049C8004A0899AA48004D88004DC899AE080049CA0045092A66AA280116C8A004D4A0046D72A66B8280127300128332054A8C99A56C30012D3266AE32AD2F32F85844CAB4C8C99A67430011AD8C99ADCCC81E0C0049CE004A0EBE1A4EC81A8E004ACE99AB0EBE15B23801333AF8743A66B53801363B20773AF878380127400128426694B100046764001374266B8400113A12004A52FF0A92004D52004D92FF06F848012750012853FC2950013650013753FC385001275801285B25A95801365801375B25B858012660012763FC2860013760013863FC396001266801276BFC286801376801386BFC396801267001277325A87001377001387325B9700112A1E0046FA7801248001258355A682AD278266A88001378001388266B982AD3A8355BB8001248801258B55A68AAD278A66A88801378801388A66B98AAD3A8B55BB8801249001259320531E4AB4A24004DE400471992AD3A93207B9001249801259B20531E6AB4A26004DE60047199AAD3A9B207B980124A00125A355A6A2AD27A266A8A00137A00138A266B9A2AD3AA355BBA00124A80125AB55A6AAAD27AA66A8A80137A80138AA66B9AAAD3AAB55BBA80112A2C0046FAB00100";
        }

        if (v == Head.HALO) {
            return hex"9006EF9406F29806F59C06FBA00706A40711A8071FAC072AB00734B4073AB8073D5F001CFB101CF3201CE7301CCB401CAB501C87601C5F701C37801C13901BF7A01BDFB01BCFC01BC1EF806EE44309BBA409BC2509BCE609BE2709C06809C36909C72A09CAAB09CE2C09D0ED09D1AE09D257C0274AC42748C82744CC273FD02737D4272ED82722DC2717E0270AE42702E826FAEC26F4F026F1F426EF8846EE8C46EF9046F19446F59846FB9C4705A04713A44725A84735AC4743B0474EB44751B847535F111D4B211D3F311D1F411D07511CDB611CAB711C83811C4B911C1FA11BF7B11BDFC11BC9EF846EFFC46EE8C66EF9066F19466F59866FD9C6708A06718A4672AA8673B57419D63519CF3619CC3719C8F819C57919C2BA19BFFB19BE3C19BCFD19BC3E19BBA221BBA321BBE421BC6521BD6621BF6721C2A821C6A921CB2A21D62B21D36C21D516B887575F121D5B221D57321D43421D1B521D63621CCF721C9B821C63921C2BA21BFFB21BDFC21BD3D21BC1F7C86EE8CA6EF90A6F094A6F598A6FD9CA709A0A717A4A72AA8A73C57429D63529CF3629CC7729C93829C57929C2BA29C03B29BE3C29BD3D29BC3E29BBA331BBA431BC6531BD2631BEA731C16831C4E931C9AA31CD6B31D0EC31D32D31D45740C753C4C751C8C74FCCC749D0C741D4C737D8C72CDCC720E0C712E4C708E8C6FEECC6F7F0C6F2F4C6EFF8C6EE90E6F094E6F298E6F99CE701A0E70EA4E71CA8E72AACE738B0E742B4E745B8E74ABCE74CC0E74BC4E749C8E745CCE740D0E738D4E72FD8E723DCE718E0E70EE4E703E8E6FBECE6F5F0E6F1F4E6EF7DF39BBA341BBA441BBE541BC6641BDA741BEE841C16941C46A41C7AB41CA2C41CCED41CEAE41CF97C1073FC5073EC9073ACD0734D1072BD50723D90719DD070EE10704E506FEE906F7ED06F2F106F07BE41BBA449BBA549BC2649BCA749BDE849BF6949C1EA49C42B49C6AC49C8AD49C9EE49CB2F49CBB049CBF149CB7249CA7349C93449C7B549C57649C33749C13849BFB949BE7A49BCFB49BC7C49BBFD49BB921546EE9946F09D46F3A146F8A546FDA94703AD470BB14710B54716B9471ABD471DC1471EC5471BC94717CD4714D1470FD54708D94702DD46FCE146F8E546F4E946F2ED46EFF146EE4A659BBA759BCA859BCE959BDEA59BE6B59BFEC59C12D59C1AE59C2AF59C2F059C33159C2F259C1F359C13459C03559BF3659BE3759BDB859BCF959BC7A59BBDDF966EE9986EE4E861BBE961BCEA61BD6B61BDEC61BE6D61BF2E61BF6F61BFB061BF7161BFB261BEF361BEB461BE3561BDF661BCF761BC7861BC3961BBDD6D86EE50969BB952DA6F1B1A6F2B5A6F3B9A6F45F069BD58CDA6F4D1A6F36B669BC7769BC1C69A6EE52A71BB95B1C6EF5AE71BC6F71BC1845C6F165371BBF471BC3571BBDB61C6EE56E79BBAF79BBF079BBB179BBF279BBB479BBF579BBB779BBB181BBB481BB8";
        }

        revert("invalid head");
    }
} 

library MouthSprites {
    function getSprite(Mouth v) external pure returns (bytes memory) {
        if (v == Mouth.SURPRISED) {
            return hex"5F0C0012EC80117C333C5C720045F0D00100";
        }

        if (v == Mouth.SMILE) {
            return hex"B30004CF00045B2C8010";
        }

        if (v == Mouth.PIPE) {
            return hex"F638AAF698AAF6B8AA75BBE2AACC00133C0011D6F18AA5B2C80133CBA6F4C80133D00134D3A6F5D0011BEF4004D36004D76E9B6D7D8011C6B71A6EF6004D78004DB8E9BDF800471AE3A6FBE00136E8011BEBAE9BEFA0046FAF0010";
        }

        if (v == Mouth.OPEN_SMILE) {
            return hex"593C0012DC801174738AACB20045D1D00100";
        }

        if (v == Mouth.NEUTRAL) {
            return hex"5B2C8010";
        }

        if (v == Mouth.MASK) {
            return hex"A66004DA600454BA0011A568004AAA004AEAC8C593A80134AB2335A80128B0012AB00115D2D3ABD6C004DEC00452AB8012BBB3D564EEC8CD2ECF56B6B8012AC0012BC408564F13ABD31021D70004AB2004AF2D43B330215B2CB2333CC0874CB50F5C8012BD0012CD2D116BB50215F0D4EAD8CB5021CF4B44695D001163760045D1DA95994F60045D1E0010";
        }

        if (v == Mouth.TONGUE_OUT) {
            return hex"B30004CF0004B72004BB2D005F0CBD2F1CB4032C8012ED00117C35393C74004BB60045F0DBD2F1D80100";
        }

        if (v == Mouth.GOLD_GRILL) {
            return hex"B30004B7189DBB17EABF18AAC3185FC718AACB17EACF0004B72004BB389DBF3075C338AAC73075CB20045D1D0010";
        }

        if (v == Mouth.DIAMOND_GRILL) {
            return hex"B30004B71005BB075FBF18AAC3075FC718AACB075FCF0004B72004BB38AABF234AC338AAC7234ACB20045D1D0010";
        }

        if (v == Mouth.NAVY_RESPIRATOR) {
            return hex"A26004DE60049E8004A2881CA68004DA8004DE881CE280049EA004A2A81CA6A9B2AAA0045D1A80135A80136AA6CB7AA0738A80127B00128B20729B216EAB26C95B6C0045D1B226D952C004D6C9B2DAC85BDEC81CE2C004A2E00452ABA16EBBA6C963AE81C5F0BA6C98CEE81CD2E9B26B6BA16F7B80126C00113A309B2A70004AB085B56DC20717470004654C20735C216F6C0011BE309B2E700049B20049F281CA3285BA729B2AB200456CCA072DC8012ECA072FCA16F0CA0731CA16F2C80119D3281CD72004DB29B2DF285BE3281CE720049B40049F485BA3481CA7485BAB49B2AF4004B3485BB74004BB481CBF485BC3481CC7485BCB4004CF485BD34004D749B2DB485BDF481CE3485BE740049F6004A3685BA7681CAB685BAF6004B3685BB76004BB681CBF685BC3681CC7685BCB6004CF685BD36004D7685BDB681CDF685BE36004A38004A7885BAB881CAF8004BB881CBF885BC3881CC7885BD38004D7881CDB885BDF800452BE8011747A004696E80100";
        }

        if (v == Mouth.RED_RESPIRATOR) {
            return hex"A26004DE60049E8004A289DFA68004DA8004DE89DFE280049EA004A2A9DFA6AFB8AAA0045D1A80135A80136ABEE37AA77F8A80127B00128B277E9B2F3EAB3EE15B6C0045D1B342D952C004D6CFB8DACBCFDEC9DFE2C004A2E00452ABAF3EBBBEE163AE9DF5F0BBEE18CEE9DFD2EFB86B6BAF3F7B80126C00113A30FB8A70004AB0BCF56DC277D7470004654C277F5C2F3F6C0011BE30FB8E700049B20049F29DFA32BCFA72FB8AB200456CCA77EDC8012ECA77EFCAF3F0CA77F1CAF3F2C80119D329DFD72004DB2FB8DF2BCFE329DFE720049B40049F4BCFA349DFA74BCFAB4FB8AF4004B34BCFB74004BB49DFBF4BCFC349DFC74BCFCB4004CF4BCFD34004D74FB8DB4BCFDF49DFE34BCFE740049F6004A36BCFA769DFAB6BCFAF6004B36BCFB76004BB69DFBF6BCFC369DFC76BCFCB6004CF6BCFD36004D76BCFDB69DFDF6BCFE36004A38004A78BCFAB89DFAF8004BB89DFBF8BCFC389DFC78BCFD38004D789DFDB8BCFDF800452BE8011747A004696E80100";
        }

        if (v == Mouth.MAGENTA_RESPIRATOR) {
            return hex"A26004DE60049E8004A289D9A68004DA8004DE89D9E280049EA004A2A9D9A6AEFCAAA0045D1A80135A80136ABBF37AA7678A80127B00128B27669B2E8AAB3BF15B6C0045D1B3319952C004D6CEFCDACBA2DEC9D9E2C004A2E00452ABAE8ABBBBF163AE9D95F0BBBF18CEE9D9D2EEFC6B6BAE8B7B80126C00113A30EFCA70004AB0BA256DC27657470004654C27675C2E8B6C0011BE30EFCE700049B20049F29D9A32BA2A72EFCAB200456CCA766DC8012ECA766FCAE8B0CA7671CAE8B2C80119D329D9D72004DB2EFCDF2BA2E329D9E720049B40049F4BA2A349D9A74BA2AB4EFCAF4004B34BA2B74004BB49D9BF4BA2C349D9C74BA2CB4004CF4BA2D34004D74EFCDB4BA2DF49D9E34BA2E740049F6004A36BA2A769D9AB6BA2AF6004B36BA2B76004BB69D9BF6BA2C369D9C76BA2CB6004CF6BA2D36004D76BA2DB69D9DF6BA2E36004A38004A78BA2AB89D9AF8004BB89D9BF8BA2C389D9C78BA2D38004D789D9DB8BA2DF800452BE8011747A004696E80100";
        }

        if (v == Mouth.GREEN_RESPIRATOR) {
            return hex"A26004DE60049E8004A2804BA68004DA8004DE804BE280049EA004A2A04BA6A16FAAA0045D1A80135A80136A85BF7A812F8A80127B00128B012E9B027EAB05BD5B6C0045D1B0389952C004D6C16FDAC09FDEC04BE2C004A2E00452AB827EBB85BD63AE04B5F0B85BD8CEE04BD2E16F6B6B827F7B80126C00113A3016FA70004AB009F56DC012D7470004654C012F5C027F6C0011BE3016FE700049B20049F204BA3209FA7216FAB200456CC812EDC8012EC812EFC827F0C812F1C827F2C80119D3204BD72004DB216FDF209FE3204BE720049B40049F409FA3404BA7409FAB416FAF4004B3409FB74004BB404BBF409FC3404BC7409FCB4004CF409FD34004D7416FDB409FDF404BE3409FE740049F6004A3609FA7604BAB609FAF6004B3609FB76004BB604BBF609FC3604BC7609FCB6004CF609FD36004D7609FDB604BDF609FE36004A38004A7809FAB804BAF8004BB804BBF809FC3804BC7809FD38004D7804BDB809FDF800452BE8011747A004696E80100";
        }

        if (v == Mouth.MEMPO) {
            return hex"A26004DE6004509A001174680046D7A00128A80129AAD55536A0045D1AB2A1956A004DAAB55DEA004A2C004A6CB5554DB32A1746C004655B32A36B2D577B00128B80114AAECA8AEE00458DBC832EB80117C2F20CC6E004653BC8334B8011ADAECA8DEE004A30004A70B5554CC0012DC48317470004CB120C675C00136C2D577C00129C8012ACAD56BCC83164F2004D3320CD72B55DB2004AB4004AF4B55B3520CB740045D1D48332D00133D48334D2D575D0012BD801164F6CA8D36004593E0010";
        }

        if (v == Mouth.VAPE) {
            return hex"8E58A88E78A879DA62A1192B8A879DAE2A23B62A24B62A65B62964BE2A65BE295CEEF8A84E8C62A2CC00133C0011CF318A84E9CE2A2DC8012ECC10AFC80130CB0571C80132CC109D6F38A84EED62A2FD00130D28131D001194F58A86D8D62A121778A54EDDE2A17476004CB718A678DE2A1DF378A5485E629543398A8BB8C15BF9086C38C06C79086CB8D19678E62A1DF398A597B8A552BEE2A2EEB056FEC21B0EB85F1EC21B2EB465ADFB8A8EFB8A55D2F294AEFA94AFFB1EB0FDE8F1FB1EB2FA9480";
        }

        if (v == Mouth.PILOT_OXYGEN_MASK) {
            return hex"5F0A00116BAA0045F0AB5758CAA00454CB00116BACD5DBEC6E5C2C64A632B35759D6C004A6E00454CBB5756BAE64ABEE6E5C2E64A632B8ED59D6ED5DDAE004A30004A70D5DAB045FAF07FE58EC192AFC1DAF0C19298CF03B5D307FED70208DB0D5DDF0004A32004A7264AAB2004AF220858EC992AFC9DAF0C99298CF23B5D32208D72004DB23B5DF2004A7400454ED192AFD1B970D19298D743B5DB4004AB6004AF664AB363B55AED99297C36A8C632D8ED73D9FFB4D8ED75D8012BE0011637864ABB8A8CBF902EC38CF4C78A8C653E0ED74E0011637A004BBAA8CBFADD1C3ABD8C7AA8C653E8012EF0012FF40BB0F33D31F0012EF8012FFB7470FAF631F8010";
        }

        if (v == Mouth.CIGAR) {
            return hex"F5B8A779D7629FC9629FB9E287C9E29DDF298A175BB629DCEEF8A7B30004CF000473BC629D6CB2004CF2E13D3200473BCE29F2D00119D35185D74004EB58A7CF6004695DB84F6D80134E00135E384F6E392B7E00138E629F5E80136EB0F37E8011B5FC0040";
        }

        if (v == Mouth.BANANA) {
            return hex"AF0004655C00116472004653CE2034C80131D001194F5880D34004C76004653DE2034D80131E001194F9880D38DC0D78004C3A004C7B842CBADC0CFB880D3ADC0D7B842DBA004BFC004C3D842C7D177CBD842CFCDC0D3D1776B6F610B7F0012FF80130FE10B1FB7032FE10B3FB7034FE10B5FB7036FE10B7F80100";
        }

        if (v == Mouth.CHROME_RESPIRATOR) {
            return hex"A26004DE60049E8004A28864A68004DA8004DE8864E280049EA004A2B19DA6AF0CAAA0045D1A80135A80136AA05F7A913B8A80127B00128B21929B26C6AB30D55B6C004BACA37BED450C2C44EC6CA37654B00135B24676B26C77B21938B00113A2E00452ABA6C6BBAC1ECBB5CADBC67573EEF1C611B88F72B8D0F3B85CB4BA469ADAE9B16F8B80126C00113A3149CA70004AB09B1574C21935C26C76C0011BE30457E700049B20049F2864A329B1A73252AB2004AF2B07B32864B72E5DBB2864BF3450C3244EC72864CB21BFCF2864D3291AD72004DB23BFDF29B1E32864E720049B40049F5252A34864A749B1AB501DAF49B1B34864B74E5DBB4864BF4F1CC3423DC74864CB41BFCF4864D349B1D743BFDB49B1DF4864E343BFE740049F6004A369B1A76864AB69B1AF6D17B36864B769B1BB6864BF6F1CC3623DC76864CB69B1CF6864D36267D769B1DB6864DF69B1E36004A38004A79252AB8864AF8D17B38864B789B1BB8864BF8F1CC3823DC78864CB89B1CF8864D38267D78864DB83BFDF800452AE8012BEA0FD747A004696E80100";
        }

        if (v == Mouth.STOIC) {
            return hex"5F0C8010";
        }

        if (v == Mouth.UNEASY) {
            return hex"AF0004B700045F0C00132C00134C0012CC8012EC80131C80133C8010";
        }

        if (v == Mouth.SMIRK) {
            return hex"CF00045D2C8010";
        }
        revert("invalid mouth");
    }
}

library MiscSprites {
    function passSprite() external pure returns (bytes memory) {
        return hex"41F0230501C28C1A020985370828B808261CFC28C18040E0426123067102628101314DC4229E0404CE4409875F1230501868C19C60A2A066B2A4604CA866B2AC6AF158D1BFEAE19B257C46FFAC866C6CC6FFAD06FE5D46AF1D866C6DC604CE066B2E460A275E1A307F1838101888C19C80A2A09145A4804CA880F3576203EF720133823FEB920289D7C88C14062A30672828A829ACA9283EEA2AC6D5D8AAF1DCA0FBE0A6B2E4A0A275F2A30500CC8C190C0E04A63230673028A8308A69303ED538CAF15F0300118D8CAF1DCC0FBE0C229E4C0A275F32305018E8C19CE0A2A0F145A4E0FBA8EAD356D3ABC6E38012F3B8DB0380118D8EAF1DCE0FBE0F145E4E0A2E8E8C1ECE1A979F3A30501908C19D00A2A10229A500FB54C42BC6D40012E45EB2F400118590AF1DD00FBE10229E500A275F4230501928C19D20A2A126D5A520FB54B4ABC6C48012D4DEB2E4C1FEF480118592AF1DD20FBE126B2E520A275F4A30500D48C19148C34A65230675028A850A329503EEA52BC6B50012C55EB2D56196E541FEF55EB30500118CD4AF169550013652BC77503EF8508AB95028BA52313B5234BC5230DEFD48C18168C18562B58968D24665A30675828A85836E958132A5ABC6B58012C5DEB2D5E196E5C1FEF5DEB305C1FD8CD6004D17865D56004D96AF1DD604CE160ECE560A275C5A307D5A313E5A30FF58AD60622DA16231111988C19D80A2A180DBA5804CA98AF1AD8004B197ACB59865B9907FBD97ACC197F4634641FF560013662BC776013386036F960289D7D88C181A8C84266A30676828A869B1A968132A6ABC6B68012C6DEB2D6DFD2E6E196F6C1FF06DEB316DFD326DEB19D1B865D5A033D9AAF1DDA04CE1A6C6E5A0A2E9A8DDEDA8C1F1A8D17BF6A305011C8C195C8DD99C8F09DC0A2A1CFFAA5C04C54B72BC6C70012D75EB2E75FD2F76195851D07FD5C004D9CAF1DDC04CE1CFFAE5C04CE9C8F077C72345EFDC8C14037A30647A37657A3EE67A43277813287BFEA978131531EAF1B5E0045D07DEB18CDF865D1E0046B67ABC777813387BFEB978133A7A66DDF1E8FBF5E8F07DF7A34500608C18A08DD8E08F092090C9602D19A09A89E00A2A20FFAA6004C54D82BC574E000469682BC7780133883FEB98028BA8270FB8266FC8244BD80AF3E82377F8234608A37618A3C228A45E38A44A48A6BE58A7AA68A81E78828A889B1A98813155A2AF1DE204CE226C6E620A2EA2A1CEE29E2F229C3F62912FA28FBFE28F08248FA8648FB8A498F8E49A89249E2964A1C9A4A369E40A2A246C6A6404C556962AB790133891B1B99028BA92AE7B92987C928B7D927CFE9270FF9266E09A43219A66E29A6E239A7CE49A8B659AA2A69ABD679828A899B1A99813155A6AF1DE604CE266C6E660A2EA6B2AEE6AF5F26A7FF66A36FA6A13FE69B88289A88689CF8A89F38E8A48928AB9968B2B9A8B8D9E80A2A29145A6804CAA8AF156CA08A6DA2BC57468229CA8AF1675A08A76A2BC77A01338A45179A028BAA2F4FBA2DFBCA2C07DA2A73EA29BBFA281E0A8BC61AA8722AA9863AAB3E4AACAA5AAFAA6AB1D27A828A8AC5169A8132AAABC6BA88A6CAABC56BAA229BEAAF1C2A229C6AAF1653A88A74AABC75A88A76AABC77A81338AC5179A828BAAB337BAB117CAAE1FDAAC83EAAB13FA8C7E0B286E1B29FA2B2B5A3B2DD24B2F925B324E6B35667B028A8B45169B013155ACAF1DEC04CE2D145E6C0A2EACE15EECCFAF2CC60F6CBEAFACB65FECACF82EA6186EB018AEB7E8EEC2D92ECB596ED8D9AEEA19EE0A2A2E229A6E0FBAAEAF156EB88A6FBABC5846E229CAEAF1CEE229D2EAF1D6E229DAEAF1DEE04CE2E229E6E0A2EAEF25EEEE7CF2ED51F6ECA3FAEC02FEEB58830AD6870B658B0C368F0CCD930DA6970E749B0FA99F00A2A306C6A700FB54BC2BC6CC08A6DC2BC573F0229C30AF1632C08A73C2BC5A570229DB0AF1DF004CE306C6E700A2EB106AEF0F7DF30E95F70D83FB0C93FF0C02832B2B872C138B2CA38F2D9C932EC0972FD49B31279F20A2A326C6A720FB556CABC77C83EF8C9B1B9C828BACC7C3BCC20BCCBE7BDCBA1BECB567FCB1EE0D2EA21D32162D35663D3A864D3E7A5D44FA6D49227D028A8D45169D03ED55B58AADF40FBE34FFAE740A2EB52FBEF5208F35082F74F87FB4E6FFF4CFA836C2D876CFA8B6E468F6F8793711C9772299B734D9F60A2A37145A7604CAB60F3576D83EF7D81338DBFEB9D828BADD04FBDCB83CDC7C3DDC1ABEDBD5FFDB8560E324E1E36D62E3C463E41024E47BE5E4C3E6E504E7E028A8E1ACA9E0132AE1ACABE2BC56378FFABB86C95F1E3FEB2E1B1B3E3FEB4E3F975E2BC76E1B1B7E01338E1ACB9E028BAE525BBE4F37CE4B1BDE46EBEE3F83FE3BE60EB4121EB8062EBEDE3EC5E121BA0049FA098A3A04C537E88A78E81339E8261D73A004F7B27CFBB13EFFAF9E83CDB587CF118BD04F8FC004487F61968F61994AFD86CB3D8685B6F61B1BE3D86873CF6197DF0013EF47C3FF40560FB8DE1FBDF62FC5363FCA664F801129FF7AC509FC1FD533F7ACB7F07F5D2FDEB33FC1FDA5BF7AC6F8FC1FDCEFF7ACF3E004F7F3BCFBF27CFFF10F";
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Holds a string that can expand dynamically.
 */
struct StringBuffer {
    string[] buffer;
    uint numberOfStrings;
    uint totalStringLength;
}

library StringBufferLibrary {
    /**
     * @dev Copies 32 bytes of `src` starting at `srcIndex` into `dst` starting at `dstIndex`.
     */
    function memcpy32(string memory src, uint srcIndex, bytes memory dst, uint dstIndex) internal pure {
        assembly {
            mstore(add(add(dst, 32), dstIndex), mload(add(add(src, 32), srcIndex)))
        }
    }

    /**
     * @dev Copies 1 bytes of `src` at `srcIndex` into `dst` at `dstIndex`.
     *      This uses the same amount of gas as `memcpy32`, so prefer `memcpy32` if at all possible.
     */
    function memcpy1(string memory src, uint srcIndex, bytes memory dst, uint dstIndex) internal pure {
        assembly {
            mstore8(add(add(dst, 32), dstIndex), shr(248, mload(add(add(src, 32), srcIndex))))
        }
    }

    /**
     * @dev Copies a string into `dst` starting at `dstIndex` with a maximum length of `dstLen`.
     *      This function will not write beyond `dstLen`. However, if `dstLen` is not reached, it may write zeros beyond the length of the string.
     */
    function copyString(string memory src, bytes memory dst, uint dstIndex, uint dstLen) internal pure returns (uint) {
        uint srcIndex;
        uint srcLen = bytes(src).length;

        for (; srcLen > 31 && srcIndex < srcLen && srcIndex < dstLen - 31; srcIndex += 32) {
            memcpy32(src, srcIndex, dst, dstIndex + srcIndex);
        }
        for (; srcIndex < srcLen && srcIndex < dstLen; ++srcIndex) {
            memcpy1(src, srcIndex, dst, dstIndex + srcIndex);
        }

        return dstIndex + srcLen;
    }

    /**
     * @dev Adds `str` to the end of the internal buffer.
     */
    function pushToStringBuffer(StringBuffer memory self, string memory str) internal pure returns (StringBuffer memory) {
        if (self.buffer.length == self.numberOfStrings) {
            string[] memory newBuffer = new string[](self.buffer.length * 2);
            for (uint i = 0; i < self.buffer.length; ++i) {
                newBuffer[i] = self.buffer[i];
            }
            self.buffer = newBuffer;
        }

        self.buffer[self.numberOfStrings] = str;
        self.numberOfStrings++;
        self.totalStringLength += bytes(str).length;

        return self;
    }

    /**
     * @dev Concatenates `str` to the end of the last string in the internal buffer.
     */
    function concatToLastString(StringBuffer memory self, string memory str) internal pure {
        if (self.numberOfStrings == 0) {
            self.numberOfStrings++;
        }
        uint idx = self.numberOfStrings - 1;
        self.buffer[idx] = string(abi.encodePacked(self.buffer[idx], str));

        self.totalStringLength += bytes(str).length;
    }

    /**
     * @notice Creates a new empty StringBuffer
     * @dev The initial capacity is 16 strings
     */
    function empty() external pure returns (StringBuffer memory) {
        return StringBuffer(new string[](16), 0, 0);
    }

    /**
     * @notice Converts the contents of the StringBuffer into a string.
     * @dev This runs in O(n) time.
     */
    function get(StringBuffer memory self) internal pure returns (string memory) {
        bytes memory output = new bytes(self.totalStringLength);

        uint ptr = 0;
        for (uint i = 0; i < self.numberOfStrings; ++i) {
            ptr = copyString(self.buffer[i], output, ptr, self.totalStringLength);
        }

        return string(output);
    }

    /**
     * @notice Appends a string to the end of the StringBuffer
     * @dev Internally the StringBuffer keeps a `string[]` that doubles in size when extra capacity is needed.
     */
    function append(StringBuffer memory self, string memory str) internal pure {
        uint idx = self.numberOfStrings == 0 ? 0 : self.numberOfStrings - 1;
        if (bytes(self.buffer[idx]).length + bytes(str).length <= 1024) {
            concatToLastString(self, str);
        } else {
            pushToStringBuffer(self, str);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenURIProvider {
    function tokenURI(uint tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainScouts.sol";

abstract contract ChainScoutsExtension {
    IChainScouts internal chainScouts;

    modifier onlyAdmin() {
        require(chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: admins only");
        _;
    }

    modifier canAccessToken(uint tokenId) {
        require(chainScouts.canAccessToken(msg.sender, tokenId), "ChainScoutsExtension: you don't own the token");
        _;
    }

    function extensionKey() public virtual view returns (string memory);

    function setChainScouts(IChainScouts _contract) external {
        require(address(0) == address(chainScouts) || chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: The Chain Scouts contract must not be set or you must be an admin");
        chainScouts = _contract;
        chainScouts.adminSetExtension(extensionKey(), this);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// shamelessly stolen from the anonymice contract
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Integer {
    /**
     * @dev Gets the bit at the given position in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *
     *      For example: bitAt(2, 0) == 0, because the rightmost bit of 10 is 0
     *                   bitAt(2, 1) == 1, because the second to last bit of 10 is 1
     */
    function bitAt(uint integer, uint pos) internal pure returns (uint) {
        require(pos <= 255, "pos > 255");

        return (integer & (1 << pos)) >> pos;
    }

    function setBitAt(uint integer, uint pos) internal pure returns (uint) {
        return integer | (1 << pos);
    }

    /**
     * @dev Gets the value of the bits between left and right, both inclusive, in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *      
     *      For example: bitsFrom(10, 3, 1) == 7 (101 in binary), because 10 is *101*0 in binary
     *                   bitsFrom(10, 2, 0) == 2 (010 in binary), because 10 is 1*010* in binary
     */
    function bitsFrom(uint integer, uint left, uint right) internal pure returns (uint) {
        require(left >= right, "left > right");
        require(left <= 255, "left > 255");

        uint delta = left - right + 1;

        return (integer & (((1 << delta) - 1) << right)) >> right;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtensibleERC721Enumerable.sol";
import "./ChainScoutsExtension.sol";
import "./ChainScoutMetadata.sol";

interface IChainScouts is IExtensibleERC721Enumerable {
    function adminCreateChainScout(
        ChainScoutMetadata calldata tbd,
        address owner
    ) external;

    function adminRemoveExtension(string calldata key) external;

    function adminSetExtension(
        string calldata key,
        ChainScoutsExtension extension
    ) external;

    function adminSetChainScoutMetadata(
        uint256 tokenId,
        ChainScoutMetadata calldata tbd
    ) external;

    function getChainScoutMetadata(uint256 tokenId)
        external
        view
        returns (ChainScoutMetadata memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IExtensibleERC721Enumerable is IERC721Enumerable {
    function isAdmin(address addr) external view returns (bool);

    function addAdmin(address addr) external;

    function removeAdmin(address addr) external;

    function canAccessToken(address addr, uint tokenId) external view returns (bool);

    function adminTransfer(address from, address to, uint tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}