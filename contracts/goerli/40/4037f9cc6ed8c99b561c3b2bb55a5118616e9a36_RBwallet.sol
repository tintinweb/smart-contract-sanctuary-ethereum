/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// File: BokkyPooBahsDateTimeLibrary.sol


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

// File: BokkyPooBahsDateTimeContract.sol


pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00 - Contract Instance
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
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------


contract BokkyPooBahsDateTimeContract {
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant SECONDS_PER_HOUR = 60 * 60;
    uint public constant SECONDS_PER_MINUTE = 60;
    int public constant OFFSET19700101 = 2440588;

    uint public constant DOW_MON = 1;
    uint public constant DOW_TUE = 2;
    uint public constant DOW_WED = 3;
    uint public constant DOW_THU = 4;
    uint public constant DOW_FRI = 5;
    uint public constant DOW_SAT = 6;
    uint public constant DOW_SUN = 7;

    function _now() public view returns (uint timestamp) {
        timestamp = block.timestamp;
    }
    function _nowDateTime() public view returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(block.timestamp);
    }
    function _daysFromDate(uint year, uint month, uint day) public pure returns (uint _days) {
        return BokkyPooBahsDateTimeLibrary._daysFromDate(year, month, day);
    }
    function _daysToDate(uint _days) public pure returns (uint year, uint month, uint day) {
        return BokkyPooBahsDateTimeLibrary._daysToDate(_days);
    }
    function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
        return BokkyPooBahsDateTimeLibrary.timestampFromDate(year, month, day);
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
        return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
    }
    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
    }
    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
    }

    function isValidDate(uint year, uint month, uint day) public pure returns (bool valid) {
        valid = BokkyPooBahsDateTimeLibrary.isValidDate(year, month, day);
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (bool valid) {
        valid = BokkyPooBahsDateTimeLibrary.isValidDateTime(year, month, day, hour, minute, second);
    }
    function isLeapYear(uint timestamp) public pure returns (bool leapYear) {
        leapYear = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
    }
    function _isLeapYear(uint year) public pure returns (bool leapYear) {
        leapYear = BokkyPooBahsDateTimeLibrary._isLeapYear(year);
    }
    function isWeekDay(uint timestamp) public pure returns (bool weekDay) {
        weekDay = BokkyPooBahsDateTimeLibrary.isWeekDay(timestamp);
    }
    function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
        weekEnd = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
    }

    function getDaysInMonth(uint timestamp) public pure returns (uint daysInMonth) {
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
    }
    function _getDaysInMonth(uint year, uint month) public pure returns (uint daysInMonth) {
        daysInMonth = BokkyPooBahsDateTimeLibrary._getDaysInMonth(year, month);
    }
    function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
        dayOfWeek = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint year) {
        year = BokkyPooBahsDateTimeLibrary.getYear(timestamp);
    }
    function getMonth(uint timestamp) public pure returns (uint month) {
        month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
    }
    function getDay(uint timestamp) public pure returns (uint day) {
        day = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
    }
    function getHour(uint timestamp) public pure returns (uint hour) {
        hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
    }
    function getMinute(uint timestamp) public pure returns (uint minute) {
        minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);
    }
    function getSecond(uint timestamp) public pure returns (uint second) {
        second = BokkyPooBahsDateTimeLibrary.getSecond(timestamp);
    }

    function addYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addYears(timestamp, _years);
    }
    function addMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, _months);
    }
    function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, _days);
    }
    function addHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addHours(timestamp, _hours);
    }
    function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addMinutes(timestamp, _minutes);
    }
    function addSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addSeconds(timestamp, _seconds);
    }

    function subYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subYears(timestamp, _years);
    }
    function subMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subMonths(timestamp, _months);
    }
    function subDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subDays(timestamp, _days);
    }
    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subHours(timestamp, _hours);
    }
    function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subMinutes(timestamp, _minutes);
    }
    function subSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subSeconds(timestamp, _seconds);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) public pure returns (uint _years) {
        _years = BokkyPooBahsDateTimeLibrary.diffYears(fromTimestamp, toTimestamp);
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) public pure returns (uint _months) {
        _months = BokkyPooBahsDateTimeLibrary.diffMonths(fromTimestamp, toTimestamp);
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
        _hours = BokkyPooBahsDateTimeLibrary.diffHours(fromTimestamp, toTimestamp);
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) public pure returns (uint _minutes) {
        _minutes = BokkyPooBahsDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) public pure returns (uint _seconds) {
        _seconds = BokkyPooBahsDateTimeLibrary.diffSeconds(fromTimestamp, toTimestamp);
    }
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol


pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol


pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: hardhat/console.sol


pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// File: RRDAO Prime.sol



//Russian Roulette DAO. 2022. https://rrdao.github.io

//This project explores the effects of extreme taxing & limited batched sells on sustainability

//This is the first sustainable ponzi, for obvious reasons youll see

//We introduce for the first time: 

//1 - extreme sell tax swings, from 10% to 90% sells without becoming a honeypot,

//2 - limited scheduled sells, cashable on Saturdays only for a low tax

//3 - and a responsive community controlled wallet for buybacks 

//This is a hardcore ponzi, a bear market hedge meant to be up only and sustainable. 

//A project for the people, fair launch, autonomous, funds 100% community controlled with a clear economic framework.

//Why we are here: taxed transactions are not going anywhere anytime soon, they are the simplest and direct fiscal tool to regulate any economy

//used correctly, alongside other simple mechanisms, taxes can give projects stability and sustainability, 

//taxes can give investors what they need; continuous sustainable money making ecosystems

//which is what we all need, everyone is tired of projects that pump and fizzle out whilst we sleep and youre left holding worthless tokens

//without taxes, many no-use-case/meme/ponzi projects would have failed to create sustainable income streams.

// [Backstory

//  Pegged/Backed elastic tokens tried to introduce value retention/guaranteeing mechanisms, but with an inflationary approach and people bought it

//  the rebasing tokens mania was proof that people are desperate for sustainable Up Only investments that guarantee value retention

//  rebase tokens failed to stay up as promised, no matter the narrative, and as people cash out they take a hit in value

//  no project can simultaneously withstand unlimited value drain from sells whilst guranteeing profit for all investors regardless of entry price 

//  but Pegging is just one of the many innovative money concepts that will come to this space

//.....

//with taxes, we are going back to simpler tools yet taking the experiment further, on sustainable new money concepts

//for the guarantee our approach offers what you sacrifice is time, and like in rebase tokens you can get out anytime you want, but here you take a hefty penalty

//our penalty is hard hitting, but if youre tired of jeets or projects that fizzle out forcing you to jump ship & find another, then this is the project for you

//...this is for the seasonless project for the degen web3 believers. a zero loss system designed to be up only.



pragma solidity ^0.8.4;










