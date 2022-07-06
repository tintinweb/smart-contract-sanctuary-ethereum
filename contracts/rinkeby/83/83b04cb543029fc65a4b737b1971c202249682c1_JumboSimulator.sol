/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

/*
Roadmap:
Buy Lottery
Get My Tickets
Get Sold Tickets
Get ticket owner address
ChooseWinner
*/

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

contract JumboSimulator {
    
    address public deployer;

    uint constant TICKET_PRICE = 0.005 ether;

    uint[] soldTickets;

    mapping(uint => address payable) soldTicketData;

    mapping(address => Customer) customerData;

    struct Customer {
        uint totalTickets;
        uint[] tickets;
    }

    string season = "";

    constructor(string memory _season) {
        require(bytes(_season).length > 0, "empty season not allowed");
        deployer = msg.sender;
        season = _season;
    }

    function buyLotteries(uint _pieces) public payable {
        require(bytes(season).length > 0, "cannot participate on empty season");
        require(_pieces > 0, "cannot buy 0 tickets");
        uint totalPrices = _pieces * TICKET_PRICE;
        require(msg.value > totalPrices, "Has not enough money");
        for ( uint i = 0; i < _pieces; i++ ) {
            uint ticketId = generateRandomId();
            soldTickets.push(ticketId);
            soldTicketData[ticketId] = payable(msg.sender);
            customerData[msg.sender].tickets.push(ticketId);
        }
        customerData[msg.sender].totalTickets += _pieces;
    }

    function chooseWinner() public onlyDeployer {
        require(bytes(season).length > 0, "season is undefined");
        uint winnerIndex = generateRandomId() % soldTickets.length;
        uint winnerTicketId = soldTickets[winnerIndex];
        address payable winnerAddress = soldTicketData[winnerTicketId];
        uint winnerPrice = soldTickets.length * TICKET_PRICE;
        season = "";
        winnerAddress.transfer(winnerPrice);
    }

    function getMyTickets() public view returns (Customer memory) {
        return customerData[msg.sender];
    }

    function getTotalSoldTickets() public view returns (uint[] memory) {
        return soldTickets;
    }

    function getTicketOwner(uint _ticketId) public view returns (address) {
        return soldTicketData[_ticketId];
    }

    function generateRandomId() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, season)));
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "This is only for deployer");
        _;
    }
}