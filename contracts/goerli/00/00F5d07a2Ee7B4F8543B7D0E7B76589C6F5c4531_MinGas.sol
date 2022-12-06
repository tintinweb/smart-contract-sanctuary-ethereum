// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MinGas {

    function getStorageValue() public view returns (uint256 value) {
        assembly {
            value := sload(0)
        }
    }

    function setStorageValue() public {
        assembly {
            if iszero(gt(gas(), 200000)) {
                revert(0, 0)
            }
            sstore(0, timestamp())
        }
    }
}