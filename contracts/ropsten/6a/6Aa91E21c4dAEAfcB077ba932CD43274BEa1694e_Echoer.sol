/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Echoer {
  
  mapping(address => bytes) private echoMapping;
  event Echo(address indexed who, bytes data);

  function echo(bytes calldata _data) external {
    echoMapping[msg.sender] = _data;
    emit Echo(msg.sender, _data);
  }
  
  function getEchoData(address addr) public view returns(bytes memory aaa) {
    return echoMapping[addr];
  }
}