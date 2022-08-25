// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AppStorage.sol";

contract StakingFacet2 {
  AppStorage internal s;

  function myFacetFunction2() external {
    s.lastVar = s.firstVar + s.secondVar;
  }

  
  function readlastVar() external view returns(uint256) {
    return s.lastVar;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
  uint256 firstVar;
  uint256 secondVar;
  uint256 lastVar;
}