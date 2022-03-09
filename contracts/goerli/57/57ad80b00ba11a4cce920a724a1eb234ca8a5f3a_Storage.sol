/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string A;

    /**
     * @dev Store value in variable
     * @param input value to store
     */
    function setA(string memory input) public {
        A = input;
    }

    /**
     * @dev Return value 
     * @return value of 'A'
     */
    function getA() public view returns (string memory){
        return A;
    }
}