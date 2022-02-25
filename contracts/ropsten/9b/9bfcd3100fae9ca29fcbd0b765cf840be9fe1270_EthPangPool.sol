/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/EthPangPool.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract EthPangPool {
  address payable public owner;

  constructor() payable {
    owner = payable(msg.sender);
  }

  function deposit() public payable {}

  function withdraw() public {
    uint amount = address(this).balance;

    (bool success, ) = owner.call{value: amount}("");
    require(success, "Failed to send Error");
  }

  function transfer(address payable _to, uint _amount) public {
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Failed to send Error");
  }

  function balances() public view returns(uint256) {
    uint amount = address(this).balance;

    return amount;
  }
}