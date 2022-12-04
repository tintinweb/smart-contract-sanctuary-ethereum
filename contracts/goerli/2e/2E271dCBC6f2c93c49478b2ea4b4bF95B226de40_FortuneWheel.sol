/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract FortuneWheel {
    uint256 private capacity;
    address[] players;


    constructor(uint256 capacityParam) {
        capacity = capacityParam;
    }

    function play() external payable {
        uint256 allowedAmount = 10000000000000000;

        require(msg.value == allowedAmount, "Only 0.01 ETH is allowed");
        bool alreadyPlayed = false;
        for (uint256 i = 0; i < players.length;i++) {
            if(players[i] == msg.sender) {
                alreadyPlayed = true;
                break;
            }
        }
        require(!alreadyPlayed, "You cannot play more than once");

        players.push(msg.sender);

        if (players.length == capacity) {
            payPrize();
        }
    }

    function payPrize() private {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Transfer failed");
        delete players;
    }
}