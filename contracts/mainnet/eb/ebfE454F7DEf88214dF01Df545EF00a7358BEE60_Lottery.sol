/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address payable public deployer;
    uint public prizePot;
    uint public lastDrawTimestamp;
    address public lastWinner;
    address[] public winners;
    mapping(address => uint) public tickets;

    event TicketPurchased(address indexed buyer, uint prizeAmount);
    event WinnerDrawn(address indexed winner, uint prizeAmount);

    constructor() {
        deployer = payable(msg.sender);
        lastDrawTimestamp = block.timestamp + 7 days;
    }

    function buyTicket() public payable {
        require(msg.value == 0.1 ether, "You must send exactly 0.1 ether to buy a ticket");
        uint prizeAmount = 0.08 ether;
        prizePot += prizeAmount;
        uint feeAmount = 0.02 ether;
        deployer.transfer(feeAmount);
        tickets[msg.sender] += 1;
        emit TicketPurchased(msg.sender, prizeAmount);
    }

    function drawWinner() public {
        require(msg.sender == deployer, "Only the deployer can draw the winner");
        require(block.timestamp - lastDrawTimestamp >= 7 days, "You can only draw a winner once a week");

        // Create an array to store the addresses of ticket holders
        address[] memory ticketHolders = new address[](getTicketCount());
        uint index = 0;

        // Loop through the tickets mapping and add each ticket holder to the array
        for (uint i = 0; i < 100; i++) {
            address randomAddress = address(uint160(uint(keccak256(abi.encodePacked(block.timestamp, i)))) & 0x000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            uint ticketCountValue = tickets[randomAddress];
            for (uint j = 0; j < ticketCountValue; j++) {
                ticketHolders[index] = randomAddress;
                index++;
            }
        }

        // Select a winner randomly from the array of ticket holders
        if (index > 0) {
            uint winnerIndex = uint(keccak256(abi.encodePacked(block.timestamp, index))) % index;
            lastWinner = ticketHolders[winnerIndex];
            winners.push(lastWinner); // add the new winner to the winners array
            uint prizeAmount = prizePot;
            prizePot = 0;
            payable(lastWinner).transfer(prizeAmount);
            emit WinnerDrawn(lastWinner, prizeAmount);
        }

        // Schedule the next draw to occur 7 days after the current draw
        lastDrawTimestamp = block.timestamp;
    }

    function withdrawPrize() public {
        require(msg.sender == lastWinner, "Only the winner can withdraw the prize");
        require(tickets[msg.sender] > 0, "You must have purchased at least one ticket to claim the prize");
        uint prizeAmount = 0.08 ether * tickets[msg.sender];
        tickets[msg.sender] = 0;
        payable(msg.sender).transfer(prizeAmount);
    }

    function getTicketCount() public view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < 100; i++) {
            address randomAddress = address(uint160(uint(keccak256(abi.encodePacked(block.timestamp, i)))) & 0x000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            count += tickets[randomAddress];
        }
        return count;
    }

    function getWinners() public view returns (address[] memory) {
        return winners;
    }
}