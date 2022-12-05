// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract FortuneWheel {

    address[] public players;
    uint256 public immutable wheelCapacity;

    
    constructor(uint256 capacity) {
        wheelCapacity = capacity;
    }

    function enter() external payable {
        uint256 entranceFee = 1e16;
        require(msg.value == entranceFee, "Wrong amount of ETH");

        for (uint i = 0; i < players.length; i++) {
            require(msg.sender != players[i], "Already in the fortune wheel");
        }

        players.push(msg.sender);
        
        if (players.length == wheelCapacity) {
            players = new address[](0);
            (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(callSuccess, "Transfer failed");
        }
    }
}