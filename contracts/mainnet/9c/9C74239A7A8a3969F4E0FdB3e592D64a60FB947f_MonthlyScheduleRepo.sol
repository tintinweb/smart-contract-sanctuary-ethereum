pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

/// @title IPeriodMapper
/// @notice A mapping of timestamps to "periods"
interface IPeriodMapper {
  /// @notice Returns the period that a timestamp resides in
  function periodOf(uint256 timestamp) external pure returns (uint256 period);

  /// @notice Returns the starting timestamp of a given period
  function startOf(uint256 period) external pure returns (uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ISchedule {
  /**
   * @notice Returns the period that timestamp resides in
   */
  function periodAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the principal period that timestamp resides in
   */
  function principalPeriodAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the interest period that timestamp resides in
   */
  function interestPeriodAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns true if the given timestamp resides in a principal grace period
   */
  function withinPrincipalGracePeriodAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (bool);

  /**
   * Returns the next timestamp where either principal or interest will come due following `timestamp`
   */
  function nextDueTimeAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the previous timestamp where either principal or timestamp came due
   */
  function previousDueTimeAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the previous timestamp where new interest came due
   */
  function previousInterestDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @notice Returns the previous timestamp where new principal came due
   */
  function previousPrincipalDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @notice Returns the total number of principal periods
   */
  function totalPrincipalPeriods() external view returns (uint256);

  /**
   * @notice Returns the total number of interest periods
   */
  function totalInterestPeriods() external view returns (uint256);

  /**
   * @notice Returns the timestamp that the term will end
   */
  function termEndTime(uint256 startTime) external view returns (uint256);

  /**
   * @notice Returns the timestamp that the term began
   */
  function termStartTime(uint256 startTime) external view returns (uint256);
}

pragma solidity >=0.6.12;

// NOTE: this file exists only to remove the extremely long error messages in safe math.

import {SafeMath as OzSafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return OzSafeMath.sub(a, b, "");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    return OzSafeMath.sub(a, b, errorMessage);
  }

  /// @notice Do a - b. If that would result in overflow then return 0
  function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256) {
    return b > a ? 0 : a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return OzSafeMath.div(a, b, "");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    return OzSafeMath.div(a, b, errorMessage);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return OzSafeMath.mod(a, b, "");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    return OzSafeMath.mod(a, b, errorMessage);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// solhint-disable-next-line
import {BokkyPooBahsDateTimeLibrary as DateTimeLib} from "BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";
import {IPeriodMapper} from "../../../interfaces/IPeriodMapper.sol";

/// @title Monthly schedule
/// @author Warbler Labs Engineering
/// @notice A schedule mapping timestamps to periods. Each period begins on the first second
///         of each month
contract MonthlyPeriodMapper is IPeriodMapper {
  // @inheritdoc IPeriodMapper
  function periodOf(uint256 timestamp) external pure override returns (uint256) {
    return DateTimeLib.diffMonths(0, timestamp);
  }

  /// @inheritdoc IPeriodMapper
  function startOf(uint256 period) external pure override returns (uint256) {
    return DateTimeLib.addMonths(0, period);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ISchedule} from "../../../interfaces/ISchedule.sol";
import {MonthlyPeriodMapper} from "./MonthlyPeriodMapper.sol";
import {Schedule} from "./Schedule.sol";

/**
 * @notice Repository for re-usable schedules that function on calendar month periods.
 * In general periods can be any length, but Warbler maintains a repository of schedules
 * with monthly periods because that's the most common type of schedule used on the
 * Goldfinch protocol.
 */
contract MonthlyScheduleRepo {
  MonthlyPeriodMapper public periodMapper;

  mapping(bytes32 => address) private schedules;

  constructor() public {
    periodMapper = new MonthlyPeriodMapper();
  }

  /// @notice Get the schedule with the requested params. Reverts if the
  /// schedule is not in the repo - see _createSchedule_
  /// @return schedule the schedule
  function getSchedule(
    uint256 periodsInTerm,
    uint256 periodsPerPrincipalPeriod,
    uint256 periodsPerInterestPeriod,
    uint256 gracePrincipalPeriods
  ) external view returns (ISchedule) {
    bytes32 scheduleId = getScheduleId(
      periodsInTerm,
      periodsPerPrincipalPeriod,
      periodsPerInterestPeriod,
      gracePrincipalPeriods
    );
    address schedule = schedules[scheduleId];
    require(schedule != address(0), "Schedule doesn't exist");
    return ISchedule(schedule);
  }

  /// @notice Add a schedule with the provided params to the repo
  /// @return schedule the schedule
  function createSchedule(
    uint256 periodsInTerm,
    uint256 periodsPerPrincipalPeriod,
    uint256 periodsPerInterestPeriod,
    uint256 gracePrincipalPeriods
  ) external returns (ISchedule) {
    bytes32 scheduleId = getScheduleId(
      periodsInTerm,
      periodsPerPrincipalPeriod,
      periodsPerInterestPeriod,
      gracePrincipalPeriods
    );

    address schedule = schedules[scheduleId];

    // No need to create it again if it already exists
    if (schedule != address(0)) {
      return ISchedule(schedule);
    }

    Schedule newSchedule = new Schedule(
      periodMapper,
      periodsInTerm,
      periodsPerPrincipalPeriod,
      periodsPerInterestPeriod,
      gracePrincipalPeriods
    );
    schedules[scheduleId] = address(newSchedule);
    return newSchedule;
  }

  function getScheduleId(
    uint256 periodsInTerm,
    uint256 periodsPerPrincipalPeriod,
    uint256 periodsPerInterestPeriod,
    uint256 gracePrincipalPeriods
  ) private pure returns (bytes32) {
    // Right pad with 0 params so we have the option to add new parameters in the future
    // Use encode instead of encodePacked because non-padded concatenation can lead to
    // non-unique ids
    bytes memory concattedParams = abi.encode(
      periodsInTerm,
      periodsPerPrincipalPeriod,
      periodsPerInterestPeriod,
      gracePrincipalPeriods
    );
    return keccak256(concattedParams);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IPeriodMapper} from "../../../interfaces/IPeriodMapper.sol";
import {ISchedule} from "../../../interfaces/ISchedule.sol";
import {SafeMath} from "../../../library/SafeMath.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

/**
 * @title Schedule
 * @author Warbler Labs Engineering
 * @notice A contract meant to be re-used between tranched pools to determine when payments are due
 *         using some period mapper contract that maps timestamps to real world concepts of time (months).
 *         This contract allows a user to specify how often interest payments and principal payments should come
 *         due by allowing the creator to specify the length of of interest periods and principal periods. Additionally
 *         the creator can specify how many of the principal periods are considered "grace periods"
 *
 * Example:
 * Here's a visualization of a schedule with the following parameters
 * periodMapper = monthly periods
 * periodsInTerm = 12 (1 year)
 * periodsPerInterestPeriod = 3 (quarterly)
 * periodsPerPrincipalPeriod = 6 (halfly)
 * gracePrincipalPeriods = 1
 *
 *                       +- Stub Period     +- Principal Grace Period
 *  grace periods        v                  v
 *                     +---+-----------------------+-----------------------+
 *  principal periods  |///|=======================|           0           |
 *                     |///+-----------+-----------+-----------+-----------+ E
 *  interest periods   |///|     0     |     1     |     2     |     4     | N
 *                     +---+---+---+---+---+---+---+---+---+---+---+---+---+ D
 *  periods            |FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|JAN|FEB|
 *                     |   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10| 11|
 *                  ---+---+---+---+---+---+---+---+---+---+---+---+---+---+---
 *  absolute        ...| 25| 26| 27| 28| 29| 30| 31| 32| 33| 34| 35| 36| 37|...
 *  periods            |   |   |   |   |   |   |   |   |   |   |   |   |   |
 *                  ---+---+---+---+---+---+---+---+---+---+---+---+---+---+---
 *                      ^
 *                      +- start time
 * When a borrower draws down, a "stub period" is created. This period is the remainder of the
 * period they drew down in, but at the end of this period no payment of any kind should be due.
 * We treat this stub period as an extension to period 0.
 *
 * At the end of each interest or principal period a payment is expected. For example
 * imagine today is Oct 10th. Your next interest payment will be the beginning of December
 * because the current interest period, period 2, ends in december. Your next principal payment
 * will be due at the end of February because the current principal period, period 0, ends in
 * February. This is also the end of the loan, and so all interest and principal should be due
 * at this time.
 *
 * @dev Because this contract is meant to be re-used between contracts, the "start time" is not stored on this contract
 *      Instead, it's passed in to each function call.
 */
contract Schedule is ISchedule {
  using Math for uint256;
  using SafeMath for uint256;

  /// @notice the payment date schedule
  IPeriodMapper public immutable periodMapper;

  /// @notice the number of periods in the term of the loan
  uint256 public immutable periodsInTerm;

  /// @notice the number of payment periods that need to pass before interest
  ///         comes due
  uint256 public immutable periodsPerInterestPeriod;

  /// @notice the number of payment periods that need to pass before principal
  ///         comes due
  uint256 public immutable periodsPerPrincipalPeriod;

  /// @notice the number of principal periods where no principal will be due
  uint256 public immutable gracePrincipalPeriods;

  //===============================================================================
  // external functions
  //===============================================================================

  /// @param _periodMapper contract that maps timestamps to periods
  /// @param _periodsInTerm the number of periods in the term of the loan
  /// @param _periodsPerPrincipalPeriod the number of payment periods that need to pass before principal
  ///         comes due
  /// @param _periodsPerInterestPeriod the number of payment periods that need to pass before interest
  ///         comes due.
  /// @param _gracePrincipalPeriods principal periods where principal will not be due
  constructor(
    IPeriodMapper _periodMapper,
    uint256 _periodsInTerm,
    uint256 _periodsPerPrincipalPeriod,
    uint256 _periodsPerInterestPeriod,
    uint256 _gracePrincipalPeriods
  ) public {
    require(address(_periodMapper) != address(0), "Z");

    require(_periodsInTerm > 0, "Z");
    require(_periodsPerPrincipalPeriod > 0, "Z");
    require(_periodsPerInterestPeriod > 0, "Z");

    require(_periodsInTerm % _periodsPerPrincipalPeriod == 0, "PPPP");
    require(_periodsInTerm % _periodsPerInterestPeriod == 0, "PPIP");

    uint256 nPrincipalPeriods = _periodsInTerm / _periodsPerPrincipalPeriod;
    require(_gracePrincipalPeriods < nPrincipalPeriods, "GPP");

    periodMapper = _periodMapper;
    periodsInTerm = _periodsInTerm;
    periodsPerPrincipalPeriod = _periodsPerPrincipalPeriod;
    periodsPerInterestPeriod = _periodsPerInterestPeriod;
    gracePrincipalPeriods = _gracePrincipalPeriods;
  }

  /// @inheritdoc ISchedule
  function interestPeriodAt(
    uint256 startTime,
    uint256 timestamp
  ) public view override returns (uint256) {
    return
      Math.min(_periodToInterestPeriod(periodAt(startTime, timestamp)), totalInterestPeriods());
  }

  /// @inheritdoc ISchedule
  function periodAt(uint256 startTime, uint256 timestamp) public view override returns (uint256) {
    uint256 currentAbsPeriod = periodMapper.periodOf(timestamp);
    uint256 startPeriod = _termStartAbsolutePeriod(startTime);

    return Math.min(currentAbsPeriod.saturatingSub(startPeriod), periodsInTerm);
  }

  /// @inheritdoc ISchedule
  function principalPeriodAt(
    uint256 startTime,
    uint256 timestamp
  ) public view override returns (uint256) {
    return
      Math.min(_periodToPrincipalPeriod(periodAt(startTime, timestamp)), totalPrincipalPeriods());
  }

  /// @inheritdoc ISchedule
  function withinPrincipalGracePeriodAt(
    uint256 startTime,
    uint256 timestamp
  ) public view override returns (bool) {
    return
      timestamp < startTime ||
      (timestamp >= startTime &&
        periodAt(startTime, timestamp).div(periodsPerPrincipalPeriod) < gracePrincipalPeriods);
  }

  /// @inheritdoc ISchedule
  function nextDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view override returns (uint256) {
    return
      Math.min(
        _nextPrincipalDueTimeAt(startTime, timestamp),
        _nextInterestDueTimeAt(startTime, timestamp)
      );
  }

  /// @inheritdoc ISchedule
  function previousDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view override returns (uint256) {
    return
      Math.max(
        previousInterestDueTimeAt(startTime, timestamp),
        previousPrincipalDueTimeAt(startTime, timestamp)
      );
  }

  /// @inheritdoc ISchedule
  function totalPrincipalPeriods() public view override returns (uint256) {
    // To make amortization math easy, we want to exclude grace periods from this
    return periodsInTerm.div(periodsPerPrincipalPeriod).sub(gracePrincipalPeriods);
  }

  /// @inheritdoc ISchedule
  function totalInterestPeriods() public view override returns (uint256) {
    return periodsInTerm.div(periodsPerInterestPeriod);
  }

  /// @inheritdoc ISchedule
  function termEndTime(uint256 startTime) external view override returns (uint256) {
    uint256 endPeriod = _termEndAbsolutePeriod(startTime);
    return periodMapper.startOf(endPeriod);
  }

  /// @inheritdoc ISchedule
  function termStartTime(uint256 startTime) external view override returns (uint256) {
    uint256 startPeriod = _termStartAbsolutePeriod(startTime);
    return periodMapper.startOf(startPeriod);
  }

  /// @inheritdoc ISchedule
  function previousInterestDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) public view override returns (uint256) {
    uint interestPeriod = interestPeriodAt(startTime, timestamp);
    return interestPeriod > 0 ? _startOfInterestPeriod(startTime, interestPeriod) : 0;
  }

  /// @inheritdoc ISchedule
  function previousPrincipalDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) public view override returns (uint256) {
    uint principalPeriod = principalPeriodAt(startTime, timestamp);
    return principalPeriod > 0 ? _startOfPrincipalPeriod(startTime, principalPeriod) : 0;
  }

  //===============================================================================
  // Internal functions
  //===============================================================================

  function _nextPrincipalDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) internal view returns (uint256) {
    uint256 nextPrincipalPeriod = Math.min(
      totalPrincipalPeriods(),
      principalPeriodAt(startTime, timestamp).add(1)
    );
    return _startOfPrincipalPeriod(startTime, nextPrincipalPeriod);
  }

  /// @notice Returns the next time interest will come due, or the termEndTime if there are no more due times
  function _nextInterestDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) internal view returns (uint256) {
    uint256 nextInterestPeriod = Math.min(
      totalInterestPeriods(),
      interestPeriodAt(startTime, timestamp).add(1)
    );
    return _startOfInterestPeriod(startTime, nextInterestPeriod);
  }

