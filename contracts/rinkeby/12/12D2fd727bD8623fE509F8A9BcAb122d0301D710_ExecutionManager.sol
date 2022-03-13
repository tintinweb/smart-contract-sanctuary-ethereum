// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {EnumerableSet} from "./EnumerableSet.sol";

import {IExecutionManager} from "./IExecutionManager.sol";

/**
 * @title ExecutionManager
 * @notice It allows adding/removing execution strategies for trading on the LooksRare exchange.
 */
contract ExecutionManager is IExecutionManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedStrategies;

    event StrategyRemoved(address indexed strategy);
    event StrategyWhitelisted(address indexed strategy);

    /**
     * @notice Add an execution strategy in the system
     * @param strategy address of the strategy to add
     */
    function addStrategy(address strategy) external override onlyOwner {
        require(!_whitelistedStrategies.contains(strategy), "Strategy: Already whitelisted");
        _whitelistedStrategies.add(strategy);

        emit StrategyWhitelisted(strategy);
    }

    /**
     * @notice Remove an execution strategy from the system
     * @param strategy address of the strategy to remove
     */
    function removeStrategy(address strategy) external override onlyOwner {
        require(_whitelistedStrategies.contains(strategy), "Strategy: Not whitelisted");
        _whitelistedStrategies.remove(strategy);

        emit StrategyRemoved(strategy);
    }

    /**
     * @notice Returns if an execution strategy is in the system
     * @param strategy address of the strategy
     */
    function isStrategyWhitelisted(address strategy) external view override returns (bool) {
        return _whitelistedStrategies.contains(strategy);
    }

    /**
     * @notice View number of whitelisted strategies
     */
    function viewCountWhitelistedStrategies() external view override returns (uint256) {
        return _whitelistedStrategies.length();
    }

    /**
     * @notice See whitelisted strategies in the system
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewWhitelistedStrategies(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedStrategies.length() - cursor) {
            length = _whitelistedStrategies.length() - cursor;
        }

        address[] memory whitelistedStrategies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedStrategies[i] = _whitelistedStrategies.at(cursor + i);
        }

        return (whitelistedStrategies, cursor + length);
    }
}