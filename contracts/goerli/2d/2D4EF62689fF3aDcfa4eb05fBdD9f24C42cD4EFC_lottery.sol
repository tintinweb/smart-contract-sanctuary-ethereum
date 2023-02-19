/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract lottery {
    address[] public players;
    uint public timeStartGame;
    uint public minimalPay;
    uint public gameBalance;

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, players))) % players.length;
    }

    receive() payable external {
        if(players.length == 0){minimalPay = msg.value;}
        if(msg.value>=minimalPay) {
            players.push(msg.sender);
            timeStartGame = block.timestamp;
            gameBalance += msg.value;
        }
        if(players.length >= 2){getAWin();}
    }
    
    function getAWin() public {
        require(block.timestamp > timeStartGame + 10 minutes && players.length >= 2);
        payable(players[random()]).transfer(gameBalance - ((gameBalance/100)*5));
        delete players;
        delete gameBalance;
    }
}