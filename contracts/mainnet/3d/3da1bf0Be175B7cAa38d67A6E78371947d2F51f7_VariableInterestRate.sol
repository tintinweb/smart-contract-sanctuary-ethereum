// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

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
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "./interfaces/IRateCalculator.sol";

/// @title A formula for calculating interest rates as a function of utilization and time
/// @author Drake Evans github.com/drakeevans
/// @notice A Contract for calculating interest rates as a function of utilization and time
contract VariableInterestRate is IRateCalculator {
    // Utilization Rate Settings
    uint32 private constant MIN_UTIL = 75000; // 75%
    uint32 private constant MAX_UTIL = 85000; // 85%
    uint32 private constant UTIL_PREC = 1e5; // 5 decimals

    // Interest Rate Settings (all rates are per second), 365.24 days per year
    uint64 private constant MIN_INT = 79123523; // 0.25% annual rate
    uint64 private constant MAX_INT = 146248476607; // 10,000% annual rate
    uint256 private constant INT_HALF_LIFE = 43200e36; // given in seconds, equal to 12 hours, additional 1e36 to make math simpler

    /// @notice The ```name``` function returns the name of the rate contract
    /// @return memory name of contract
    function name() external pure returns (string memory) {
        return "Variable Time-Weighted Interest Rate";
    }

    /// @notice The ```getConstants``` function returns abi encoded constants
    /// @return _calldata abi.encode(uint32 MIN_UTIL, uint32 MAX_UTIL, uint32 UTIL_PREC, uint64 MIN_INT, uint64 MAX_INT, uint256 INT_HALF_LIFE)
    function getConstants() external pure returns (bytes memory _calldata) {
        return abi.encode(MIN_UTIL, MAX_UTIL, UTIL_PREC, MIN_INT, MAX_INT, INT_HALF_LIFE);
    }

    /// @notice The ```requireValidInitData``` function No-op as this contract has no init data
    function requireValidInitData(bytes calldata _initData) external pure {}

    /// @notice The ```getNewRate``` function calculates the new interest rate as a function of time and utilization
    /// @param _data abi.encode(uint64 _currentRatePerSec, uint256 _deltaTime, uint256 _utilization, uint256 _deltaBlocks)
    /// @param _initData empty for this Rate Calculator
    /// @return _newRatePerSec The new interest rate per second, 1e18 precision
    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns (uint64 _newRatePerSec) {
        (uint64 _currentRatePerSec, uint256 _deltaTime, uint256 _utilization, ) = abi.decode(
            _data,
            (uint64, uint256, uint256, uint256)
        );
        if (_utilization < MIN_UTIL) {
            uint256 _deltaUtilization = ((MIN_UTIL - _utilization) * 1e18) / MIN_UTIL;
            uint256 _decayGrowth = INT_HALF_LIFE + (_deltaUtilization * _deltaUtilization * _deltaTime);
            _newRatePerSec = uint64((_currentRatePerSec * INT_HALF_LIFE) / _decayGrowth);
            if (_newRatePerSec < MIN_INT) {
                _newRatePerSec = MIN_INT;
            }
        } else if (_utilization > MAX_UTIL) {
            uint256 _deltaUtilization = ((_utilization - MAX_UTIL) * 1e18) / (UTIL_PREC - MAX_UTIL);
            uint256 _decayGrowth = INT_HALF_LIFE + (_deltaUtilization * _deltaUtilization * _deltaTime);
            _newRatePerSec = uint64((_currentRatePerSec * _decayGrowth) / INT_HALF_LIFE);
            if (_newRatePerSec > MAX_INT) {
                _newRatePerSec = MAX_INT;
            }
        } else {
            _newRatePerSec = _currentRatePerSec;
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.16;

interface IRateCalculator {
    function name() external pure returns (string memory);

    function requireValidInitData(bytes calldata _initData) external pure;

    function getConstants() external pure returns (bytes memory _calldata);

    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns (uint64 _newRatePerSec);
}