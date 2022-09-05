//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract EtherWallet {
  mapping(address => uint) internal balances;
  event Depoist(address from, uint amount);
  event Withdraw(address to, uint amount);

  function balanceOf(address account) public view returns (uint) {
    return balances[account];
  }

  function _deposit() internal {
    require(msg.value > 0, "Value must be greater than 0");
    balances[msg.sender] += msg.value;
    emit Depoist(msg.sender, msg.value);
  }

  function deposit() external payable {
    _deposit();
  }

  function withdraw(address payable target, uint amount) external {
    require(balanceOf(msg.sender) >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    (bool sent,) = target.call{value:amount}("");
    require(sent, "Failed to withdraw");
    emit Withdraw(target, amount);
  }

  receive() external payable {
    _deposit();
  }
}