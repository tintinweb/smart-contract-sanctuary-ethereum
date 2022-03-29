/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Counter {

    uint256 number;

    function add() public {
        number = number + 1;
    }

    function put(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256){
        return number;
    }
}