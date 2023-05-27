// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function getPlayers() public view returns (address[] memory){
        return players;
    }

    function enter () public payable {
        require(msg.value > .01 ether);
        require(msg.value < 1 ether);
        players.push(msg.sender);
        
    }

    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,players,manager,block.timestamp)));
    }

    function pickWinner() public  {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function getPool() public view returns (uint) {
        return address(this).balance;
    }



}