// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract TestCalls {
    address public creator;
    uint256 public number;

    constructor(uint256 _number) {
        number = _number;
        creator = msg.sender;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can set a number!");
        _;
    }

    function setNumber(uint256 _number) public onlyCreator {
        number = _number;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}