/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract simpleStorage {
    
    uint256 public favNum = 500;

    function changeFavNum(uint256 _favNum) public {
        favNum = _favNum;
    }

}