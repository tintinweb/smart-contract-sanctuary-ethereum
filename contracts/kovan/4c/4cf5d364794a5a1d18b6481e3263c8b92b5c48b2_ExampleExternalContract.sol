/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}