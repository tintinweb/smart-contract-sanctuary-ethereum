/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File contracts/jobs/traits/MultiAgentJob.sol

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


// File contracts/jobs/CounterWithResolverJob.sol

pragma solidity ^0.8.13;

contract CounterWithResolverJob is MultiAgentJob {
  error NotSevenBut(uint256);
  event Increment(address pokedBy, uint256 iterations);

  uint256 public constant INTERVAL = 30;
  uint256 public constant INCREMENT_BY = 7;

  uint256 public current;
  uint256 public lastChangeAt;

  constructor(address[] memory agents_) MultiAgentJob (agents_) {
  }

  function myResolver() external view returns (bool ok, bytes memory cd) {
    return (
      block.timestamp >= (lastChangeAt + INTERVAL),
      abi.encodeWithSelector(CounterWithResolverJob.increment.selector, INCREMENT_BY)
    );
  }

  function increment(uint256 amount) external onlyAgent {
    if (amount != 7) {
      revert NotSevenBut(amount);
    }
    require(block.timestamp >= (lastChangeAt + INTERVAL), "interval");
    current += amount;
    lastChangeAt = block.timestamp;
    emit Increment(msg.sender, current);
  }
}