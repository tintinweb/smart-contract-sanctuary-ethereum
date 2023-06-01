// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {

  bool public completed;
  address public immutable owner;

  constructor(){
    owner=msg.sender;
  }

  function complete() public payable {
    completed = true;
  }

  receive()external payable{}

  function withdraw() external{
    require(msg.sender==owner,'only owner can withdraw');
    (bool sent,)=payable(msg.sender).call{value:address(this).balance}("");
    require(sent,'something went wrong');
  }

}