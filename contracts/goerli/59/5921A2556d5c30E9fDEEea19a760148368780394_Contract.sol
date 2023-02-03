/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Contract { 

    uint256 number;
    function store(uint256 num) public {
        number = num;
    }
    function increment() public {
        number += 1;
    }
    function decrement() public {
        number -= 1;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}