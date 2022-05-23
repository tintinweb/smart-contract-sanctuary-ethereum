// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <=0.9.0;

contract Multisend {
  function sendBatch(address[] memory _addresses) public payable {
    uint len = _addresses.length;
    uint value = msg.value/len;
    for(uint i = 0; i < len;) {
      payable(_addresses[i]).transfer(value);
      unchecked { ++i; }
    }
  }
}