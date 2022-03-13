/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    int private number;

    constructor(int _number) {
        number = _number;
    }

    function getNumber() public view returns (int) {
        return number;
    }

    function setGreeting(int _number) public {
        number = _number;
    }
}