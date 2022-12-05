pragma solidity 0.8.17;


library LibA {
    struct DiamondStorage {
        address owner;
        bytes32 dataA;
    }

    function diamondStorage() internal pure returns(DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibA");
        assembly {
            ds.slot := storagePosition
        }
    }
}


contract FacetB {
    function getData() external view returns (bytes32) {
        return LibA.diamondStorage().dataA;
    }
}