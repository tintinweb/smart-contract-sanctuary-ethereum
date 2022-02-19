/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}