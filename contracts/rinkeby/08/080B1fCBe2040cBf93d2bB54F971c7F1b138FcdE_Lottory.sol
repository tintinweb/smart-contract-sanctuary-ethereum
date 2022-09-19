/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Lottory{
    address manager;
    address payable[] players;

    constructor(){
        manager = msg.sender; // address ผู้จัดการ
    }

    function getBalance() public view returns(uint){
        return address(this).balance; // แสดงยอดเงินใน Contract
    }

    function buyLottery() public payable{
        require(msg.value == 0.01 ether, "Please Buy Lottery 1 ETH Only."); // เช็คจำนวนเงินโอน
        //require(msg.value == 1 ether, "Please Buy Lottery 1 ETH Only."); // เช็คจำนวนเงินโอน
        players.push(payable(msg.sender)); // เพิ่ม address ผู้ซื้อใน players
    }

    function getLength() public view returns(uint){
        return players.length; // แสดงจำนวนผู้ซื้อ
    }

    function randomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

    function selectWinner() public{
        require(msg.sender == manager, "You can't Manager"); // เช็ค address ผู้จัดการ
        require(getLength() >= 2, "Less then 2 players"); // เช็ค ต้องมีผู้ซื้ออย่างน้อย 2 คน ขึ้นไป

        uint pickrandom = randomNumber(); // เลขที่ random ออกมาก
        uint selectIndex = (pickrandom % players.length); // เลข random หารกับจำนวนผู้ซื้อ เพื่อเอาเศษจากจำนวนผู้ซื้อ

        address payable winner;
        winner = players[selectIndex]; // หาตำแหน่งในอาร์เรย์
        winner.transfer(getBalance()); // โอนเงินให้ผู้ถูกรางวัล
        players = new address payable[](0); // เคลีย์ค่าใน players
    }

    /*function selectWinner() view public returns(address,uint){
        require(msg.sender == manager, "You can't Manager");
        require(getLength() >= 2, "Less then 2 players");

        uint pickrandom = randomNumber(); // เลขที่ random ออกมาก
        uint selectIndex = (pickrandom % players.length); // เลข random หารกับจำนวนผู้ซื้อ เพื่อเอาเศษจากจำนวนผู้ซื้อ
        return (players[selectIndex], selectIndex);
    }*/
}