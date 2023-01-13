// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Box {
    uint public val;
    struct name{
        string names;
    }
    mapping(address => name) public namesStruct;

    function initialize() external {
        namesStruct[msg.sender].names = "talha";
    }
}