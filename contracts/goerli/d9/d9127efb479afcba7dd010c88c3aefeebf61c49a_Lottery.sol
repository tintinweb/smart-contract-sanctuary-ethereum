/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    
    address public manager;
    
    address payable[] public players;
    uint public playersCounter;
    
    uint public maxPlayersNumber;
    
    event PlayerJoined(address player);
    event PlayerWon(address player, uint amount);
    
    constructor(uint playersNumber) {
        maxPlayersNumber = playersNumber;
        manager = msg.sender;
    }
    
    function join() payable public {
        require(msg.value >= .1 ether);
        
        players.push(payable(msg.sender));
        playersCounter++;
        
        emit PlayerJoined(msg.sender);
        
        if (playersCounter >= maxPlayersNumber) {
            drawWinner();
        }
    }
    
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
    
    function forceDrawing() public onlyManager {
        drawWinner();
    }
    
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }
    
    function drawWinner() private {
        uint index = random() % players.length;
        uint amount = address(this).balance;
        
        address payable winner = players[index];
        winner.transfer(amount);
        
        players = new address payable[](0);
        playersCounter = 0;
        
        emit PlayerWon(winner, amount);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, players)));
    }   
}