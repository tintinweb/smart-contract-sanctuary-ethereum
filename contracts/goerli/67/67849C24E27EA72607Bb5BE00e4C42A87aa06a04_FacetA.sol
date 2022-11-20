// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibA {

// stores the Facets variables
struct DiamondStorage {
    address owner;
    bytes32 dataA;
}

// specifies a random position from a hash of a string, and 
// sets the position of our struct in contract storage.
function diamondStorage() internal pure returns(DiamondStorage storage ds) {
    bytes32 storagePosition = keccak256("diamond.storage.LibA");
    assembly {
    ds.slot := storagePosition
    }
}
}

// The contract implements two functions, setDataA, which takes a bytes32 value and 
// sets diamond storage defined above, and getDataA, which reads from the set storage.
contract FacetA {
    function setDataA(bytes32 _dataA) external {
        LibA.DiamondStorage storage ds = LibA.diamondStorage();
        ds.dataA = _dataA;
    }

    function getDataA() external view returns (bytes32) {
        return LibA.diamondStorage().dataA;
    }
}