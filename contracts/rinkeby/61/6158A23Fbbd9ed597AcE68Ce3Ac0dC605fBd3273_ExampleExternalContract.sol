// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

  function withdraw(address payable _recipient, uint256 _ammount) public {
    require(address(this).balance >= _ammount, "Not enough funds to withdraw!");
    _recipient.transfer(_ammount);
  }

  function checkCompleted() external view returns (bool) {
    return completed;
  }

}