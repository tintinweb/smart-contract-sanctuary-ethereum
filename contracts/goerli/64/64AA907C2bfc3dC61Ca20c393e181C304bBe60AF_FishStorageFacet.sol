/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library FishStorageLib {
    struct FishStorage {
        uint32 squid;
        uint8 tuna;
        uint8 octopus;
    }

    function fishStorage() internal pure returns (FishStorage storage fs) {
        bytes32 position = keccak256("diamond.standard.fish.storage");
        assembly {
            fs.slot := position
        }
    }
}

contract FishStorageFacet {
    function setStorage(
        uint32 _squid,
        uint8 _tuna,
        uint8 _octopus
    ) external {
        FishStorageLib.FishStorage storage fs = FishStorageLib.fishStorage();
        fs.squid = _squid;
        fs.tuna = _tuna;
        fs.octopus = _octopus;
    }

    function eaten()
        public
        view
        returns (
            uint32,
            uint8,
            uint8
        )
    {
        FishStorageLib.FishStorage storage fs = FishStorageLib.fishStorage();
        return (fs.squid, fs.tuna, fs.octopus);
    }
}