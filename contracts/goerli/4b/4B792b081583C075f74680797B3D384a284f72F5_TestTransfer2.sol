// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract TestTransfer2 {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transfer() public payable {
        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}