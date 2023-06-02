pragma solidity ^0.8.0;

library LibA {
    struct DiamondStorage {
        address owner;
        bytes32 dataA;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.LibA");
        assembly {
            ds.slot := storagePosition
        }
    }
}

contract FacetA {
    function setDataA(bytes32 _dataA) external {
        LibA.DiamondStorage storage ds = LibA.diamondStorage();
        ds.dataA = _dataA;
    }

    function getDataA() external view returns (bytes32) {
        return LibA.diamondStorage().dataA;
    }
}