/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract GETH_FLIP {
    uint public betAmount;
    address public owner;
    uint public balance;
    uint public constant MAX_BET = 200 ether;
    uint public constant MIN_BET = 0.01 ether;
    uint256 public constant BET_FEE = 3;

    constructor() {
        owner = msg.sender;
    }

    event FLIPCOIN(address from, uint256 amount, uint result, uint40 tm);

    function flipCoin(uint _prediction) public payable {
        require(msg.value >= MIN_BET && msg.value <= MAX_BET, "Invalid bet amount");
        require(_prediction == 0 || _prediction == 1, "Invalid bet value");
        require(balance + msg.value <= address(this).balance, "Not enough funds");
        // Random number generation using block timestamp and sender's address
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 2;

        if (randomNumber == _prediction) {
            // Winner
            uint payout = msg.value * (100 - BET_FEE) / 100 * 2;
            balance -= payout;
            payable(msg.sender).transfer(payout);
        } else {
            // Loser
            balance += msg.value;
        }

        emit FLIPCOIN(msg.sender, msg.value, randomNumber, uint40(block.timestamp));
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only owner can withdraw funds");
        uint amount = address(this).balance;
        payable(owner).transfer(amount);
        balance = 0;
    }

    function fundContract() public payable {
        balance += msg.value;
    }
}