contract RussianRouletteDAO is ERC20, Ownable {

    modifier lockSwap {

        _inSwap = true;

        _;

        _inSwap = false;

    }

    modifier liquidityAdd {

        _inLiquidityAdd = true;

        _;

        _inLiquidityAdd = false;

    }

    uint internal rr_lastcheck;

    uint public _monthPlayers;

    uint public backEndOdds = 3; //3 here, 2 front end

    uint public frontEndOdds = 2;

    uint public _sixersLimit;

    uint public _sixersSlot;

    uint public _totalBonfireCount;

    uint public _totalRewardCount;

    address public _pairAddress;

    uint256 public _RRDay = 6;//Saturday using BPBT library

    uint256 public _maxHoldings = 300000000 * 1e18; //2500000 final 0.5% as we will start with 1k liquidity

    uint256 public _beneficiaryReward;

    uint256 public _buyRate = 15;

    uint256 public _sellRate = 90;

    uint256 public _rrwinnerRate = 10;

    uint256 public _reflectRate = 5;

    uint256 public _discountRate = 5;//discount for helping us liquidate fee tokens when you buy from our website/proxy dex

    uint256 public _holders;

    uint256 public _ethRewardBasis;

    uint256 public _netRewardClaims;

    uint256 public _totalDeleSell;

    uint256 public _totalDeleLease;

    uint256 public _totalLeased;

    uint256 public _totalEthRebalanced;

    uint256 public _totalFeeLiquidated;

    uint256 public _totalDonated;

    uint256 public _totalServiceFees;

    uint256 public _totalStaked;

    uint256 public _tradingStartBlock = 3041510;//mainnet 14400000

    uint256 public _totalSupply;

    uint256 public _totalBuyBackETH;

    uint256 public _totalNVL_proxysell;

    uint256 public _totalNVL_dexsell;

    uint256 public _totalBeneficiaryAssigns;

    address payable public _rebalanceWallet;

    address payable public _treasuryWallet;

    address public _bokkyAddress;

    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));



    bool internal _teamMint = false;

    bool internal _inSwap = false;

    bool internal _inLiquidityAdd = false;

    bool public _useWinnerFees = false;

    

    mapping(uint => address []) public _sixmontherEntry;

    mapping(address => bool) private _rewardExclude;

    mapping(address => bool) private _taxExcluded;

    mapping(address => bool) private _bot;

    mapping(address => bool) private _feeLiquifier;

    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _lastBuy;

    mapping(address => uint256) private _daysLeftToCool;

    mapping(address => uint256) private _lastRewardBasisShares;

    mapping(address => uint256) private _lastRewardBasisStaked;

    mapping(address => uint256) private _sharesLeaseAmnt;

    mapping(address => uint256) public _lastPlay;

    mapping(address => uint256) public _sellDelegation;

    mapping(address => uint256) public _shareDelegation;

    mapping(address => uint256) public _netEthRewardedBE;

    mapping(address => uint256) public _totalEthReflectedSL;

    mapping(address => uint256) public _totalEthReflectedST;

    mapping(address => uint256) public _netEthRewardedWallet;

    mapping(address => uint256) public _netRewardsmyDonors;

    mapping(address => uint256) public _netRewardsTomyBE;

    mapping(address => uint256) public _lastRewardBasis;

    mapping(address => address) public _claimBeneficiary;

    mapping(address => acptStruct) private _acptMap;

    mapping(address => myBenefactors) private _privateList;

    mapping(address => myloansStruct) private _shareClaimsMap;

    mapping(address => mysharesStruct) private _shareMap;//store stracts

    mapping(address => mystakesStruct) private _stakeMap;

    mapping(address => winningStruct) private _winnerMap;	

    

    address[] internal _scheduledSellsArray; //lifetime winners

    address[] internal _lessorsArray;

    

    event Burn(uint256 indexed amount); 

    event BUYft(address indexed buyer, uint256 amount, uint256 netamount);

    event BuyBack(address indexed torcher, uint256 ethbuy, uint256 amount); 

    event BanditSell(address indexed seller, uint256 tokens, uint256 ethreceive);

    event trigger(address indexed player, uint256 loaded, uint256 pulled);

    event Staked(address indexed staker, uint256 indexed expiry, uint256 tokens);

    event Unstaked(address indexed staker, uint256 tokens, bool sixmonther);

    event LeaseList(address indexed lessor, uint256 ethask, uint256 shares);

    event LeaseStart(address indexed lessor, address indexed lessee, uint256 shares);

    event LeaseUnlist(address indexed lessor, uint256 shares, uint256 indexed time);

    event LeaseEnd(address indexed lessor, uint256 shares, uint256 indexed time);

    event DelegateSell(address indexed investor, address indexed proxy, uint256 amount);

    event unDelegateSell(address indexed proxy, address indexed investor, uint256 amount);

    event DelegateLease(address indexed investor, address indexed proxy, uint256 amount);

    event unDelegateLease(address indexed proxy, address indexed investor, uint256 amount);

    event ClaimReflectionLease(address indexed claimer, address indexed lessor, uint256 reflection);

    event ClaimReflectionStake(address indexed claimer, address indexed proxy, uint256 reflection);

    event ClaimReflection(address indexed claimer, uint256 reflection);



    BokkyPooBahsDateTimeContract private bokky; // Bokky contract 

    constructor(address payable _bokkyAdd

    ) ERC20("Russian Roulette DAO", "RRDAO") Ownable() {

        //bokky datetime

        bokky = BokkyPooBahsDateTimeContract(_bokkyAdd);

        //Owner wallet is not tax excluded, it plays RR too

        addTaxExcluded(owner());

        addTaxExcluded(_burnAddress);

        addTaxExcluded(address(this));

        //Uniswap 

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // 0x10ED43C718714eb63d5aA57B78B54704E256024E pancake test, 0xa6AD18C2aC47803E193F75c3677b14BF19B94883 SpookySwap test

        // Create a uniswap pair for this new token

        _pairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this),_uniswapV2Router.WETH());

        // set the rest of the contract variables

        _router = _uniswapV2Router;

    }

    function addLiquidity(uint256 tokens) public payable onlyOwner() liquidityAdd {

        uint256 lptokens = (tokens * 90) / 100;

        _mint(address(this), lptokens);

        _mint(owner(), tokens-lptokens);

        _approve(address(this), address(_router), lptokens);

        _router.addLiquidityETH{value: msg.value}(

            address(this),

            lptokens,

            0,

            0,

            owner(),

            //consider not relying on blocktime

            block.timestamp

        );

    }

    function acpt(address account) public view returns (uint256) {

        return _acptMap[account].tokenscost / _acptMap[account].tokens;

    }

    //donations welcome. on holidays. etc

    function addReflectionETH() public payable {

        require(msg.value > 0);

        _ethRewardBasis += msg.value; _totalRewardCount += 1; _totalDonated += msg.value;

    }

    function _circSupply() public view returns (uint256) {

        return _totalSupply - balanceOf(_burnAddress);

    }

    function currentRewardForWallet(address addr) public view returns(uint256) {

        uint256 ethChange = _ethRewardBasis - _lastRewardBasis[addr];

        return (ethChange * balanceOf(addr)) / _circSupply();

    }

    function currentDonorRewards(address addr) public view returns(uint n, uint256 netreward) {

        n = _privateList[addr].myDonors.length;

        for (uint i = 0; i < n; i++) {

            //sum the rewards

            netreward += currentRewardForWallet(_privateList[addr].myDonors[i]);

            if(i == n-1){break;}

        }

        return (n, netreward);

    }

    function price() public view returns (uint256 tokenprice) {//ETH PER TOKEN

        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);

        (uint reserveA, uint reserveB,) = pair.getReserves();

        //tendency to switch pair: ETH/TOKEN | TOKEN/ETH

        if(reserveA > reserveB){//tokens in slot A

            tokenprice = (reserveB * (10 ** uint256(18))) / reserveA;

        }else{//tokens in slot B

            tokenprice = (reserveA * (10 ** uint256(18))) / reserveB;

        }

        return tokenprice;

    }

    function ScheduledSells() public view returns(address[] memory) {

        return _scheduledSellsArray;

    }

    function fetchSwapAmounts(uint256 amountIn, uint swap) public view returns(uint256){

        address[] memory path = new address[](2);

        if(swap == 1){//buy

            path[0] = _router.WETH();

            path[1] = address(this);

        }else if(swap == 0){//sell

            path[0] = address(this);

            path[1] = _router.WETH();

        }

		uint[] memory  amountsOut = _router.getAmountsOut(amountIn, path);

        return amountsOut[amountsOut.length - 1];

    }

    //taxes

    function isTaxExcluded(address account) public view returns (bool) {

        return _taxExcluded[account];

    }

    function addTaxExcluded(address account) internal {

        _taxExcluded[account] = true;

    }    

    //2 mappings, one for wallet donors

    //then for each address fetch array index

    struct myBenefactors {

        address[] myDonors;

        mapping(address => uint) myDonorsIndex;

    }

    //add reflection beneficiary

    function addBeneficiary(address account) public{

        require(!isBot(msg.sender) && !isBot(account));

       //adding self as donor to beneficiarys private storage

       _claimBeneficiary[msg.sender] = account;//who is wallets beneficiary..1 max

        _privateList[account].myDonors.push(msg.sender);

        uint index = _privateList[account].myDonors.length - 1;

        //store key

        _privateList[account].myDonorsIndex[msg.sender] = index;//add self

        _totalBeneficiaryAssigns += 1;

    }

    function removeBeneficiary(address account) public{

       //removing beneficiary

       _claimBeneficiary[msg.sender] = msg.sender;//who is wallets beneficiary

       uint index = _privateList[account].myDonorsIndex[msg.sender];

       //remove donor from array

       uint lastIndex = _privateList[account].myDonors.length - 1;

       _privateList[account].myDonors[index] = _privateList[account].myDonors[lastIndex];

       _privateList[account].myDonors.pop();

       _totalBeneficiaryAssigns -= 1;

    }

    function viewBenefactors() public view returns(address[] memory){

       return _privateList[msg.sender].myDonors;

    }

    

    function playersCount() internal {

        uint todayDate = dateToday();

        if(todayDate == 1 && rr_lastcheck ==  28 || rr_lastcheck == 29 || rr_lastcheck == 30 || rr_lastcheck == 31){

            //first person - reset for all you shall

            _sixersSlot = _monthPlayers = 0;

        }

        _monthPlayers += 1;

        rr_lastcheck = dateToday();//extract date from this timsstamp

    }

    // play Russian Roulette

    function _playRussianRoulette(uint _num) external{

        //tax excluded accounts cant play - won already or owner

        require(!isTaxExcluded(msg.sender));

        require( balanceOf(msg.sender) > 1000000000000000000000, "hold 1000 tokens"); 

        uint daysSincePlay = diffDays(_lastPlay[msg.sender]);//then - now

        //require((daysSincePlay - _daysLeftToCool[msg.sender]) >= 0,"on cooldown");

        require( _num > 0  && _num <= frontEndOdds, "1 to 2");

        uint result = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _num))) % backEndOdds;

        if(result == _num){

            addRRwinners(msg.sender);

        }

        playersCount();

        //set last play time & days till month is over

        _daysLeftToCool[msg.sender] = daysLeftInMonth();//uint 1-30

        _lastPlay[msg.sender] = block.timestamp;

        emit trigger(msg.sender, _num, result);

    }

    struct winningStruct {

        uint arrayKey;

        uint256 time;

    }

    function addRRwinners(address account) internal{

        _taxExcluded[account] = true;

        _scheduledSellsArray.push(account);

        uint indexw = _scheduledSellsArray.length - 1;

        //store key in struct... current winners who havent sold yet /used their ticket, will remain winners

        _winnerMap[account].arrayKey = indexw;

        _winnerMap[account].time = block.timestamp;

    }

    function removeWinner(address account) internal{

        _taxExcluded[account] = false;

        require(_winnerMap[account].arrayKey < _scheduledSellsArray.length);

        _scheduledSellsArray[_winnerMap[account].arrayKey] = _scheduledSellsArray[_scheduledSellsArray.length-1];

        _scheduledSellsArray.pop();

        delete _winnerMap[account];

    }

    //bot accounts on uniswap trading from router

    function isBot(address account) public view returns (bool) {

        return _bot[account];

    }

    function _addBot(address account) internal {

        _bot[account] = true;

        _rewardExclude[account] = true;

    }

    function addBot(address account) public onlyOwner() {

        if(account != address(_router) || account != _pairAddress){revert();}

        _addBot(account);

    }

    //token balances

    function _addBalance(address account, uint256 amount) internal {

        _balances[account] = _balances[account] + amount;

    }

    function _subtractBalance(address account, uint256 amount) internal {

        _balances[account] = _balances[account] - amount;

    }

    //------------------------------------------------------------------

    //Transfer overwrites erc-20 method. Struct first

    struct acptStruct {

        uint256 tokenscost;

        uint256 tokens;

    }

    function _transfer(

        address sender,

        address recipient,

        uint256 amount

    ) internal override {

        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {

            //owner cant sell

            if(sender == owner() && recipient == _pairAddress){return;}

            if(_inLiquidityAdd || sender == address(this) || recipient == address(this) || recipient == _burnAddress || sender == owner()){//No fees

                if(balanceOf(recipient) == 0){_holders +=1; }//before

                _rawTransfer(sender, recipient, amount);

                if(balanceOf(sender) == 0){_holders -= 1;}//after

                return;

            }else{

                uint musi = bokky.getDayOfWeek(block.timestamp);

                if(musi == _RRDay && _winnerMap[sender].time != 0){_useWinnerFees = true;}

            }

        }

        //automatic start to trading

        require(block.number >= _tradingStartBlock);

        //recipient can receive but wont send, dwindles circ supply

        require(!isBot(sender) && !isBot(msg.sender) && !isBot(tx.origin));

        require(amount <= _maxHoldings || _inLiquidityAdd || _inSwap || recipient == address(_router));

        

        //indicates swap

        bool tokenSwap = false;

        bool buyCostAvg = false;

        uint256 send = amount;  uint256 reflect;    uint256 rebalance;

        // Buy

        if (sender == _pairAddress) {

            require(balanceOf(recipient)+amount < _maxHoldings);

            (send,reflect,rebalance) = _getBuyTax(amount);

            if(_feeLiquifier[recipient]){//already taxed in ETH

                (send,reflect,rebalance) = (amount,0,0);

                _feeLiquifier[recipient] = false;

            }

            //indicates swap

            tokenSwap = true;

            buyCostAvg = true;

        }

        // Sell

        if (recipient == _pairAddress) {

            //owner wallet already stopped at top      

            (send,rebalance) = _getSellTax(amount);

            if (_useWinnerFees){

                (send,rebalance) = _getWinnerTax(amount);

                //reset winner status

                if(sender != address(this)){removeWinner(sender);}

            }

            //indicates swap

            tokenSwap = true;

            //check NVL in transaction

            _totalNVL_dexsell += fetchSwapAmounts(send, 0);

        }

        //Wallet to Wallet transfer

        if(tokenSwap == false){

            //default..discourage transfer prevent RR cheating

            (send,reflect,rebalance) = ((amount * 1 / 10000),0,0);

        }

        if(buyCostAvg){

            _acptMap[recipient].tokenscost += send * price();

            _acptMap[recipient].tokens += send;

        }

        //before balance check

        if(balanceOf(recipient) == 0){_holders +=1; }

        //transfer

        _rawTransfer(sender, recipient, send);

        //after balance check

        if(balanceOf(sender) == 0){_holders -= 1;}

        //take rebalance

        if(rebalance>0){

            _takeSwapFees(sender, rebalance + reflect);

        }

        

        if (block.number == _tradingStartBlock && !isTaxExcluded(tx.origin)) {

            if (tx.origin == address(_pairAddress)) {

                if (sender == address(_pairAddress)) {

                    _addBot(recipient);

                } else {

                    _addBot(sender);

                }

            } else {

                _addBot(tx.origin);

            }

        }

    }

    function claimReflection() public {

        require(!_rewardExclude[msg.sender] && !_rewardExclude[msg.sender]);//covers both bot & feeCollectors

        //get array

        uint n = _privateList[msg.sender].myDonors.length;

        uint256 netreward = currentRewardForWallet(msg.sender);

        

        if(n>0){

            for (uint i = 0; i < n; i++) {

                address donor = _privateList[msg.sender].myDonors[i];

                uint256 owed = currentRewardForWallet(donor);

                //all rewards from my donors

                _netRewardsmyDonors[msg.sender] += owed;

                //update my donors: for each donor: save claims by my 1 beneficiary

                _netRewardsTomyBE[donor] += owed;

                //sum the rewards

                netreward += owed; _beneficiaryReward += owed; 

                //last point wallet claimed 

                _lastRewardBasis[donor] = _ethRewardBasis;

                //break

                if(i == n-1){break;}

            }

        }

        if(netreward>0){

            //finally transfer

            payable(msg.sender).transfer(netreward);

            //update

            _netRewardClaims += netreward;

            //all rewards for my wallet

            _netEthRewardedWallet[msg.sender] += netreward;

            //last point wallet claimed 

            _lastRewardBasis[msg.sender] = _ethRewardBasis;

            emit ClaimReflection(msg.sender, netreward);

        }        

    }

    //Swap user tokens for eth through our contract, Uniswap has a 49% limit so we work around it here

    //Bandits (those who sell unscheduled / off the RR calender) suffer 90% tax. The more bandits the merrier for LP

    //share bidding allows you to sell without affecting the LP but we charge 10% for every proxy service to both parties netting 20% (10% seller tokens & 10% buyer ETH)

    //Lastly we rely on investors to also buy the small dips in speculation and help level out the chart

    //bypassing Uniswap tax limitations

    function _sellGuns(uint256 amount, uint swapdeadline) public lockSwap {

        require ( !_inSwap );

        require(_sellDelegation[msg.sender] >= amount);

        require(msg.sender != owner());//owner cant sell

        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = _router.WETH();



        _sellDelegation[msg.sender] -= amount;

        uint musi = bokky.getDayOfWeek(block.timestamp);

        (uint256 amountSwap,uint256 rebalance) = _getSellTax(amount);

        if(musi == _RRDay && _winnerMap[msg.sender].time != 0){//winner 

            (amountSwap,rebalance) = _getWinnerTax(amount);

            removeWinner(msg.sender);

        }

        //THE MOST DEFINING PART THAT AFFECTS THE WHOLE PROJECT IS THIS (simple 1 line of below)

        //If we liquidate fee tokens in LP that means we will inflate the LP on each bandit sell (90% tax)

        //Though bandit sells will obviously be slow, meaning buyers will likely scoup them up thru Proxy buys (not uniswap)

        //We instead liquidate fee tokens through or Proxy Dex buys

        _totalServiceFees += rebalance;

        /*---------------------------------------------------*/

        _approve(address(this), address(_router), amountSwap);

        uint[] memory returnAmnt = _router.swapExactTokensForETH(

            amountSwap,

            0,

            path,

            payable(msg.sender),

            block.timestamp + swapdeadline

        );

        if(returnAmnt[1] >0){

            _totalNVL_proxysell += uint256(returnAmnt[1]);

            emit BanditSell(msg.sender, amountSwap, returnAmnt[1]);

        }else{revert();}

    }

    //Migration helper

    //moves all ETH from contract if we migrate, holders then assign it to treasury

    //or perfom a grand Bornfire, we remove taxes everyone collects, we migrate

    function withdrawAll() public onlyOwner() {

        uint256 totalETH = address(this).balance;

        _rebalanceWallet.transfer(totalETH);

    }

    function _takeSwapFees(address account, uint256 totalFees) internal {

        _rawTransfer(account, address(this), totalFees);

        _totalServiceFees += totalFees;

    }

    function _delegateSell(uint256 amount) public {

        require(!_rewardExclude[tx.origin] && !_rewardExclude[msg.sender]);//covers both bot & feeCollectors

        _rawTransfer(msg.sender, address(this), amount);

        _sellDelegation[msg.sender] += amount;

        _totalDeleSell += amount;

        emit DelegateSell(msg.sender, address(this), amount);

    }

    function _undelegateSell(uint256 amount) public {

        require(_sellDelegation[msg.sender] >= amount, "exceeds");

        _sellDelegation[msg.sender] -= amount;

        _totalDeleSell -= amount;

        _rawTransfer(address(this), msg.sender, amount);

        emit unDelegateSell(address(this), msg.sender, amount);

    }

    function _delegateShares(uint256 amount) public {

        require(!_rewardExclude[tx.origin] && !_rewardExclude[msg.sender]);//covers both bot & feeCollectors

        _rawTransfer(msg.sender, address(this), amount);

        _shareDelegation[msg.sender] += amount;

        _totalDeleLease += amount;//track tokens delegated for share leasing

        emit DelegateLease(msg.sender, address(this), amount);

    }

    function _undelegateShares(uint256 amount) public {

        require(_shareDelegation[msg.sender] >= amount);

        _shareDelegation[msg.sender] -= amount;

        _totalDeleLease -= amount;

        _rawTransfer(address(this), msg.sender, amount);//after updating balance

        emit unDelegateLease(address(this), msg.sender, amount);

    }

    function _bonfireEvent(uint swapdeadline) public payable returns (uint256) {

        address[] memory path = new address[](2);

        path[0] = _router.WETH();//buy

        path[1] = address(this);

        uint deadline = block.timestamp + swapdeadline;

        uint[] memory tokenAmount_ = _router.swapExactETHForTokens{value: msg.value}(

            0, //always succeeds

            path, 

            payable(_burnAddress), //address to

            deadline

        );

        uint256 outputTokenCount = uint256(tokenAmount_[tokenAmount_.length - 1]);

        if(outputTokenCount >0){

            _totalBonfireCount += 1;

            _totalBuyBackETH += msg.value;//for tokens burnt we simply query deadAdd balance

            emit BuyBack(msg.sender, msg.value, outputTokenCount);

            emit Burn(outputTokenCount);

        }else{revert();}

        return outputTokenCount;

    }

    struct mystakesStruct {

        uint256 amount;

        uint256 duration;

        uint256 expiry;

        bool sixmonther;

    }

    function _stakeTokens(uint stakedays, uint256 tokens)public{

        require(tokens > 0 && stakedays > 0);

        require(msg.sender != owner() && !_rewardExclude[tx.origin] && !_rewardExclude[msg.sender]);//Bots & FeeCollectors covered

        uint256 expiration = addDays(stakedays);

        //limited sixers incase everyone wants to stake at once

        //to get list of sixers: key=year*month. using expiry dates to construct key.

        uint monthkey = getYear(expiration) * getMonth(expiration);

        if(stakedays >= 180 && _sixersSlot <= _sixersLimit){_stakeMap[msg.sender].sixmonther = true; _sixersSlot += 1; _sixmontherEntry[monthkey].push(msg.sender);}



        //update

        if(_stakeMap[msg.sender].amount > 0){//can add tokens whether expired or not

            _stakeMap[msg.sender].amount += tokens;//add to existing

        }else{

            _stakeMap[msg.sender].amount = tokens;

            _stakeMap[msg.sender].duration = stakedays;

            _stakeMap[msg.sender].expiry = expiration;

            _lastRewardBasisStaked[msg.sender] = _ethRewardBasis;

        }

        _totalStaked += tokens;

        _rawTransfer(msg.sender, address(this), tokens);

        //emit

        emit Staked(msg.sender, expiration, tokens);

    }

    function _buyGuns(uint swapdeadline) public payable lockSwap returns (uint256 outputTokenCount, uint256 requiredTokens, uint256 balancePending) {

        //anyone even bots & fee collectors can buy. they cant sell or transfer

        require(msg.value > 0);

        address[] memory path = new address[](2);

        path[0] = _router.WETH();

        path[1] = address(this);

        //ETH FEE TAKING 

        _feeLiquifier[msg.sender] = true;//tax free, tokens send from LP,if any

        (uint256 buyETH, uint256 reflectETH, uint256 rebalanceETH) = _getBuyTax(msg.value);

        //check values

        uint256 swap_price = price();

        requiredTokens = fetchSwapAmounts(buyETH, 1);

        require(balanceOf(msg.sender)+requiredTokens < _maxHoldings);

        //proceed

        uint256 bonusedAmount = requiredTokens * (100 + _discountRate) / 100;//bonus

        uint256 tokensTransfer = 0;

        if(_totalServiceFees > 0){

            if(_totalServiceFees > bonusedAmount){

                tokensTransfer = bonusedAmount;

            }else if(_totalServiceFees > requiredTokens && _totalServiceFees < bonusedAmount){

                tokensTransfer = requiredTokens;

                uint256 discounted = requiredTokens * (100 - _discountRate) / 100;//factor bonus into given amount to get new balance needed

                balancePending = requiredTokens - discounted;

            }else if(_totalServiceFees < requiredTokens){//user should check if its worth it

                tokensTransfer = _totalServiceFees;

                uint256 discounted = _totalServiceFees * (100 - _discountRate) / 100;//factor bonus into given amount to get new balance needed

                balancePending = requiredTokens - discounted;

            }

        }else{//straight LP buy, bonus not available

            balancePending = requiredTokens;

        }

        if(balancePending > 0){

            //buy whats pending from UNISWAP LP

            //how much eth to use calculated based on requiredTokens not bonus

            uint256 inputETH = buyETH * balancePending/requiredTokens;

            buyETH -= inputETH;//adjust starting eth balance

            uint256 deadline = block.timestamp + swapdeadline;

            uint[] memory tokenAmount_ = _router.swapExactETHForTokens{value: inputETH}(

                0,

                path, 

                payable(msg.sender), 

                deadline

            );

            outputTokenCount += uint256(tokenAmount_[tokenAmount_.length - 1]);

        }

        //transfer to buyer tokens liquidated

        if(tokensTransfer > 0){

            _rawTransfer(address(this), msg.sender, tokensTransfer);

            //we have taken from Fees pool, update

            _totalServiceFees -= tokensTransfer;

            outputTokenCount += tokensTransfer;

        }

        //success or revert to prevent losing bonuses

        if(outputTokenCount == 0){revert("zero received");}

        //update acpt for both scenarios

        _acptMap[msg.sender].tokenscost += outputTokenCount * swap_price;

        _acptMap[msg.sender].tokens += outputTokenCount;

        //liquidated fee tokens, so collect eth

        if(tokensTransfer > 0){

            rebalanceETH += buyETH;//batch rebalanceETH & buyETH transfer

        }

        //take fees: reflection + rbw

        _ethRewardBasis += reflectETH;

        _totalEthRebalanced += rebalanceETH;

        _totalFeeLiquidated += tokensTransfer;

        //fee, only transfer RBW eth, leave reflections eth on contract

        payable(_rebalanceWallet).transfer(rebalanceETH);

        //emit

        emit BUYft(msg.sender, tokensTransfer, outputTokenCount);

        return (outputTokenCount, requiredTokens, balancePending);

    }

    function unstake(uint256 amount) public{

        require(_stakeMap[msg.sender].amount >= amount);

        require(_stakeMap[msg.sender].expiry < block.timestamp);

        //6monthers get RR, limited slots per month for sustainability

        //its a must to stake at least 50% of your tokens otherwise if you accumulate without staking you wont qualify

        //you can even wait last day to topup its okay, whilst you try your chances with the RR taxman, if you win there first

        if(_stakeMap[msg.sender].sixmonther == true){

            if(_stakeMap[msg.sender].amount >= balanceOf(msg.sender)/2){

                addRRwinners(msg.sender);

            }

        }

        //avoid double claiming when they return to wallet, nullify rewards claimed

        //if you didnt claim all it retains & continue claiming in wallet. Nothing lost

        _lastRewardBasis[msg.sender] += amount/_stakeMap[msg.sender].amount * _totalEthReflectedST[msg.sender];

        //update

        _totalStaked -= amount;

        _stakeMap[msg.sender].amount -= amount;

        _stakeMap[msg.sender].sixmonther = false;

        //send

        _rawTransfer(address(this), msg.sender, amount);

        emit Unstaked(msg.sender, amount, _stakeMap[msg.sender].sixmonther);

    }

    function _checkStakeReflection() view public returns (uint256) {

        uint256 basisDifference = _ethRewardBasis - _lastRewardBasisStaked[msg.sender];//tracks from time wallet takes up lease

        return basisDifference * _stakeMap[msg.sender].amount / _circSupply();

    }

    function claimStakeReflection() public {

        require(!_rewardExclude[tx.origin] && !_rewardExclude[msg.sender]);//Bots & Fee Collector covered

        require(_stakeMap[msg.sender].amount > 0);

        uint256 reward = _checkStakeReflection();

        _lastRewardBasisStaked[msg.sender] = _ethRewardBasis;

        payable(msg.sender).transfer(reward);

        _totalEthReflectedST[msg.sender] += reward; _netRewardClaims += reward;

        emit ClaimReflectionStake(msg.sender, address(this), reward);

    }

    // shareleasing struct

    struct mysharesStruct {

        uint256 amount;

        uint256 amountETH;

        uint256 matchedETH;

        uint256 duration;

        uint256 start;

        uint256 expiry;

        address subscriber;

        uint index;

    }

    function createShareLease(uint256 tokens, uint256 ethRequired, uint256 lease_days) external {

        require(tokens <= _shareDelegation[msg.sender]);

        _shareDelegation[msg.sender] -= tokens;//subtract from delegated

        _sharesLeaseAmnt[msg.sender] += tokens;//add to here

        _totalDeleLease -= tokens;

        _totalLeased += tokens;

        //add values to struct, read as shares.amount 

         _shareMap[msg.sender].amount = tokens;

         _shareMap[msg.sender].amountETH = ethRequired;

         _shareMap[msg.sender].duration = lease_days;

         _shareMap[msg.sender].subscriber = msg.sender;

         _lessorsArray.push(msg.sender);

         _shareMap[msg.sender].index = _lessorsArray.length - 1;

         emit LeaseList(msg.sender, ethRequired, tokens);

    }

    function concludeShareLease()external {

        require(block.timestamp >= _shareMap[msg.sender].expiry);

        require(_shareMap[msg.sender].amount > 0);

        require(_sharesLeaseAmnt[msg.sender] == _shareMap[msg.sender].amount);

        _totalDeleLease += _shareMap[msg.sender].amount;

        _totalLeased -= _shareMap[msg.sender].amount;

        //get token amount in lease from struct

        _shareDelegation[msg.sender] += _shareMap[msg.sender].amount;

        _sharesLeaseAmnt[msg.sender] -= _shareMap[msg.sender].amount;

        //to avoid double claiming when they return to wallet, nullify rewards claimed by lessee

        //if lessee didnt claim all, we retain it in last_basis, you continue claims from wallet

        _lastRewardBasis[msg.sender] += _totalEthReflectedSL[_shareMap[msg.sender].subscriber];

        //reset values

        _totalEthReflectedSL[_shareMap[msg.sender].subscriber] = 0;

        //remove lessor from array

        _lessorsArray[_shareMap[msg.sender].index] = _lessorsArray[_lessorsArray.length-1];

        _lessorsArray.pop();        

        //emit

        if(_shareMap[msg.sender].expiry >0){

            emit LeaseEnd(msg.sender, _shareMap[msg.sender].amount, block.timestamp);

        }else{

            emit LeaseUnlist(msg.sender, _shareMap[msg.sender].amount, block.timestamp);

        }

        //destroy structs

        delete _shareClaimsMap[_shareMap[msg.sender].subscriber];

        delete _shareMap[msg.sender];    

    }

    struct myloansStruct{

        address lessor;

        uint256 amount;

        uint256 date;

    }

    function takeupShareLease(address payable lessor)external payable{

        require(_shareClaimsMap[msg.sender].amount == 0);

        require(_shareMap[lessor].amountETH == msg.value);

        require(_shareMap[lessor].matchedETH == 0);

        //pay first money wont sit on contract

        uint256 net_amountETH = (msg.value)*90/100;

        lessor.transfer(net_amountETH);//take 10% maker fee from both parties, lessor now, lessee on claims

        _rebalanceWallet.transfer(msg.value - net_amountETH);//fee

        //accept eth deposit & record it

        _shareMap[lessor].start = block.timestamp;

        _shareMap[lessor].expiry = addDays(_shareMap[lessor].duration);

        _shareMap[lessor].matchedETH = msg.value;

        _shareMap[lessor].subscriber = msg.sender;

        //take rights to claim rewards due for tokens

        _shareClaimsMap[msg.sender].amount = _shareMap[lessor].amount;

        _shareClaimsMap[msg.sender].lessor = lessor;

        //track rewards due for tokens leased

        _lastRewardBasisShares[msg.sender] = _ethRewardBasis;

        emit LeaseStart(lessor, msg.sender, _shareMap[lessor].amount);

    }

    function _checkShareReflection(address addr) view public returns (uint256) {

        require(_shareMap[addr].subscriber == msg.sender);

        uint256 reward = (_ethRewardBasis - _lastRewardBasisShares[msg.sender]) * _shareClaimsMap[msg.sender].amount / _circSupply();

        return reward;

    }

    //lessee Checks, returns: lessor, tokens, ETHasked, taken date, expiry date

    function _checkOccupiedLease() view public returns (address, uint256, uint256, uint256, uint256) {

        address lessor = _shareClaimsMap[msg.sender].lessor;

        return (lessor, _shareClaimsMap[msg.sender].amount, _shareMap[lessor].matchedETH, _shareMap[lessor].start, _shareMap[lessor].expiry);

    }

    function claimShareReflection(address payable lessor) public{

        require(!_rewardExclude[tx.origin] && !_rewardExclude[msg.sender]);

        require(block.timestamp <= _shareMap[lessor].expiry);//cant claim once expired

        uint256 reward = _checkShareReflection(lessor);



        _lastRewardBasisShares[msg.sender] = _ethRewardBasis;//resets when new lease is taken

        _totalEthReflectedSL[msg.sender] += reward; _netRewardClaims += reward;

        uint256 net_reward = (reward)*90/100;//less service fee

        payable(msg.sender).transfer(net_reward);

        _rebalanceWallet.transfer(reward - net_reward);

        emit ClaimReflectionLease(msg.sender, lessor, net_reward);

    }

    function getShareLeases() view public returns (address[] memory) {

        return _lessorsArray;

    }

    //lessor Checks, returns: [0]tokens, [1]ETHasked, [2]ETHclaimed, [3]duration, [4]datetaken, [5]expiry, [6]subscriber

    function getShareLease(address _address) view public returns (uint256, uint256, uint256, uint256, uint256, uint256, address) {

         return (_shareMap[_address].amount, _shareMap[_address].amountETH, _totalEthReflectedSL[_shareMap[_address].subscriber], _shareMap[_address].duration, _shareMap[_address].start, _shareMap[_address].expiry, _shareMap[_address].subscriber);

    }

    function getStakeData(address _address) view public returns (uint256, uint256, uint256, bool) {

        return (_stakeMap[_address].amount, _stakeMap[_address].duration, _stakeMap[_address].expiry, _stakeMap[_address].sixmonther);

    }

    function getSixersExpiring(uint _expiryKey) view public returns (address[] memory) {

        return _sixmontherEntry[_expiryKey];

    }

    //tax-man resides here

    function _getBuyTax(uint256 amount)internal view  returns (uint256 send, uint256 reflect,  uint256 rebalance){

        uint256 sendRate = 100 - _buyRate;//85

        send = (amount * sendRate) / 100; //send 85%

        reflect = (amount * _reflectRate) / 100; //take 5% reflection

        rebalance = amount - send - reflect; //10% thats left goes to RBW

    }

    function _getSellTax(uint256 amount) internal view returns (uint256 send, uint256 rebalance){

        send = (amount * (100 - _sellRate)) / 100;

        rebalance = amount - send;

    }

    function _getWinnerTax(uint256 amount)internal view returns (uint256 send, uint256 rebalance){

        send = (amount * (100 - _rrwinnerRate)) / 100;

        rebalance = amount - send;

    }

    //setters

    function setSellTax(uint rate) external onlyOwner() {

        require( rate >= 40 && rate <= 90); 

        _sellRate = rate;

    }

    function setRRDay(uint day) external onlyOwner() {

        require( day > 0 && day <= 7); //sunday 7 in BokkyPooBah

        _RRDay = day;

    }

    function setOdds(uint8 _odds) external onlyOwner() {

        require( _odds > 0 && _odds <= 3); //2 shortens the total odds to 4

        backEndOdds = _odds;

    }

    function setMaxHoldings(uint256 maxHoldings) external onlyOwner() {

        _maxHoldings = maxHoldings;

    }

    function setSixersLimit(uint limit) external onlyOwner() {

        //set manually - to get around incompatible error on eg: (1/10 * _holders)

        _sixersLimit = limit;

    }

    function setFeeLiqDiscount(uint256 discountFee) external onlyOwner() {

        _discountRate = discountFee;

    }

    function setTreasuryWallet(address payable _treasury) external onlyOwner(){

        _treasuryWallet = _treasury;

    }

    function setRebalanceWallet(address payable _rebalance) external onlyOwner(){

        //require(_rebalanceWallet == address(0));

        _rebalanceWallet = _rebalance;

    }

    // date checks

    function daysLeftInMonth() public view returns (uint) {

		uint256 daysInMonth = bokky.getDaysInMonth(block.timestamp);

        return daysInMonth - dateToday(); 

    }

    function dateToday() public view returns (uint) {

		return bokky.getDay(block.timestamp);

    }

    function addDays(uint duration) public view returns (uint) {

		return bokky.addDays(block.timestamp, duration);

    }

    function diffDays(uint stamp) public view returns (uint) {

		return bokky.diffDays(stamp, block.timestamp);

    }

    function getMonth(uint stamp) public view returns (uint) {

		return bokky.getMonth(stamp);

    }

    function getYear(uint stamp) public view returns (uint) {

		return bokky.getYear(stamp);

    }

    // modified from OpenZeppelin ERC20

    function _rawTransfer(

        address sender,

        address recipient,

        uint256 amount

    ) internal {

        require(sender != address(0));

        require(recipient != address(0));



        uint256 senderBalance = balanceOf(sender);

        require(senderBalance >= amount);

        unchecked {

            _subtractBalance(sender, amount);

        }

        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);

    }

    function balanceOf(address account) public view virtual override returns (uint256){

        return _balances[account];

    }

    function totalSupply() public view override returns (uint256) {

        return _totalSupply;

    }

    function _mint(address account, uint256 amount) internal override {

        _holders += 1;

        _totalSupply += amount;

        _addBalance(account, amount);

        emit Transfer(address(0), account, amount);

    }

    receive() external payable {}

}
// File: Treasury.sol



