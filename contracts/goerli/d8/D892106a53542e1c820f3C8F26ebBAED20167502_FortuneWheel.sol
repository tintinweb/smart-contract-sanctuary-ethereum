// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract FortuneWheel {

    address[] public players;
    uint256 public immutable capacity; // number of places in the Fortune Wheel (max number of players)

    constructor(uint256 _capacity) {
        require(_capacity > 0, "Capacity has to be higher than 0");
        capacity = _capacity;
    }

    function enter() external payable {
        // accept funds from players
        // only exactly 0.01 ETH is allowed
        uint256 gameCost = 1e16;
        require(msg.value == gameCost, "To play you have to pay exactly 0.01 ETH");

        bool senderHasPlayed = false;
        for (uint256 i = 0; i < players.length; i++)
            if (players[i] == msg.sender) {
                senderHasPlayed = true;
                break;
            }
        
        require(senderHasPlayed == false, "You can only play once per round");

        if(players.length >= capacity - 1) {
            players = new address[](0);

            (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
            
            require(callSuccess, "Award transfer failed");
        } else {
            players.push(msg.sender);
        }
    }

}