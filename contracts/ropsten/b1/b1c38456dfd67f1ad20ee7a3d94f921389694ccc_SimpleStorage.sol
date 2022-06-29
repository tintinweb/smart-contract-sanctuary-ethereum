/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
    // this will get initialized to 0!
    // two backslashes will comment
    uint256 public favouriteNumber;

    function store(uint256 _favouriteNumber) public  {
        favouriteNumber = _favouriteNumber;
    }


}