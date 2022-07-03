// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "lib.sol";

contract MyContract {
  uint val;
  address owner;

  constructor(uint _val) {
    val = _val;
    owner = msg.sender;
  }

  function f() public pure returns (uint) {
    return L.f();
  }

  function _startTokenId() public pure returns (uint256) {
    return 1;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Must from real wallet address");
    _;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Must from owner");
    _;
  }

  function getVal() public view returns (uint) {
    return val;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library L {
  function f() internal pure returns (uint) {
    return 7;
  }
}