pragma solidity ^0.8.4;




contract Treasury {//not ownable but checks main contract owner as admin



    RussianRouletteDAO private token; // Token contract

    BokkyPooBahsDateTimeContract private bokky; // Bokky contract 



	constructor(address payable _tokenAdd, address _bokkyAdd) {

		require(_tokenAdd != address(0) );

		token = RussianRouletteDAO(_tokenAdd);

		bokky = BokkyPooBahsDateTimeContract(_bokkyAdd);

		//set addresses

		tokenAddress = _tokenAdd;

		bokkyAddress = _bokkyAdd;

        //start buffer period

        _bufferTime = block.timestamp + (1 * 60 * 60 * 24 * 30);//30 days

	}

    //define

    bool public _curActiveRequest;

	uint public _requestCount;

    uint public _farmerDay = 1;

    uint public _pollingHours = 12;

    uint public _cooldownHours = 24;

    uint256 public _bufferTime;

    uint256 public _lastFarmerWithdrawal;

    uint256 public _coolDownUntilTime;

    uint256 public _lastRequest;

	uint256 public _totalRBW_receive;

	uint256 public _totalRBW_withdrawals;

    uint256 public _totalFarmerWithdrawals;

	address payable public tokenAddress;

    address public bokkyAddress;

    address public farmerWallet;

	mapping(uint => withdrawalRequest) public requests;



	//events

	event request(uint indexed requestID, uint256 indexed ethConsidered, uint256 indexed availableETH, uint256 lastRequest);

	event withdrawal(uint totalNVL, uint256 ethConsider, uint256 balance, uint256 NVLgap);

    event wdStamp(address indexed stamper, bool indexed stamp, uint indexed requestID);

    event farmerAssigned(address indexed setter, address indexed farmer);

    event farmerWithdrawal(address indexed farmer, uint256 amount, uint256 time);



	struct withdrawalRequest{

		address requester;

		uint ethBalance;

        uint ethToConsider;

		uint yesVotes;

        uint noVotes;

        uint256 gapNVL_BBS;//diff btwn nvl-bbs in eth, i.e. eth to 1 rbb

		uint256 start;

        uint256 expires;

        mapping(address => Stamper) stampInfo;

	}

    struct Stamper{

		bool hasStamped;

		bool stamp;

		uint256 time;

	}

    function depositETH() public payable {

        require(msg.value > 0,"not zero");

        _totalRBW_receive += msg.value;

    }

    //Withdrawals only requestable on Sunday, after RR day, nvl gap after RR day is key to withdrawals

    //RR days start every saturday, buy backs start Saturday until end of day Sunday

    //Midweek BuyBack freq is 6 hours

    //Weekends BuyBack freq is 1 hour

    function requestWithdrawal(uint256 ethRequested) public{

        require(msg.sender == token._rebalanceWallet(), "not Rebalancing Wallet");

        require(!_curActiveRequest, "conclude last request");

        require(block.timestamp > _coolDownUntilTime,"new request cooldown");

        //nvl and buyback sums, NVL / buybacks = rbb

		uint256 proxysellNVL = token._totalNVL_proxysell();

		uint256 uniswapsellNVL = token._totalNVL_dexsell();

		uint256 totalNVL = uniswapsellNVL + proxysellNVL;

		uint256 currentBBTotal = token._totalBuyBackETH();

        uint NVLgap = totalNVL - currentBBTotal;

        //how much max to approve

        uint256 availableETH = address(this).balance;

        uint256 ethToConsider = 0;

        //approve what we have

        if(availableETH < ethRequested){

            ethToConsider = availableETH;

        }else{

            ethToConsider = ethRequested;

        }

        //create withdrawal slip

        if(availableETH > 0){

            _requestCount += 1;

            requests[_requestCount].requester = msg.sender;

            requests[_requestCount].ethBalance = availableETH;

            requests[_requestCount].ethToConsider = ethRequested;

            requests[_requestCount].gapNVL_BBS = NVLgap;

            requests[_requestCount].start = block.timestamp;

            requests[_requestCount].expires = block.timestamp + (1 * 60 * 60 * _pollingHours);

            //mark active to avoid double requests

            _curActiveRequest = true;

            _lastRequest = block.timestamp;

            //start request timeout to 1 day

            _coolDownUntilTime = block.timestamp + (1 * 60 * 60 * _cooldownHours);

            //emit event

            emit request(_requestCount, ethRequested, availableETH, _lastRequest);

        }

	}



    //stampRequest to approve or deny withdrawal of Gap size

    function stampWithdrawal(bool stamp) public {

        require(token.balanceOf(msg.sender) >= 10000 * (1 ** uint256(token.decimals())), "insufficient tokens.");

        require(_curActiveRequest,"no longer active");

        //conclude only on SUNDAY after RR day or when expired

        if(block.timestamp > requests[_requestCount].expires){//bokkypoobah 1-monday, 6 - saturday, 7-sunday

            conclude(_requestCount);

            return;

        }

        require(!requests[_requestCount].stampInfo[msg.sender].hasStamped,"stamped already");

        //if sunday then stamp the slip

        if(stamp){

            requests[_requestCount].yesVotes += 1;

        }else{

            requests[_requestCount].noVotes += 1;

        }

        requests[_requestCount].stampInfo[msg.sender].hasStamped = true;

        emit wdStamp(msg.sender, stamp, _requestCount);

    }



    //reset to allow multiple withdrawals a day

    function skipCoolDown(uint ethRequested) public OnlyOwner(){

        require(!_curActiveRequest, "conclude last request");

        //check day of week: SUNDAY after RR day or any other day

        //this gives community to buy in before we clear all NVL

        uint RRDay = token._RRDay();

        require(dayOfWeek() != RRDay, "not today");//bokkypoobah 1-monday, 6 - saturday, 7-sunday

        //nvl and buyback sums

		uint256 proxysellNVL = token._totalNVL_proxysell();

		uint256 uniswapsellNVL = token._totalNVL_dexsell();

		uint256 totalNVL = uniswapsellNVL + proxysellNVL;

		uint256 currentBBTotal = token._totalBuyBackETH();

        uint NVLgap = totalNVL - currentBBTotal;

        //how much max to approve

        uint256 availableETH = address(this).balance;

        require(availableETH > 0,"treasury has no eth");

        //now check request eth range

        uint256 gapEthRequested = _buybackTOMEDIANrbb(totalNVL, currentBBTotal);

        require(ethRequested <= gapEthRequested && ethRequested <= availableETH,"eth out of range");

        uint256 ethToConsider = 0;

        //approve what we have

        if(availableETH < ethRequested){

            ethToConsider = availableETH;

        }else{

            ethToConsider = ethRequested;

        }        

        //create withdrawal slip

        _requestCount += 1;

        requests[_requestCount].requester = msg.sender;

        requests[_requestCount].ethBalance = availableETH;

        requests[_requestCount].ethToConsider = ethRequested;

        requests[_requestCount].gapNVL_BBS = NVLgap;

        requests[_requestCount].start = block.timestamp;

        requests[_requestCount].expires = block.timestamp + (1 * 60 * 60 * _pollingHours);//12 hours voting time, other 12 hours is to use it in rebalancing wallet whilst RBW frequency is high during weekends

        //mark active to avoid double requests

        _curActiveRequest = true;

        _lastRequest = block.timestamp;

        //start request timeout to 1 day

        _coolDownUntilTime = block.timestamp + (1 * 60 * 60 * _cooldownHours);

        //emit event

        emit request(_requestCount, ethRequested, availableETH, _lastRequest);

    }



    function conclude(uint _reqCount) internal{

        require(block.timestamp >= requests[_reqCount].expires, "Voting ongoing not expired");

        uint256 withdraw;

        //withdraw to rbw

        address rbwAddress = token._rebalanceWallet();

        if(requests[_reqCount].ethToConsider >= address(this).balance){

            withdraw = requests[_reqCount].ethToConsider;

        }else{

            withdraw = address(this).balance;

        }

        if(requests[_reqCount].yesVotes > requests[_reqCount].noVotes){

		    payable(rbwAddress).transfer(withdraw);

        }

        //update

		_totalRBW_withdrawals += withdraw;

        _curActiveRequest = false;

        //emit event

        emit withdrawal(_reqCount, withdraw, address(this).balance, requests[_reqCount].gapNVL_BBS );

    }

    //Farmer wallet is proposed by community as well

    //Owner simply assigns it

    //after a topup withdrawal to RBW the rest is excess can be invested by Farmer

    //only once each month can Farmer also withdraw

    //the month gap gives enough for excess funds to accumulate and create a buffer (between NVL gaps covered & free treasury funds)

    function farmerWithdraw(uint256 amount) public OnlyFarmer(){

        require(!_curActiveRequest, "conclude last request");

        require(address(this).balance >= amount,"insufficient balance");

        require(_bufferTime < block.timestamp,"30 day buffer from launch to build excess");

        uint month = 0;

        if(_lastFarmerWithdrawal > 0){

            month = bokky.getMonth(_lastFarmerWithdrawal);

        }

        uint cur_month = bokky.getMonth(block.timestamp);

        require(month != cur_month, "already withdrawn for the month.");

        //only after RR day sunday buy backs, preferably monday

        uint day = bokky.getDayOfWeek(block.timestamp);

        require(day == _farmerDay, "wait for new month same day");

        //withdraw

        payable(farmerWallet).transfer(amount);

        _lastFarmerWithdrawal = block.timestamp;

        _totalFarmerWithdrawals += amount;

        //emit event

        emit farmerWithdrawal(msg.sender, amount, block.timestamp);

    }

    //setters - poll duration

    function setPollingHours(uint _hours) external OnlyOwner() {

        require( _hours >= 1 && _hours <= 12); 

        _pollingHours = _hours;

    }

    //setters - cooldown period

    function setCooldownHours(uint _hours) external OnlyOwner() {

        require( _hours >= 12 && _hours <= 24); 

        _cooldownHours = _hours;

    }

    //setters - farmer withdrawal day, only up to wedn (monday 1, tues 2, etc

    function setFarmerDay(uint _day) external OnlyOwner() {

        require( _day >= 1 && _day <= 3); 

        _farmerDay = _day;

    }

    //setters - official farmer wallet

    function setFarmerWallet(address _farmerWallet) public OnlyOwner(){

        address owner = token.owner();

        require(_farmerWallet != owner);

        farmerWallet = _farmerWallet;

        emit farmerAssigned(msg.sender, _farmerWallet);

    }

    //get day of week

    function dayOfWeek() public view returns (uint){

		uint day = bokky.getDayOfWeek(block.timestamp);

		return day;

    }

	// rbb_median of 1.25: rbb_median = totalNVL/ desiredBBTotal; gives us desired & we know current.

    function _buybackTOMEDIANrbb(uint256 totalNVL, uint256 currentBBTotal) public pure returns(uint256){

		uint256 rbb_median = 125;// 1.25 ideal landing zone

		uint256 desiredBBTotal = (totalNVL / rbb_median) * 100; 

		uint256 diffTObuy = desiredBBTotal - currentBBTotal;

		return diffTObuy;

	}

    //get withdrawal request, returns: [0] requester, [1] ethGapNVL_BBS, [2] ethRequested, [3] ethBalance, [4] pollstart, [5] expires, [6] approveVotes, [7] rejectVotes

	function getWithdrawalRequest(uint _requestID) public view validRequest(_requestID) returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256){

		return (requests[_requestCount].requester, requests[_requestCount].gapNVL_BBS, requests[_requestCount].ethToConsider, requests[_requestCount].ethBalance, requests[_requestCount].start, requests[_requestCount].expires, requests[_requestCount].yesVotes, requests[_requestCount].noVotes);

	}

    //checks for a valid request ID.

	modifier validRequest(uint _requestID){

		require(_requestID > 0 && _requestID <= _requestCount, "request not valid");

		_;

	}

    //checks farmer wallet

    modifier OnlyFarmer(){

		require(msg.sender == farmerWallet, "not farmer");

		_;

	}

    //check owner

    modifier OnlyOwner(){

		require(msg.sender == token.owner(), "not owner");

		_;

	}

    receive() external payable {}

}
// File: RBW Prime.sol



