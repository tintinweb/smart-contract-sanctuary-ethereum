// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favNum;

    function setFavNum(uint256 input) public {
        favNum = input;
    }
    function getFavNum() public view returns(uint256) {
        return favNum;
    }
}