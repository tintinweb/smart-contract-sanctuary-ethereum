/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.23;

contract Forward {

  address public destinationAddress;
  event LogForwarded(address indexed sender, uint amount);
  event LogFlushed(address indexed sender, uint amount);

  constructor() public {
    destinationAddress = msg.sender;
  }

  function() payable public {
    emit LogForwarded(msg.sender, msg.value);
    destinationAddress.transfer(msg.value);
  }


}