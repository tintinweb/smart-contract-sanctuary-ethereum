// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract TestTransfer {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function testCall(address payable _to) public payable {
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}