// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Storage {
    int256 number;
    address owner;

    constructor() {
        number = 0;
        owner = msg.sender;
    }

    function setNumber(int256 _number) public {
        number = _number;
    }

    function getNumber() public view returns (int256) {
        return number;
    }

    function resetNumber() public {
        require(msg.sender == owner, "You are not owner.");
        number = 0;
    }
}