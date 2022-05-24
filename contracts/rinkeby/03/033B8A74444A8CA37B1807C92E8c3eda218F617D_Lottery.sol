//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Lottery{
    address public admin;
    address public winner;
    uint public pool;
    address[] public players;
    mapping(address => uint) public ticketsOwned;

    // constructor 
    constructor(){
        admin = msg.sender; // set the admin to be the deployer of contract
    }

    // add player to pool
    function enterPool(uint numTickets) public{
        // add address to the player array numTicket times
        for(uint ticket=0; ticket<numTickets;ticket++){
            players.push(msg.sender);
        }
        pool = pool + (numTickets * 19); // update the winning pool
        
        ticketsOwned[msg.sender] = ticketsOwned[msg.sender] - numTickets; // reduce owned tickets from total
    }

    // increment  the number of tickets owned by user
    function addTickets(uint numTickets) public{
        ticketsOwned[msg.sender] = ticketsOwned[msg.sender] + numTickets;
    }

    // get winner and reset
    function selectWinner() public{
        require(msg.sender == admin, "You do not have authority!");
        // write code to get winner
        winner = players[random()];
        
        // reset for next round
        pool = 0;
        players = new address[](0);
        // for(uint i =0; i < players.length; i++){
        //     delete players[i];
        // }
    }

    // helper function to get random number
    function random() private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        return randomHash % players.length;
    }

    // other functions
    function numPlayers() public view returns (uint){
        return players.length;
    }

    // other functions
    function getWinner() public view returns (address){
        return winner;
    }

    function getPool() public view returns (uint){
        return pool;
    }

    function getAdmin() public view returns (address){
        return admin;
    }

    function getTicketsOwned() public view returns (uint){
        return ticketsOwned[msg.sender];
    }

    function getNumEntries() public view returns (uint){
        uint entryCount = 0;
        for(uint x=0;x<players.length;x++){
            if(players[x] == msg.sender){
                entryCount++;
            }
        }

        return entryCount;
    }

}