// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Killable {
    address payable public owner;

    uint8 public version;

    constructor(uint8 _version) {
        version = _version;
        owner = payable(msg.sender);
    }

    function killMe() external {
        require(msg.sender == owner, "Only the owner can kill this contract");
        selfdestruct(owner);
    }
}