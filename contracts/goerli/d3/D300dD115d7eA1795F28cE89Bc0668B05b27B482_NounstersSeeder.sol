// SPDX-License-Identifier: GPL-3.0

/// @title The NounstersToken pseudo-random seed generator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounstersSeeder } from './interfaces/INounstersSeeder.sol';
import { INounsDescriptorMinimal } from './interfaces/INounsDescriptorMinimal.sol';

contract NounstersSeeder is INounstersSeeder {
    /**
     * @notice Generate a pseudo-random Noun seed using the previous blockhash and noun ID.
     */

    uint256 internal nounsterTypes;
    uint256 internal paletteCount;
    mapping(uint256 => uint256[]) internal _bodies;
    mapping(uint256 => uint256[]) internal _accessories;
    mapping(uint256 => uint256[]) internal _heads;
    mapping(uint256 => uint256[]) internal _glasses;

    function populateNounsterTypes(uint256[] memory encodedNounsterTypes, uint256 _paletteCount) public {
        nounsterTypes = encodedNounsterTypes.length;
        paletteCount = _paletteCount;
        for (uint256 i = 0; i < nounsterTypes; i++) {
            _glasses[i] = [uint16(encodedNounsterTypes[i] >> 16), uint16(encodedNounsterTypes[i])];
            _heads[i] = [uint16(encodedNounsterTypes[i] >> 48), uint16(encodedNounsterTypes[i] >> 32)];
            _accessories[i] = [uint16(encodedNounsterTypes[i] >> 80), uint16(encodedNounsterTypes[i] >> 64)];
            _bodies[i] = [uint16(encodedNounsterTypes[i] >> 112), uint16(encodedNounsterTypes[i] >> 96)];
        }
    }

    /**
     * @notice Get the number of available Nounster `bodies` for a given NounsterType.
     */
    function bodiesCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_bodies[nounsterType][1] - _bodies[nounsterType][0]) + 1);
    }

    /**
     * @notice Get the number of available Nounster `accessories` for a given NounsterType.
     */
    function accessoriesCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_accessories[nounsterType][1] - _accessories[nounsterType][0]) + 1);
    }

    /**
     * @notice Get the number of available Nounster `heads` for a given NounsterType.
     */
    function headsCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_heads[nounsterType][1] - _heads[nounsterType][0]) + 1);
    }

    /**
     * @notice Get the number of available Nounster `glasses` for a given NounsterType.
     */
    function glassesCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_glasses[nounsterType][1] - _glasses[nounsterType][0]) + 1);
    }

    // prettier-ignore
    function generateSeed(uint256 nounsterId, INounsDescriptorMinimal descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), nounsterId))
        );
        // Choose a non-zero nounster type
        uint256 _nounsterType = uint256((uint8(pseudorandomness) % (nounsterTypes - 1)) + 1);

        return Seed({
            background: uint48(
                (uint48(pseudorandomness) % descriptor.backgroundCount())
            ),
            body: uint48(
                ((uint48(pseudorandomness >> 48) % bodiesCount(_nounsterType)) + _bodies[_nounsterType][0])
            ),
            accessory: uint48(
                ((uint48(pseudorandomness >> 96) % accessoriesCount(_nounsterType)) + _accessories[_nounsterType][0])
            ),
            head: uint48(
                ((uint48(pseudorandomness >> 144) % headsCount(_nounsterType)) + _heads[_nounsterType][0])
            ),
            glasses: uint48(
                ((uint48(pseudorandomness >> 192) % glassesCount(_nounsterType)) + _glasses[_nounsterType][0])
            ),
            primary: uint8(
                (uint8(pseudorandomness >> 240) % paletteCount)
            ),
            secondary: uint8(
                (uint8(pseudorandomness >> 248) % paletteCount)
            )
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounstersSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounstersSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
        uint8 primary;
        uint8 secondary;
    }

    function generateSeed(uint256 nounsterId, INounsDescriptorMinimal descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounstersToken and NounstersSeeder.

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

import { INounstersSeeder } from './INounstersSeeder.sol';

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounstersSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounstersSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}