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
import { INounstersDescriptorMinimal } from './interfaces/INounstersDescriptorMinimal.sol';

contract NounstersSeeder is INounstersSeeder {
    /**
     * @notice Generate a pseudo-random Noun seed using the previous blockhash and noun ID.
     */

    uint256 internal nounsterTypes;
    uint256 internal paletteCount;
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';
    uint256 private constant _INDEX_TO_BYTES3_FACTOR = 3;

    mapping(uint256 => mapping(uint256 => uint256[])) internal nounsterTraitKeys;
    mapping(uint256 => uint256[]) internal traitLengths;

    function populateTraitKeys(
        uint256[][][] memory encodedNounsterKeys,
        uint256[][] memory encodedTraitLengths,
        uint256 _paletteCount
    ) public {
        nounsterTypes = encodedNounsterKeys.length;
        paletteCount = _paletteCount;
        for (uint256 i = 0; i < nounsterTypes; i++) {
            nounsterTraitKeys[i][0] = encodedNounsterKeys[i][0];
            nounsterTraitKeys[i][1] = encodedNounsterKeys[i][1];
            nounsterTraitKeys[i][2] = encodedNounsterKeys[i][2];
            nounsterTraitKeys[i][3] = encodedNounsterKeys[i][3];
            traitLengths[i] = encodedTraitLengths[i];
        }
    }

    function seedNounsterTrait(
        uint256[] storage nounsterKeys,
        uint256 traitLength,
        uint48 pseudorandomness
    ) internal view returns (uint256) {
        uint256 counter = pseudorandomness % traitLength;
        uint256 index = 0;

        for (uint256 page = 0; page < nounsterKeys.length; page++) {
            for (uint256 i = 1; i < 254; i++) {
                if (((nounsterKeys[page] >> (254 - i)) & 1) == 1) {
                    if (counter == 0) {
                        return index;
                    }
                    counter--;
                    index++;
                }
            }
        }

        return (420); //There is a huge problem!
    }

    // prettier-ignore
    function generateSeed(uint256 nounsterId, INounstersDescriptorMinimal descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), nounsterId))
        );
        // Choose a non-zero nounster type
        uint256 _nounsterType = uint256((uint8(pseudorandomness) % (nounsterTypes - 1)));
        return Seed({
            background: uint48(
                (uint48(pseudorandomness) % descriptor.backgroundCount())
            ),
            body: uint48(
                (seedNounsterTrait(nounsterTraitKeys[_nounsterType][0], traitLengths[_nounsterType][0], uint48(pseudorandomness >> 48)))
            ),
            accessory: uint48(
                (seedNounsterTrait(nounsterTraitKeys[_nounsterType][1], traitLengths[_nounsterType][1], uint48(pseudorandomness >> 96)))
               ),
            head: uint48(
                (seedNounsterTrait(nounsterTraitKeys[_nounsterType][2], traitLengths[_nounsterType][2], uint48(pseudorandomness >> 144)))
            ),
            glasses: uint48(
                (seedNounsterTrait(nounsterTraitKeys[_nounsterType][3], traitLengths[_nounsterType][3], uint48(pseudorandomness >> 192)))
            ),
            colors: uint32(
                uint32(uint8(pseudorandomness >> 192 ) % (paletteCount - 2) + 2) << 24 | 
                uint32(uint8(pseudorandomness >> 144 ) % (paletteCount - 2) + 2) << 16 |
                uint32(uint8(pseudorandomness >> 96) % (paletteCount - 2) + 2) << 8 |
                uint32(uint8(pseudorandomness >> 48) % (paletteCount - 2) + 2)
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

import { INounstersDescriptorMinimal } from './INounstersDescriptorMinimal.sol';

interface INounstersSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
        uint32 colors;
    }

    function generateSeed(uint256 nounsterId, INounstersDescriptorMinimal descriptor)
        external
        view
        returns (Seed memory);
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

interface INounstersDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounstersSeeder.Seed memory seed) external returns (string memory);

    function dataURI(uint256 tokenId, INounstersSeeder.Seed memory seed) external returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}