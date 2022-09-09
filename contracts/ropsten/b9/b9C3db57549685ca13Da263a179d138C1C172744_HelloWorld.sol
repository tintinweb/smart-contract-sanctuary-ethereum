/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract HelloWorld {

    string saySomething;
    uint256 public Sulemani_Number;

    constructor(uint256 _Sulemani_Number) {
        Sulemani_Number = _Sulemani_Number;
        saySomething = "Hello World!";
    }

    function speak() public view returns(string memory) {
        return saySomething;
    }
}