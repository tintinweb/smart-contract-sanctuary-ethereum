/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Lottery{
    address public owner;
    address payable[] public players;
    
    constructor () {
        owner = msg.sender;
    }

    function enterLotteryGame() public payable {
        require(msg.value > 0.001 ether);
        players.push(payable(msg.sender));
    }

    function pickWinner() public payable adminAccess{
        uint index = randomPicker() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function randomPicker() private view returns (uint){
        return uint(sha256(abi.encode(block.difficulty, block.timestamp, players)));     
    }

    modifier adminAccess(){
        require(msg.sender == owner);
        _;
    }

    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

}