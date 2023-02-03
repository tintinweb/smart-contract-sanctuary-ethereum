// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "ICurve3Pool.sol";
import "IStrategy.sol";
import "ICurveMeta.sol";
import "IStop.sol";

library StopLossErrors {
    error NotOwner(); // 0x30cd7471
}

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/gro-strategies-brownie

/// @title stop loss logic
/// @notice Determines if stop loss needs to be triggered for underlying strategy.
///     Note that this contract shouldnt be used in isolation, but rather by a
///     keeper system that only references over extended time periods to determine the
///     health of the underlying pool. WARNING - this contract should not be used as a
///     spot oracle.
contract StopLossLogic is IStop {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event LogStrategyUpdated(
        address indexed strategy,
        uint128 equilibriumValue,
        uint128 healthThreshold
    );
    event LogStrategyRemoved(address indexed strategy);

    int128 constant CRV_IDX = 1;
    int128 constant META_IDX = 0;
    uint256 constant DEFAULT_DECIMALS_FACTOR = 1E18;
    uint256 constant PERCENTAGE_DECIMAL_FACTOR = 1E4;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    struct PoolCheck {
        uint128 equilibriumValue; // The mean of assets value in the pool
        uint128 healthThreshold; // How much the pool can deviate from above value
    }

    mapping(address => PoolCheck) public strategyData; // maps a strategy to its values

    /// @notice set a new owner for the contract
    /// @param _newOwner owner to swap to
    function setOwner(address _newOwner) external {
        if (msg.sender != owner) revert StopLossErrors.NotOwner();
        address previousOwner = msg.sender;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @notice Add a strategy to the stop loss logic - Needed in order to be
    ///     be able to determine health of stragies underlying investments (meta pools)
    /// @param _strategy the target strategy
    /// @param _equilibriumValue calculated mean value for the value of the requested asset
    /// @param _healthThreshold how far the current value can deviate from the equilibrium
    function setStrategy(
        address _strategy,
        uint128 _equilibriumValue,
        uint128 _healthThreshold
    ) external {
        if (msg.sender != owner) revert StopLossErrors.NotOwner();
        strategyData[_strategy].equilibriumValue = _equilibriumValue;
        strategyData[_strategy].healthThreshold = _healthThreshold;

        emit LogStrategyUpdated(_strategy, _equilibriumValue, _healthThreshold);
    }

    /// @notice Remove strategy from stop loss logic
    /// @param _strategy address of strategy
    function removeStrategy(address _strategy) external {
        if (msg.sender != owner) revert StopLossErrors.NotOwner();
        delete strategyData[_strategy];

        emit LogStrategyRemoved(_strategy);
    }

    /// @notice Check if pool is healthy
    function stopLossCheck() external view returns (bool) {
        PoolCheck memory strategyData_ = strategyData[msg.sender];
        if (strategyData_.healthThreshold == 0) return false;
        return
            _thresholdCheck(
                strategyData_.equilibriumValue,
                strategyData_.healthThreshold
            );
    }

    function _thresholdCheck(
        uint128 _equilibriumValue,
        uint128 _healthThreshold
    ) internal view returns (bool) {
        ICurveMeta metaPool = ICurveMeta(IStrategy(msg.sender).getMetaPool());
        uint256 dy = metaPool.get_dy(
            META_IDX,
            CRV_IDX,
            DEFAULT_DECIMALS_FACTOR
        );
        uint256 dy_diff = (dy * PERCENTAGE_DECIMAL_FACTOR) / _equilibriumValue;
        int256 trail = abs(int256(dy_diff) - int256(PERCENTAGE_DECIMAL_FACTOR));
        if (uint256(trail) > _healthThreshold) return true;
        else return false;
    }

    /// @notice Get the absolute value of an integer
    /// @param _x integer input
    function abs(int256 _x) private pure returns (int256) {
        return _x >= 0 ? _x : -_x;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// Curve 3pool interface
interface ICurve3Pool {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        uint256[3] calldata _deposit_amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// Curve metapool interface
interface ICurveMeta {
    function get_virtual_price() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 i)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata inAmounts, bool deposit)
        external
        view
        returns (uint256);

    function add_liquidity(
        uint256[2] calldata uamounts,
        uint256 min_mint_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _tokenAmount,
        int128 i,
        uint256 min_uamount
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// Stop loss logic interface
interface IStop {
    function stopLossCheck() external view returns (bool);
}