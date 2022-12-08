// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {EquipmentRarity, EquipmentType} from "./interfaces/IAnomuraEquipment.sol";

interface IEquipmentData {
    function pluckType(uint256) external view returns (EquipmentType);

    function pluckBody(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckClaws(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckLegs(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckShell(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckHeadpieces(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckHabitat(uint256)
        external
        view
        returns (string memory, EquipmentRarity);
}

contract EquipmentData is IEquipmentData {
    string[18] public BODY_PARTS = [
        "Premier Body",
        "Unhinged Body",
        "Mesmerizing Body",
        "Rave Body",
        "Combustion Body",
        "Radiating Eye",
        "Charring Body",
        "Inferno Body",
        "Siberian Body",
        "Antarctic Body",
        "Glacial Body",
        "Amethyst Body",
        "Beast",
        "Panga Panga",
        "Ceylon Ebony",
        "Katalox",
        "Diamond",
        "Golden"
    ];
    string[12] public CLAW_PARTS = [
        "Natural Claw",
        "Coral Claw",
        "Titian Claw",
        "Pliers",
        "Scissorhands",
        "Laser Gun",
        "Snow Claw",
        "Sky Claw",
        "Icicle Claw",
        "Pincers",
        "Hammer Logs",
        "Carnivora Claw"
    ];
    string[12] public LEGS_PARTS = [
        "Argent Leg",
        "Sunlit Leg",
        "Auroral Leg",
        "Steel Leg",
        "Tungsten Leg",
        "Titanium Leg",
        "Crystal Leg",
        "Empyrean Leg",
        "Azure Leg",
        "Bamboo Leg",
        "Walmara Leg",
        "Pintobortri Leg"
    ];
    string[30] public SHELL_PARTS = [
        "Auger Shell",
        "Seasnail Shell",
        "Miter Shell",
        "Alembic",
        "Chimney",
        "Starship",
        "Ice Cube",
        "Ice Shell",
        "Frosty",
        "Mora",
        "Carnivora",
        "Pure Runes",
        "Architect",
        "Bee Hive",
        "Coral",
        "Crystal",
        "Diamond",
        "Ethereum",
        "Golden Skull",
        "Japan Temple",
        "Planter",
        "Snail",
        "Tentacles",
        "Tesla Coil",
        "Cherry Blossom",
        "Maple Green",
        "Volcano",
        "Gates of Hell",
        "Holy Temple",
        "ZED Skull"
    ];
    string[24] public HEADPIECES_PARTS = [
        "Morning Sun Starfish",
        "Granulated Starfish",
        "Royal Starfish",
        "Sapphire",
        "Emerald",
        "Kunzite",
        "Rhodonite",
        "Aventurine",
        "Peridot",
        "Moldavite",
        "Jasper",
        "Alexandrite",
        "Copper Fire",
        "Chemical Fire",
        "Carmine Fire",
        "Charon",
        "Deimos",
        "Ganymede",
        "Sol",
        "Sirius",
        "Vega",
        "Aconite Skull",
        "Titan Arum Skull",
        "Nerium Oleander Skull"
    ];
    string[21] public HABITAT_PARTS = [
        "Crystal Cave",
        "Crystal Cave Rainbow",
        "Emerald Forest",
        "Garden of Eden",
        "Golden Glade",
        "Beach",
        "Magical Deep Sea",
        "Natural Sea",
        "Bioluminescent Abyss",
        "Blazing Furnace",
        "Steam Apparatus",
        "Science Lab",
        "Starship Throne",
        "Happy Snowfield",
        "Midnight Mountain",
        "Cosmic Star",
        "Sunset Cliffs",
        "Space Nebula",
        "Plains of Vietnam",
        "ZED Run",
        "African Savannah"
    ];
    string[28] public PREFIX_ATTRS = [
        "Briny",
        "Tempestuous",
        "Limpid",
        "Pacific",
        "Atlantic",
        "Abysmal",
        "Profound",
        "Misty",
        "Solar",
        "Empyrean",
        "Sideral",
        "Astral",
        "Ethereal",
        "Crystal",
        "Quantum",
        "Empiric",
        "Alchemic",
        "Crash Test",
        "Nuclear",
        "Syntethic",
        "Tempered",
        "Fossil",
        "Craggy",
        "Gemmed",
        "Verdant",
        "Lymphatic",
        "Gnarled",
        "Lithic"
    ];
    string[24] public SUFFIX_ATTRS = [
        "of the Coast",
        "of Maelstrom",
        "of Depths",
        "of Eternity",
        "of Peace",
        "of Equilibrium",
        "of the Universe",
        "of the Galaxy",
        "of Absolute Zero",
        "of Constellations",
        "of the Moon",
        "of Lightspeed",
        "of Evidence",
        "of Relativity",
        "of Evolution",
        "of Consumption",
        "of Progress",
        "of Damascus",
        "of Gaia",
        "of The Wild",
        "of Overgrowth",
        "of Rebirth",
        "of World Roots",
        "of Stability"
    ];
    string[24] public UNIQUE_ATTRS = [
        "The Leviathan",
        "Will of Oceanus",
        "Suijin's Touch",
        "Tiamat Kiss",
        "Poseidon Vow",
        "Long bao",
        "Uranus Wish",
        "Aim of Indra",
        "Cry of Yuki Onna",
        "Sirius",
        "Vega",
        "Altair",
        "Ephestos Skill",
        "Gift of Prometheus",
        "Pandora's",
        "Wit of Lu Dongbin",
        "Thoth's Trick",
        "Cyclopes Plan",
        "Root of Dimu",
        "Bhumi's Throne",
        "Rive of Daphne",
        "The Minotaur",
        "Call of Cernunnos",
        "Graze of Terra"
    ];
    string[4] public BACKGROUND_PREFIX_ATTRS = [
        "Bountiful",
        "Isolated",
        "Mechanical",
        "Reborn"
    ];

    constructor() {}

    /* 
    1 / 25 = 4% headpieces => 96% rest, for 5 other parts
    0       -     191 = BODY
    192     -     383 = CLAWS
    384     -     575 = LEGS
    576     -     767 = SHELL
    768     -     959 = HABITAT
    960     -     999 - HEADPIECES
    */
    function pluckType(uint256 prob)
        external
        pure
        returns (EquipmentType typeOf)
    {
        uint256 rand = prob % 1000;

        if (rand < 192) typeOf = EquipmentType.BODY;
        else if (rand < 192 * 2) typeOf = EquipmentType.CLAWS;
        else if (rand < 192 * 3) typeOf = EquipmentType.LEGS;
        else if (rand < 192 * 4) typeOf = EquipmentType.SHELL;
        else if (rand < 192 * 5) typeOf = EquipmentType.HABITAT;
        else typeOf = EquipmentType.HEADPIECES;
    }

    function pluckBody(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.BODY);
    }

    function pluckClaws(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.CLAWS);
    }

    function pluckLegs(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.LEGS);
    }

    function pluckShell(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.SHELL);
    }

    function pluckHeadpieces(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(
            prob,
            EquipmentType.HEADPIECES
        );
    }

    function pluckHabitat(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluckBackground(prob);
    }

    function pluckBackground(uint256 _seed)
        internal
        view
        returns (string memory output, EquipmentRarity)
    {
        uint256 randomCount = 0;
        uint256 greatness = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        ) % 51;
        uint256 randNameSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );
        uint256 randPartSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );

        output = HABITAT_PARTS[randNameSeed % HABITAT_PARTS.length];

        if (greatness > 45) {
            output = string(
                abi.encodePacked(
                    BACKGROUND_PREFIX_ATTRS[
                        randPartSeed % BACKGROUND_PREFIX_ATTRS.length
                    ],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.RARE);
        }
        return (output, EquipmentRarity.NORMAL); // does not have any special attributes
    }

    function pluck(uint256 _seed, EquipmentType typeOf)
        internal
        view
        returns (string memory output, EquipmentRarity)
    {
        uint256 randomCount = 0;
        uint256 greatness = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        ) % 94;
        uint256 randNameSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );
        uint256 randPartSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );

        if (typeOf == EquipmentType.BODY) {
            output = BODY_PARTS[randNameSeed % BODY_PARTS.length];
        } else if (typeOf == EquipmentType.CLAWS) {
            output = CLAW_PARTS[randNameSeed % CLAW_PARTS.length];
        } else if (typeOf == EquipmentType.LEGS) {
            output = LEGS_PARTS[randNameSeed % LEGS_PARTS.length];
        } else if (typeOf == EquipmentType.SHELL) {
            output = SHELL_PARTS[randNameSeed % SHELL_PARTS.length];
        } else if (typeOf == EquipmentType.HEADPIECES) {
            output = HEADPIECES_PARTS[randNameSeed % HEADPIECES_PARTS.length];
        } else if (typeOf == EquipmentType.HABITAT) {
            output = HABITAT_PARTS[randNameSeed % HABITAT_PARTS.length];
        }

        if (greatness > 92) {
            output = string(
                abi.encodePacked(
                    UNIQUE_ATTRS[randPartSeed % UNIQUE_ATTRS.length],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.LEGENDARY);
        }

        if (greatness > 83) {
            output = string(
                abi.encodePacked(
                    PREFIX_ATTRS[randPartSeed % PREFIX_ATTRS.length],
                    " ",
                    output,
                    " ",
                    SUFFIX_ATTRS[randPartSeed % SUFFIX_ATTRS.length]
                )
            );
            return (output, EquipmentRarity.RARE);
        }

        if (greatness > 74) {
            output = string(
                abi.encodePacked(
                    output,
                    " ",
                    SUFFIX_ATTRS[randPartSeed % SUFFIX_ATTRS.length]
                )
            );
            return (output, EquipmentRarity.MAGIC);
        }

        if (greatness > 65) {
            output = string(
                abi.encodePacked(
                    PREFIX_ATTRS[randPartSeed % PREFIX_ATTRS.length],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.MAGIC);
        }
        return (output, EquipmentRarity.NORMAL); // does not have any special attributes
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAnomuraEquipment  { 
    function isTokenExists(uint256 _tokenId) external view returns(bool); 
    function getMetadataForToken(uint256 _tokenId) external view returns(EquipmentMetadata memory);
    function setMetaDataForToken(bytes calldata performData) external; 
    function getTotalSupply() external view returns(uint256); 
}

// This will likely change in the future, this should not be used to store state, or can only use inside a mapping
struct EquipmentMetadata {
    string name;
    EquipmentType equipmentType;
    EquipmentRarity equipmentRarity;
    bool isSet;
}

/// @notice equipment information
enum EquipmentType {
    BODY,
    CLAWS,
    LEGS,
    SHELL,
    HEADPIECES,
    HABITAT
}

/// @notice rarity information
enum EquipmentRarity {
    NORMAL,
    MAGIC,
    RARE,
    LEGENDARY 
}