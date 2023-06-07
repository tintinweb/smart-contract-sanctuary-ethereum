// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import './WithLibs.sol';

contract WithAll {
  uint256 public value;
  address public immutable owner;
  string public mark = '0x8A784F6768EDdb06E373b18e2ce9097078Aba4aC';

  constructor(uint256 _value, address _owner) {
    value = ConstructorLib.libDo(_value);
    owner = _owner;
  }

  function setMark(string memory _mark) public {
    mark = _mark;
  }

  function setValue(uint256 _value) public {
    value = _value;
  }

  function getNumber(uint256 aNumber) public pure returns (uint256) {
    return NormalLib.libDo(aNumber);
  }

  function getMark() public view returns (string memory) {
    return mark;
  }

  function getValue() public view returns (uint256) {
    return value;
  }

  function getOwner() public view returns (address) {
    return owner;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library NormalLib {
  function libDo(uint256 n) external pure returns (uint256) {
    return n * 2;
  }
}

library ConstructorLib {
  function libDo(uint256 n) external pure returns (uint256) {
    return n * 4;
  }
}

contract OnlyNormalLib {
  string message = '0x78380C3ACF79328A1C288066D8FF6ACFC700DC8F';

  constructor() {}

  function getNumber(uint256 aNumber) public pure returns (uint256) {
    return NormalLib.libDo(aNumber);
  }
}

contract OnlyConstructorLib {
  uint256 public someNumber;
  string message = '0x78380C3ACF79328A1C288066D8FF6ACFC700DC8F';

  constructor(uint256 aNumber) {
    someNumber = ConstructorLib.libDo(aNumber);
  }
}

contract BothLibs {
  uint256 public someNumber;
  string message = '0x78380C3ACF79328A1C288066D8FF6ACFC700DC8F';

  constructor(uint256 aNumber) {
    someNumber = ConstructorLib.libDo(aNumber);
  }

  function getNumber(uint256 aNumber) public pure returns (uint256) {
    return NormalLib.libDo(aNumber);
  }
}