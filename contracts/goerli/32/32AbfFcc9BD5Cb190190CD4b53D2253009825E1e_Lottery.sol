/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Lottery{
    address public manager;
    address payable[] public players;

    constructor(){
        manager = msg.sender;
    }
    function getBalance() public view returns(uint){
        return address(this).balance;           // address(this) is smart contract address
    }
    function buyLottery() public payable{
        require(msg.value == 1 ether, "The Lottery price is 1 Ether");
        players.push(payable(msg.sender));
    }
    function getLength() public view returns(uint){
        return players.length;
    }
    function randomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,players.length))); //convert hexadecimal string to byte number format via sha-3
    }
    function selectWinner() public {
        require(msg.sender == manager, "You are not manager.");
        require(getLength()>=2, "Number of player less than 2 people.");
        uint pickrandom = randomNumber();
        address payable winner;
        uint selectIndex = pickrandom % players.length; //หารแล้วเหลือเศษคือ index ของผู้ชนะ
        winner = players[selectIndex];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}