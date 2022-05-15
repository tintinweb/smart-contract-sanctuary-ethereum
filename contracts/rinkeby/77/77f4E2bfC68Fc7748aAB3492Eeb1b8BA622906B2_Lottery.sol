/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor(){
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) { //function _random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))); // uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        // Enforce the caller is the contract owner (manager)
        //require(msg.sender == manager);
        
        uint index = random() %players.length;
        payable(players[index]).transfer(address(this).balance);
        
        // Create a new array of players after running pickWinner
        players = new address[](0); 

    }
    
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getBalance() public view returns(uint){
        return address(this).balance; // this.balance
    }
    
    // Cancel entire round of lottery and send back the money to 
    // the senders
    function returnEntries() public view restricted{ // returnEntries() public restricted
        //require(msg.sender == manager);
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _; // target to the code of the referred
    }
    
}