// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favNum;

    function setFavNum(uint256 num) public {
        favNum = num;
    }
    function addFive() public {
        favNum += 5;
    }
    function getFavNum() public view returns (uint256) { return favNum; }
}