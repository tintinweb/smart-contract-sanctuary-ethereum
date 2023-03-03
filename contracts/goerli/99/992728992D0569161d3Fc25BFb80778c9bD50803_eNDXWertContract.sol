/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract eNDXWertContract { 

  address public contractOwner;

  constructor() {
    contractOwner = msg.sender;
  }
 
  function deposit(address payable _receiver) external payable { }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function withdrawAll(address payable _to) public { 
    require(contractOwner == _to);
    _to.transfer(address(this).balance);
  }

}