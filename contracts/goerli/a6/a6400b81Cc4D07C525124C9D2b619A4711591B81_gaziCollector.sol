/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

contract gaziCollector { //0x201310e995D3e3F11c734Cca1B68aF68844b5007
    address public owner;
    uint256 public balance; 

  constructor() {
     owner = msg.sender; 
  }

  receive() payable external {
        balance += msg.value;
  }

  function withdraw(uint amount, address payable destAddr) public {
     require(msg.sender == owner, "Sadece owner withdraw islemi yapabilir");
     require(amount <= balance, "Yetersiz bakiye");
     
      destAddr.transfer(amount);
      balance -= amount;
    
  }
}