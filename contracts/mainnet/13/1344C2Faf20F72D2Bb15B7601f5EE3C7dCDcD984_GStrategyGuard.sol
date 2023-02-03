// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "IStrategy.sol";
import "IGStrategyGuard.sol";

library GuardErrors {
    error NotOwner(); // 0x30cd7471
    error NotKeeper(); // 0xf512b278
    error StrategyNotInQueue();
}

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/gro-strategies-brownie

/// @title Strategy guard
/// @notice Contract that interacts with strategies, determining when harvest and stop loss should
///     be triggered. These actions dont need to be individually strategies specified as the time
///     sensitivity of the action isnt critical to the point where it needs to be executed within
///     1 block of the action has been green lit. As long as it gets triggered within a set period of time,
///     this should not block further execution of other strategies, simplifying the keeper setup
///     that will run these jobs.
contract GStrategyGuard is IGStrategyGuard {
    event LogOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event LogKeeperSet(address newKeeper);
    event LogKeeperRemoved(address keeper);
    event LogStrategyAdded(address indexed strategy, uint256 timeLimit);
    event LogStrategyRemoved(address indexed strategy);
    event LogStrategyStatusUpdated(address indexed strategy, bool status);
    event LogStrategyStopLossPrimer(
        address indexed strategy,
        uint128 primerTimeStamp
    );
    event LogStrategyQueueReset(address[] strategies);
    event LogStopLossEscalated(address strategy);
    event LogStopLossDescalated(address strategy, bool active);
    event LogStopLossExecuted(address strategy, bool success);
    event LogStrategyHarvestFailure(
        address strategy,
        string reason,
        bytes lowLevelData
    );

    address public owner;
    mapping(address => bool) public keepers;

    struct strategyData {
        bool active; // Is the strategy active
        uint64 timeLimit;
        uint64 primerTimestamp; // The time at which the health threshold was broken
    }

    address[] public strategies;

    // maps a strategy to its stop loss data
    mapping(address => strategyData) public strategyCheck;

    constructor() {
        owner = msg.sender;
    }

    /// @notice set a new owner for the contract
    /// @param _newOwner owner to swap to
    function setOwner(address _newOwner) external {
        if (msg.sender != owner) revert GuardErrors.NotOwner();
        address previousOwner = msg.sender;
        owner = _newOwner;
        emit LogOwnershipTransferred(previousOwner, _newOwner);
    }

    /// @notice set a new keeper for the contract
    /// @param _newKeeper address of new keeper
    function setKeeper(address _newKeeper) external {
        if (msg.sender != owner) revert GuardErrors.NotOwner();
        keepers[_newKeeper] = true;
        emit LogKeeperSet(_newKeeper);
    }

    /// @notice remove a keeper from the contract
    /// @param _keeper address of keeper to remove
    function revokKeeper(address _keeper) external {
        if (msg.sender != owner) revert GuardErrors.NotOwner();
        keepers[_keeper] = false;
        emit LogKeeperRemoved(_keeper);
    }

    /// @notice forcefully sets the order of the strategies listened to
    /// @param _strategies array of strategies - these strategies must have been added previously
    /// @dev used to clear out the queue from zero addresses, be careful when using this
    function setStrategyQueue(address[] calldata _strategies) external {
        if (msg.sender != owner) revert GuardErrors.NotOwner();
        address[] memory _oldQueue = strategies;
        delete strategies;
        for (uint256 i; i < _strategies.length; ++i) {
            for (uint256 j; j < _oldQueue.length; ++j) {
                if (_strategies[i] == _oldQueue[j]) {
                    strategies.push(_strategies[i]);
                    break;
                }
                revert GuardErrors.StrategyNotInQueue();
            }
        }
        emit LogStrategyQueueReset(_strategies);
    }

    /// @notice Add a strategy to the stop loss logic - Needed in order to be
    ///     be able to determine health of strategies underlying investments (meta pools)
    /// @param _strategy the target strategy
    /// @param _timeLimit amount of time that needs to pass before triggering stop loss
    function addStrategy(address _strategy, uint64 _timeLimit) external {
        if (msg.sender != owner) revert GuardErrors.NotOwner();
        _addStrategy(_strategy);
        strategyCheck[_strategy].timeLimit = _timeLimit;
        strategyCheck[_strategy].active = true;

        emit LogStrategyAdded(_strategy, _timeLimit);
    }

    /// @notice Check if strategy already has been added, if not
    ///     add it to the list of strategies
    function _addStrategy(address _strategy) internal {
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            if (strategies[i] == _strategy) {
                return;
            }
        }
        strategies.push(_strategy);
    }

    /// @notice Remove strategy from stop loss logic
    /// @param _strategy address of strategy
    function removeStrategy(address _strategy) external {
        if (msg.sender != owner) revert GuardErrors.NotOwner();
        delete strategyCheck[_strategy];
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            if (strategies[i] == _strategy) {
                strategies[i] = address(0);
            }
        }

        emit LogStrategyRemoved(_strategy);
    }

    /// @notice Activate/Deactivate strategy
    /// @param _strategy the target strategy
    /// @param _status set status of strategy
    function updateStrategyStatus(address _strategy, bool _status) external {
        if (msg.sender != owner) revert GuardErrors.NotOwner();
        if (_strategy == address(0)) return;
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = strategies[i];
            if (strategy == _strategy) {
                strategyCheck[strategy].active = _status;
                emit LogStrategyStatusUpdated(_strategy, _status);
                return;
            }
        }
    }

    /// @notice Check if stop loss primer needs to be triggered for a strategy
    function canUpdateStopLoss() external view returns (bool result) {
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = strategies[i];
            if (strategy == address(0)) continue;
            if (IStrategy(strategy).canStopLoss()) {
                if (
                    strategyCheck[strategy].primerTimestamp == 0 &&
                    strategyCheck[strategy].active
                ) {
                    result = true;
                }
            }
        }
    }

    /// @notice Check if stop loss primer needs to be stopped
    function canEndStopLoss() external view returns (bool result) {
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = strategies[i];
            if (strategy == address(0)) continue;
            if (!IStrategy(strategy).canStopLoss()) {
                if (
                    strategyCheck[strategy].primerTimestamp != 0 &&
                    strategyCheck[strategy].active
                ) {
                    result = true;
                }
            }
        }
    }

    /// @notice Check if stop loss needs to be executed
    function canExecuteStopLossPrimer() external view returns (bool result) {
        uint256 strategiesLength = strategies.length;
        address strategy;
        uint64 primerTimestamp;
        for (uint256 i; i < strategiesLength; i++) {
            strategy = strategies[i];
            primerTimestamp = strategyCheck[strategy].primerTimestamp;
            if (primerTimestamp == 0) continue;
            if (IStrategy(strategy).canStopLoss()) {
                if (
                    block.timestamp - primerTimestamp >=
                    strategyCheck[strategy].timeLimit &&
                    strategyCheck[strategy].active
                ) {
                    result = true;
                }
            }
        }
    }

    /// @notice Update the stop loss primer by setting a stop loss start time for a strategy
    function setStopLossPrimer() external {
        if (!keepers[msg.sender]) revert GuardErrors.NotKeeper();
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = strategies[i];
            if (strategy == address(0)) continue;
            if (IStrategy(strategy).canStopLoss()) {
                if (
                    strategyCheck[strategy].primerTimestamp == 0 &&
                    strategyCheck[strategy].active
                ) {
                    strategyCheck[strategy].primerTimestamp = uint64(
                        block.timestamp
                    );
                    emit LogStopLossEscalated(strategy);
                    return;
                }
            }
        }
    }

    /// @notice Cancel the stop loss by resetting the stop loss start time for a strategy
    function endStopLossPrimer() external {
        if (!keepers[msg.sender]) revert GuardErrors.NotKeeper();
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = strategies[i];
            if (strategy == address(0)) continue;
            if (!IStrategy(strategy).canStopLoss()) {
                if (
                    strategyCheck[strategy].primerTimestamp != 0 &&
                    strategyCheck[strategy].active
                ) {
                    strategyCheck[strategy].primerTimestamp = 0;
                    emit LogStopLossDescalated(strategy, true);
                    return;
                }
            }
        }
    }

    /// @notice Execute stop loss for a given strategy
    function executeStopLoss() external {
        if (!keepers[msg.sender]) revert GuardErrors.NotKeeper();
        uint256 strategiesLength = strategies.length;
        address strategy;
        uint256 primerTimestamp;
        for (uint256 i; i < strategiesLength; i++) {
            strategy = strategies[i];
            primerTimestamp = strategyCheck[strategy].primerTimestamp;
            if (primerTimestamp == 0 || strategy == address(0)) continue;
            if (IStrategy(strategy).canStopLoss()) {
                if (
                    (block.timestamp - primerTimestamp) >=
                    strategyCheck[strategy].timeLimit &&
                    strategyCheck[strategy].active
                ) {
                    bool success = IStrategy(strategy).stopLoss();
                    emit LogStopLossExecuted(strategy, success);
                    if (success) {
                        strategyCheck[strategy].primerTimestamp = 0;
                        strategyCheck[strategy].active = false;
                        emit LogStopLossDescalated(strategy, false);
                    }
                    return;
                }
            }
        }
    }

    /// @notice Check if any strategy needs to be harvested
    function canHarvest() external view returns (bool result) {
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = strategies[i];
            if (strategy == address(0)) continue;
            if (IStrategy(strategy).canHarvest()) {
                if (strategyCheck[strategy].active) {
                    result = true;
                }
            }
        }
    }

    /// @notice Execute strategy harvest
    function harvest() external {
        if (!keepers[msg.sender]) revert GuardErrors.NotKeeper();
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = strategies[i];
            if (strategy == address(0)) continue;
            if (IStrategy(strategy).canHarvest()) {
                if (strategyCheck[strategy].active) {
                    try IStrategy(strategy).runHarvest() {} catch Error(
                        string memory _reason
                    ) {
                        strategyCheck[strategy].active = false;
                        bytes memory lowLevelData;
                        emit LogStrategyHarvestFailure(
                            strategy,
                            _reason,
                            lowLevelData
                        );
                    } catch (bytes memory _lowLevelData) {
                        strategyCheck[strategy].active = false;
                        string memory reason;
                        emit LogStrategyHarvestFailure(
                            strategy,
                            reason,
                            _lowLevelData
                        );
                    }
                    return;
                }
            }
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IStrategy {
    function asset() external view returns (address);

    function vault() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256, uint256);

    function canHarvest() external view returns (bool);

    function runHarvest() external;

    function canStopLoss() external view returns (bool);

    function stopLoss() external returns (bool);

    function getMetaPool() external view returns (address);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGStrategyGuard {
    /// @notice returns true if keeper should call setStopLossPrimer for strategy
    function canUpdateStopLoss() external view returns (bool);

    /// @notice sets timer if update stop loss returns true
    function setStopLossPrimer() external;

    /// @notice returns true if keeper should call stopStopLossPrimer for strategy
    function canEndStopLoss() external view returns (bool);

    /// @notice resets timer if endStopLoss returns true
    function endStopLossPrimer() external;

    /// @notice returns true if keeper should call executeStopLoss for strategy
    function canExecuteStopLossPrimer() external view returns (bool);

    /// @notice run stop loss function if canExecuteStopLossPrimer is true
    function executeStopLoss() external;

    /// @notice returns true if keeper can execute harvest
    function canHarvest() external view returns (bool);

    /// @notice run strategy harvest
    function harvest() external;
}