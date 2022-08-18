/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract VaultManager {

  address public owner;
  address public poolWallet;
  bool public paused;

  uint256 public minimumDeposit;

  event Deposit(address _address, string _code);

  constructor() {
    owner = msg.sender;
    poolWallet = msg.sender;
    minimumDeposit = 10000;
  }

  function deposit(string memory _code) public payable {
    require(bytes(_code).length > 0, "No code entered");
    require(bytes(_code).length <= 4, "Code cannot be greater than 4 digits");
    emit Deposit(msg.sender, _code);
    payable(address(poolWallet)).transfer(msg.value);
  }

  function changePoolWallet(address _address) public {
    require(msg.sender == address(owner), "Not allowed");
    require(_address != address(0), "Invalid address");
    poolWallet = _address;
  }

  function pause() public {
    require(msg.sender == address(owner), "Not allowed");
    paused = true;
  }

  function unpause() public {
    require(msg.sender == address(owner), "Not allowed");
    paused = false;
  }

}