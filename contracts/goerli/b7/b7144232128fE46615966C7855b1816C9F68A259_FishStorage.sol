// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./FishStorageLib.sol";

contract FishStorage {
    bool isInitialized = false;

    function eaten()
        external
        pure
        returns (
            uint32 squid,
            uint8 tuna,
            uint8 octopus
        )
    {
        return FishStorageLib.eaten();
    }

    function init(
        uint32 squid,
        uint8 tuna,
        uint8 octopus
    ) external {
        require(isInitialized == false, "Already initialized");
        FishStorageLib.init(squid, tuna, octopus);
        isInitialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library FishStorageLib {
    bytes32 constant MAP_STORAGE_POSITION =
        keccak256("diamond.standard.fish.storage");

    // Stored at slot `keccak256("diamond.standard.fish.storage")`
    struct FishStorage {
        uint32 squid;
        uint8 tuna;
        uint8 octopus;
    }

    function eaten()
        internal
        pure
        returns (
            uint32 squid,
            uint8 tuna,
            uint8 octopus
        )
    {
        FishStorage memory s = mapStorage();

        return (s.squid, s.tuna, s.octopus);
    }

    function init(
        uint32 squid,
        uint8 tuna,
        uint8 octopus
    ) internal {
        FishStorage storage s = mapStorage();
        s.squid = squid;
        s.tuna = tuna;
        s.octopus = octopus;
    }

    function mapStorage() private pure returns (FishStorage storage map) {
        bytes32 position = MAP_STORAGE_POSITION;
        assembly {
            map.slot := position
        }
    }
}