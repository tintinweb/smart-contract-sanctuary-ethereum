pragma solidity 0.7.5;

import  "./Ownable.sol";
import "./Selfdestruct.sol";

contract Bank is Selfdestruct {

mapping (address => uint) balance;


event depositDone(uint amount, address to);
event _transferredinfo(uint amount, address from, address to);


function deposit () public payable returns (uint){
  balance[msg.sender] += msg.value;
  emit depositDone (msg.value, msg.sender);
  return balance[msg.sender];
  
}

function getBalance (address _address) public view returns(uint){
    return balance[_address];
}

function transfer (address recipient, uint amount) public {

    _transfer(msg.sender, recipient, amount);
    emit _transferredinfo(amount, recipient, msg.sender);
}

function withdraw (uint amount) public returns (uint){
    require (amount<=balance[msg.sender] , "you try to withdraw more than your deposit");
        msg.sender.transfer(amount);
        balance[msg.sender]-=amount;
        return balance[msg.sender];
}

function _transfer (address from, address to, uint amount) private {
    balance[from] -= amount;
    balance[to] += amount;

 close () ;
}

}