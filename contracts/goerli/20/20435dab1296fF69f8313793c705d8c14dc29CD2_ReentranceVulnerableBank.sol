/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;

// Credit to Ethernaut OpenZeppelin Re-Entrancy Level for contract inspiration
// https://goerli.etherscan.io/address/0x2F2133892BCA9d3f3b893c07311feB14381E0319#code

contract ReentranceVulnerableBank {
  
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