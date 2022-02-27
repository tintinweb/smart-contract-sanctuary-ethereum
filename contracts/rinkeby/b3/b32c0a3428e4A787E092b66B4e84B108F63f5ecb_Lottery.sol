/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

contract Lottery {
    address payable public creator;
    address payable public manager;
    address payable[] public players;
    bool public isOpen;
    mapping (address => uint) yourTicket;
    mapping (uint => bool) usedTickets;
    //only to check the used tickets...
    uint[] usedTicketsList;
    uint[] tickets;
    
    constructor() {
        creator = payable(msg.sender);
        isOpen = false;
    }

    function randomRange(uint256 number) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, players)
                )
            ) % number + 1;
    }

      function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }


    modifier onlyOwner() {
        require(msg.sender == manager);
        _;
    }

    event Winner(
       uint ticketNumber,
       address winner
        );

    function createLottery(uint maxPlayers) public {
        require(!isOpen);
        manager = payable(msg.sender);
        uint i;
        for (i=1 ; i <= maxPlayers ; i++){
            tickets.push(i);
        }
        isOpen = true;
    }


    function enter(uint ticketNumber) public payable {
        require(msg.value == 1 ether, "entering value is exactly 1 ether");
        require(usedTicketsList.length <  tickets.length, "no tickets available");
        require(!usedTickets[ticketNumber], "ticked already taken!");
        require(ticketNumber != 0, "ticket must be a positive number");

        players.push(payable(msg.sender));
        usedTicketsList.push(ticketNumber);
        usedTickets[ticketNumber] = true;
        yourTicket[msg.sender] = ticketNumber;

    }
    
    function pickWinner() public onlyOwner {
        
        uint index = randomRange(usedTicketsList.length);
        players[index].transfer(address(this).balance *100 / 125 );
        manager.transfer(address(this).balance);
        
        emit Winner(yourTicket[players[index]] , players[index]);

        uint i;
        
        for (i=0 ; i < players.length; i++){
            yourTicket[players[i]] = 0;
            usedTickets[i] = false;
        }

        players = new address payable[](0);
        usedTicketsList = new uint[](0);
        tickets = new uint[](0);
        isOpen = false;
      
    }

    function seeUsedTickets() public view returns (uint[] memory){
        return usedTicketsList;
    }

     function seeYourTicket(address yourAddress) public view returns (uint){
        return yourTicket[yourAddress];
    }

    function getAllLoterryTickets() public view returns (uint[] memory){
        return tickets;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}