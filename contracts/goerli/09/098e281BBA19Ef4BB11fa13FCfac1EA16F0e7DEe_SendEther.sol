pragma solidity ^0.8.0;

contract SendEther {
  function sendEther(address payable recipient, uint256 amount) public {
    recipient.transfer(amount);
  }
}