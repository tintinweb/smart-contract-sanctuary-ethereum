/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint favNumber;

    function store(uint _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint) {
        return favNumber;
    }
}