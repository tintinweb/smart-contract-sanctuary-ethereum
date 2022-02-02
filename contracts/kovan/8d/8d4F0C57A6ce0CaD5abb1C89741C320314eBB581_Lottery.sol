/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery{
    address _manager;
    address payable[] players;

    constructor() {
        _manager = msg.sender;
    }

    function getBalance() public view returns (uint balance) {
        balance = address(this).balance;
        return balance;
    }

    function buyLottery() public payable {
        require(msg.value == 0.1 ether, "Lottery 1 ETH");
        players.push(payable(msg.sender));
    }

    function getLength() public view returns(uint len) {
        len = players.length;
        return len;
    }
    
    function randomNumber() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

    function selectWinner() public {
        require(msg.sender == _manager, "You is not manager !");
        require(getLength() >= 2,"Player more than 2 ");
        uint pickrandom = randomNumber();
        address payable winner;
        uint selectIndex = pickrandom % players.length;
        winner = players[selectIndex];
        winner.transfer(getBalance());
        players = new address payable[](0);
        //return (players[selectIndex], selectIndex);
    }
}