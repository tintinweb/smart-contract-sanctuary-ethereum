// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../contracts/jobs/traits/AgentJob.sol";

contract IntervalResolverJobMock is AgentJob {
  event Increment(address pokedBy, uint256 newCurrent);

  uint256 public immutable INTERVAL;

  uint256 public lastChangeAt;
  uint256 public current;

  constructor(address agent_, uint256 interval_) AgentJob (agent_) {
    INTERVAL = interval_;
  }

  function myResolver() external view returns (bool ok, bytes memory cd) {
    if (block.timestamp >= (lastChangeAt + INTERVAL)) {
      return (
        true,
        abi.encodeWithSelector(
          IntervalResolverJobMock.increment.selector,
          address(123),
          true
        )
      );
    } else {
      return (false, new bytes(0));
    }
  }

  function increment(address code, bool ok) external onlyAgent {
    require(block.timestamp >= (lastChangeAt + INTERVAL), "interval");
    require(code == address(123), "invalid address code");
    require(ok, "not ok");

    current += 1;

    lastChangeAt = block.timestamp;
    emit Increment(msg.sender, current);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract AgentJob {
  address public agent;

  modifier onlyAgent() {
    require(msg.sender == agent);
    _;
  }

  constructor(address agent_) {
    agent = agent_;
  }

  fallback() external virtual {
    revert("AgentJob: unexpected fallback");
  }
}