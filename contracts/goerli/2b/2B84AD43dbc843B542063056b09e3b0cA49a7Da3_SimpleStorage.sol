// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SimpleStorage {
    uint256 favNum = 7;

    function changeFavNum(uint256 newFavNum) public {
        favNum = newFavNum;
    }
}