/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract EtherClicker {
    struct Transaction {
        address player;
        uint coins;
    }

    mapping(address => uint) scores;
    Transaction[] transactionHistory;

    address public bestPlayer;
    uint public bestScore;

    uint private newScore;

    function setCoins(uint _coins) public {
        newScore = scores[msg.sender] + _coins;
        
        scores[msg.sender] = newScore;

        if(newScore > bestScore) {
            bestScore = newScore;
            bestPlayer = msg.sender;
        }

        Transaction memory newTransaction = Transaction(msg.sender, _coins);
        transactionHistory.push(newTransaction);
    }

    function getHistory() public view returns(Transaction[] memory) {
        return transactionHistory;
    }

}