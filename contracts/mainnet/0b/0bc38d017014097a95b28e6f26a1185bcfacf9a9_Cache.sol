/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Cache {

  address public destinationAddress;
  event LogReceived(address indexed sender, uint amount);
  event LogFlush(address indexed sender, uint amount);
  event LogRelease(address indexed sender, uint amount);
  event LogFallback(address indexed sender, uint amount);

  constructor() {
    destinationAddress = msg.sender;
  }

  receive() external payable {
    emit LogReceived(msg.sender, msg.value);
  }

  fallback() external payable {
    emit LogFallback(msg.sender, msg.value);
  }

  function release(uint amt) public {
    emit LogRelease(msg.sender, amt);
    payable(destinationAddress).transfer(amt);
  }

  function flush() public {
    emit LogFlush(msg.sender, address(this).balance);
    emit LogRelease(msg.sender, address(this).balance);
    payable(destinationAddress).transfer(address(this).balance);
  }
}