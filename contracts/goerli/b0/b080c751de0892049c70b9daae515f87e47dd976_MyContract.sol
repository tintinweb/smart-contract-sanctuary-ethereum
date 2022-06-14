/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

contract MyContract {
    string value;

  constructor() {
    value = "myValue";
}

function get() public view returns(string memory) {
    return value;
  }

  function set(string memory _value) public {
    value = _value;
    }
}