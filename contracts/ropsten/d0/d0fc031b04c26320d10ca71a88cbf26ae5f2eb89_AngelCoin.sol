/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;

contract AngelCoin {
   address public minter;

   mapping (address => uint) public balances;
   
   event Sent(address from, address to, uint amount);

   constructor() public {
      minter = msg.sender;
      }

   function mint(address receiver, uint amount) public {
      require(msg.sender == minter, "error sender != minter");
      require(amount < 1e60, "error amount");
      balances[receiver] += amount;
   }

   function send(address receiver, uint amount) public {
      require(amount <= balances[msg.sender], "Insufficient balance.");
      balances[msg.sender] -= amount;
      balances[receiver] += amount;
      emit Sent(msg.sender, receiver, amount);
   }
}