pragma solidity ^0.8.4;




contract RBwallet{

    RussianRouletteDAO private token; // Token contract

    BokkyPooBahsDateTimeContract private bokky; // Bokky contract

	Treasury private treasury; // Treasury contract

	constructor(address payable _tokenAdd,address payable _treasury, address _bokkyAdd) {

		require(_tokenAdd != address(0) );

		token = RussianRouletteDAO(_tokenAdd);

		bokky = BokkyPooBahsDateTimeContract(_bokkyAdd);

		treasury = Treasury(_treasury);

		//set addresses

		tokenAddress = _tokenAdd;

		bokkyAddress = _bokkyAdd;

		treasuryAddress = _treasury;

	}



	bool public _curActivePoll = false;

	bool public _firstPoll = true;

	uint public _pollCount;

	uint public _lastPollTime;

	uint public _RBfrequency = 1;

	uint public _rebalancedthruPolls;

	uint public _rebalancedthruChecks;

	uint256 public _amountthruPolls;

	uint256 public _amountthruChecks;

	uint256 public _ethVotedOn;

	uint256 public _minimumVotes = 2;//20 voters

	uint256 public _totalRBW_buybacks;//add this to RussianRoulette buyback tally to get NetBuyBacks;

	uint256 public _totalRBW_treasury;

	uint256 public _totalAutoRebalancingChecks;

	uint256 internal _buyback_amnt;

	uint256 internal _cooldown = 60 minutes;

	address payable public tokenAddress;

	address payable public treasuryAddress;

	address public bokkyAddress;

	mapping(uint256 => Poll) public polls;

	mapping(address => uint []) pastpolls;

	mapping(address => uint256) private lastCheck;

	string public myVoteString = 'idle';



	//events

	event rbCHECK(address indexed checker, uint256 indexed rbb, uint256 indexed verdict, uint256 returned);

	event rbbraw(uint256 totalNVL, uint256 currentBBTotal);

	event rbbs(uint256 rbb, uint256 rbbmin, uint256 rbbmax, uint256 call);

	event rbTREASURY(uint256 amount);

	event rbBURN(uint256 amount); 

	event outofPollRange(uint currentRBB, uint256 indexed action);

    event rbBUYBACK(address indexed torcher, uint256 ethbuy, uint256 amount);

	event voteCasted(address indexed voter, uint indexed pollID, string vote);

	event pollCreated(address creator, uint indexed pollID, uint256 indexed starts, uint256 indexed expires);

	event pollEnded(uint indexed pollID, uint treasuryVotes, uint buybackVotes, PollStatus status);

	event passedBuyBack(uint indexed pollID, uint256  amount, uint treasuryVotes, uint buybackVotes);

	event passedTreasury(uint indexed pollID, uint256 amount, uint treasuryVotes, uint buybackVotes);

	enum PollStatus { IN_PROGRESS, TREASURY, BUYBACK }//returns index where action is defined; in_progress=0, treasury=1, buyback=2



	struct Poll{

		uint treasuryVotes;

		uint buybackVotes;

		uint rbb;

		uint256 ethVotedOn;

		uint256 start;

		uint256 expiration;//1 hour min, 6hours max

		PollStatus status;

		address creator;

		address[] voters;

		mapping(address => Voter) voterInfo;

	}



	struct Voter

	{

		bool hasVoted;

		bool vote;

		uint256 time;

	}



	struct myvotehistory

	{

		uint256 poll;

		bool vote;

	}



	//set frequency

	function setFrequency(uint frequency) OnlyOwner() public returns(uint) {

		require(frequency >= 1 && frequency <= 6,"min 1 hour , max 6hours");

		_RBfrequency = frequency;

		return _RBfrequency;

	}

	//New Poll: returns pollID & verdict to prove what it was allowed to do

	//on Russian Roulette Day - every saturday, no voting only auto rebalancing to the max, 

	function newPoll() external returns (uint, uint){

		uint RRDay = token._RRDay();

		require(dayOfWeek() != RRDay,"voting disabled on RR Day"); //bokkypoobah 1-monday, 6 - saturday, 7-sunday

		if(!_firstPoll){

			uint gap = hoursDifference(_lastPollTime-600);//10mins wait

			require(gap >= _RBfrequency, "too soon for a new poll.");

			require(!_curActivePoll, "end last poll first.");

		}



		(bool continuePoll, uint256 cur_rbb, uint verdict, uint256 diffTObuy) = autoRebalancingCheck();//returns: bool(true or false continue to poll), uint rbb, uint autorebalance action(0 wait on Vote, 1 LP buyback, 2 Treasury)

	

		if(continuePoll && verdict == 0){

			_lastPollTime = block.timestamp;

			_curActivePoll = true;

			_pollCount += 1;

			if(_firstPoll){_firstPoll = false;}



			polls[_pollCount].rbb = cur_rbb;

			polls[_pollCount].ethVotedOn = diffTObuy;

			polls[_pollCount].start = block.timestamp;

			polls[_pollCount].expiration = hoursAdd(_RBfrequency);

			polls[_pollCount].creator = msg.sender;

		}else{

			emit outofPollRange(cur_rbb, verdict);

			return (0, verdict);

		}

		emit pollCreated(msg.sender, _pollCount, block.timestamp, hoursAdd(_RBfrequency));

		return (_pollCount, verdict);

	}

	// Cast a vote, weight is not used, everyone can vote.

	function castVote(uint _pollID, bool _vote) external validPoll(_pollID){

		require(getPollStatus(_pollID) == PollStatus.IN_PROGRESS, "Poll concluded.");

		require(!getIfUserHasVoted(_pollID, msg.sender), "User has already voted.");

		require(token.balanceOf(msg.sender) >= 10000 * (1 ** uint256(token.decimals())), "insufficient tokens.");

		//if minimum voters are not met it should not expire

		//if time hasnt expired it should keep accepting votes

		if(polls[_pollID].treasuryVotes+polls[_pollID].buybackVotes >= _minimumVotes){

			require(getPollExpirationTime(_pollID) > block.timestamp ,"expiration time passed: conclude poll");

		}

		// update array

		pastpolls[msg.sender].push(_pollID);

		polls[_pollID].voterInfo[msg.sender] = Voter({

				hasVoted: true,

				vote: _vote,

				time: block.timestamp

		});

		if(_vote){//BuyBack BuyBack

			polls[_pollID].buybackVotes += 1; myVoteString = "BuyBack";

		}

		else{//give Treasury

			polls[_pollID].treasuryVotes += 1; myVoteString = "Treasury";

		}



		polls[_pollID].voters.push(msg.sender);

		emit voteCasted(msg.sender, _pollID, myVoteString);

	}

	//Break impasse

	function breakImpasse(uint _pollID, bool _vote) external validPoll(_pollID) OnlyOwner(){

		require(getPollStatus(_pollID) == PollStatus.IN_PROGRESS, "Poll concluded.");

		pastpolls[msg.sender].push(_pollID);

		polls[_pollID].voterInfo[msg.sender] = Voter({

				hasVoted: true,

				vote: _vote,

				time: block.timestamp

		});

		if(_vote){//BuyBack BuyBack

			polls[_pollID].buybackVotes += 1; myVoteString = "BuyBack";

		}

		else{//give Treasury

			polls[_pollID].treasuryVotes += 1; myVoteString = "Treasury";

		}

		polls[_pollID].voters.push(msg.sender);

		emit voteCasted(msg.sender, _pollID, myVoteString);

	}

	//Conclude poll and deploy funds based on outcome

	function endPoll(uint _pollID) external validPoll(_pollID){

		require(polls[_pollID].status == PollStatus.IN_PROGRESS, "Poll has already ended.");

		require(block.timestamp >= getPollExpirationTime(_pollID), "Voting ongoing not expired");

		require(polls[_pollID].treasuryVotes+polls[_pollID].buybackVotes >= _minimumVotes,"at least 20 voters required");

		//since polls are locked and autoRebalancingCheck only works if previous poll has ended, 

		//all funds from when poll started are there

		if (polls[_pollID].treasuryVotes > polls[_pollID].buybackVotes){

			polls[_pollID].status = PollStatus.TREASURY;

			rebalanceTreasury(polls[_pollID].ethVotedOn);

		}

		else{

			polls[_pollID].status = PollStatus.BUYBACK;

			rebalanceLP(polls[_pollID].ethVotedOn);			

		}

		_curActivePoll = false;

		_rebalancedthruPolls += 1;

		_amountthruPolls += polls[_pollID].ethVotedOn;

		emit pollEnded(_pollID, polls[_pollID].treasuryVotes, polls[_pollID].buybackVotes, polls[_pollID].status);

	}

	//GETTERS 

	function getRRarray() view public returns (address[] memory) {

		address[] memory winnersArray = token.ScheduledSells();

        return winnersArray;

    }

	function getReserveRequire() view public returns (uint256) {

		address[] memory winnersArray = token.ScheduledSells();

		uint n = winnersArray.length;

		uint256 reserveRequire;

		if(n>0){

			for (uint i = 0; i < n; i++) {

				address winner = winnersArray[i];

				uint256 balance = token.balanceOf(winner);

				reserveRequire += token.price() * balance;

				if(i == n-1){

					break;

				}

			}

		}

        return reserveRequire;

    }

	//we are keeping a reserve for RR

	//keeping a reserve is better than just relying on withdrawals

	// since only excess is send to treasury, despite keeping a treasury buffer for a month which would be to account for un expected high number of winners

	//factors the reserves to amount asked, if we have excess on hand payment is processed

	function rebalanceTreasury(uint256 eth_toDeploy) internal {

		uint256 reserve = getReserveRequire();//returns inflated 1e18 result

		eth_toDeploy = eth_toDeploy * 1e18;//match inflation

		//first, if we have excess in hand with reserves factored in

		uint256 netTransfer = reserve + eth_toDeploy;

		uint256 availableBal = address(this).balance * 1e18;//match inflation

		if(availableBal >= netTransfer){

				eth_toDeploy = eth_toDeploy;

		}else{

			//if we cant cover reserves, 2 sub scenarios:

			//1. eth_toDeploy can be met by balance?

			//2. cant be met by reserves?

			if(availableBal >= eth_toDeploy){

				eth_toDeploy = eth_toDeploy;

			}else{//balance cant meet ask, send what we have instead

				eth_toDeploy = availableBal;

			}

		}

		//remove inflation

		eth_toDeploy = eth_toDeploy / 1e18;

		//transfer

		treasury.depositETH{value: eth_toDeploy}();

		_totalRBW_treasury += eth_toDeploy;

		_totalAutoRebalancingChecks += 1;

        emit rbTREASURY(eth_toDeploy);

	}

	function rebalanceLP(uint256 eth_toDeploy) internal returns(uint256){

		//On autorebalance checks: AMOUNT fed is already optimised to get us to 1.25 rbb median

		//On poll outcome: the whole eth balance on contract is used on poll creation & passed on verdict rebalancing.

		//But to cover all other scenarios, we check if we have enough to buyback as asked (to rbb_min, rbb_median, rbb_max)

		uint256 eth_avail = address(this).balance;

		if(eth_avail < eth_toDeploy){

			eth_toDeploy = eth_avail;

		}

		//bonfire event

		uint256 returnedAmnt = token._bonfireEvent{value: eth_toDeploy}(300);

		_totalRBW_buybacks += eth_toDeploy;

		_totalAutoRebalancingChecks += 1;

		//Withdraw more funds from Treasury if RBB is still > max_rbb

		//Request after RR day, give community a chance to buy before buybacks

		uint RRDay = token._RRDay();

		if(dayOfWeek() != RRDay){//bokkypoobah 1-monday, 6 - saturday, 7-sunday

			topupBuyBackETH();

		}

		//emit events

		emit rbBUYBACK(address(this), eth_toDeploy, returnedAmnt);

        emit rbBURN(returnedAmnt);

		return returnedAmnt;

	}

	

	//Sunday after Russian Roulette day, clean up the NVL

	function topupBuyBackETH() internal{

		//check NVL gap & rbb; if rbb out of range then calc eth buyback to rbb median

		uint256 proxysellNVL = token._totalNVL_proxysell();// NVL / buybacks = rbb

		uint256 uniswapsellNVL = token._totalNVL_dexsell();

		uint256 totalNVL = uniswapsellNVL + proxysellNVL;

		uint256 currentBBTotal = token._totalBuyBackETH();

		//rbb check

		uint rbb = (1e18 * totalNVL)/currentBBTotal;

		uint256 rbb_max = (3 * 1e18)/2; //1.5

		//if over the max range

		uint256 gapEthRequested = 0;

		if(rbb > rbb_max){

			gapEthRequested = _buybackTOMEDIANrbb(totalNVL, currentBBTotal);

		}

		//send withdrawal request

		if(gapEthRequested > 0){//request more

			treasury.requestWithdrawal(gapEthRequested);

		}else{}

	}



	//get poll

	function getPoll(uint _pollID) public view returns (uint256 Tvotes, uint256 BBvotes, uint256 rbbATOP, uint256 ethInQ, uint256 start, uint256 expire, address creator){

		require(_pollID > 0 && _pollID <= _pollCount, "poll not valid");//stack too deep bypass..omits modifier

		return (polls[_pollID].treasuryVotes, polls[_pollID].buybackVotes, polls[_pollID].rbb, polls[_pollID].ethVotedOn, polls[_pollID].start, polls[_pollID].expiration, polls[_pollID].creator);

	}

	//get poll status

	//returns enum index where action is defined; in_progress=0, treasury=1, buyback=2

	function getPollStatus(uint _pollID) public view validPoll(_pollID) returns (PollStatus){

		return polls[_pollID].status;

	}

	//get expiration

	function getPollExpirationTime(uint _pollID) public view validPoll(_pollID) returns (uint256){

		return polls[_pollID].expiration;

	}

	//get wallet's past voting history

	function getPollHistory(address _voter) public view returns(uint256[] memory){

		return pastpolls[_voter];

	}

	//gets a voter's vote for a given expired poll

	function getPollInfoForVoter(uint _pollID, address _voter) public view validPoll(_pollID) returns (bool, bool, uint256){

		require(getIfUserHasVoted(_pollID, _voter));

		bool _vote = polls[_pollID].voterInfo[_voter].vote;

		bool _hasVoted = polls[_pollID].voterInfo[_voter].hasVoted;

		uint256 _votetime = polls[_pollID].voterInfo[_voter].time;

		return (_vote, _hasVoted, _votetime);

	}

	//gets all the voters of a poll

	function getVotersForPoll(uint _pollID) public view validPoll(_pollID) returns (address[] memory){

		require(getPollStatus(_pollID) != PollStatus.IN_PROGRESS);

		return polls[_pollID].voters;

	}

	//checks if a user has voted for a specific poll

	function getIfUserHasVoted(uint _pollID, address _user) public view validPoll(_pollID) returns (bool){

		return (polls[_pollID].voterInfo[_user].hasVoted);

	}

	//checks for a valid poll ID.

	modifier validPoll(uint _pollID){

		require(_pollID > 0 && _pollID <= _pollCount, "poll not valid");

		_;

	}

	//Implements straight through processing

	//called before Vote creation or manually

	//There should be ETH on RBW contract else reverts, incl poll creation

	//checks rbb levels to determine if a vote is needed

	//if out of poll range: auto rebalances to gurantee a max rbb level at 1.5, min level 1

	//based on rbb levels, calculates how much is needed to rebalance to:

	//-1. median rbb 1.25 - if cur_rbb >= 1.5 (buyback is needed)

	//-2. if rbb <= 1 (no more buy backs) funds go to treasury

	//--on (2) we also need to avoid sending too much to treasury & have none left if the next sell triggers a rbb > 1.5

	//--on (1) each buy back checks how much is needed to get to 1.25, thus protects from going below 1.25 in each buyback

	//--thus (2) is not to protect against over buying but to know how far off we are from 1.25 in current_NVL value

	//--the amount of ETH needed in sells (NVL increase) to take us from <1 & back to 1.25 is what we foregore to the treasury

	//treasury_foregore function reserves funds needed to buyback to median rbb, sends excess to treasury, which can also come back if needed

	//POLLs only allow for unchecked buyback or treasury rebalancing, sending the whole balance. VOTE WISELY!

	//Once that happens we either: stay in range, go below 1, go above 1.5 rbb

	//at that point auto rebalancing is designed to self regulate rbb to within acceptable range

	//AutoRebalance returns: bool(true or false continue to poll), uint rbb, uint autorebalance action(0 wait on Vote, 1 LP buyback, 2 Treasury)

	//CHECK THERES NO CURRENT POLL ACTIVE TO AVOID PEOPLE OVERIDING POLLS

	//Polls should have ended by at least 10mins to create a new one, this shifts polling times to have a random sample of holders participate

	function autoRebalancingCheck() payable public returns(bool voteProceed, uint256 rbb, uint action, uint256 eth_toDeploy){

		require(!_curActivePoll, "end current poll first.");

		require(block.timestamp - lastCheck[tx.origin] > _cooldown, "hit address cooldown");

		require(token.balanceOf(msg.sender) >= 10000 * (1 ** uint256(token.decimals())), "insufficient tokens.");

		//eth in question

		uint256 eth_avail = address(this).balance;

		require(eth_avail > 0, "no funds in RBW.");

		//nvl and buyback sums

		uint256 proxysellNVL = token._totalNVL_proxysell();// NVL / buybacks = rbb

		uint256 uniswapsellNVL = token._totalNVL_dexsell();

		uint256 totalNVL = uniswapsellNVL + proxysellNVL;

		uint256 currentBBTotal = token._totalBuyBackETH();//[6th call]

		//rbb levels

		uint call = 0;

		uint256 rbb_max = (3 * 1e18)/2; //1.5

		uint256 rbb_min = (1 * 1e18);//1

		uint256 returnedAmnt = 0;



		//ZERO RBB LEVEL CHECKS

		if(totalNVL > 0 && currentBBTotal > 0){//none zero

			rbb = (1e18 * totalNVL)/currentBBTotal;

		}

		if(totalNVL > 0 && currentBBTotal == 0){//money un-replaced

			rbb = 0;//buyback zero division

			call = 1;//liquidity pool rebalance

			// desiredBBTotal = totalNVL / 1.5 

			// p.s: in reality 1.5 is not our target, ideal is 1.25 (rbb_median) then leave community to tilt itself

			eth_toDeploy = _buybackTOMEDIANrbb(totalNVL, currentBBTotal);

		}

		if(totalNVL == 0){//no sells yet

			rbb = 0;//totalNVL zero division

			call = 2;//treasury rebalance

			eth_toDeploy = eth_avail;//send all to treasury for good use as no buybacks needed now

		}



		//NON ZERO RBB LEVEL CHECKS - only overides call value if rbb>0

		if(rbb > 0 && rbb <= rbb_min){//buybacks limit reached,send to treasury

			call = 2;//treasury rebalance

			// find how much we allow to be lost in NVL before we reach 1.25 rbb starting from <1 rbb

			// desiredNVL = rbb_median * currentBBTotal;

			// diffTOlose = desiredNVL - totalNVL;

			// p.s 1.25 still ideal middle ground

			eth_toDeploy = _foregoreTOMEDIANrbb(totalNVL, currentBBTotal);

		}

		if(rbb >= rbb_max){//beyond allowed (1.5) limit, perfom buyback

			call = 1;//liquidity pool rebalance

			//we dont want to buy back the whole difference each time, that would exert a bias of excessive buybacks taking us below rbb of 1

			//we want the DAO to give the treasury a chance, self regulating based on seasons

			//rbb must not be less than 1.5 after the buyback, we want to buyback with just enough.

			//how much do we spend in current buyback in order to not go below 1.5 rbb_max (1.25 rbb_median in practice)

			//logic approach: not to cross 1.5 fix on basis of current rbb & currentBBTotal

			//rbb = totalNVL / totalBuybacks

			// p.s 1.25 still ideal middle ground

			eth_toDeploy = _buybackTOMEDIANrbb(totalNVL, currentBBTotal);

		}

		if(rbb > rbb_min && rbb < rbb_max){//within allowed range 1 -- 1.5

			call = 0;//poll decides

			//community should decide what to do with all the balance we are in a safe range

			//if we over buy, auto checks will correct us from 1 back to median

			//if we send too much to treasury, auto checks take us from 1.5 to median

			eth_toDeploy = eth_avail;

		}

		//update

		emit rbbraw(totalNVL, currentBBTotal);

		emit rbbs(rbb, rbb_min, rbb_max, call);

		lastCheck[tx.origin] = block.timestamp;

		//perfom actions

		if(call == 1){//perfom buyback

			returnedAmnt = rebalanceLP(eth_toDeploy);//returns tokens bought

			_amountthruChecks += eth_toDeploy;

			_rebalancedthruChecks += 1;

			emit rbCHECK(msg.sender, rbb, 1, returnedAmnt);

			return (false,rbb,1,eth_toDeploy);//0 is community vote, 1 LP buyback, 2 Treasury rebalance

		}

		if(call == 2){//send to treasury

			rebalanceTreasury(eth_toDeploy);

			_amountthruChecks += eth_toDeploy;

			_rebalancedthruChecks += 1;

			emit rbCHECK(msg.sender, rbb, 2, eth_toDeploy);

			return (false,rbb,2,eth_toDeploy);

		}

		if(call == 0){//community poll decides

			emit rbCHECK(msg.sender, rbb, 0, eth_toDeploy);//RETURNED AMNT CANT BE ZERO THATS NOT USEFUL MU

			return (true,rbb,0,eth_toDeploy);

		}

	}

	

	/*	HELPER FUNCTIONS	*/

	// Pure functions first

	function _buybackTOMAXrbb(uint256 totalNVL, uint256 currentBBTotal) public pure returns(uint256){

		uint256 rbb_max = 150; //1.5

		//NVL / BUYBACKS = rbb

		//knownAmnt = 1.5 * unknownBuyBackAmnt

		uint256 desiredBBTotal = (totalNVL / rbb_max) *100; 

		uint256 diffTObuy = desiredBBTotal - currentBBTotal;

		return diffTObuy;

	}

	function _buybackTOMEDIANrbb(uint256 totalNVL, uint256 currentBBTotal) public pure returns(uint256){

		uint256 rbb_median = 125;// 1.25 ideal landing zone

		// NVL / BUYBACKS = rbb

		// rbb_median of 1.25: rbb_median = totalNVL/ desiredBBTotal; gives us desired & we know current.

		uint256 desiredBBTotal = (totalNVL / rbb_median) *100; 

		uint256 diffTObuy = desiredBBTotal - currentBBTotal;

		return diffTObuy;

	}

	function _buybackTOMiNrbb(uint256 totalNVL, uint256 currentBBTotal) public pure returns(uint256){

		uint256 rbb_min = 100; //1

		// NVL / BUYBACKS = rbb

		// rbb_min of 1: rbb_min = totalNVL/ desiredBBTotal; gives us desired & we know current.

		uint256 desiredBBTotal = (totalNVL / rbb_min) *100; 

		uint256 diffTObuy = desiredBBTotal - currentBBTotal;//should be equal to NVL

		return diffTObuy;

	}

	//p.s ONLY works when rbb is below median, if current rbb is > median rbb: ERROR

	function _foregoreTOMEDIANrbb(uint256 totalNVL, uint256 currentBBTotal) public view returns(uint256){

		uint256 eth_avail = address(this).balance;//eth in question



		uint256 rbb_median = 125;// 1.25 ideal landing zone

		//NVL = rbb * BUYBACKS

		//rbb is low - below peg, meaning NVL needs to increase, whilst buybacks are constant, to raise rbb to target

		//NVL_needed = Totalbuybacks * rbb_toIncrease_to;

		//p.s ONLY works when rbb is below median, if current rbb is > median rbb: ERROR

		uint256 desiredNVL = (currentBBTotal * rbb_median)/100;

		uint256 nvl_equivalent = 0;

		//THE CONCEPT HERE IS: we are not buying back anything, but we want to know how much we need in sells in order to raise rbb

		//rbb below 1 means we bought back excessively, hence we assign it to treasury instead to balance the over buying

		//the sells that follow will be bought back at community's preference

		if(desiredNVL > totalNVL){

			nvl_equivalent = desiredNVL - totalNVL;

		}else{

		//we may need to buy back soon. rbb is high, reserve whats needed to buyback to median..send away excess

			uint256 reserveForBB = _buybackTOMEDIANrbb(totalNVL, currentBBTotal);

			nvl_equivalent = eth_avail - reserveForBB;

		}		

		return nvl_equivalent;

	}

	function rbbLevels() public view returns(uint256, uint256){

		uint256 proxysellNVL = token._totalNVL_proxysell();// NVL / buybacks = rbb

		uint256 uniswapsellNVL = token._totalNVL_dexsell(); 

		uint256 buybacks = token._totalBuyBackETH();

		uint256 rbb = (1e18* (uniswapsellNVL + proxysellNVL))/buybacks;

		require(rbb > 0,"no buybacks yet");

		uint256 rbb_max = (3 * 1e18)/2;

		return (rbb,rbb_max);

	}

	function hoursDifference(uint timeA) public view returns (uint){

		uint difhours = bokky.diffHours(timeA, block.timestamp);

		return difhours;

    }

    function hoursAdd(uint timeA) public view returns (uint){

		uint sumhours = bokky.addHours(block.timestamp, timeA);

		return sumhours;

    }

	function dayOfWeek() public view returns (uint){

		uint day = bokky.getDayOfWeek(block.timestamp);

		return day;

    }

	function blockTime() public view returns (uint){

		return block.timestamp;

    }

	//check owner

    modifier OnlyOwner(){

		require(msg.sender == token.owner(), "not owner");

		_;

	}



	receive() external payable {}

}