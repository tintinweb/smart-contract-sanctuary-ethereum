// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract FortuneWheel {
    uint32 private immutable capacity;
    address[] private players;

    constructor(uint32 _capacity) {
        require(_capacity > 0, "Capacity must be greater than 0");
        capacity = _capacity;
    }

    function playGame() external payable {
        for (uint32 i = 0; i < players.length; i++) {
            require(msg.sender != players[i], "Given game cannot be entered twice");
        }
        require(msg.value == 1e16, "The paid value is not equal to 0.01 ETH");
        players.push(msg.sender);
        if (players.length == capacity) {
            uint256 balance = address(this).balance;
            (bool sent, ) = msg.sender.call{value: balance}("");
            require(sent, "Failed to send ETH to the winner");
            delete players;
        }
    }
}