  /// @notice Returns the absolute period that the terms will end in, accounting
  ///           for the stub period
  function _termEndAbsolutePeriod(uint256 startTime) internal view returns (uint256) {
    return _termStartAbsolutePeriod(startTime).add(periodsInTerm);
  }

  /// @notice Returns the absolute period that the terms started in, accounting
  ///           for the stub period
  function _termStartAbsolutePeriod(uint256 startTime) internal view returns (uint256) {
    // We add one here so that a "stub period" is created. Example: Imagine
    // a the borrower draws down in the 15th of Jan. It would be incorrect for them
    // to make a payment on Feb 1, as it would not be a full payment period. Instead
    // we count the first 15 days as an extension on the first period, or a "stub period"
    return periodMapper.periodOf(startTime).add(1);
  }

  /// @notice Convert a period to a principal period
  function _periodToPrincipalPeriod(uint256 p) internal view returns (uint256) {
    // To make amortization math easy, we want to make it so that the "0th" principal
    // period is the first non-grace principal period.
    return p.div(periodsPerPrincipalPeriod).saturatingSub(gracePrincipalPeriods);
  }

  /// @notice Convert a period to an interest period
  function _periodToInterestPeriod(uint256 p) internal view returns (uint256) {
    return p.div(periodsPerInterestPeriod);
  }

