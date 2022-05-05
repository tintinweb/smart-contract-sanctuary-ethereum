pragma solidity ^0.8.0;

contract BabyStep {
  mapping(address => uint256) private counter;
  event Message(string body);

  constructor(){}

  function hello() public returns (uint256) {
    counter[msg.sender]++;
    if (counter[msg.sender] >= 2) {
      emit Message("Hello Again.");
    }
    else {
      emit Message("Hello World.");
    }
    return counter[msg.sender];
  }
}