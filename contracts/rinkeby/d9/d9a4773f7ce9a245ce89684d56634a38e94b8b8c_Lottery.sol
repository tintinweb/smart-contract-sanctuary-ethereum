/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// File: contracts/final.sol


pragma solidity ^0.8.7;

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
      require(lotteryState == STATE.STOP, "The lottery is running!");
      lotteryState = STATE.RUNNING;
      require(fee > 0, "You should enter a positive number!");
      wager = fee;
    }

    function enter() payable public {
      require(lotteryState == STATE.RUNNING, "The lottery is not running!");
      require(msg.value >= wager, "Insufficient wager!");
      player.push(msg.sender);
    }

    function endLottery() public isOwner{
      require(lotteryState == STATE.RUNNING, "The lottery is not running!");
      require(player.length > 0, "No player in the current pool!");
      lotteryState = STATE.PENDING;

      uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % player.length;
      winner = player[indexOfWinner];
      payable(winner).transfer(address(this).balance);
      delete player;

      lotteryState = STATE.STOP;
    }
    
}