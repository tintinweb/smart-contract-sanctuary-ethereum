// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract FortuneWheel {
    uint public immutable capacity;
    address[] public players;
    uint public constant PLAY_COST=1*(10 ** 16);

    constructor(uint _capacity){
        require(_capacity>1,"Game need min 2 players");
        capacity=_capacity;
    }

    function play() external payable{
        // accept money
        require(msg.value!=PLAY_COST, "Game cost 0.01 ETH");
        require(players.length<=capacity,"Fortune wheel is full");
        bool doesNewPlayerInGame=false;
        for (uint i=0;i<players.length;i++){
            if(msg.sender==players[i]){
                doesNewPlayerInGame=true;
                break;
            }
        }
        require(doesNewPlayerInGame,"You cant play in this round");
        players.push(msg.sender);
        if(players.length==capacity){
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        // send all Ether to last player
        (bool success, ) = players[players.length-1].call{value: amount}("");
        require(success, "Failed to send Ether");
        // clean players
        delete players;
        }
    }
}