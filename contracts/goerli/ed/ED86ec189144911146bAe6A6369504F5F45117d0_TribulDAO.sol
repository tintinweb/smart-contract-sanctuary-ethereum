// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TribulDAO {
  mapping(address => address) public gnosisSafeAddress;

  function setGnosisSafeAddres(address gnosisSafe) external {
    require(gnosisSafeAddress[msg.sender] != address(0), "Address already set");
    gnosisSafeAddress[msg.sender] = gnosisSafe;
  }
}