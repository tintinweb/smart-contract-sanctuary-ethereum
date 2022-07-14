// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Box.sol';

contract BoxV2 is Box {
  function increment() public {
    store(retrieve() + 1);
  }
}

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
  uint256 private _value;

  event ValueChanged(uint256 value);

  function store(uint256 value) public {
    _value = value;
    emit ValueChanged(_value);
  }

  function retrieve() public view returns (uint256) {
    return _value;
  }
}