// SPDX-License-Identifier: GPL-3.0

/// @title The NounsToken pseudo-random seed generator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';

contract NounsSeeder is INounsSeeder {
    /**
     * @notice Generate a pseudo-random Noun seed using the previous blockhash and noun ID.
     */
    // prettier-ignore
    function generateSeed(uint256 nounId, INounsDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), nounId))
        );

        uint256 artStyleCount = descriptor.artStyleCount();
        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 baseColorCount = descriptor.baseColorCount();
        uint256 visorCount = descriptor.visorCount();
        uint256 mathLettersCount = descriptor.mathlettersCount();
        uint256 accessoriesCount = descriptor.accessoriesCount();
        uint256 flairCount = descriptor.flairCount();

        return Seed({
            artstyle: uint48(
                uint48(pseudorandomness) % artStyleCount
            ),
            background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
            basecolor: uint48(
                uint48(pseudorandomness >> 48) % baseColorCount
            ),
            visor: uint48(
                uint48(pseudorandomness >> 96) % visorCount
            ),
            mathletters: uint48(
                uint48(pseudorandomness >> 144) % mathLettersCount
            ),
            accessory: uint48(
                uint48(pseudorandomness >> 192) % accessoriesCount
            ),
            flair: uint48(
                uint48(pseudorandomness >> 240) % flairCount
            )
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsDescriptor } from './INounsDescriptor.sol';

interface INounsSeeder {
    struct Seed {
        uint48 artstyle;
        uint48 background;
        uint48 basecolor;
        uint48 visor;
        uint48 mathletters;
        uint48 accessory;
        uint48 flair;
    }

    function generateSeed(uint256 nounId, INounsDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function artstyles(uint256 index) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (bytes memory);

    function basecolors(uint256 index) external view returns (bytes memory);

    function visors(uint256 index) external view returns (bytes memory);

    function mathletters(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function flair(uint256 index) external view returns (bytes memory);

    function artStyleCount() external view returns (uint256);

    function backgroundCount() external view returns (uint256);

    function baseColorCount() external view returns (uint256);

    function visorCount() external view returns (uint256);

    function mathlettersCount() external view returns (uint256);

    function accessoriesCount() external view returns (uint256);

    function flairCount() external view returns (uint256);

    function addManyBackgrounds(bytes[] calldata backgrounds) external;

    function addManyBaseColors(bytes[] calldata bodies) external;

    function addManyVisors(bytes[] calldata heads) external;

    function addManyMATHletters(bytes[] calldata glasses) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyFlair(bytes[] calldata flair) external;

    function addArtStyle(string calldata artstyle) external;

    function addBackground(bytes calldata background) external;

    function addBaseColor(bytes calldata basecolor) external;

    function addVisor(bytes calldata visor) external;

    function addMATHletters(bytes calldata mathletters) external;

    function addAccessory(bytes calldata accessory) external;

    function addFlair(bytes calldata flair) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory);
}