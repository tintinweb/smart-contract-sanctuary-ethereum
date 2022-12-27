/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract TestAddFacet {
    bytes32 constant FISH_STORAGE_POSITION =
        keccak256("diamond.standard.fish.storage");

    struct FishStorage {
        uint32 squid;
        uint8 tuna;
        uint8 octopus;
    }

    constructor(
        uint32 _squid,
        uint8 _tuna,
        uint8 _octopus
    ) {
        fishStorage().squid = _squid;
        fishStorage().tuna = _tuna;
        fishStorage().octopus = _octopus;
    }

    function fishStorage() private pure returns (FishStorage storage fish) {
        bytes32 position = FISH_STORAGE_POSITION;

        assembly {
            fish.slot := position
        }
    }

    function eaten()
        public
        view
        returns (
            uint32 squid,
            uint8 tuna,
            uint8 octopus
        )
    {
        squid = fishStorage().squid;
        tuna = fishStorage().tuna;
        octopus = fishStorage().octopus;
    }
}