// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * Utils library for comparing arrays of addresses
 */
library ArrayAddressUtils {
    /**
     * @dev uses hashes of array to compare, therefore arrays with different order of same elements wont be equal
     * @param arr1 address[]
     * @param arr2 address[]
     * @return bool
     */
    function isEqual(address[] memory arr1, address[] memory arr2) external pure returns (bool) {
        return keccak256(abi.encodePacked(arr1)) == keccak256(abi.encodePacked(arr2));
    }
}