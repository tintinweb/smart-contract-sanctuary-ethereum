// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {IGnarSeederV2} from "../interfaces/IGNARSeederV2.sol";
import {IGnarDescriptorV2} from "../interfaces/IGNARDescriptorV2.sol";

contract GNARSeederV2 is IGnarSeederV2 {
    function generateSeed(uint256 gnarId, IGnarDescriptorV2 descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), gnarId)));

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 glassesCount = descriptor.glassesCount();
        require(backgroundCount > 0, "background is missing");
        require(bodyCount > 0, "body is missing");
        require(accessoryCount > 0, "accessories is missing");
        require(headCount > 0, "head is missing");
        require(glassesCount > 0, "glasses is missing");

        return
            Seed({
                background: uint48(uint48(pseudorandomness) % backgroundCount),
                body: uint48(uint48(pseudorandomness >> 48) % bodyCount),
                accessory: uint48(uint48(pseudorandomness >> 96) % accessoryCount),
                head: uint48(uint48(pseudorandomness >> 144) % headCount),
                glasses: uint48(uint48(pseudorandomness >> 192) % glassesCount)
            });
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {IGnarDescriptorV2} from "./IGNARDescriptorV2.sol";

interface IGnarSeederV2 {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 gnarId, IGnarDescriptorV2 descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {IGnarSeederV2} from "./IGNARSeederV2.sol";
import {IGnarDecorator} from "../interfaces/IGnarDecorator.sol";

interface IGnarDescriptorV2 {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    event DecoratorUpdated(IGnarDecorator decorator);

    function setDecorator(IGnarDecorator _decorator) external;

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IGnarSeederV2.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IGnarSeederV2.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IGnarSeederV2.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IGnarSeederV2.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {IGnarSeederV2} from "./IGNARSeederV2.sol";

interface IGnarDecorator {
    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (string memory);

    function accessories(uint256 index) external view returns (string memory);

    function heads(uint256 index) external view returns (string memory);

    function glasses(uint256 index) external view returns (string memory);

    function addManyBackgrounds(string[] calldata _backgrounds) external;

    function addManyBodies(string[] calldata _bodies) external;

    function addManyAccessories(string[] calldata _accessories) external;

    function addManyHeads(string[] calldata _heads) external;

    function addManyGlasses(string[] calldata _glasses) external;
}