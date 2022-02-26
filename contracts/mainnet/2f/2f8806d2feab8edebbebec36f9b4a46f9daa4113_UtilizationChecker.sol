//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "Ownable.sol";

interface IBentoBox {
  struct StrategyData {
    uint64 strategyStartDate;
    uint64 targetPercentage;
    uint128 balance;
  }

  struct Rebase {
    uint128 elastic;
    uint128 base;
  }

  function totals(address token) external view returns (Rebase memory);
  function strategyData(address token) external view returns (StrategyData memory);
  function harvest(address token, bool rebalance, uint256 maxChange) external;
}

contract UtilizationChecker is Ownable {
  IBentoBox constant BentoBox = IBentoBox(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

  uint256 constant UTILIZATION_PRECISION = 1e6;

  struct Strategy {
    address token;
    uint256 maxUtilization;
    uint256 minUtilization;
    bool enabled;
  }

  Strategy[] public strategies;

  function addStrategies(address[] calldata tokens, uint256[] calldata maxUtilizations, uint256[] calldata minUtilizations) external onlyOwner {
    for(uint256 i = 0; i < tokens.length; i++) {
      strategies.push(Strategy(tokens[i], maxUtilizations[i] * UTILIZATION_PRECISION, minUtilizations[i] * UTILIZATION_PRECISION, true));
    }
  }

  function setStrategies(uint256[] calldata indexes, uint256[] calldata maxUtilizations, uint256[] calldata minUtilizations, bool[] calldata enableds) external onlyOwner {
    for(uint256 i = 0; i < indexes.length; i++) {
      strategies[indexes[i]] = Strategy(strategies[indexes[i]].token, maxUtilizations[i] * UTILIZATION_PRECISION, minUtilizations[i] * UTILIZATION_PRECISION, enableds[i]);
    }
  }

  function checker() external view returns (bool canExec, bytes memory execPayload) {
    for(uint256 i = 0; i < strategies.length; i++) {
      Strategy memory strategy = strategies[i];

      if(strategy.enabled == false) {
        continue;
      }

      IBentoBox.Rebase memory totals = BentoBox.totals(strategy.token);
      IBentoBox.StrategyData memory strategyData = BentoBox.strategyData(strategies[i].token);

      uint256 currentPercentage = (strategyData.balance * UTILIZATION_PRECISION / totals.elastic) * 100;

      if(currentPercentage >= strategy.maxUtilization || currentPercentage <= strategy.minUtilization) {
        canExec = true;
        execPayload = abi.encodeWithSelector(
            IBentoBox.harvest.selector,
            strategy.token,
            true,
            0
        );

        break;
      }
    }
  }
}