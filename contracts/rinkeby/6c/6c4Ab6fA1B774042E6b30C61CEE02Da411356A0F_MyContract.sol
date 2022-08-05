/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

pragma solidity ^0.8.7;

contract MyContract{

uint pointMultiplier = 10e18;
struct Account {
  uint balance;
  uint lastDividendPoints;
}
mapping(address=>Account) accounts;
uint totalSupply;
uint totalDividendPoints;
uint unclaimedDividends;
function dividendsOwing(address account) internal returns(uint) {
  uint newDividendPoints = totalDividendPoints - accounts[account].lastDividendPoints;
  return (accounts[account].balance * newDividendPoints) / pointMultiplier;
}
modifier updateAccount(address account) {
  uint owing = dividendsOwing(account);
  if(owing > 0) {
    unclaimedDividends -= owing;
    accounts[account].balance += owing;
    accounts[account].lastDividendPoints = totalDividendPoints;
  }
  _;
}
function disburse(uint amount) public {
  totalDividendPoints += (amount * pointMultiplier / totalSupply);
  totalSupply += amount;
  unclaimedDividends += amount;
}
}