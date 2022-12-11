//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SimpleStorage {
    uint256 public favNo;

    function SetFavoriteNumber(uint256 _inputNumber) public {
        favNo = _inputNumber;
    }

    function GetFavoriteNumber() public view returns (uint256) {
        return favNo;
    }
}