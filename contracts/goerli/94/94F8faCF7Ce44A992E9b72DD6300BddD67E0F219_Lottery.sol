// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] public players; 
    uint public winningAmount; 
    uint public ticketPrice;

    constructor(uint _ticketPrice) {
        manager = msg.sender;
        ticketPrice = _ticketPrice;
    }

    modifier restricted() {
        require(msg.sender == manager, "Only Mnager");
        _;
    }

    function buyTicket() public payable {
        require(msg.value == ticketPrice, "Ticket price is incorrect.");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function generateWinner() public restricted {
        require(players.length > 0, "No players found");
        uint index = random() % players.length;
        players[index].transfer(winningAmount);
        players = new address payable[](0);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function withdraw(uint amount) public restricted {
        require(amount <= getBalance(), "Not enough balance in the contract.");
        payable(manager).transfer(amount);
    }

    function setWinningAmount(uint amount) public restricted {
        winningAmount = amount;
    }
}