/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract MyContract {

    uint256 public number = 43;

    function store(uint256 value) public {
        number = value;
    }

    function retrieve() view public returns(uint256){
        return number;
    }
}