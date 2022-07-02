// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract NFTSniper {
    mapping(address => bool) public subscribers;

    address public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function buySubscribtion() public payable {
        // require(msg.value < 1, "You must send more than 0.02 eth");

        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");
    }
}