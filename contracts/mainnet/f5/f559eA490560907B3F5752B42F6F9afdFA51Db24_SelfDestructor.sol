pragma solidity 0.8.10;

contract SelfDestructor {
  function kill() external {
      selfdestruct(payable(msg.sender)); // send the funds to msg.sender just to test
  }
}