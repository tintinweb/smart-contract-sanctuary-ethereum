/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number_1 ;
    uint256 number_2 ;
    /**
     * @dev Store value in variable
     * @param num_1 value to store
     */
    function store(uint256 num_1, uint256 num_2) public {
        number_1 = num_1 ;
        number_2 = num_2 ;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256, uint256){
        return (number_1,number_2) ;
    }
}