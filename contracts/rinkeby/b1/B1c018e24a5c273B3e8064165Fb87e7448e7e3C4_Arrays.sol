// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Arrays {
    uint256[5] arrFixed; //fixed size array

    uint256[] arrDynamic; //dynamic array, no fixed size

    function setArray(uint256 _size) public returns (uint256[] memory) {
        uint256[] memory balance = new uint256[](_size);
        balance[0] = 10;
        balance[1] = 20;
        balance[2] = 30;

        return balance;
    }

    // function getArray() public view returns (uint[] memory) {
    //     return balance;
    // }
}