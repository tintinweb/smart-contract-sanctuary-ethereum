/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    bytes16[] array;

    /**
     * @dev Store value in variable
     * @param hash hash value to be added to array
     */
    function push(bytes16 hash) public {
        array.push(hash);
    }

    /**
     * @dev Return value 
     * @return representation of array
     */
    function retrieve() public view returns (bytes16[] memory){
        bytes16[] memory fixed_array = new bytes16[](array.length);

        for (uint i = 0; i < array.length; i++) {
            fixed_array[i] = array[i];
        }

        return fixed_array;
    }

    function clean() public {
        delete array;
    }
}