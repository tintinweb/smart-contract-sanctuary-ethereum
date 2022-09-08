// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Arrow is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "Arrow";
    }

    function reverse(uint256 x) public pure returns (uint256) {
        x = (x & 0x5555555555555555555555555555555555555555555555555555555555555555) << 1 |
            (x & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA) >> 1;
        x = (x & 0x3333333333333333333333333333333333333333333333333333333333333333) << 2 |
            (x & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC) >> 2;
        x = (x & 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) << 4 |
            (x & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0) >> 4;
        x = (x & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8 |
            (x & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8;
        x = (x & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16 |
            (x & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16;
        x = (x & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32 |
            (x & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32;
        x = (x & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64 |
            (x & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64;
        x = (x & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << 128 |
            (x & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 128;
        return x;
    }

    function run(uint256[64] memory canvas, uint8 lastIndex)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[2] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0xe000f000f8007c003e001f000f8007c003e001f000f8007c003e001f000f0007, // Diagonal Line
            0xe000f000f8007c003e001f000f8007c103e301f700ff007f003f007f00ff01ff  // Downwards Arrow down 
        ];

        if (canvas[61] != sprites[1]) { // Downright Arrow
            return (61, sprites[1]);
        } else if (canvas[43] != reverse(sprites[1])) { // Upsidedown Arrow
            return (43, reverse(sprites[1]));
        } else if (canvas[52] != sprites[0]) { // Diagonal Line
            return (52, sprites[0]);
        } 
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISnowV1Program {
    function name() external view returns (string memory);

    function run(uint256[64] memory canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISnowV1Program} from "./ISnowV1Program.sol";

contract TicTacToe is ISnowV1Program {
    function name() external view returns (string memory) {
        return "MultiTileProgramBackwards";
    }

    function run(uint256[64] calldata canvas, uint8 /* lastUpdatedIndex */) external returns (uint8 index, uint256 value) {
        // bottom left 3x3 tiles
        uint8[9] memory indices = [ 40, 41, 42, 48, 49, 50, 56, 57, 58 ];
        uint256[9] memory values = [
            0x0001000108090c11046106410281010107810c4118213011001100010001ffff,
            0x8001800183f18611841198099009b011a011a011a031906198c187818001ffff,
            0x80008000860c8308819880908070806080b081108318860c8c0480008000ffff,
            0xffff0001000118210c410481038102010701098118c13041002100010001ffff,
            0xffff8001800188118c31846182c181818101828186c18c61983180018001ffff,
            0xffff8000800083e086308c18880888088808880888108810847083c08000ffff,
            0xffff0001000101e107310411081908090809080908190831046107c100010001,
            0xffff8001800187e18c3188119011901190119011981188318fe1800180018001,
            0xffff8000800087c08460842086208020806080c0808080808000800080808000
        ];

        uint256 i = 9;
        unchecked {
            // look for tiles that have not been painted yet or have been stomped on
            // inspired by https://hackmd.io/@axic/snow-qr-nft
            while (canvas[indices[i-1]] == values[i-1] && i > 0) {
                --i;
            }
        }

        return (indices[i-1], values[i-1]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";

contract Sprite is ISnowV1Program {
    uint8 private lastIndex;
    uint8 private spriteIndex;

    function name() external pure returns (string memory) {
        return "Sprite";
    }

    function run(uint256[64] memory, uint8)
        external
        returns (uint8 index, uint256 value)
    {
        uint256[5] memory sprites = [
            // Sprites created with https://snow.computer/operators
            0xffff8139bd45bd6dbd6dbf6dbf6dbf6dbf6db16db16dbd6dbd6dbd6d816dffff,
            0x00007ec642ba4292429240924092409240924e924e924292429242927e920000,
            0xffff8139bd45bd6dbd6dbf6dbf6dbf6dbf6db16db16dbd6dbd6dbd6d816dffff,
            0x00007ec642ba4292429240924092409240924e924e924292429242927e920000,
            0xffff8139bd45bd6dbd6dbf6dbf6dbf6dbf6db16db16dbd6dbd6dbd6d816dffff
        ];

        spriteIndex = (spriteIndex + 1) % 5;
        lastIndex = (lastIndex + 1) % 64;

        return (lastIndex, sprites[spriteIndex]);
    }
}