/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract Lottery {
    address owner;
    uint256 private randnum;
    uint256 private balance;
    event GuessMade(address player, uint256 guess);
    event LotteryStarted(uint256 randnum);
    event GuessWasLess(address player);
    event GuessWasMore(address player);
    event LotteryEnded(address winner, uint256 winnings);
  
    constructor()  {
        owner = msg.sender;
    }
    modifier onlyOwner {
      require(msg.sender == owner , "Only Owner Can Do This");
      _;
   }


    function startLottery() public onlyOwner {
        randnum = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100) + 1;
        emit LotteryStarted(randnum);
    }

    function makeGuess(uint256 _guess) public payable   {
        require(msg.value > 0.002 ether, "You must send a above 0.002 amount of ether.");
        require(randnum > 0, "The lottery has not started yet.");
        emit GuessMade(msg.sender, _guess);
        balance += msg.value;
        if (_guess == randnum) {
            payable(msg.sender).transfer(balance);
            randnum = 0;
            balance=0;
            emit LotteryEnded(msg.sender, balance);
        }else if (randnum > _guess) {
            emit GuessWasLess(msg.sender);
        }  else {
            emit GuessWasMore(msg.sender);
        }
    }

}