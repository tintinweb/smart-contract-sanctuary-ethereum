/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract SimpleStorage {

    uint256 savedNumber;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        savedNumber = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return savedNumber;
    }
}