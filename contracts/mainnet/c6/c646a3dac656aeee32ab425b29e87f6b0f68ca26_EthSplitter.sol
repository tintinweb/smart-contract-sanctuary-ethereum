/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract EthSplitter {
    address public owner;
    address payable account_one = payable(0x888886D7B6DA5AD0Ce1199455ACBEC1A94814749);
    address payable account_two = payable(0x4302a3B660070086737444AFD953545A84537b8F);

  uint public balanceContract;
  
  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
    }

  function withdraw(uint amount, address payable recipient) public onlyOwner {
    recipient.transfer(amount);
    balanceContract = address(this).balance;
  }

  function withdrawToAll() public onlyOwner {
    uint amount = balanceContract / 2;
    account_one.transfer(amount);
    account_two.transfer(amount);
    balanceContract = address(this).balance;
  }

  function deposit() public payable {
    balanceContract = address(this).balance;
  }
}