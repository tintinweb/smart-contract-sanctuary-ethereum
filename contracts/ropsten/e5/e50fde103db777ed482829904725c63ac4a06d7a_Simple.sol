// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Simple {

    address public owner;
    uint public foo;

    constructor() {
        owner = msg.sender;
    }

    function setFoo(uint _foo) public {
        require(msg.sender == owner, "Not owner");
        foo = _foo;
    }

    function getFoo() public view returns (uint) {
        return foo;
    }

}