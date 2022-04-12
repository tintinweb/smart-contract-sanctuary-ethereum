/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract InsecureBetRandom {
    // A mapping creates a namespace in which all possible keys exist, so we need
    // an array just to keep track of the addresses which have bet
    address payable[] public betters;

    mapping(address => uint) public bets;

    function bet() public payable {
        require(!hasBet(payable(msg.sender)), "This address has already made a bet.");

        betters.push(payable(msg.sender));
        bets[msg.sender] = msg.value;
    }

    function disburse() public returns(address) {
        require(betters.length > 0, "No one has made any bets.");

        uint randIndex = random() % betters.length;

        address payable winner = betters[randIndex];
        (bool sent,) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send ether.");

        // Delete stored info on betters
        for (uint i = 0; i < betters.length; i++) {
            delete bets[betters[i]];
        }
        delete betters;

        return winner;
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