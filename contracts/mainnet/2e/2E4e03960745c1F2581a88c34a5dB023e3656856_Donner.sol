//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Donner {
    string public constant encrypted = "15b6e0bb28c9a44f60513a909a35bca8df31a05b71eeb5b2220facb1c4c4d89c";

    function encrypter(uint8 a_, uint8 b_, bytes calldata plainText_) public pure returns (bytes memory) {
        bytes memory cipherText = new bytes(plainText_.length);
        for (uint i = 0; i < plainText_.length; i++) {
            uint16 x = ((a_ * (uint8(plainText_[i]) >> 4)) + b_) % 16;
            uint16 y = ((a_ * (uint8(plainText_[i]) << 4 >> 4)) + b_) % 16;
            cipherText[i] =  bytes1(uint8(x << 4 | y));
        }
        return bytes(cipherText);
    }
}