  /// @notice Convert an interest period to a normal period
  function _interestPeriodToPeriod(uint256 p) internal view returns (uint256) {
    return p.mul(periodsPerInterestPeriod);
  }

  /// @notice Convert a principal period to a normal period
  function _principalPeriodToPeriod(uint256 p) internal view returns (uint256) {
    return p.mul(periodsPerPrincipalPeriod);
  }

  /// @notice Convert a period to an absolute period. An absolute period is relative to
  ///   the beginning of time rather than being relative to the start time
  function _periodToAbsolutePeriod(uint256 startTime, uint256 p) internal view returns (uint256) {
    return _termStartAbsolutePeriod(startTime).add(p);
  }

  /// @notice Returns the starting timestamp of a principal period
  function _startOfPrincipalPeriod(
    uint256 startTime,
    uint256 principalPeriod
  ) internal view returns (uint256) {
    uint256 period = _principalPeriodToPeriod(principalPeriod.add(gracePrincipalPeriods));
    uint256 absPeriod = _periodToAbsolutePeriod(startTime, period);
    return periodMapper.startOf(absPeriod);
  }

  /// @notice Returns the starting timestamp of an interest period
  function _startOfInterestPeriod(
    uint256 startTime,
    uint256 interestPeriod
  ) internal view returns (uint256) {
    uint256 period = _interestPeriodToPeriod(interestPeriod);
    uint256 absPeriod = _periodToAbsolutePeriod(startTime, period);
    return periodMapper.startOf(absPeriod);
  }
}