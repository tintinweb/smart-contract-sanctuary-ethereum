// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Example {
    uint256 number = 0;

    constructor(){}

    function readNumber() public view returns(uint256){
        return number;
    }

    function changeNumber(uint256 _number) public {
        number = _number;
    }
}