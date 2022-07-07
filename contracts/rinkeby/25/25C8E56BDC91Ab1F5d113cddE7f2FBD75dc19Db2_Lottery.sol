// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract Lottery {
    address public owner;
    address[] public players;

    constructor() {
        owner = msg.sender;
    }

    function enter() external payable {
        require(msg.value == 0.1 ether, "You must give 0.1 eth to enter");
        uint i;
        for(i = 0; i < players.length; i++){
            require(players[i] != msg.sender, "You cannot enter the lottery twice!");
        }
        players.push(msg.sender);    
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public {
        require(msg.sender == owner, "This can only be called by the owner");
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function getPlayers() public view returns (address[] memory){
        return players;
    }
}