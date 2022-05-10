// SPDX-License-Identifier: GPL-3.0

/// @title The ShinyToken pseudo-random seed generator

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinySeeder } from './interfaces/IShinySeeder.sol';
import { IShinyDescriptor } from './interfaces/IShinyDescriptor.sol';

contract ShinySeeder is IShinySeeder {
    /**
     * @notice Generate a pseudo-random Shiny seed using the previous blockhash and Shiny ID.
     */
    // prettier-ignore
    function generateSeedForMint(uint256 shinyId, IShinyDescriptor descriptor, bool isShiny) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), shinyId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 eyesCount = descriptor.eyesCount();
        uint256 nosesCount = descriptor.nosesCount();
        uint256 mouthsCount = descriptor.mouthsCount();

        return Seed({
            background: uint16(
                uint16(pseudorandomness) % backgroundCount
            ),
            body: uint16(
                uint16(pseudorandomness >> 32) % bodyCount
            ),
            accessory: uint16(
                uint16(pseudorandomness >> 64) % accessoryCount
            ),
            head: uint16(
                uint16(pseudorandomness >> 96) % headCount
            ),
            eyes: uint16(
                uint16(pseudorandomness >> 128) % eyesCount
            ),
            nose: uint16(
                uint16(pseudorandomness >> 160) % nosesCount
            ),
            mouth: uint16(
                uint16(pseudorandomness >> 192) % mouthsCount
            ),
            shinyAccessory: isShiny ? uint16(1) : uint16(0)
        });
    }

        /**
     * @notice Generate a pseudo-random Shiny seed using the previous blockhash and Shiny ID.
     */
    // prettier-ignore
    function generateSeedWithValues(Seed memory newSeed,
                                    IShinyDescriptor descriptor,
                                    bool _isShiny) external view returns (Seed memory) {
        // Check that seedString values are valid
        require(newSeed.background <= descriptor.backgroundCount());
        require(newSeed.body <= descriptor.bodyCount());
        require(newSeed.accessory <= descriptor.accessoryCount());
        require(newSeed.head <= descriptor.headCount());
        require(newSeed.eyes <= descriptor.eyesCount());
        require(newSeed.nose <= descriptor.nosesCount());
        require(newSeed.mouth <= descriptor.mouthsCount());
        require(newSeed.shinyAccessory <= descriptor.shinyAccessoriesCount());
        // If not shiny, don't allow setting shinyAccessory
        if (!_isShiny) {
            require(newSeed.shinyAccessory == 0, 'Non-shiny is not allowed to change shinyAccessory');
        }

        return Seed({
            background: newSeed.background,
            body: newSeed.body,
            accessory: newSeed.accessory,
            head: newSeed.head,
            eyes: newSeed.eyes,
            nose: newSeed.nose,
            mouth: newSeed.mouth,
            shinyAccessory: newSeed.shinyAccessory
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinySeeder

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinyDescriptor } from './IShinyDescriptor.sol';

interface IShinySeeder {
    struct Seed {
        uint16 background;
        uint16 body;
        uint16 accessory;
        uint16 head;
        uint16 eyes;
        uint16 nose;
        uint16 mouth;
        uint16 shinyAccessory;
    }

    function generateSeedForMint(uint256 tokenId, IShinyDescriptor descriptor, bool isShiny) external view returns (Seed memory);

    function generateSeedWithValues(Seed memory newSeed,
                                    IShinyDescriptor descriptor,
                                    bool isShiny) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinyDescriptor

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinySeeder } from './IShinySeeder.sol';

interface IShinyDescriptor {
    event PartsLocked();

    function arePartsLocked() external returns (bool);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function noses(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function shinyAccessories(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function nosesCount() external view returns (uint256);

    function mouthsCount() external view returns (uint256);

    function shinyAccessoriesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyEyes(bytes[] calldata eyes) external;

    function addManyNoses(bytes[] calldata noses) external;

    function addManyMouths(bytes[] calldata mouths) external;

    function addManyShinyAccessories(bytes[] calldata shinyAccessories) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addNoses(bytes calldata noses) external;

    function addMouths(bytes calldata mouths) external;

    function lockParts() external;

    function tokenURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    function dataURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IShinySeeder.Seed memory seed,
        bool isShiny
    ) external view returns (string memory);

    function generateSVGImage(IShinySeeder.Seed memory seed) external view returns (string memory);
}