// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {
   address payable owner ;
  constructor (){
     owner = payable(msg.sender);
  }

  bool public completed;

  function complete() public payable {
    completed = true;
  }

  function takeFundsOut() public  {
    require(msg.sender == owner,"only owner can take the funds");
    (bool sent,)=address(owner).call{value: address(this).balance}("");
    require(sent,"Transaction was not sent");
  }

}