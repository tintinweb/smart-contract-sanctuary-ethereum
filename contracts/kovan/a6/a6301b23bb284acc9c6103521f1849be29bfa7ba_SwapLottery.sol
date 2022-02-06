/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity ^0.8.11;
// SPDX-License-Identifier: MIT

contract SwapLottery {
    
    address public owner;
    uint public lotteryId;
    address payable[] public players;
    uint256 public maxTickets = 4;
    uint public ticketCount = 0;
    address public lastWinner;
  
    mapping(address => uint256) public winnings;
    address[] public tickets;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
      function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function enter() private {
       
        players.push(payable(msg.sender));
        ticketCount ++;
    }
    function pickWinner() private {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(address(this).balance);
        //winner.transfer( (getBalance() * 90) / 100);
        payable(owner).transfer( (getBalance() * 10) / 100);
        resetLottery(); 
    }
      function resetLottery() internal {
        players = new address payable[](0);
        ticketCount = 0;  
    }

}