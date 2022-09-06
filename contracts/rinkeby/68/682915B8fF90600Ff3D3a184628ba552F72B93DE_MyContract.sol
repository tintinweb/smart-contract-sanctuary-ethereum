// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;



contract MyContract {
  event State(uint stateStatus, string name);
  event Amount(uint amount);
  event Timed(uint time);

  mapping(address=> uint) public balances;

  function deposit() external payable {
      balances[msg.sender]+=msg.value;
      if(balances[msg.sender] % 2 == 0){
          emit State(0,"Buy");
      }
      else {
          emit State(1,"SELL");
      }
          emit Amount(balances[msg.sender]);
          emit Timed(block.timestamp);
  }
}