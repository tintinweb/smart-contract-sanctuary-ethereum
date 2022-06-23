/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Lottery_Ticket{
    address payable[] public players;
    address public manager;
    
    constructor(){
        manager = msg.sender;
    }
    
    receive() external payable{
        require(msg.value == 0.1 ether); //可設定固定的下注金額為多少
        players.push(payable(msg.sender));    
    }
    
    //取得合約目前的餘額Wei值，該功能必須是合約發佈者才可使用
    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }
    
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    //
    function PickWinner() public{
        require(msg.sender == manager);
        require(players.length >= 3); //設定最低下注人數才能繼續選取勝者
        
        uint r = random();
        address payable winner;
        
        uint index = r % players.length; //調用random這個function所得出的隨機值取下注人數的餘數
        winner = players[index]; 
        
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}