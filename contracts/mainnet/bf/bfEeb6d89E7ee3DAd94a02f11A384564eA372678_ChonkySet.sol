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

interface IChonkySet {
    function getSetId(uint256 _genome) external pure returns (uint256);

    function getSetFromGenome(uint256 _genome)
        external
        pure
        returns (string memory);

    function getSetFromId(uint256 _setId) external pure returns (string memory);
}