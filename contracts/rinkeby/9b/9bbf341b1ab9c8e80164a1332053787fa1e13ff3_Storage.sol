/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract Storage {

    uint8 number = 250;

    function increment() public {
        number++;
    }

    function display() public view returns (uint256){
        return number;
    }
}