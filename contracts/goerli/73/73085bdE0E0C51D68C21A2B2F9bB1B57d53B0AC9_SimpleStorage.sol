// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 myNumber;

    function setMyNumber(uint256 _num) public {
        myNumber = _num;
    }

    function getMyNumber() public view returns (uint256) {
        return myNumber;
    }
}