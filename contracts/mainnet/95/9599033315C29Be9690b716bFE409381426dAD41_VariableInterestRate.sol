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

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IRateCalculatorV2.sol";

/// @title A formula for calculating interest rates as a function of utilization and time
/// @author Drake Evans github.com/drakeevans
/// @notice A Contract for calculating interest rates as a function of utilization and time
contract VariableInterestRate is IRateCalculatorV2 {
    using Strings for uint256;

    // Name Suffix
    string public suffix;

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
    /// @notice The minimum interest rate (per second) when utilization is 100%
    uint256 public immutable MIN_FULL_UTIL_RATE; // 18 decimals
    /// @notice The maximum interest rate (per second) when utilization is 100%
    uint256 public immutable MAX_FULL_UTIL_RATE; // 18 decimals
    /// @notice The interest rate (per second) when utilization is 0%
    uint256 public immutable ZERO_UTIL_RATE; // 18 decimals
    /// @notice The interest rate half life in seconds, determines rate of adjustments to rate curve
    uint256 public immutable RATE_HALF_LIFE; // 1 decimals
    /// @notice The percent of the delta between max and min
    uint256 public immutable VERTEX_RATE_PERCENT; // 18 decimals
    /// @notice The precision of interest rate calculations
    uint256 public constant RATE_PREC = 1e18; // 18 decimals

    /// @notice The ```constructor``` function
    /// @param _vertexUtilization The utilization at which the slope increases
    /// @param _vertexRatePercentOfDelta The percent of the delta between max and min, defines vertex rate
    /// @param _minUtil The minimimum utilization wherein no adjustment to full utilization and vertex rates occurs
    /// @param _maxUtil The maximum utilization wherein no adjustment to full utilization and vertex rates occurs
    /// @param _zeroUtilizationRate The interest rate (per second) when utilization is 0%
    /// @param _minFullUtilizationRate The minimum interest rate at 100% utilization
    /// @param _maxFullUtilizationRate The maximum interest rate at 100% utilization
    /// @param _rateHalfLife The half life parameter for interest rate adjustments
    constructor(
        string memory _suffix,
        uint256 _vertexUtilization,
        uint256 _vertexRatePercentOfDelta,
        uint256 _minUtil,
        uint256 _maxUtil,
        uint256 _zeroUtilizationRate,
        uint256 _minFullUtilizationRate,
        uint256 _maxFullUtilizationRate,
        uint256 _rateHalfLife
    ) {
        suffix = _suffix;
        MIN_TARGET_UTIL = _minUtil;
        MAX_TARGET_UTIL = _maxUtil;
        VERTEX_UTILIZATION = _vertexUtilization;
        ZERO_UTIL_RATE = _zeroUtilizationRate;
        MIN_FULL_UTIL_RATE = _minFullUtilizationRate;
        MAX_FULL_UTIL_RATE = _maxFullUtilizationRate;
        RATE_HALF_LIFE = _rateHalfLife;
        VERTEX_RATE_PERCENT = _vertexRatePercentOfDelta;
    }

    /// @notice The ```name``` function returns the name of the rate contract
    /// @return memory name of contract
    function name() external view returns (string memory) {
        return string(abi.encodePacked("Variable Rate V2 ", suffix));
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
            uint256 _decayGrowth = (RATE_HALF_LIFE * 1e36) + (_deltaUtilization * _deltaUtilization * _deltaTime);
            // 18 decimals
            _newFullUtilizationInterest = uint64((_fullUtilizationInterest * (RATE_HALF_LIFE * 1e36)) / _decayGrowth);
        } else if (_utilization > MAX_TARGET_UTIL) {
            // 18 decimals
            uint256 _deltaUtilization = ((_utilization - MAX_TARGET_UTIL) * 1e18) / (UTIL_PREC - MAX_TARGET_UTIL);
            // 36 decimals
            uint256 _decayGrowth = (RATE_HALF_LIFE * 1e36) + (_deltaUtilization * _deltaUtilization * _deltaTime);
            // 18 decimals
            _newFullUtilizationInterest = uint64((_fullUtilizationInterest * _decayGrowth) / (RATE_HALF_LIFE * 1e36));
        } else {
            _newFullUtilizationInterest = _fullUtilizationInterest;
        }
        if (_newFullUtilizationInterest > MAX_FULL_UTIL_RATE) {
            _newFullUtilizationInterest = uint64(MAX_FULL_UTIL_RATE);
        } else if (_newFullUtilizationInterest < MIN_FULL_UTIL_RATE) {
            _newFullUtilizationInterest = uint64(MIN_FULL_UTIL_RATE);
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
        uint256 _vertexInterest = (((_newFullUtilizationInterest - ZERO_UTIL_RATE) * VERTEX_RATE_PERCENT) / RATE_PREC) +
            ZERO_UTIL_RATE;
        if (_utilization < VERTEX_UTILIZATION) {
            // For readability, the following formula is equivalent to:
            // uint256 _slope = ((_vertexInterest - ZERO_UTIL_RATE) * UTIL_PREC) / VERTEX_UTILIZATION;
            // _newRatePerSec = uint64(ZERO_UTIL_RATE + ((_utilization * _slope) / UTIL_PREC));

            // 18 decimals
            _newRatePerSec = uint64(
                ZERO_UTIL_RATE + (_utilization * (_vertexInterest - ZERO_UTIL_RATE)) / VERTEX_UTILIZATION
            );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}