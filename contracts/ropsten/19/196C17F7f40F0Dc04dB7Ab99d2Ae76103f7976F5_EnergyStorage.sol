/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract EnergyStorage {
  struct Account{
      address account;
      uint256 cost;
      uint256 profit;
      int256 funds;
  }
    Account[] public accounts;
    address public owner ;
    int256 public marketPay;

    mapping(address => uint256) public accountToCost;
    mapping(address => uint256) public accountToProfit;
    mapping(address => uint256) public accountToArrayIndex;
    mapping(address => int256) public addressToAmountFunded;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    event notEnoughFunds(address _address, int256 _funds);


  constructor(){
    owner = msg.sender;
  }

    function updateAccount(address  _address, uint256 _cost,uint256 _profit) public{
    uint256 addresIndex = accountToArrayIndex[_address];
    if(addresIndex>0){
        accounts[addresIndex-1].cost+=_cost;
        accounts[addresIndex-1].profit+=_profit;
    }else{
        accounts.push(Account(_address,_cost,_profit,0));
        accountToArrayIndex[_address]=accounts.length;
    }
    accountToCost[_address]+=_cost;
    accountToProfit[_address]+=_profit;
  }

  function fund() public payable{ // 1 ethereum is 1000 euro
      uint256 addresIndex = accountToArrayIndex[msg.sender];
      addressToAmountFunded[msg.sender] += int(msg.value);
      accounts[addresIndex].funds+= int(msg.value);
  }
  function settle() onlyOwner public{
    for(uint i = 0;i<accounts.length;i++){
      accounts[i].funds-=(int(accounts[i].cost)-int(accounts[i].profit));
      accountToCost[accounts[i].account]=0;
      accountToProfit[accounts[i].account]=0;
      addressToAmountFunded[accounts[i].account]-=(int(accounts[i].cost)-int(accounts[i].profit));
      marketPay+=(int(accounts[i].cost)-int(accounts[i].profit));
      if(accounts[i].funds<0){
        emit notEnoughFunds(accounts[i].account, accounts[i].funds);
      }
    }
  }
  function seeAll() onlyOwner public view returns(Account[] memory) {
    return accounts;
  }
  function withDrawMarket() onlyOwner public{
    address payable addr = payable(msg.sender);
    require(marketPay>0,"Energy surplus: please fund contract");
    require(uint(marketPay)<address(this).balance,"Not enough funds in contract");
    addr.transfer(uint(marketPay));
  }
  function withdraw() public{
    require(addressToAmountFunded[msg.sender]>0);
    require(address(this).balance>uint(addressToAmountFunded[msg.sender]),"Not Enough funds in contract");
    address payable addr = payable(msg.sender);
    addr.transfer(address(this).balance);
  }
}