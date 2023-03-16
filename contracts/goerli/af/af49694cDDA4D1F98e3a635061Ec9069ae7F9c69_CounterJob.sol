// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./traits/MultiAgentJob.sol";

contract CounterJob is MultiAgentJob {
  event Increment(address pokedBy, uint256 newCurrent);

  uint256 public current;

  constructor(address[] memory agents_) MultiAgentJob (agents_) {
  }

  function increment() external onlyAgent {
    current += 1;
    emit Increment(msg.sender, current);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract MultiAgentJob {
  mapping(address => bool) public canAccess;

  modifier onlyAgent() {
    require(canAccess[msg.sender] == true);
    _;
  }

  constructor(address[] memory agents) {
    for (uint256 i = 0; i < agents.length; i++) {
      canAccess[agents[i]] = true;
    }
  }

  fallback() external virtual {
    revert("MultiAgentJob: unexpected fallback");
  }
}