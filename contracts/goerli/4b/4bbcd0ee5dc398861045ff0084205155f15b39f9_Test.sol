/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.12;


contract Test{
    uint256 private number;

    function store(uint256 num) public{
            number = num;
    }

    function retreive() public view returns(uint256){
        return number;
    }
}