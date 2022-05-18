/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error NotSevenBut(uint256);
contract CreditedCounterWithResolverJob {
  event Increment(address pokedBy, uint256 iterations);

  uint256 public constant INTERVAL = 30;
  uint256 public constant INCREMENT_BY = 7;

  uint256 public current;
  uint256 public lastChangeAt;
  mapping(address => bool) public canAccess;

  modifier onlyAgent() {
    require(canAccess[msg.sender] == true);
    _;
  }

  constructor(address[] memory agents) {
    current = 0;
    for (uint256 i = 0; i < agents.length; i++) {
      canAccess[agents[i]] = true;
    }
  }

  function myResolver() external view returns (bool ok, bytes memory cd) {
    return (
      block.timestamp >= (lastChangeAt + INTERVAL),
      abi.encodeWithSelector(CreditedCounterWithResolverJob.increment.selector, INCREMENT_BY)
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