/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
// SPDX-License-Identifier: GPL-3.0


contract Storage {
    uint256 number;
    uint256 number2;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num,uint256 num2) public {
        number = num;
        number2 = num2;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256,uint256){
        return (number,number2);
    }
}