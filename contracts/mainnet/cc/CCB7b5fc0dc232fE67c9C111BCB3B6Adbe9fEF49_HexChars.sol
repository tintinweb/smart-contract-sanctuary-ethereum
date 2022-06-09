// SPDX-License-Identifier: Unlicense
// Creator: 0xBasedPixel; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet
pragma solidity ^0.8.0;

library HexChars {
    function getHex(uint _index) public pure returns (uint256) {
        uint256[16] memory hexChars = [
        uint256(48), uint256(49),
        uint256(50), uint256(51),
        uint256(52), uint256(53),
        uint256(54), uint256(55),
        uint256(56), uint256(57),
        uint256(65), uint256(66),
        uint256(67), uint256(68),
        uint256(69), uint256(70)
        ];

        return hexChars[_index];
    }
}