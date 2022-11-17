// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== VariableInterestRate ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import "./interfaces/IRateCalculatorV2.sol";

/// @title A formula for calculating interest rates as a function of utilization and time
/// @author Drake Evans github.com/drakeevans
/// @notice A Contract for calculating interest rates as a function of utilization and time
contract VariableInterestRate is IRateCalculatorV2 {
    // Utilization Settings
    /// @notice The minimimum utilization wherein no adjustment to full utilization and vertex rates occurs
    uint256 public immutable MIN_TARGET_UTIL;
    /// @notice The maximum utilization wherein no adjustment to full utilization and vertex rates occurs
    uint256 public immutable MAX_TARGET_UTIL;
    /// @notice The utilization at which the slope increases
    uint256 public immutable VERTEX_UTILIZATION;
    /// @notice precision of utilization calculations
    uint256 public constant UTIL_PREC = 1e5; // 5 decimals

    // Interest Rate Settings (all rates are per second), 365.24 days per year
    /// @notice The minimum interest rate (per second)
    uint64 public immutable MIN_INT; // 18 decimals
    /// @notice The maximum interest rate (per second)
    uint64 public immutable MAX_INT; // 18 decimals
    /// @notice The interest rate half life in seconds, determines rate of adjustments to rate curve
    uint256 public immutable INT_HALF_LIFE; // 1 decimals
    /// @notice The percent of the delta between max and min
    uint256 public immutable VERTEX_INTEREST_PERCENT; // 18 decimals
    /// @notice The precision of interest rate calculations
    uint256 public constant INT_PREC = 1e18; // 18 decimals

    /// @notice The ```constructor``` function
    /// @param _vertexUtilization The utilization at which the slope increases
    /// @param _vertexInterestPercentOfMax The percent of the delta between max and min, defines vertex rate
    /// @param _minUtil The minimimum utilization wherein no adjustment to full utilization and vertex rates occurs
    /// @param _maxUtil The maximum utilization wherein no adjustment to full utilization and vertex rates occurs
    /// @param _minInterest The minimum interest rate
    /// @param _maxInterest The maximum interest rate
    /// @param _interestHalfLife The half life parameter for interest rate adjustments
    constructor(
        uint256 _vertexUtilization,
        uint256 _vertexInterestPercentOfMax,
        uint256 _minUtil,
        uint256 _maxUtil,
        uint64 _minInterest,
        uint64 _maxInterest,
        uint256 _interestHalfLife
    ) {
        MIN_TARGET_UTIL = _minUtil;
        MAX_TARGET_UTIL = _maxUtil;
        VERTEX_UTILIZATION = _vertexUtilization;

        MIN_INT = _minInterest;
        MAX_INT = _maxInterest;
        INT_HALF_LIFE = _interestHalfLife;
        VERTEX_INTEREST_PERCENT = _vertexInterestPercentOfMax;
    }

    /// @notice The ```name``` function returns the name of the rate contract
    /// @return memory name of contract
    function name() external pure returns (string memory) {
        return "Variable Time-Weighted Interest Rate V2";
    }

    /// @notice The ```version``` function returns the semantic version of the rate contract
    /// @dev Follows semantic versioning
    /// @return _major Major version
    /// @return _minor Minor version
    /// @return _patch Patch version
    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch) {
        _major = 2;
        _minor = 0;
        _patch = 0;
    }

    /// @notice The ```getFullUtilizationInterest``` function calculate the new maximum interest rate, i.e. rate when utilization is 100%
    /// @dev Given in interest per second
    /// @param _deltaTime The elapsed time since last update given in seconds
    /// @param _utilization The utilization %, given with 5 decimals of precision
    /// @param _fullUtilizationInterest The interest value when utilization is 100%, given with 18 decimals of precision
    /// @return _newFullUtilizationInterest The new maximum interest rate
    function getFullUtilizationInterest(uint256 _deltaTime, uint256 _utilization, uint64 _fullUtilizationInterest)
        internal
        view
        returns (uint64 _newFullUtilizationInterest)
    {
        if (_utilization < MIN_TARGET_UTIL) {
            // 18 decimals
            uint256 _deltaUtilization = ((MIN_TARGET_UTIL - _utilization) * 1e18) / MIN_TARGET_UTIL;
            // 36 decimals
            uint256 _decayGrowth = (INT_HALF_LIFE * 1e36) + (_deltaUtilization * _deltaUtilization * _deltaTime);
            // 18 decimals
            _newFullUtilizationInterest = uint64((_fullUtilizationInterest * (INT_HALF_LIFE * 1e36)) / _decayGrowth);
        } else if (_utilization > MAX_TARGET_UTIL) {
            // 18 decimals
            uint256 _deltaUtilization = ((_utilization - MAX_TARGET_UTIL) * 1e18) / (UTIL_PREC - MAX_TARGET_UTIL);
            // 36 decimals
            uint256 _decayGrowth = (INT_HALF_LIFE * 1e36) + (_deltaUtilization * _deltaUtilization * _deltaTime);
            // 18 decimals
            _newFullUtilizationInterest = uint64((_fullUtilizationInterest * _decayGrowth) / (INT_HALF_LIFE * 1e36));
        } else {
            _newFullUtilizationInterest = _fullUtilizationInterest;
        }
        if (_newFullUtilizationInterest > MAX_INT) {
            _newFullUtilizationInterest = uint64(MAX_INT);
        } else if (_newFullUtilizationInterest < MIN_INT) {
            _newFullUtilizationInterest = uint64(MIN_INT);
        }
    }

    /// @notice The ```getNewRate``` function calculates interest rates using two linear functions f(utilization)
    /// @param _deltaTime The elapsed time since last update, given in seconds
    /// @param _utilization The utilization %, given with 5 decimals of precision
    /// @param _oldFullUtilizationInterest The interest value when utilization is 100%, given with 18 decimals of precision
    /// @return _newRatePerSec The new interest rate, 18 decimals of precision
    /// @return _newFullUtilizationInterest The new max interest rate, 18 decimals of precision
    function getNewRate(uint256 _deltaTime, uint256 _utilization, uint64 _oldFullUtilizationInterest)
        external
        view
        returns (uint64 _newRatePerSec, uint64 _newFullUtilizationInterest)
    {
        _newFullUtilizationInterest = getFullUtilizationInterest(_deltaTime, _utilization, _oldFullUtilizationInterest);

        // _vertexInterest is calculated as the percentage of the detla between min and max interest
        uint256 _vertexInterest = (((_newFullUtilizationInterest - MIN_INT) * VERTEX_INTEREST_PERCENT) / INT_PREC) +
            MIN_INT;
        if (_utilization < VERTEX_UTILIZATION) {
            // For readability, the following formula is equivalent to:
            // uint256 _slope = ((_vertexInterest - MIN_INT) * UTIL_PREC) / VERTEX_UTILIZATION;
            // _newRatePerSec = uint64(MIN_INT + ((_utilization * _slope) / UTIL_PREC));

            // 18 decimals
            _newRatePerSec = uint64(MIN_INT + (_utilization * (_vertexInterest - MIN_INT)) / VERTEX_UTILIZATION);
        } else {
            // For readability, the following formula is equivalent to:
            // uint256 _slope = (((_newFullUtilizationInterest - _vertexInterest) * UTIL_PREC) / (UTIL_PREC - VERTEX_UTILIZATION));
            // _newRatePerSec = uint64(_vertexInterest + (((_utilization - VERTEX_UTILIZATION) * _slope) / UTIL_PREC));

            // 18 decimals
            _newRatePerSec = uint64(
                _vertexInterest +
                    ((_utilization - VERTEX_UTILIZATION) * (_newFullUtilizationInterest - _vertexInterest)) /
                    (UTIL_PREC - VERTEX_UTILIZATION)
            );
        }
        if (_newRatePerSec < MIN_INT) {
            _newRatePerSec = uint64(MIN_INT);
        } else if (_newRatePerSec > MAX_INT) {
            _newRatePerSec = uint64(MAX_INT);
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

interface IRateCalculatorV2 {
    function name() external view returns (string memory);

    function version() external view returns (uint256, uint256, uint256);

    function getNewRate(uint256 _deltaTime, uint256 _utilization, uint64 _maxInterest)
        external
        view
        returns (uint64 _newRatePerSec, uint64 _newMaxInterest);
}