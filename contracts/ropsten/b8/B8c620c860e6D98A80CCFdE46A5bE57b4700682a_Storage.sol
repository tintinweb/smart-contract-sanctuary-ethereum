/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

   
    function store(uint256 num) public returns (address myAddress, uint256 mul){
        number = num;
        mul = num * 2;
        myAddress = address(this);
    }

    function retrieve() public view returns (uint256 num, uint256 mul){
        num = number;
        mul = number * 2;
    }
}