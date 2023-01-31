/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;


contract Block4Coffee {
  
  address payable public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    owner =  payable(msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = payable(newOwner);
  }


  uint price;
  int stock;
  int caisse;
  mapping (address => int) ownerCredit;
  mapping (address => int) providers;

  modifier onlyProviders() {
    require(providers[msg.sender] == 1);
    _;
  }

  function sendMoney(uint _nbcoins) external payable {
    require (msg.value == _nbcoins*(1 ether ));
    ownerCredit[msg.sender]+= int(_nbcoins) ;
}

  function getMoneyBack() external{
    require (ownerCredit[msg.sender] > 0);
    caisse -= ownerCredit[msg.sender];
    payable(msg.sender).transfer(uint256(ownerCredit[msg.sender])*(1 ether ));
  }

  receive () external payable {}

  function buyCoffee() external{
    require (ownerCredit[msg.sender] > -11);
    require (stock > 0);
    ownerCredit[msg.sender] -= int(price);
    caisse += int(price);
    stock --;

  }

  function addCoffeeProvider(address _provider) public onlyOwner{
      providers[_provider]=1;
  }

  function fixCoffeePrice(uint _price) public onlyOwner{
    price = _price;
  }

  function changeOwner(address _newOwner) public onlyOwner{
    transferOwnership(_newOwner);
  }

  function addCoffee(int _stock, int _proof) public onlyProviders{
    require (_proof == _stock*int(price));
    stock+=_stock;
    payable(msg.sender).transfer(uint(_proof)*1 ether);

  }
}