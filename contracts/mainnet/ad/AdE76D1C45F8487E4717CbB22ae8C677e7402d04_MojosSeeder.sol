// SPDX-License-Identifier: GPL-3.0

/// @title The MojosToken pseudo-random seed generator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░███████████████████████░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IMojosSeeder } from './interfaces/IMojosSeeder.sol';
import { IMojosDescriptor } from './interfaces/IMojosDescriptor.sol';

contract MojosSeeder is IMojosSeeder {
    /**
     * @notice Generate a pseudo-random Mojo seed using the previous blockhash and Mojo ID.
     */
    // prettier-ignore
    function generateSeed(uint256 mojoId, IMojosDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), mojoId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 bodyAccessoryCount = descriptor.bodyAccessoryCount();
        uint256 faceCount  = descriptor.faceCount();
        uint256 headAccessoryCount  = descriptor.headAccessoryCount();

        return Seed({
        background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
        body: uint48(
                uint48(pseudorandomness >> 48) % bodyCount
            ),
        bodyAccessory: uint48(
                uint48(pseudorandomness >> 96) % bodyAccessoryCount
            ),
        face: uint48(
                uint48(pseudorandomness >> 144) % faceCount
            ),
        headAccessory: uint48(
                uint48(pseudorandomness >> 192) % headAccessoryCount
            )
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for MojosDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░███████████████████████░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IMojosSeeder } from './IMojosSeeder.sol';

interface IMojosDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function bodyAccessories(uint256 index) external view returns (bytes memory);

    function faces(uint256 index) external view returns (bytes memory);

    function headAccessories(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function bodyAccessoryCount() external view returns (uint256);

    function faceCount() external view returns (uint256);

    function headAccessoryCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyBodyAccessories(bytes[] calldata bodyAccessories) external;

    function addManyFaces(bytes[] calldata faces) external;

    function addManyHeadAccessories(bytes[] calldata headAccessories) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addBodyAccessory(bytes calldata bodyAccessory) external;

    function addFace(bytes calldata face) external;

    function addHeadAccessory(bytes calldata headAccessory) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IMojosSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IMojosSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IMojosSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IMojosSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for MojosSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░███████████████████████░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IMojosDescriptor } from './IMojosDescriptor.sol';

interface IMojosSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 bodyAccessory;
        uint48 face;
        uint48 headAccessory;
    }

    function generateSeed(uint256 mojoId, IMojosDescriptor descriptor) external view returns (Seed memory);
}