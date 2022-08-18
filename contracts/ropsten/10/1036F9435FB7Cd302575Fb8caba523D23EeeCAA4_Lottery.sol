// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Lottery contract 
/// @author Glory Praise Emanuel
/// @dev A contract that accepts collects money from people and gives the total to a person as a lottery

contract Lottery {

  address[] public playersRecord;
  address payable winner;
  address public staff;
  uint256 depositedMoney;

  constructor() {
    staff = msg.sender;
  }

  modifier onlyOwner {
    require(staff == msg.sender, "Denied, not a staff!");
    _;
  }
  function checkLotteryBalance() view public returns (uint256) {
   return address(this).balance;
  }

  function deposit() public payable {
    require(msg.value > 0, "You must have money tp participate");
    require(msg.value < 5 ether , "You need to stake 5 ethers to qualify for this lottery");
    playersRecord.push(msg.sender);
  }

  function random() public view returns(uint256){
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
  }

  function pickWinner() public onlyOwner {
    require(playersRecord.length > 3, "3 players or more needed to pick a winner");

    uint r = random();
    uint256 calculate = r%playersRecord.length;
    winner = payable(playersRecord[calculate]);
    winner.transfer(checkLotteryBalance());
  }



  function checkWinnerBalance() view public returns (uint256) {
   return winner.balance;
  }

  function checkNoOfPlayers() view public returns(uint) {
    return playersRecord.length;
  }
}