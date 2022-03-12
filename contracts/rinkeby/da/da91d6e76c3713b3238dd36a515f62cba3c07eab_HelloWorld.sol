/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract HelloWorld {
    string public greeting;
    uint public number;

    constructor () {
        greeting = "Hello, World!";
    }

    function viewGreeting() public view returns(string memory){
        return greeting;
    }

    function inputNumber(uint _number) public {
        number = _number;
    }

    function squareNumber() public view returns(uint){
        uint square = number * number;
        return square;
    }
}