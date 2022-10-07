// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../contracts/jobs/traits/AgentJob.sol";
import "./ICounter.sol";

contract OnlySelectorTestJob is ICounter, AgentJob {
  event Increment(address pokedBy, uint256 newCurrent);

  uint256 public current;

  constructor(address agent_) AgentJob (agent_) {
  }

  function myResolver(string calldata pass) external pure returns (bool, bytes memory) {
    require(keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked("myPass")), "invalid pass");

    return (true, abi.encode(OnlySelectorTestJob.increment.selector));
  }

  function increment() external onlyAgent {
    current += 1;
    emit Increment(msg.sender, current);
  }

  function increment2() external pure {
    revert("unexpected increment2");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICounter {
  function current() external view returns (uint256);
  function myResolver(string calldata pass) external view returns (bool, bytes memory);
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
}