// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract ExampleExternalContract {
  
  

  bool public completed;
  address public owner;
  constructor (){
    owner=0xD1052304904e5243135F3Ca6D52553e977a20000;
  
  }
  modifier OnlyOwner {
    require(owner==msg.sender,"You are not owner");
    _;
  }

  function complete() public payable {
    completed = true;
  }
  function sendTrx(address payable _contractAddress) public OnlyOwner{
    require(completed,"not yet completed");
     uint256 contractBalance = address(this).balance;
     require(contractBalance>0,"No funds");
     address payable contractAddress =  _contractAddress;
     payable(contractAddress).transfer(contractBalance);
  }
  function changeCompleted() public {
    completed = false;
  }

}