/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract EthCounter {

    uint256 number;

    constructor (uint256 num) {
      number = num;
    }

    function store(uint256 num) public {
      number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}