// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibA {

struct DiamondStorage {
    address owner;
    uint dataID;
}


function diamondStorage() internal pure returns(DiamondStorage storage ds) {
    bytes32 storagePosition = keccak256("diamond.storage.LibA");
    assembly {
    ds.slot := storagePosition
    }
}
}

contract FacetB {
    function setDataA(uint _dataID) external {
        LibA.DiamondStorage storage ds = LibA.diamondStorage();
        ds.dataID = _dataID;
    }

    function getDataA() external view returns (uint) {
        return LibA.diamondStorage().dataID;
    }
}