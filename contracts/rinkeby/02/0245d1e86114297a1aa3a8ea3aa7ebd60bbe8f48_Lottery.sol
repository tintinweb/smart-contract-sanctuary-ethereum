/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;

    address private _owner;

    uint256 public entranceFee;

    modifier onlyOwner {
      require(msg.sender == _owner, "Not contract owner");
      _;
    }

    enum LOTTERY_STATE {
      STOPPED,
      STARTED,
      CALCULATING
    }

    LOTTERY_STATE contractState;

    constructor() {
      contractState = LOTTERY_STATE.STOPPED;
      _owner = msg.sender;
    }

    function startLottery(uint256 fee) public {
      require(contractState == LOTTERY_STATE.STOPPED, "Lottery is currently running, this require it to be stopped.");
      contractState = LOTTERY_STATE.STARTED;

      require(fee > 0, "You have to specify a positive number");

      // 1.00000 ETH is 1 * 10 ** 18
      // 0.00001 ETH is 1 * 10 ** (18 - 5)
      entranceFee = fee;
    }

    function enter() payable public {
      require(contractState == LOTTERY_STATE.STARTED, "Lottery is not running.");
      require(msg.value >= entranceFee, "Insufficient funds.");
      players.push(msg.sender);
    }

    function endLottery() public onlyOwner {
      require(contractState == LOTTERY_STATE.STARTED, "Lottery is currently stopped or calculating winner.");
      require(players.length > 0, "There is currently no player in the pool.");

      contractState = LOTTERY_STATE.CALCULATING;

      uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;

      recentWinner = players[indexOfWinner];

      payable(recentWinner).transfer(address(this).balance);

      delete players;

      contractState = LOTTERY_STATE.STOPPED;
    }
}