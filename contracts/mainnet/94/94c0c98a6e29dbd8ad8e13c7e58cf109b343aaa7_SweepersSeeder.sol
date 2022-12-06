// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ISweepersSeeder } from './interfaces/ISweepersSeeder.sol';
import { ISweepersDescriptor } from './interfaces/ISweepersDescriptor.sol';

contract SweepersSeeder is ISweepersSeeder {

    uint256 public snowmanStart = 1670871600;
    uint256 public treeStart = 1671562800;
    uint256 public treeEnd = 1672513200;

    function setSpecialTimes(uint256 _snowmanStart, uint256 _treeStart, uint256 _treeEnd) external {
        require(msg.sender == 0x9D0717fAdDb61c48e3fCE46ABC2B2DCAA43D1255);
        snowmanStart = _snowmanStart;
        treeStart = _treeStart;
        treeEnd = _treeEnd;
    }
    
    /**
     * @notice Generate a pseudo-random Sweeper seed using the previous blockhash and sweeper ID.
     */
    // prettier-ignore
    function generateSeed(uint256 sweeperId, ISweepersDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), sweeperId))
        );

        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 eyesCount = descriptor.eyesCount();
        uint256 mouthCount = descriptor.mouthCount();

        uint48 backgroundRandomness = uint48(pseudorandomness) % 400;
        uint48 randomBackground;

        if(block.timestamp >= snowmanStart && block.timestamp < treeStart) {
            if(backgroundRandomness == 0) {
                randomBackground = 3;
            } else if(backgroundRandomness <= 2) {
                randomBackground = 11;
            } else if(backgroundRandomness <= 6) {
                randomBackground = 14;
            } else if(backgroundRandomness <= 18) {
                randomBackground = 21;
            } else if(backgroundRandomness <= 58) {
                randomBackground = 23;
            } else if(backgroundRandomness <= 92) {
                randomBackground = 2;
            } else if(backgroundRandomness <= 126) {
                randomBackground = 5;
            } else if(backgroundRandomness <= 160) {
                randomBackground = 6;
            } else if(backgroundRandomness <= 194) {
                randomBackground = 7;
            } else if(backgroundRandomness <= 228) {
                randomBackground = 8;
            } else if(backgroundRandomness <= 262) {
                randomBackground = 9;
            } else if(backgroundRandomness <= 296) {
                randomBackground = 10;
            } else if(backgroundRandomness <= 331) {
                randomBackground = 1;
            } else if(backgroundRandomness <= 365) {
                randomBackground = 12;
            } else {
                randomBackground = 17;
            }
        } else if(block.timestamp >= treeStart && block.timestamp <= treeEnd) {
            if(backgroundRandomness == 0) {
                randomBackground = 3;
            } else if(backgroundRandomness <= 2) {
                randomBackground = 11;
            } else if(backgroundRandomness <= 6) {
                randomBackground = 14;
            } else if(backgroundRandomness <= 18) {
                randomBackground = 21;
            } else if(backgroundRandomness <= 98) {
                randomBackground = 22;
            } else if(backgroundRandomness <= 128) {
                randomBackground = 2;
            } else if(backgroundRandomness <= 158) {
                randomBackground = 5;
            } else if(backgroundRandomness <= 189) {
                randomBackground = 6;
            } else if(backgroundRandomness <= 229) {
                randomBackground = 7;
            } else if(backgroundRandomness <= 259) {
                randomBackground = 8;
            } else if(backgroundRandomness <= 289) {
                randomBackground = 9;
            } else if(backgroundRandomness <= 319) {
                randomBackground = 10;
            } else if(backgroundRandomness <= 349) {
                randomBackground = 1;
            } else if(backgroundRandomness <= 379) {
                randomBackground = 12;
            } else {
                randomBackground = 17;
            }
        } else {
           if(backgroundRandomness == 0) {
                randomBackground = 3;
            } else if(backgroundRandomness <= 2) {
                randomBackground = 11;
            } else if(backgroundRandomness <= 6) {
                randomBackground = 14;
            } else if(backgroundRandomness <= 18) {
                randomBackground = 21;
            } else if(backgroundRandomness <= 56) {
                randomBackground = 2;
            } else if(backgroundRandomness <= 94) {
                randomBackground = 5;
            } else if(backgroundRandomness <= 132) {
                randomBackground = 6;
            } else if(backgroundRandomness <= 170) {
                randomBackground = 7;
            } else if(backgroundRandomness <= 208) {
                randomBackground = 8;
            } else if(backgroundRandomness <= 246) {
                randomBackground = 9;
            } else if(backgroundRandomness <= 285) {
                randomBackground = 10;
            } else if(backgroundRandomness <= 323) {
                randomBackground = 1;
            } else if(backgroundRandomness <= 361) {
                randomBackground = 12;
            } else {
                randomBackground = 17;
            }
        }

        return Seed({
            background: randomBackground,
            body: uint48(
                uint48(pseudorandomness >> 48) % bodyCount
            ),
            accessory: uint48(
                uint48(pseudorandomness >> 96) % accessoryCount
            ),
            head: uint48(
                uint48(pseudorandomness >> 144) % headCount
            ),
            eyes: uint48(
                uint48(pseudorandomness >> 192) % eyesCount
            ),
            mouth: uint48(
                uint48(pseudorandomness >> 208) % mouthCount
            )
        });
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for SweepersDescriptor



pragma solidity ^0.8.6;

import { ISweepersSeeder } from './ISweepersSeeder.sol';

interface ISweepersDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function bgPalette(uint256 index) external view returns (uint8);

    function bgColors(uint256 index) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (bytes memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function backgroundNames(uint256 index) external view returns (string memory);

    function bodyNames(uint256 index) external view returns (string memory);

    function accessoryNames(uint256 index) external view returns (string memory);

    function headNames(uint256 index) external view returns (string memory);

    function eyesNames(uint256 index) external view returns (string memory);

    function mouthNames(uint256 index) external view returns (string memory);

    function bgColorsCount() external view returns (uint256);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function mouthCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBgColors(string[] calldata bgColors) external;

    function addManyBackgrounds(bytes[] calldata backgrounds, uint8 _paletteAdjuster) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyEyes(bytes[] calldata eyes) external;

    function addManyMouths(bytes[] calldata mouths) external;

    function addManyBackgroundNames(string[] calldata backgroundNames) external;

    function addManyBodyNames(string[] calldata bodyNames) external;

    function addManyAccessoryNames(string[] calldata accessoryNames) external;

    function addManyHeadNames(string[] calldata headNames) external;

    function addManyEyesNames(string[] calldata eyesNames) external;

    function addManyMouthNames(string[] calldata mouthNames) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBgColor(string calldata bgColor) external;

    function addBackground(bytes calldata background, uint8 _paletteAdjuster) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addMouth(bytes calldata mouth) external;

    function addBackgroundName(string calldata backgroundName) external;

    function addBodyName(string calldata bodyName) external;

    function addAccessoryName(string calldata accessoryName) external;

    function addHeadName(string calldata headName) external;

    function addEyesName(string calldata eyesName) external;

    function addMouthName(string calldata mouthName) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        ISweepersSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(ISweepersSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { ISweepersDescriptor } from './ISweepersDescriptor.sol';

interface ISweepersSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 eyes;
        uint48 mouth;
    }

    function generateSeed(uint256 sweeperId, ISweepersDescriptor descriptor) external view returns (Seed memory);
}