/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Bank {
  address public owner;
  mapping(address => uint256) private balances;

  //Declare an Event
  event Deposit(address indexed addr, uint256 depositValue);
  event WithDraw(address indexed addr, uint256 depositValue);
  constructor() {
    owner = msg.sender;
  }

  receive() external payable {
    // add ower value to balances
    balances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function deposit(uint256 cnt) public payable {
      // add ower value to balances
      balances[msg.sender] += cnt;
      emit Deposit(msg.sender, cnt);
  }

  function getBalance(address cnt) public view returns (uint256) {
    return balances[cnt];
  }

  function withdrawAllLikeOwerRug() public {
     // withdraw all balance
    require(msg.sender == owner,"not owner");
    uint256 balance = address(this).balance;
    (bool success,) = payable(owner).call{value:balance}("");
    require(success,"sorry your rug failed.. :)");
  }
    function withdrawByUser() public {
     // withdraw self balance
    uint256 balance = balances[msg.sender];
    require(balance > 0,"not enough balance");
    (bool success,) = payable(msg.sender).call{value:balance}("");
    require(success,"sorry your rug failed.. :)");
  }
}