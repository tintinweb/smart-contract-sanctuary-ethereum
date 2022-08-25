// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
  uint256 firstVar;
  uint256 secondVar;
  uint256 lastVar;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AppStorage.sol";

contract StakingFacet {
  AppStorage internal s;

  function myFacetFunction() external {
    s.lastVar = s.firstVar + s.secondVar;
  }
}