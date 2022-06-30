// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISeeder} from "./interfaces/ISeeder.sol";
import {IArtivaDescriptor} from "./interfaces/IArtivaDescriptor.sol";

contract Seeder is ISeeder {

    function generateSeed(uint256 tokenId, IArtivaDescriptor descriptor) external view returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        uint256 configurationsCount = descriptor.configurationsCount();
        uint256 paletteCount = descriptor.paletteCount();

        uint24 configurationIndex = uint24(
            uint24(pseudorandomness) % configurationsCount
        );
        uint8 paletteIndex = uint8(
            uint8(pseudorandomness >> 24) % paletteCount
        );
        uint256 basePaletteColorCount = descriptor.colorsInPalletCount(paletteIndex);

        uint256 colorCountChoice = (uint8(pseudorandomness >> 32) % 2) + 3;
        uint8[] memory colorIndexes = new uint8[](colorCountChoice);

        
        for(uint256 i = 0; i < colorCountChoice; i++) {
            colorIndexes[i] = uint8((pseudorandomness << (i * 8 + 40)) % (basePaletteColorCount - i));
        }

        return Seed({
            configurationIndex: configurationIndex,
            paletteIndex: paletteIndex,
            colorIndexes: colorIndexes
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {IArtivaDescriptor} from "./IArtivaDescriptor.sol";

interface ISeeder {
    struct Seed {
        uint8[] colorIndexes;
        uint8 paletteIndex;
        uint24 configurationIndex;
    }

    function generateSeed(uint256 tokenId, IArtivaDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { ISVGGenerator } from './ISVGGenerator.sol';
import { ISeeder } from './ISeeder.sol';

interface IArtivaDescriptor {
    struct Configuration {
        uint48 background;
        uint48 circle;
        uint48 path;
        uint48 gradientType;
        uint48 gradientStatic;
        bytes[] gradientDynamic;
    }

    event SVGGeneratorUpdated(ISVGGenerator svgGenerator);

    event SVGGeneratorLocked();

    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function paletteCount() external view returns (uint256);

    function getPalette(uint8 paletteIndex) external view returns (bytes[] memory);
    
    function colorsInPalletCount(uint8 paletteIndex) external view returns (uint256);

    function configurationsCount() external view returns (uint256);

    function backgroundPropsCount() external view returns (uint256);

    function circlePropsCount() external view returns (uint256);

    function pathPropsCount() external view returns (uint256);

    function gradientStaticPropsCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface ISVGGenerator {
    struct SVGParams {
        bytes backgroundProps;
        bytes circleProps;
        bytes pathProps;
        bytes gradientStaticProps;
        uint48 gradientType;
        bytes[] gradientDynamicProps;
        bytes[] palette;
    }

    function generateSVGImage(SVGParams memory params) external view returns (string memory);
}