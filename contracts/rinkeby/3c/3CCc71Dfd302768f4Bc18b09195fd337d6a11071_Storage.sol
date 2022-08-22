/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Storage {
    uint256 favNumber;

    function store(uint256 _favNumber) external virtual {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }
}