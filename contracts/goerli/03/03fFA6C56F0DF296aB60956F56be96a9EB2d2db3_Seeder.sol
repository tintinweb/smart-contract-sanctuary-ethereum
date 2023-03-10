// SPDX-License-Identifier: GPL-3.0

/// Random seed generator

pragma solidity ^0.8.6;

import {iSeeder} from "./interfaces/iSeeder.sol";
import {iDescriptorMinimal} from "./interfaces/iDescriptorMinimal.sol";

contract Seeder is iSeeder {
    /**
     * @notice Generate a random seed
     */
    // prettier-ignore
    function generateSeed(uint256 tokenId, uint256 quantity_, iDescriptorMinimal descriptor) external view override returns (Seed memory) {
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            tokenId,
            quantity_,
            block.timestamp,
            block.difficulty,
            block.gaslimit,
            blockhash(block.number - 1)
        )));

        // Default: Token 2501-3000
        uint64 altitudeSeed = 1;
        if (tokenId < 501){ // Token 1-500
            altitudeSeed = uint64(randomness) % 5 + 16;
        }
        else if (tokenId < 1001){ // Token 501-1000
            altitudeSeed = uint64(randomness) % 5 + 11;
        }
        else if (tokenId < 1501){ // Token 1001-1500
            altitudeSeed = uint64(randomness) % 3 + 8;
        }
        else if (tokenId < 2001){ // Token 1501-2000
            altitudeSeed = uint64(randomness) % 3 + 5;
        }
        else if (tokenId < 2501){ // Token 2001-2500
            altitudeSeed = uint64(randomness) % 3 + 2;
        }

        uint64 backgroundSeed = getBackgroundSeed(altitudeSeed);

        return Seed({
            background: backgroundSeed,
            sky: backgroundSeed,
            pepe: backgroundSeed,
            altitude: altitudeSeed
        });
    }

    //prettier-ignore
    function reachNewAltitude(uint256 newAltitude_) external view override returns (Seed memory) {
        uint64 _altitude = newAltitude_ >= 99 ? uint64(99) : uint64(newAltitude_);
        uint64 _newBackgroundSeed = getBackgroundSeed(_altitude);
        return Seed({
            background: _newBackgroundSeed,
            sky: _newBackgroundSeed,
            pepe: _newBackgroundSeed,
            altitude: _altitude
        });
    }

    //prettier-ignore
    function getBackgroundSeed(uint64 altitude_) private pure returns (uint64) {
        uint64 backgroundSeed = 12; // Default: Altitude 99+
        if (altitude_ < 11) {
            // Altitude 1-10
            backgroundSeed = uint64(0);
        } else if (altitude_ < 21) {
            // Altitude 11-20
            backgroundSeed = uint64(1);
        } else if (altitude_ < 31) {
            // Altitude 21-30
            backgroundSeed = uint64(2);
        } else if (altitude_ < 41) {
            // Altitude 31-40
            backgroundSeed = uint64(3);
        } else if (altitude_ < 51) {
            // Altitude 41-50
            backgroundSeed = uint64(4);
        } else if (altitude_ < 61) {
            // Altitude 51-60
            backgroundSeed = uint64(5);
        } else if (altitude_ < 71) {
            // Altitude 61-70
            backgroundSeed = uint64(6);
        } else if (altitude_ < 81) {
            // Altitude 71-80
            backgroundSeed = uint64(7);
        } else if (altitude_ < 91) {
            // Altitude 81-90
            backgroundSeed = uint64(8);
        } else if (altitude_ < 97) {
            // Altitude 91-96
            backgroundSeed = uint64(9);
        } else if (altitude_ < 98) {
            // Altitude 97
            backgroundSeed = uint64(10);
        } else if (altitude_ < 99) {
            // Altitude 98
            backgroundSeed = uint64(11);
        }

        return backgroundSeed;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// Based on Nouns

pragma solidity ^0.8.6;

import {iSeeder} from "./iSeeder.sol";

interface iDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(
        uint256 tokenId,
        iSeeder.Seed memory seed,
        bool burned
    ) external view returns (string memory);

    function dataURI(
        uint256 tokenId,
        iSeeder.Seed memory seed,
        bool burned
    ) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function skyCount() external view returns (uint256);

    function pepeCount() external view returns (uint256);

    function altitudesCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/// Based on Nouns

pragma solidity ^0.8.6;

import {iDescriptorMinimal} from "./iDescriptorMinimal.sol";

interface iSeeder {
    struct Seed {
        uint64 background;
        uint64 sky;
        uint64 pepe;
        uint64 altitude;
    }

    //prettier-ignore
    function generateSeed(uint256 tokenId, uint256 quantity_, iDescriptorMinimal descriptor) external view returns (Seed memory);

    //prettier-ignore
    function reachNewAltitude(uint256 newAltitude_) external view returns (Seed memory);
}