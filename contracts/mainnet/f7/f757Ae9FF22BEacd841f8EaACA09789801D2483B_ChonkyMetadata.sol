// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";
import {Base64} from "base64-sol/base64.sol";
import {ChonkyGenomeLib} from "./lib/ChonkyGenomeLib.sol";
import {ChonkyAttributes} from "./ChonkyAttributes.sol";
import {ChonkySet} from "./ChonkySet.sol";

import {IChonkyMetadata} from "./interface/IChonkyMetadata.sol";
import {IChonkySet} from "./interface/IChonkySet.sol";

contract ChonkyMetadata is IChonkyMetadata {
    using UintUtils for uint256;

    function buildTokenURI(
        uint256 id,
        uint256 genomeId,
        uint256 genome,
        string memory CID,
        address chonkyAttributes,
        address chonkySet
    ) public pure returns (string memory) {
        string
            memory description = "A collection of 7777 mischievous Chonky's ready to wreak havoc on the ETH blockchain.";
        string memory attributes = _buildAttributes(
            genome,
            chonkyAttributes,
            chonkySet
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"image":"ipfs://',
                                CID,
                                "/",
                                _buildPaddedID(genomeId),
                                '.png",',
                                '"description":"',
                                description,
                                '",',
                                '"name":"Chonky',
                                "'s #",
                                _buildPaddedID(id),
                                '",',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function _buildPaddedID(uint256 id) internal pure returns (string memory) {
        if (id == 0) return "0000";
        if (id < 10) return string(abi.encodePacked("000", id.toString()));
        if (id < 100) return string(abi.encodePacked("00", id.toString()));
        if (id < 1000) return string(abi.encodePacked("0", id.toString()));

        return id.toString();
    }

    ////

    function _getBGBase(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Aqua";
        if (id == 2) return "Black";
        if (id == 3) return "Brown";
        if (id == 4) return "Dark Purple";
        if (id == 5) return "Dark Red";
        if (id == 6) return "Gold";
        if (id == 7) return "Green";
        if (id == 8) return "Green Apple";
        if (id == 9) return "Grey";
        if (id == 10) return "Ice Blue";
        if (id == 11) return "Kaki";
        if (id == 12) return "Orange";
        if (id == 13) return "Pink";
        if (id == 14) return "Purple";
        if (id == 15) return "Rainbow";
        if (id == 16) return "Red";
        if (id == 17) return "Sky Blue";
        if (id == 18) return "Yellow";

        return "";
    }

    function _getBGRare(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "HamHam";
        if (id == 2) return "Japan";
        if (id == 3) return "Skulls";
        if (id == 4) return "Stars";

        return "";
    }

    function _getWings(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Angel";
        if (id == 2) return "Bat";
        if (id == 3) return "Bee";
        if (id == 4) return "Crystal";
        if (id == 5) return "Devil";
        if (id == 6) return "Dragon";
        if (id == 7) return "Fairy";
        if (id == 8) return "Plant";
        if (id == 9) return "Robot";

        return "";
    }

    function _getSkin(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Almond";
        if (id == 2) return "Aqua";
        if (id == 3) return "Blue";
        if (id == 4) return "Brown";
        if (id == 5) return "Cream";
        if (id == 6) return "Dark";
        if (id == 7) return "Dark Blue";
        if (id == 8) return "Gold";
        if (id == 9) return "Green";
        if (id == 10) return "Grey";
        if (id == 11) return "Ice";
        if (id == 12) return "Indigo";
        if (id == 13) return "Light Brown";
        if (id == 14) return "Light Purple";
        if (id == 15) return "Neon Blue";
        if (id == 16) return "Orange";
        if (id == 17) return "Pink";
        if (id == 18) return "Purple";
        if (id == 19) return "Rose White";
        if (id == 20) return "Salmon";
        if (id == 21) return "Skye Blue";
        if (id == 22) return "Special Red";
        if (id == 23) return "White";
        if (id == 24) return "Yellow";

        return "";
    }

    function _getPattern(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "3 Dots";
        if (id == 2) return "3 Triangles";
        if (id == 3) return "Corner";
        if (id == 4) return "Dalmatian";
        if (id == 5) return "Half";
        if (id == 6) return "Tiger Stripes";
        if (id == 7) return "Triangle";
        if (id == 8) return "White Reversed V";
        if (id == 9) return "Zombie";

        return "";
    }

    function _getPaint(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Beard";
        if (id == 2) return "Board";
        if (id == 3) return "Earrings";
        if (id == 4) return "Face Tattoo";
        if (id == 5) return "Happy Cheeks";
        if (id == 6) return "Pink Star";
        if (id == 7) return "Purple Star";
        if (id == 8) return "Scar";

        return "";
    }

    function _getBody(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Retro Shirt";
        if (id == 2) return "Angel Wings";
        if (id == 3) return "Aqua Monster";
        if (id == 4) return "Astronaut";
        if (id == 5) return "Bag";
        if (id == 6) return "Baron Samedi";
        if (id == 7) return "Bee";
        if (id == 8) return "Black Samurai";
        if (id == 9) return "Black Wizard";
        if (id == 10) return "Blue Football";
        if (id == 11) return "Blue Parka";
        if (id == 12) return "Blue Kimono";
        if (id == 13) return "Blue Hoodie";
        if (id == 14) return "Blue Wizard";
        if (id == 15) return "Jester";
        if (id == 16) return "Bubble Tea";
        if (id == 17) return "Captain";
        if (id == 18) return "Caveman";
        if (id == 19) return "Chef";
        if (id == 20) return "Chinese Shirt";
        if (id == 21) return "Cloth Monster";
        if (id == 22) return "Color Shirt";
        if (id == 23) return "Cowboy Shirt";
        if (id == 24) return "Cyber Assassin";
        if (id == 25) return "Devil Wings";
        if (id == 26) return "Scuba";
        if (id == 27) return "Doreamon";
        if (id == 28) return "Dracula";
        if (id == 29) return "Gold Chain";
        if (id == 30) return "Green Cyber";
        if (id == 31) return "Green Parka";
        if (id == 32) return "Green Kimono";
        if (id == 33) return "Green Hoodie";
        if (id == 34) return "Hamsterdam Shirt";
        if (id == 35) return "Hazard";
        if (id == 36) return "Hiding Hamster";
        if (id == 37) return "Pink Punk Girl";
        if (id == 38) return "Japanese Worker";
        if (id == 39) return "King";
        if (id == 40) return "Leather Jacket";
        if (id == 41) return "Leaves";
        if (id == 42) return "Lobster";
        if (id == 43) return "Luffy";
        if (id == 44) return "Magenta Cyber";
        if (id == 45) return "Sailor";
        if (id == 46) return "Mario Pipe";
        if (id == 47) return "Mommy";
        if (id == 48) return "Ninja";
        if (id == 49) return "Old Grandma";
        if (id == 50) return "Orange Jumpsuit";
        if (id == 51) return "Chili";
        if (id == 52) return "Chili Fire";
        if (id == 53) return "Pharaoh";
        if (id == 54) return "Pink Football";
        if (id == 55) return "Pink Ruff";
        if (id == 56) return "Pink Jumpsuit";
        if (id == 57) return "Pink Kimono";
        if (id == 58) return "Pink Polo";
        if (id == 59) return "Pirate";
        if (id == 60) return "Plague Doctor";
        if (id == 61) return "Poncho";
        if (id == 62) return "Purple Cyber";
        if (id == 63) return "Purple Polo";
        if (id == 64) return "Mystery Hoodie";
        if (id == 65) return "Rainbow Snake";
        if (id == 66) return "Red Ruff";
        if (id == 67) return "Red Punk Girl";
        if (id == 68) return "Red Samurai";
        if (id == 69) return "Referee";
        if (id == 70) return "Robotbod";
        if (id == 71) return "Robot Cyber";
        if (id == 72) return "Rocker";
        if (id == 73) return "Roman Legionary";
        if (id == 74) return "Safari";
        if (id == 75) return "Scout";
        if (id == 76) return "Sherlock";
        if (id == 77) return "Shirt";
        if (id == 78) return "Snow Coat";
        if (id == 79) return "Sparta";
        if (id == 80) return "Steampunk";
        if (id == 81) return "Suit";
        if (id == 82) return "Tie";
        if (id == 83) return "Tire";
        if (id == 84) return "Toga";
        if (id == 85) return "Tron";
        if (id == 86) return "Valkyrie";
        if (id == 87) return "Viking";
        if (id == 88) return "Wereham";
        if (id == 89) return "White Cloak";
        if (id == 90) return "Yellow Jumpsuit";
        if (id == 91) return "Zombie";

        return "";
    }

    function _getMouth(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Black Gas Mask Ninja";
        if (id == 2) return "Black Ninja Mask";
        if (id == 3) return "Shocked";
        if (id == 4) return "Creepy";
        if (id == 5) return "=D";
        if (id == 6) return "Drawing";
        if (id == 7) return "Duck";
        if (id == 8) return "Elegant Moustache";
        if (id == 9) return "Fire";
        if (id == 10) return "Gold Teeth";
        if (id == 11) return "Grey Futuristic Gas Mask";
        if (id == 12) return "Happy Open";
        if (id == 13) return "Goatee";
        if (id == 14) return "Honey";
        if (id == 15) return "Jack-O-Lantern";
        if (id == 16) return "Lipstick";
        if (id == 17) return "Little Moustache";
        if (id == 18) return "Luffy Smile";
        if (id == 19) return "Sanitary Mask";
        if (id == 20) return "Robot Mask";
        if (id == 21) return "Mega Happy";
        if (id == 22) return "Mega Tongue Out";
        if (id == 23) return "Meh";
        if (id == 24) return "Mexican Moustache";
        if (id == 25) return "Monster";
        if (id == 26) return "Moustache";
        if (id == 27) return "Drunk";
        if (id == 28) return "Fake Moustache";
        if (id == 29) return "Full";
        if (id == 30) return "Piece";
        if (id == 31) return "Stretch";
        if (id == 32) return "Ninja";
        if (id == 33) return "Normal";
        if (id == 34) return "Ohhhh";
        if (id == 35) return "Chili";
        if (id == 36) return "Purple Futuristic Gas Mask";
        if (id == 37) return "Red Gas Mask Ninja";
        if (id == 38) return "Red Ninja Mask";
        if (id == 39) return "Robot Mouth";
        if (id == 40) return "Scream";
        if (id == 41) return "Cigarette";
        if (id == 42) return "Smoking Pipe";
        if (id == 43) return "Square";
        if (id == 44) return "Steampunk";
        if (id == 45) return "Stitch";
        if (id == 46) return "Super Sad";
        if (id == 47) return "Thick Moustache";
        if (id == 48) return "Tongue";
        if (id == 49) return "Tongue Out";
        if (id == 50) return "Triangle";
        if (id == 51) return "Vampire";
        if (id == 52) return "Wave";
        if (id == 53) return "What";
        if (id == 54) return "YKWIM";

        return "";
    }

    function _getEyes(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "^_^";
        if (id == 2) return ">_<";
        if (id == 3) return "=_=";
        if (id == 4) return "3D";
        if (id == 5) return "Angry";
        if (id == 6) return "Button";
        if (id == 7) return "Confused";
        if (id == 8) return "Crazy";
        if (id == 9) return "Cute";
        if (id == 10) return "Cyber Glasses";
        if (id == 11) return "Cyclops";
        if (id == 12) return "Depressed";
        if (id == 13) return "Determined";
        if (id == 14) return "Diving Mask";
        if (id == 15) return "Drawing";
        if (id == 16) return "Morty";
        if (id == 17) return "Eyepatch";
        if (id == 18) return "Fake Moustache";
        if (id == 19) return "Flower Glasses";
        if (id == 20) return "Frozen";
        if (id == 21) return "Furious";
        if (id == 22) return "Gengar";
        if (id == 23) return "Glasses Depressed";
        if (id == 24) return "Goku";
        if (id == 25) return "Green Underwear";
        if (id == 26) return "Hippie";
        if (id == 27) return "Kawaii";
        if (id == 28) return "Line Glasses";
        if (id == 29) return "Looking Up";
        if (id == 30) return "Looking Up Happy";
        if (id == 31) return "Mini Sunglasses";
        if (id == 32) return "Monocle";
        if (id == 33) return "Monster";
        if (id == 34) return "Ninja";
        if (id == 35) return "Normal";
        if (id == 36) return "Not Impressed";
        if (id == 37) return "o_o";
        if (id == 38) return "Orange Underwear";
        if (id == 39) return "Pink Star Sunglasses";
        if (id == 40) return "Pissed";
        if (id == 41) return "Pixel Glasses";
        if (id == 42) return "Plague Doctor Mask";
        if (id == 43) return "Proud";
        if (id == 44) return "Raccoon";
        if (id == 45) return "Red Dot";
        if (id == 46) return "Red Star Sunglasses";
        if (id == 47) return "Robot Eyes";
        if (id == 48) return "Scared Eyes";
        if (id == 49) return "Snorkel";
        if (id == 50) return "Serious Japan";
        if (id == 51) return "Seriously";
        if (id == 52) return "Star";
        if (id == 53) return "Steampunk Glasses";
        if (id == 54) return "Sunglasses";
        if (id == 55) return "Sunglasses Triangle";
        if (id == 56) return "Surprised";
        if (id == 57) return "Thick Eyebrows";
        if (id == 58) return "Troubled";
        if (id == 59) return "UniBrow";
        if (id == 60) return "Weird";
        if (id == 61) return "X_X";

        return "";
    }

    function _getLostKing(uint256 _id) internal pure returns (string memory) {
        if (_id == 1) return "The Glitch King";
        if (_id == 2) return "The Gummy King";
        if (_id == 3) return "King Diamond";
        if (_id == 4) return "The King of Gold";
        if (_id == 5) return "King Unicorn";
        if (_id == 6) return "The Last King";
        if (_id == 7) return "The Monkey King";

        return "";
    }

    function _getHonorary(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Crunchies";
        if (id == 2) return "Chuckle";
        if (id == 3) return "ChainLinkGod";
        if (id == 4) return "Crypt0n1c";
        if (id == 5) return "Bigdham";
        if (id == 6) return "Cyclopeape";
        if (id == 7) return "Elmo";
        if (id == 8) return "Caustik";
        if (id == 9) return "Churby";
        if (id == 10) return "Chonko";
        if (id == 11) return "Hamham";
        if (id == 12) return "Icebergy";
        if (id == 13) return "IronHam";
        if (id == 14) return "RatWell";
        if (id == 15) return "VangogHam";
        if (id == 16) return "Boneham";

        return "";
    }

    function _getHat(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Retro";
        if (id == 2) return "Aqua Monster";
        if (id == 3) return "Astronaut";
        if (id == 4) return "Baby Hamster";
        if (id == 5) return "Baron Samedi";
        if (id == 6) return "Bear Skin";
        if (id == 7) return "Bee";
        if (id == 8) return "Beanie";
        if (id == 9) return "Beret";
        if (id == 10) return "Biker Helmet";
        if (id == 11) return "Black Afro";
        if (id == 12) return "Black Hair JB";
        if (id == 13) return "Black Kabuki Mask";
        if (id == 14) return "Black Kabuto";
        if (id == 15) return "Black Magician";
        if (id == 16) return "Black Toupee";
        if (id == 17) return "Bolts";
        if (id == 18) return "Jester";
        if (id == 19) return "Brain";
        if (id == 20) return "Brown Hair JB";
        if (id == 21) return "Candle";
        if (id == 22) return "Captain";
        if (id == 23) return "Cheese";
        if (id == 24) return "Chef";
        if (id == 25) return "Cloth Monster";
        if (id == 26) return "Cone";
        if (id == 27) return "Cowboy";
        if (id == 28) return "Crown";
        if (id == 29) return "Devil Horns";
        if (id == 30) return "Dracula";
        if (id == 31) return "Duck";
        if (id == 32) return "Elvis";
        if (id == 33) return "Fish";
        if (id == 34) return "Fan";
        if (id == 35) return "Fire";
        if (id == 36) return "Fluffy Beanie";
        if (id == 37) return "Pigskin";
        if (id == 38) return "Futuristic Crown";
        if (id == 39) return "Golden Horns";
        if (id == 40) return "Green Fire";
        if (id == 41) return "Green Knot";
        if (id == 42) return "Green Punk";
        if (id == 43) return "Green Visor";
        if (id == 44) return "Halo";
        if (id == 45) return "Headband";
        if (id == 46) return "Ice";
        if (id == 47) return "Injury";
        if (id == 48) return "Kabuto";
        if (id == 49) return "Leaf";
        if (id == 50) return "Lion Head";
        if (id == 51) return "Long Hair Front";
        if (id == 52) return "Magician";
        if (id == 53) return "Mario Flower";
        if (id == 54) return "Mini Cap";
        if (id == 55) return "Ninja Band";
        if (id == 56) return "Mushroom";
        if (id == 57) return "Ninja";
        if (id == 58) return "Noodle Cup";
        if (id == 59) return "Octopus";
        if (id == 60) return "Old Lady";
        if (id == 61) return "Pancakes";
        if (id == 62) return "Paper Hat";
        if (id == 63) return "Pharaoh";
        if (id == 64) return "Pink Exploding Hair";
        if (id == 65) return "Pink Hair Girl";
        if (id == 66) return "Pink Mini Cap";
        if (id == 67) return "Pink Punk";
        if (id == 68) return "Pink Visor";
        if (id == 69) return "Pirate";
        if (id == 70) return "Plague Doctor";
        if (id == 71) return "Plant";
        if (id == 72) return "Punk Helmet";
        if (id == 73) return "Purple Mini Cap";
        if (id == 74) return "Purple Top Hat";
        if (id == 75) return "Rainbow Afro";
        if (id == 76) return "Rainbow Ice Cream";
        if (id == 77) return "Red Black Hair Girl";
        if (id == 78) return "Red Knot";
        if (id == 79) return "Red Punk";
        if (id == 80) return "Red Top Hat";
        if (id == 81) return "Robot Head";
        if (id == 82) return "Roman Legionary";
        if (id == 83) return "Safari";
        if (id == 84) return "Sherlock";
        if (id == 85) return "Sombrero";
        if (id == 86) return "Sparta";
        if (id == 87) return "Steampunk";
        if (id == 88) return "Straw";
        if (id == 89) return "Straw Hat";
        if (id == 90) return "Teapot";
        if (id == 91) return "Tin Hat";
        if (id == 92) return "Toupee";
        if (id == 93) return "Valkyrie";
        if (id == 94) return "Viking";
        if (id == 95) return "White Kabuki Mask";
        if (id == 96) return "Yellow Exploding Hair";

        return "";
    }

    ////

    function _buildAttributes(
        uint256 genome,
        address chonkyAttributes,
        address chonkySet
    ) internal pure returns (string memory result) {
        uint256[12] memory attributes = ChonkyGenomeLib.parseGenome(genome);

        bytes memory buffer = abi.encodePacked(
            '"attributes":[',
            '{"trait_type":"Background",',
            '"value":"',
            _getBGBase(attributes[0]),
            '"}'
        );

        if (attributes[1] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ', {"trait_type":"Rare Background",',
                '"value":"',
                _getBGRare(attributes[1]),
                '"}'
            );
        }

        if (attributes[2] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Wings",',
                '"value":"',
                _getWings(attributes[2]),
                '"}'
            );
        }

        if (attributes[3] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Skin",',
                '"value":"',
                _getSkin(attributes[3]),
                '"}'
            );
        }

        if (attributes[4] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Pattern",',
                '"value":"',
                _getPattern(attributes[4]),
                '"}'
            );
        }

        if (attributes[5] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Paint",',
                '"value":"',
                _getPaint(attributes[5]),
                '"}'
            );
        }

        if (attributes[6] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Body",',
                '"value":"',
                _getBody(attributes[6]),
                '"}'
            );
        }

        if (attributes[7] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Mouth",',
                '"value":"',
                _getMouth(attributes[7]),
                '"}'
            );
        }

        if (attributes[8] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Eyes",',
                '"value":"',
                _getEyes(attributes[8]),
                '"}'
            );
        }

        if (attributes[9] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Hat",',
                '"value":"',
                _getHat(attributes[9]),
                '"}'
            );
        }

        if (attributes[10] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Lost King",',
                '"value":"',
                _getLostKing(attributes[10]),
                '"}'
            );
        }

        if (attributes[11] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Honorary",',
                '"value":"',
                _getHonorary(attributes[11]),
                '"}'
            );
        }

        uint256 setId = IChonkySet(chonkySet).getSetId(genome);

        if (setId > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Full Set",',
                '"value":"',
                IChonkySet(chonkySet).getSetFromId(setId),
                '"}'
            );
        }

        uint256[4] memory attributeValues = ChonkyAttributes(chonkyAttributes)
            .getAttributeValues(attributes, setId);

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Brain",',
            '"value":',
            attributeValues[0].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Cute",',
            '"value":',
            attributeValues[1].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Power",',
            '"value":',
            attributeValues[2].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Wicked",',
            '"value":',
            attributeValues[3].toString(),
            "}"
        );

        return string(abi.encodePacked(buffer, "]"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library UintUtils {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ChonkyGenomeLib {
    function parseGenome(uint256 _genome)
        internal
        pure
        returns (uint256[12] memory result)
    {
        assembly {
            mstore(result, sub(_genome, shl(5, shr(5, _genome))))

            mstore(
                add(result, 0x20),
                sub(shr(5, _genome), shl(3, shr(8, _genome)))
            )

            mstore(
                add(result, 0x40),
                sub(shr(8, _genome), shl(4, shr(12, _genome)))
            )

            mstore(
                add(result, 0x60),
                sub(shr(12, _genome), shl(5, shr(17, _genome)))
            )

            mstore(
                add(result, 0x80),
                sub(shr(17, _genome), shl(4, shr(21, _genome)))
            )

            mstore(
                add(result, 0xA0),
                sub(shr(21, _genome), shl(4, shr(25, _genome)))
            )

            mstore(
                add(result, 0xC0),
                sub(shr(25, _genome), shl(7, shr(32, _genome)))
            )

            mstore(
                add(result, 0xE0),
                sub(shr(32, _genome), shl(6, shr(38, _genome)))
            )

            mstore(
                add(result, 0x100),
                sub(shr(38, _genome), shl(6, shr(44, _genome)))
            )

            mstore(
                add(result, 0x120),
                sub(shr(44, _genome), shl(7, shr(51, _genome)))
            )

            mstore(
                add(result, 0x140),
                sub(shr(51, _genome), shl(3, shr(54, _genome)))
            )

            mstore(add(result, 0x160), shr(54, _genome))
        }
    }

    function formatGenome(uint256[12] memory _attributes)
        internal
        pure
        returns (uint256 genome)
    {
        genome =
            (_attributes[0]) +
            (_attributes[1] << 5) +
            (_attributes[2] << 8) +
            (_attributes[3] << 12) +
            (_attributes[4] << 17) +
            (_attributes[5] << 21) +
            (_attributes[6] << 25) +
            (_attributes[7] << 32) +
            (_attributes[8] << 38) +
            (_attributes[9] << 44) +
            (_attributes[10] << 51) +
            (_attributes[11] << 54);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IChonkyAttributes} from "./interface/IChonkyAttributes.sol";

contract ChonkyAttributes is IChonkyAttributes {
    function _getBodyAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 3) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 4) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 5) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 8) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 9) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 11) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 12) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 13) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 14) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 15) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 16) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 17) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 18) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 19) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 20) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 21) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 26) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 27) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 28) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 29) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 30) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 31) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 32) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 33) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 34) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 36) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 37) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 40) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 41) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 43) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 44) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 45) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 46) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 47) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 50) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 51) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 52) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 53) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 54) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 55) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 56) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 57) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 59) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 60) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 61) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 62) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 63) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 64) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 65) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 66) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 67) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 68) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 69) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 70) return (IChonkyAttributes.AttributeType.BRAIN, 10);
        if (_id == 71) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 72) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 73) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 74) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 75) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 76) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 77) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 78) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 79) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 80) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 81) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 82) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 83) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 84) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 85) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 86) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 87) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 88) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 89) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 90) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 91) return (IChonkyAttributes.AttributeType.WICKED, 8);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getEyesAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 3) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 4) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 5) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 7) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 8) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 10) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 11) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 12) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 13) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 14) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 15) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 16) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 17) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 18) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 19) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 20) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 21) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 22) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 25) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 26) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 27) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 28) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 29) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 30) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 31) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 32) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 33) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 34) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 35) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 36) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 37) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 41) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 43) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 44) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 45) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 48) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 50) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 51) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 52) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 53) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 54) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 55) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 56) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 57) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 59) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 60) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 61) return (IChonkyAttributes.AttributeType.WICKED, 3);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getMouthAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 3) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 4) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 5) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 6) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 8) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 9) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 11) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 12) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 13) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 14) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 15) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 16) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 17) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 18) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 19) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 20) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 21) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 26) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 27) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 28) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 29) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 30) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 31) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 33) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 34) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 36) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 38) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 39) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 40) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 41) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 42) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 43) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 44) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 45) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 48) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 50) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 51) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 52) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 53) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 54) return (IChonkyAttributes.AttributeType.NONE, 0);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getHatAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 3) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 4) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 5) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 8) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 11) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 12) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 13) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 14) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 15) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 16) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 17) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 18) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 19) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 20) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 21) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 23) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 24) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 26) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 27) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 28) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 29) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 30) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 31) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 33) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 34) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 36) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 38) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 41) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 43) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 44) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 45) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 46) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 50) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 51) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 52) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 53) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 54) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 55) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 56) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 57) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 58) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 59) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 60) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 61) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 62) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 63) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 64) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 65) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 66) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 67) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 68) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 69) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 70) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 71) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 72) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 73) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 74) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 75) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 76) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 77) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 78) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 79) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 80) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 81) return (IChonkyAttributes.AttributeType.BRAIN, 10);
        if (_id == 82) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 83) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 84) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 85) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 86) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 87) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 88) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 89) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 90) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 91) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 92) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 93) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 94) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 95) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 96) return (IChonkyAttributes.AttributeType.POWER, 2);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getWingsAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 3) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 4) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 5) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 6) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 8) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 9) return (IChonkyAttributes.AttributeType.BRAIN, 9);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getSetAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 3) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 4) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 5) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 6) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 7) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 8) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 11) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 12) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 13) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 14) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 15) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 16) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 17) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 18) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 19) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 20) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 21) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 22) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 23) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 25) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 26) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 27) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 28) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 29) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 30) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 31) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 33) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 34) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 35) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 36) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 41) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 42) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 43) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 44) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 45) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 47) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 49) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 50) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 51) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 52) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 53) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 54) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 55) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 56) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 57) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.CUTE, 0);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _addAttributeValue(
        uint256[4] memory _array,
        uint256 _value,
        IChonkyAttributes.AttributeType _valueType
    ) internal pure returns (uint256[4] memory) {
        if (_valueType != IChonkyAttributes.AttributeType.NONE) {
            _array[uint256(_valueType) - 1] += _value;
        }

        return _array;
    }

    function getAttributeValues(uint256[12] memory _attributes, uint256 _setId)
        public
        pure
        returns (uint256[4] memory result)
    {
        uint256 value;
        IChonkyAttributes.AttributeType valueType;

        (valueType, value) = _getWingsAttribute(_attributes[2]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getBodyAttribute(_attributes[6]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getMouthAttribute(_attributes[7]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getEyesAttribute(_attributes[8]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getHatAttribute(_attributes[9]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getSetAttribute(_setId);
        result = _addAttributeValue(result, value, valueType);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IChonkySet} from "./interface/IChonkySet.sol";

contract ChonkySet is IChonkySet {
    function getSetId(uint256 _genome) external pure returns (uint256) {
        return _getSetId(_genome);
    }

    function getSetFromGenome(uint256 _genome)
        external
        pure
        returns (string memory)
    {
        return _getSetFromId(_getSetId(_genome));
    }

    function getSetFromId(uint256 _setId)
        external
        pure
        returns (string memory)
    {
        return _getSetFromId(_setId);
    }

    function _getSetId(uint256 _genome) internal pure returns (uint256) {
        if (_genome == 0x025e716c06d02c) return 1;
        if (_genome == 0x02c8cca802518f) return 2;
        if (_genome == 0x38e108027089) return 3;
        if (_genome == 0x51ad0c0d7065) return 4;
        if (_genome == 0x704e0ea50332) return 5;
        if (_genome == 0xec821004d052) return 6;
        if (_genome == 0x0398a060045048) return 7;
        if (_genome == 0x05836b2008d04c) return 8;
        if (_genome == 0x016daf22043029) return 9;
        if (_genome == 0x635b242d4063) return 10;
        if (_genome == 0x018ac826022089) return 11;
        if (_genome == 0x035edd5c064089) return 12;
        if (_genome == 0x0190002a000049) return 13;
        if (_genome == 0x01bcda2e0e8083) return 14;
        if (_genome == 0x028e4d4608d068) return 15;
        if (_genome == 0x0402a45842e02c) return 16;
        if (_genome == 0x04f16530657022) return 17;
        if (_genome == 0x013bd48e40f02e) return 18;
        if (_genome == 0xf15712212084) return 19;
        if (_genome == 0x01de0966016582) return 20;
        if (_genome == 0x03b39e3407208f) return 21;
        if (_genome == 0x0228cc3608304a) return 22;
        if (_genome == 0x01eb7338017065) return 23;
        if (_genome == 0x055e587a084032) return 24;
        if (_genome == 0x04a81aa20e3029) return 25;
        if (_genome == 0x8dca3a044022) return 26;
        if (_genome == 0x01504f2c07006c) return 27;
        if (_genome == 0x02d6224c10304a) return 28;
        if (_genome == 0x012d101e0b2084) return 29;
        if (_genome == 0x01c7954e028086) return 30;
        if (_genome == 0x251906042067) return 31;
        if (_genome == 0x059e125704d065) return 32;
        if (_genome == 0x0510008c000049) return 33;
        if (_genome == 0x038974520c408b) return 34;
        if (_genome == 0x0326df280cd086) return 35;
        if (_genome == 0x03ca296204d050) return 36;
        if (_genome == 0x03ff216a058092) return 37;
        if (_genome == 0x04545a76104062) return 38;
        if (_genome == 0x046a8078041067) return 39;
        if (_genome == 0x04b6d18200508f) return 40;
        if (_genome == 0x030ca68808d042) return 41;
        if (_genome == 0x168502c5802f) return 42;
        if (_genome == 0x052e28920ea089) return 43;
        if (_genome == 0x05380894022085) return 44;
        if (_genome == 0x054cea9808d023) return 45;
        if (_genome == 0x02ea56160eb08a) return 46;
        if (_genome == 0x0560009e02a082) return 47;
        if (_genome == 0x023f63680b0090) return 48;
        if (_genome == 0x057d6ca0044983) return 49;
        if (_genome == 0x01fc6ba6aa502d) return 50;
        if (_genome == 0x031b320a00104b) return 51;
        if (_genome == 0x05bd27480ea089) return 52;
        if (_genome == 0x40db5e110028) return 53;
        if (_genome == 0x02b157aa0eb021) return 54;
        if (_genome == 0x05dae8aca25192) return 55;
        if (_genome == 0x05e568ae048023) return 56;
        if (_genome == 0x011875b6129067) return 57;

        return 0;
    }

    function _getSetFromId(uint256 _id) internal pure returns (string memory) {
        if (_id == 1) return "American Football";
        if (_id == 2) return "Angel";
        if (_id == 3) return "Astronaut";
        if (_id == 4) return "Baron Samedi";
        if (_id == 5) return "Bee";
        if (_id == 6) return "Black Kabuto";
        if (_id == 7) return "Blue Ninja";
        if (_id == 8) return "Bubble Tea";
        if (_id == 9) return "Captain";
        if (_id == 10) return "Caveman";
        if (_id == 11) return "Chef";
        if (_id == 12) return "Chonky Plant";
        if (_id == 13) return "Cloth Monster";
        if (_id == 14) return "Cowboy";
        if (_id == 15) return "Crazy Scientist";
        if (_id == 16) return "Cyber Hacker";
        if (_id == 17) return "Cyberpunk";
        if (_id == 18) return "Cyborg";
        if (_id == 19) return "Dark Magician";
        if (_id == 20) return "Devil";
        if (_id == 21) return "Diver";
        if (_id == 22) return "Doraemon";
        if (_id == 23) return "Dracula";
        if (_id == 24) return "Ese Sombrero";
        if (_id == 25) return "Gentleman";
        if (_id == 26) return "Golden Tooth";
        if (_id == 27) return "Jack-O-Lantern";
        if (_id == 28) return "Japanese Drummer";
        if (_id == 29) return "Jester";
        if (_id == 30) return "King";
        if (_id == 31) return "Lake Monster";
        if (_id == 32) return "Luffy";
        if (_id == 33) return "Mr Roboto";
        if (_id == 34) return "Mushroom Guy";
        if (_id == 35) return "New Year Outfit";
        if (_id == 36) return "Old Lady";
        if (_id == 37) return "Pharaoh";
        if (_id == 38) return "Pirate";
        if (_id == 39) return "Plague Doctor";
        if (_id == 40) return "Rainbow Love";
        if (_id == 41) return "Red Samurai";
        if (_id == 42) return "Retro";
        if (_id == 43) return "Roman";
        if (_id == 44) return "Safari Hunter";
        if (_id == 45) return "Sherlock";
        if (_id == 46) return "Snow Dude";
        if (_id == 47) return "Sparta";
        if (_id == 48) return "Spicy Man";
        if (_id == 49) return "Steampunk";
        if (_id == 50) return "Swimmer";
        if (_id == 51) return "Tanuki";
        if (_id == 52) return "Tin Man";
        if (_id == 53) return "Tired Dad";
        if (_id == 54) return "Tron Boy";
        if (_id == 55) return "Valkyrie";
        if (_id == 56) return "Viking";
        if (_id == 57) return "Zombie";

        return "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkyMetadata {
    function buildTokenURI(
        uint256 id,
        uint256 genomeId,
        uint256 genome,
        string memory CID,
        address chonkySet,
        address chonkyAttributes
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkySet {
    function getSetId(uint256 _genome) external pure returns (uint256);

    function getSetFromGenome(uint256 _genome)
        external
        pure
        returns (string memory);

    function getSetFromId(uint256 _setId) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkyAttributes {
    enum AttributeType {
        NONE,
        BRAIN,
        CUTE,
        POWER,
        WICKED
    }

    function getAttributeValues(uint256[12] memory _attributes, uint256 _setId)
        external
        pure
        returns (uint256[4] memory result);
}