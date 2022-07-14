/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleStorage {
    uint256 number;

    function store(uint256 num) public {
        number  = num;
    }

    function get() public view returns(uint256){
        return number;
    }
}