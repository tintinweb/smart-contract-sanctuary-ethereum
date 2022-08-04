/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Forwarder {

  address public destinationAddress;
  event LogForwarded(address indexed sender, uint amount);
  event LogFlushed(address indexed sender, uint amount);

  constructor() {
    destinationAddress = msg.sender;
  }

  receive() external payable {
    emit LogForwarded(msg.sender, msg.value);
    payable(destinationAddress).transfer(msg.value);
  }

  fallback() external payable {
    emit LogForwarded(msg.sender, msg.value);
    payable(destinationAddress).transfer(msg.value);
  }

  function flush() public {
    emit LogFlushed(msg.sender, address(this).balance);
    payable(destinationAddress).transfer(address(this).balance);
  }

}