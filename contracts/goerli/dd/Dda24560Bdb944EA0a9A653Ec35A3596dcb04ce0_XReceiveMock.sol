// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

contract XReceiveMock {
  address dao;
  address public xprovider;
  uint256 public value;

  modifier onlyXProvider() {
    require(msg.sender == xprovider);
    _;
  }

  modifier onlyDao() {
    require(msg.sender == dao, "XReceiveMock: only DAO");
    _;
  }

  constructor(address _dao) {
    dao = _dao;
  }

  function setXProvider(address _xprovider) external onlyDao {
    xprovider = _xprovider;
  }

  function xReceiveAndSetSomeValue(uint256 _value) external onlyXProvider {
    value = _value;
  }
}