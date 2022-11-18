/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Storage{
    uint256 number;
    
    function store(uint256 value) public {
        number = value;
    }

    function retrieve() view public returns(uint256){
        return number;
    }
}