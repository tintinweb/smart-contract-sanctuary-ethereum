/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test {
    uint x;

    function store(uint _x) public {
        x = _x;
    }

    function check() public view returns(uint) {
        return x;
    }
    
}