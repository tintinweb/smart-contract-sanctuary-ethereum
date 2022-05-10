/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract InsecureBetGuessFixed {
    // A mapping creates a namespace in which all possible keys exist, so we need
    // an array just to keep track of the addresses which have bet
    address payable[] public betters;

    mapping(address => uint) public bets;
    mapping(address => uint) public guesses;

    function bet(uint guess) public payable {
        require(!hasBet(payable(msg.sender)), "This address has already made a bet.");
        require(msg.value > 0, "The betting amount must be positive.");
        require(1 <= guess && guess <= 10, "The guess must be within 1 and 10, inclusive.");

        betters.push(payable(msg.sender));
        bets[msg.sender] = msg.value;
        guesses[msg.sender] = guess;
    }

    function disburse() public returns(uint, address payable) {
        require(betters.length > 0, "No one has made any bets.");

        uint goal = random() % 10 + 1;

        // Find winner (by finding closest guess)
        address payable winner;
        uint closestGuessDistance = 10000; // Some very high initial value
        for (uint i = 0; i < betters.length; i++) {
            address payable better = betters[i];
            uint guess = guesses[better];
            uint guessDistance = goal > guess ? goal - guess : guess - goal;

            if (guessDistance < closestGuessDistance) {
                closestGuessDistance = guessDistance;
                winner = better;
            }
        }

        // Calculate the amount won
        uint betAmount = bets[winner];
        uint balance = address(this).balance;
        uint winAmount = min(balance, 2 * betAmount);

        (bool sent,) = winner.call{value: winAmount}("");
        require(sent, "Failed to send ether.");

        // Delete stored info on betters
        for (uint i = 0; i < betters.length; i++) {
            address payable better = betters[i];
            delete bets[better];
            delete guesses[better];
        }
        delete betters;

        return (goal, winner);
    }

    function min(uint x, uint y) private pure returns(uint) {
        return x < y ? x : y;
    }

    // This function is NOT SECURE
    // A miner can keep mining blocks and not publish until they get the block they want.
    // https://betterprogramming.pub/how-to-generate-truly-random-numbers-in-solidity-and-blockchain-9ced6472dbdf
    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, betters)));
    }

    // Apparently, this will increase gas costs as the number of betters increases
    function hasBet(address payable addr) private view returns(bool) {
        for (uint i = 0; i < betters.length; i++) {
            if (betters[i] == addr) {
                return true;
            }
        }

        return false;
    }
}