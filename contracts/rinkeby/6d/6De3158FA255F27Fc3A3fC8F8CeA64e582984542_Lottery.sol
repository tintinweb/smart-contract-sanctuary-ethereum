/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Lottery{
    address manager;
    address payable[] players;

    constructor(){
        manager = msg.sender;
    }
    //เก็บยอดเงิน
    function getBalance() public view returns(uint){
            return address(this).balance;
    }
    //ซื้อ lottery
    function buyLottery() public payable{
        require(msg.value == 0.001 ether,"Please Buy Lottery 0.001 ETH per 1 time");
        players.push(payable(msg.sender));
    }
    //เก็บจำนวนผู้ซื้อ
    function getLength() public view returns(uint){
        return players.length;
    }
    //สุ่มตัวเลข
    function randomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    //เลือกว่าใครได้รับรางวัล
    function selectWinner() public{
        require(msg.sender == manager,"You aren't Manager");
        //ต้องมีคนซื้อมากกว่า 3 ใบหรือ 3 คนถึงจะประกาศผลได้
        require(getLength()>=3,"less then 3 players");
        //สร้างตัวแปรเก็บเลขที่สุ่ม
        uint pickrandom = randomNumber();
        //เก็บ address คนได้รับเงินรางวัล
        address payable winner;
        //เก็บเลข Index ผู้ที่ควรรับเงินรางวัล
        uint selectIndex = pickrandom % players.length;
        winner = players[selectIndex];
        //โอนเงินให้ผู้โชคดี
        winner.transfer(getBalance());
        //เคลียร์ค่าใหม่หลังประกาศผล
        players = new address payable[](0);
    }
}