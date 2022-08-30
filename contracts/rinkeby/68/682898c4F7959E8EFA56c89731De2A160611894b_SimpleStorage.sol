/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint internal favoriteNumber;

    function getNumber() public view returns (uint) {
        return favoriteNumber;
    }

    function setNumber(uint _num) public virtual {
        favoriteNumber = _num;
    }
}