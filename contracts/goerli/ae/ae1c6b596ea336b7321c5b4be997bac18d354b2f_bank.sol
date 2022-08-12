/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
contract bank
{
   string _name;
   string symbol;

   address owner;
   mapping (address => string) users;
   mapping (address => bool) userAccount;
   mapping (address => mapping (uint => uint)) lockTimes;
   mapping (address => uint) valueLocks;
   uint fee = 0.2 ether;

   modifier check ()
   {
      require (userAccount [msg.sender] == true , "Error : pleas creat an account");
      _;
   }

   modifier onlyOwner ()
   {
      require (msg.sender == owner , "you are not owner");
      _;
   }

   constructor (string memory name_ , string memory _symbol)
   {
      owner = msg.sender;
      _name = name_;
      symbol = _symbol;
   }

   function createAccount (string memory name) public
   {
      require (msg.sender != address (0) , "this address is 0");
      require (!userAccount [msg.sender] , "every one can create 1 account");

      users [msg.sender] = name;
      userAccount [msg.sender] = true;
   }

   function lock (uint lockTime , uint value) public payable check
   {
      uint _lockTime = lockTime + block.timestamp;
      lockTimes [msg.sender] [value] = _lockTime; 
      valueLocks [msg.sender] = value;
      require (msg.value == value , "Your account balance is insufficient");
   }

   function unlock () public payable check
   {
      address userAddress = msg.sender;
      uint userValue = valueLocks [msg.sender];
      
      require (block.timestamp >= lockTimes [userAddress] [userValue] , "Your time is not up yet");

      (bool success, ) = userAddress.call{value: userValue - fee}("");
      require(success, "transfer faild.");
   }

   function withraw () public payable onlyOwner
   {
   (bool success, ) = owner.call{value: address(this).balance}("");
   require(success, "transfer faild.");
   }
}