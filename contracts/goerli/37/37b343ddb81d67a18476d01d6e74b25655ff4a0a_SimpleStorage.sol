/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {

    uint favoriteNumber;

    function saveNumber(uint _Number) public {
        favoriteNumber = _Number;
    }


    function deleteNumber() public {
        favoriteNumber = 0;
    }


    function getNumber() public view returns(uint) {
        return favoriteNumber;
    }
}