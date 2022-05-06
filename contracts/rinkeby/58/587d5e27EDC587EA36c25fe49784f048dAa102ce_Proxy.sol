// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract DeployedTelephone {
  function changeOwner(address _owner) public { }
}

contract Proxy {
  DeployedTelephone telephoneContract;

  constructor(address _telephoneAddress) public {
    telephoneContract = DeployedTelephone(_telephoneAddress);
  }

  function changeOwner(address _owner) public {
    telephoneContract.changeOwner(_owner);
  }
}