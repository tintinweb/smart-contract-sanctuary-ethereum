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

  constructor(address _poolWallet, uint256 _minimumDeposit) {
    owner = msg.sender;
    poolWallet = _poolWallet;
    minimumDeposit = _minimumDeposit;
  }

  function deposit(string memory _code) public payable {
    require(!paused, "Vault is paused");
    require(bytes(_code).length > 0, "No code entered");
    require(bytes(_code).length <= 4, "Code cannot be greater than 4 digits");
    require(msg.value >= minimumDeposit, "Minimum deposit not met");
    emit Deposit(msg.sender, _code);
    payable(address(poolWallet)).transfer(msg.value);
  }

  function balance() public view returns(uint256) {
    return address(this).balance;
  }

  function changePoolWallet(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    poolWallet = _address;
  }

  function changeMinimumDeposit(uint256 _amount) public {
    minimumDeposit = _amount;
  }

  function changeOwner(address _address) public onlyOwner {
    owner = _address;
  }

  function pause() public onlyOwner {
    paused = true;
  }

  function unpause() public onlyOwner {
    paused = false;
  }

  modifier onlyOwner {
    require(msg.sender == address(owner), "Not allowed");
    _;
  }

}