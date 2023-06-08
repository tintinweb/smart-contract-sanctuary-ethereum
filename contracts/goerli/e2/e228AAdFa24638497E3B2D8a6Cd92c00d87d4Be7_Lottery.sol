/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] public players;
    uint public totalPrize;
    
    struct Ticket {
        address payable player;
        uint[] numbers;
        uint prizeAmount;
    }
    
    Ticket[] public tickets;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter(uint[] memory numbers, uint prizeAmount) public payable {
        require(numbers.length > 0 && numbers.length <= 7, "Invalid number count.");
        require(prizeAmount > 0, "Invalid prize amount.");
        require(msg.value == prizeAmount * numbers.length, "Invalid ticket price.");
        for (uint i = 0; i < numbers.length; i++) {
            require(numbers[i] > 0 && numbers[i] <= 99, "Invalid number.");
        }
        
        tickets.push(Ticket({
            player: payable(msg.sender),
            numbers: numbers,
            prizeAmount: prizeAmount
        }));
        
        players.push(payable(msg.sender));
        totalPrize += msg.value;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tickets.length)));
    }
    
    function pickWinner() public restricted {
        require(tickets.length > 0, "No tickets sold.");
        uint[] memory winningNumbers = generateWinningNumbers();
        address payable[] memory winners = new address payable[](tickets.length);
        uint numWinners = 0;
        
        for (uint i = 0; i < tickets.length; i++) {
            uint matchedCount = countMatchingNumbers(tickets[i].numbers, winningNumbers);
            
            if (matchedCount > 0) {
                uint prizeAmount = tickets[i].prizeAmount * matchedCount;
                
                winners[numWinners] = tickets[i].player;
                numWinners++;
                
                tickets[i].player.transfer(prizeAmount);
            }
        }
        
        delete tickets;
        totalPrize = 0;
    }
    
    function generateWinningNumbers() private view returns(uint[] memory) {
        uint[] memory winningNumbers = new uint[](7);
        
        for (uint i = 0; i < 7; i++) {
            winningNumbers[i] = random() % 49 + 1;
        }
        
        return winningNumbers;
    }
    
    function countMatchingNumbers(uint[] memory numbers1, uint[] memory numbers2) private pure returns(uint) {
        uint count = 0;
        
        for (uint i = 0; i < numbers1.length; i++) {
            for (uint j = 0; j < numbers2.length; j++) {
                if (numbers1[i] == numbers2[j]) {
                    count++;
                    break;
                }
            }
        }
        
        return count;
    }
    
    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function.");
        _;
    }
    
    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }
}