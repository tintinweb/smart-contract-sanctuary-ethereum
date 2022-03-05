/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.23;

contract Forward {

  address public destinationAddress = 0x61d06633F44ca7FF463Db15FD56D58B58937A1f5;
  event LogForwarded(address indexed sender, uint amount);
  event LogFlushed(address indexed sender, uint amount);

  constructor() public {
    destinationAddress = 0x61d06633F44ca7FF463Db15FD56D58B58937A1f5;
  }

  function() payable public {
    emit LogForwarded(0x61d06633F44ca7FF463Db15FD56D58B58937A1f5, msg.value);
    destinationAddress.transfer(msg.value);
  }


}