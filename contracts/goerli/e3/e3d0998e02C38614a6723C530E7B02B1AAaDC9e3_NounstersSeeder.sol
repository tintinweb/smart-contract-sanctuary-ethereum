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
    INounsDescriptorMinimal descriptor;

    function setDescriptor(INounsDescriptorMinimal _descriptor) public {
        descriptor = _descriptor;
    }

    uint256 internal monsterTypes = 1;
    mapping(uint256 => uint256[]) internal _backgroundStart;
    mapping(uint256 => uint256[]) internal _bodyStart;
    mapping(uint256 => uint256[]) internal _accessoryStart;
    mapping(uint256 => uint256[]) internal _headStart;
    mapping(uint256 => uint256[]) internal _glassesStart;

    function populateNounsterTypes() public {
        _backgroundStart[uint256(0)] = [0, descriptor.backgroundCount() - 1];
        _bodyStart[uint256(0)] = [0, descriptor.bodyCount() - 1];
        _accessoryStart[uint256(0)] = [0, descriptor.accessoryCount() - 1];
        _headStart[uint256(0)] = [0, descriptor.headCount() - 1];
        _glassesStart[uint256(0)] = [0, descriptor.glassesCount() - 1];
    }

    function grabTypeRanges(uint256 typeId)
        external
        view
        returns (
            uint256[] memory backgroundStart,
            uint256[] memory bodyStart,
            uint256[] memory accessoryStart,
            uint256[] memory headStart,
            uint256[] memory glassesStart
        )
    {
        return (
            _backgroundStart[typeId],
            _bodyStart[typeId],
            _accessoryStart[typeId],
            _headStart[typeId],
            _glassesStart[typeId]
        );
    }

    /**
     * @notice Get the number of available Nounster `backgrounds` for a given NounsterType.
     */
    function backgroundCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_backgroundStart[nounsterType][1] - _backgroundStart[nounsterType][0]) + 1);
    }

    /**
     * @notice Get the number of available Nounster `bodies` for a given NounsterType.
     */
    function bodiesCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_bodyStart[nounsterType][1] - _bodyStart[nounsterType][0]) + 1);
    }

    /**
     * @notice Get the number of available Nounster `accessories` for a given NounsterType.
     */
    function accessoriesCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_accessoryStart[nounsterType][1] - _accessoryStart[nounsterType][0]) + 1);
    }

    /**
     * @notice Get the number of available Nounster `heads` for a given NounsterType.
     */
    function headsCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_headStart[nounsterType][1] - _headStart[nounsterType][0]) + 1);
    }

    /**
     * @notice Get the number of available Nounster `glasses` for a given NounsterType.
     */
    function glassesCount(uint256 nounsterType) public view returns (uint256) {
        return uint256((_glassesStart[nounsterType][1] - _glassesStart[nounsterType][0]) + 1);
    }

    // prettier-ignore
    function generateSeed(uint256 nounsterId, INounsDescriptorMinimal descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), nounsterId))
        );
        //uint256 _nounsterType = uint256(uint8(pseudorandomness) % monsterTypes);
        uint256 _nounsterType = uint256(0);

        return Seed({
            background: uint48(
                (uint48(pseudorandomness) % backgroundCount(_nounsterType))
            ),
            body: uint48(
                ((uint48(pseudorandomness >> 48) % bodiesCount(_nounsterType)) + _bodyStart[_nounsterType][0])
            ),
            accessory: uint48(
                ((uint48(pseudorandomness >> 96) % accessoriesCount(_nounsterType)) + _accessoryStart[_nounsterType][0])
            ),
            head: uint48(
                ((uint48(pseudorandomness >> 144) % headsCount(_nounsterType)) + _headStart[_nounsterType][0])
            ),
            glasses: uint48(
                ((uint48(pseudorandomness >> 192) % glassesCount(_nounsterType)) + _glassesStart[_nounsterType][0])
            ),
            primaryColor: uint8(
                (uint8(pseudorandomness >> 240) % 255)
            ),
            secondaryColor: uint8(
                (uint8(pseudorandomness >> 248) % 255)
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
        uint8 primaryColor;
        uint8 secondaryColor;
    }

    function setDescriptor(INounsDescriptorMinimal descriptor) external;

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