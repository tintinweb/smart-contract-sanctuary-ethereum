/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Calc {

    int private result;

    function add(int a ,int b ) public returns (int c) { 
        c = a + b ;
        result = c;
    }

    function getResult () public view returns (int ) {
        return result;
    }
    
}