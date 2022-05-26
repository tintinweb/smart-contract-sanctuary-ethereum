// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage{
    uint256 public favouriteNum;
    event storedNum(
        uint256 indexed oldNum,
        uint indexed newNum,
        uint256 addedNumber,
        address sender
    );
    function store(uint256 _favouriteNum) public {
        emit storedNum(favouriteNum, _favouriteNum, favouriteNum + _favouriteNum, msg.sender);
        favouriteNum = _favouriteNum;
    }

}