/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity ^0.8.14;
// SPDX-License-Identifier: MIT

contract workshop {
  mapping(address=>uint) private balances;
  mapping(address=>string) private walletName;
  string private name ;
  string private symbol;
  uint private totalsupply;
  constructor(string memory _name, string memory _symbol, uint _totalsupply){
    name = _name;
    symbol = _symbol;
    balances[msg.sender] = _totalsupply;
    totalsupply = _totalsupply;
  }
  function getName()public view returns(string memory){
    return name;
  }
  function getSymbol()public view returns(string memory){
    return symbol;
  }
  function getTotalSupply()public view returns(uint){
    return totalsupply;
  }
  function balanceOf(address account)public view returns(uint){
    return balances[account];
  }
  function transfer(address _to, uint amount)public{
    address owner = msg.sender;
    require(balances[owner] >= amount ,"can not transfer!!");
    require(owner != _to,"can not tansfer with the same account!!!");
    balances[owner] -= amount;
    balances[_to] += amount;
  }
  function setMyWalletName(string memory _name)public{
    walletName[msg.sender] = _name;
  }
  function getWalletName(address _add)public view returns(string memory){
    if(bytes(walletName[_add]).length != 0){
      return walletName[_add];
    }
    else{
      return "no name";
    }
  }

}