// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SolutionLib {

    struct FishStorage {
        uint32 squid;
        uint8 tuna;
        uint8 octopus;
    }

    bytes32 constant FISH_STORAGE_POSITION = keccak256("diamond.standard.fish.storage");

    function fishStorage() internal pure returns (FishStorage storage fish) {
        bytes32 position = FISH_STORAGE_POSITION;
        assembly {
            fish.slot := position
        }
    }

}

contract SolutionFacet {

    function init () public {
        SolutionLib.fishStorage().squid = 77;
        SolutionLib.fishStorage().tuna = 102;
        SolutionLib.fishStorage().octopus = 48;
    }

    function eaten() public view returns (uint32, uint8, uint8) {
        return (
            SolutionLib.fishStorage().squid,
            SolutionLib.fishStorage().tuna,
            SolutionLib.fishStorage().octopus
        );
    }

}