// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }




  // function withdraw() public{
  //   payable(msg.sender).transfer(address(this).balance);
  // }

  // function getContractBalance() public view returns(uint){
  //   return address(this).balance;
  // }

}