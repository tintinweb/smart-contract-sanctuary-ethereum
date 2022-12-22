/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Credit to Ethernaut OpenZeppelin Re-Entrancy Level for contract inspiration

contract ReentranceVulnerable {
  
  mapping(address => uint) public balances;

  function deposit(address _to) public payable {
    balances[_to] = balances[_to] + msg.value;
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  function reset() public {
      balances[msg.sender] = 0;
  }

  receive() external payable {}
}