/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Lottery {
    address[] public player;
    address public winner;
    address private _owner;
    uint256 public wager;

    modifier isOwner{
        require(msg.sender == _owner, "You are not the owner of this contract!");
        _;
    }

    enum STATE{
      STOP,
      RUNNING,
      PENDING
    }

    STATE lotteryState;

    constructor(){
      lotteryState = STATE.STOP;
      _owner = msg.sender;
    } 

    function startLottery(uint256 fee) public {
      require(lotteryState == STATE.STOP, "Lottery is running!");
      lotteryState = STATE.RUNNING;
      require(fee > 0, "[Error] Please give a positive integer!");
      wager = fee;
    }

    function enter() payable public {
      require(lotteryState == STATE.RUNNING, "[Error] Lottery is not running!");
      require(msg.value >= wager, "[Error] Insufficient wager!");
      player.push(msg.sender);
    }

    function endLottery() public isOwner{
      require(lotteryState == STATE.RUNNING, "[Error] Lottery is not running!");
      require(player.length > 0, "[Error] No player.");
      lotteryState = STATE.PENDING;

      uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % player.length;
      winner = player[indexOfWinner];
      payable(winner).transfer(address(this).balance);
      delete player;

      lotteryState = STATE.STOP;
    }
    
}