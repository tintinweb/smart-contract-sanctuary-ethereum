// SPDX-License-Identifier: GPL-3.0

/// @title The NounsToken pseudo-random seed generator

pragma solidity ^0.8.6;

import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';

contract NounbitsSeeder is INounsSeeder {
    /**
     * @notice Generate a pseudo-random Noun seed using a pseudorandom blockhash and noun ID.
     */
    // prettier-ignore
    function generateSeed(uint256 nounId, INounsDescriptor descriptor, bytes32 pseudorandomHash) external view override returns (Seed memory) {
        if (pseudorandomHash == 0) {
            return Seed({background: 0, body: 0, accessory: 0, head: 0, glasses: 0, pants: 0, shoes: 0});
        }

        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(pseudorandomHash, nounId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 glassesCount = descriptor.glassesCount();
        uint256 pantsCount = descriptor.pantCount();
        uint256 shoesCount = descriptor.shoeCount();

        return Seed({
            background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
            body: uint48(
                uint48(pseudorandomness >> 32) % bodyCount
            ),
            accessory: uint48(
                uint48(pseudorandomness >> 64) % accessoryCount
            ),
            head: uint48(
                uint48(pseudorandomness >> 96) % headCount
            ),
            glasses: uint48(
                uint48(pseudorandomness >> 128) % glassesCount
            ),
            pants: uint48(
                uint48(pseudorandomness >> 160) % pantsCount
            ),
            shoes: uint48(
                uint48(pseudorandomness >> 192) % shoesCount
            )
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { INounsDescriptor } from './INounsDescriptor.sol';

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
        uint48 pants;
        uint48 shoes;
    }

    function generateSeed(uint256 nounId, INounsDescriptor descriptor, bytes32 pseudorandomHash) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptor {
    event PartsLocked();

    function arePartsLocked() external returns (bool);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function pants(uint256 index) external view returns (bytes memory);

    function shoes(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function pantCount() external view returns (uint256);

    function shoeCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addManyPants(bytes[] calldata pants) external;

    function addManyShoes(bytes[] calldata shoes) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function addPant(bytes calldata pant) external;

    function addShoe(bytes calldata shoe) external;

    function lockParts() external;

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);
}