/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract FortuneWheel {
    uint8 private capacity;
    uint8 public playerCounter = 0;
    address payable owner;
    uint256 public fortune = 0;
    address[] players;

    constructor() {
        capacity = 3;
        owner = payable(msg.sender);
    }

    function play() external payable {

        // checking if has already played
        bool doesPlayerExistAlready = false;
        if (players.length != 0) {
            for (uint i = 0; i < players.length; i++) {
                if (players[i] == msg.sender) {
                    doesPlayerExistAlready = true;
                }
            }
        }
        require(doesPlayerExistAlready == false, "You can play just once.");

        // player could fund money
        uint256 exactFundToPlay = 1e16;
        require(msg.value >= exactFundToPlay, "You can play only when fund exactly 0.01ETH.");

        players.push(msg.sender);
        fortune += msg.value;
        playerCounter += 1;

        // checking if its winner play
        if (playerCounter == capacity) {
            withdraw(payable(msg.sender), fortune);

            // reseting wheel
            playerCounter = 0;
            fortune = 0;
            players = new address[](0);
        }
    }

    function withdraw(address payable _to, uint256 _amount) private {
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Failed to withdraw fortune");
    }
}