// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Bafkrey {
    bytes32 private constant _BASE32_SYMBOLS = "abcdefghijklmnopqrstuvwxyz234567";

    /// Transfom uint256 to IPFS CID V1 base32 raw (starting with "bafkrei")
    function uint256ToCid(uint256 id) internal pure returns (string memory) {
        // IPFS CID V1 base32 raw "bafrei..." => 5 bits => uint32
        // uint256 id  = 256 bits = 1 bit + 51 uint32 = 1 + 51 * 5 = 256
        // 00 added right =>
        // uint8 + uint256 + 00 = 258 bits = uint8 + 50 uint32 + (3 bits + 00) = uint8 + 51 uint32 = 3 + 51 * 5 = 258

        bytes memory buffer = new bytes(52);
        uint8 high3 = uint8(id >> 253);
        buffer[0] = _BASE32_SYMBOLS[high3 & 0x1f];

        id <<= 2;
        for (uint256 i = 51; i > 0; i--) {
            buffer[i] = _BASE32_SYMBOLS[id & 0x1f];
            id >>= 5;
        }

        return string(abi.encodePacked("bafkrei", buffer));
    }
}