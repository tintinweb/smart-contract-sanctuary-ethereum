/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File: TimeLockedWallet.sol


pragma solidity ^0.8.0;

contract TimeLockedWallet {
   address public owner;
   uint public unlockPeriod;
   uint public createdAt;
   
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

   constructor() {
      unlockPeriod = 60 seconds;
      owner = msg.sender;
   }

   function deposit() external payable onlyOwner {
      createdAt = block.timestamp;
   }

   function info() public view returns(address, uint, uint, uint, uint) {
      uint timeLeft = createdAt+unlockPeriod-block.timestamp;
      return (owner, unlockPeriod, createdAt, timeLeft, address(this).balance);
   }

   function withdraw() public onlyOwner {
      require(block.timestamp >= createdAt+unlockPeriod);
      payable(owner).transfer(address(this).balance);
   }
}