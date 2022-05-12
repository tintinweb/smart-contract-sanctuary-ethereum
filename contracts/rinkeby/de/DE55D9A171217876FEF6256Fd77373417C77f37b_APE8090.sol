// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract APE8090 {

    string private saySomething;
    bool private flug;

    constructor() {
        saySomething = "Hello APE8090 !";
        flug = false;
    }

    function speak() public view returns(string memory) {
        require(flug == true, "Flug should be True");
        return saySomething;
    }

    function setOn() payable public{
        flug = true;
    }

    function setOff() public{
        flug = false;
    }
}