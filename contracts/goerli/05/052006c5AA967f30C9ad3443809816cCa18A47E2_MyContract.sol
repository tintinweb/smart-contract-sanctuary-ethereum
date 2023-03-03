//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyContract {
  uint public data;
  event setValue(uint value);

  function setData(uint _data) external {
    data = _data;
    emit setValue(_data);
  }
}