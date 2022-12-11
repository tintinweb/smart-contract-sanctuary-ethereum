/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 fav;

    function store(uint256 num) public virtual {
        fav = num;
    }

    function retrieve() public view returns (uint256) {
        return fav;
    }
}