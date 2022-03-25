/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    // uint256 number;
    int number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(int num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (int) {
        return number;
    }

    function withdraw(int amount) public {
        number = number - amount;
    }
}