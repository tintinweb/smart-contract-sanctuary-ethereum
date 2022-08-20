/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SimpleStorage {
    uint256 favNum;

    function changeFavNum(uint256 newFavNum) public {
        favNum = newFavNum;
    }
}