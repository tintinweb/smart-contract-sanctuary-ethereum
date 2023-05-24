/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract ArrayStorage {
    uint256[] private array;

    function collide() external virtual;

    function getArray() external view returns (uint256[] memory) {
        return array;
    }
}

// Method 1 - collision using external library
library ColliderLibrary {
    function setArray(uint256[] memory newArray) external {
        assembly {
            // Get the length of the new array
            let length := mload(newArray)

            // Resize the storage array to fit the new array
            sstore(0x0, length)

            let slot := keccak256(0x0, 0x20)

            // Copy each element from the memory array to the storage array
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let value := mload(add(newArray, mul(0x20, add(i, 1))))
                sstore(add(slot, i), value)
            }
        }
    }
}

// Method 2 - collision helper contract
contract ColliderHelper {
    uint256[] public array;

    function setArray(uint256[] memory newArray) public {
        array = newArray;
    }
}


contract StorageCollider is ArrayStorage {
    // Method 2
    ////////////////////////////////////////////////////////////////////////////////
    ColliderHelper public helper;

    constructor() {
        helper = new ColliderHelper();
    }
    ////////////////////////////////////////////////////////////////////////////////

    function collide() external override {
        bytes4 methodId = bytes4(keccak256(bytes("setArray(uint256[])")));
        uint256[] memory newArray = new uint256[](13); // array to overwrite with

        for (uint i = 0; i < 13; i++) {
            newArray[i] = 4308 << i;
        }

        // Method 1
        ////////////////////////////////////////////////////////////////////////////
        // (bool success,) = address(ColliderLibrary).delegatecall(
        ////////////////////////////////////////////////////////////////////////////
        // Method 2
        (bool success,) = address(helper).delegatecall(
        ////////////////////////////////////////////////////////////////////////////
            abi.encodeWithSelector(methodId, newArray)
        );

        require(success, "delegatecall failed");
    }
}