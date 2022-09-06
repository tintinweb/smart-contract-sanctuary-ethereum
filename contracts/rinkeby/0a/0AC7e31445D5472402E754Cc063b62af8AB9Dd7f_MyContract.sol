// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;



contract MyContract {
  event State(uint stateStatus, string name);
  event Amount(uint amount);
  event Timed(uint time);

  mapping(address=> uint) public balances;

  function deposit() external payable {
        emit State(msg.value%2, msg.value %2 ==0 ? "Buy":"Sell");
        emit Amount(balances[msg.sender]);
        emit Timed(block.timestamp);
  }
}