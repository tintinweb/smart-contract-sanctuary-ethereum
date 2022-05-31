//SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

contract Numbers {

    uint public myNumber;

    function setMyNumber(uint _number) public {
        myNumber = _number;
    }
}