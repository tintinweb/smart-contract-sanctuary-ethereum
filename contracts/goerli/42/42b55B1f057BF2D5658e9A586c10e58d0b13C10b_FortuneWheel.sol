// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract FortuneWheel {
    uint256 capacity;
    address[] players;
    
    constructor(uint256 _capacity) {
        require(_capacity > 0, "There should be at least one ticket to buy");
        capacity = _capacity;
    }

    function play() external payable {
        uint256 ticketCost = 1e16;
        require(msg.value == ticketCost, "The ticket costs exactly 0.01 ETH");
        
        bool alreadyPlayed = false;
        for (uint256 i=0; i<players.length; ++i) {
            if (players[i] == msg.sender) {
                alreadyPlayed = true;
                break;
            }
        }
        require(!alreadyPlayed, "You already bought the ticket");

        players.push(msg.sender);
        if (players.length == capacity) {
            (bool callSuccess, ) = payable(msg.sender).call{ value: address(this).balance }("");
            require(callSuccess, "Transfer failed");
            players = new address[](0);
        }
    }
}