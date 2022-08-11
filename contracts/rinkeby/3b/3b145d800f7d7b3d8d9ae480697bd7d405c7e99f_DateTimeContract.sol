/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: GNU Lesser General Public License 3.0
pragma solidity ^0.8.15;

/** 
    // ----------------------------------------------------------------------------
    //  DateTime库 
    //
    // 一个高效的 Solidity 日期和时间库
    //
    // 测试日期范围: 1970/01/01 到 2345/12/31
    // ----------------------------------------------------------------------------
*/
library DateTimeLibrary {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;  
    uint constant SECONDS_PER_HOUR = 60 * 60;        
    uint constant SECONDS_PER_MINUTE = 60;         
    int constant  OFFSET19700101 = 2440588;          

    uint constant DOW_MON = 1;                  
    uint constant DOW_TUE = 2;                    
    uint constant DOW_WED = 3;                 
    uint constant DOW_THU = 4;                     
    uint constant DOW_FRI = 5;                   
    uint constant DOW_SAT = 6;                      
    uint constant DOW_SUN = 7;                      

    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
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

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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

    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
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

contract DateTimeContract {
    uint private constant SECONDS_PER_DAY = 24 * 60 * 60;        // 每天多少秒
    uint private constant SECONDS_PER_HOUR = 60 * 60;            // 每个小时多少秒
    uint private constant SECONDS_PER_MINUTE = 60;               // 每分钟多少秒
    int private constant OFFSET19700101 = 2440588;               // 起始日期和时间

    uint private constant DOW_MON = 1;                           // 星期一
    uint private constant DOW_TUE = 2;                           // 星期二
    uint private constant DOW_WED = 3;                           // 星期三
    uint private constant DOW_THU = 4;                           // 星期四
    uint private constant DOW_FRI = 5;                           // 星期五
    uint private constant DOW_SAT = 6;                           // 星期六
    uint private constant DOW_SUN = 7;                           // 星期日

    // 返回当前的Unix时间戳
    function currentTimestamp() public view returns (uint timestamp) {
        timestamp = block.timestamp;
    }

    // 返回当前的UTC时间  精确到秒
    function currentDateTime() public view returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = DateTimeLibrary.timestampToDateTime(block.timestamp);
    }

    // 通过传进来的时间戳参数 返回当前的UTC时间  精确到日
    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = DateTimeLibrary.timestampToDate(timestamp);
    }

    // 通过传进来的时间戳参数 返回当前的UTC时间  精确到秒
    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = DateTimeLibrary.timestampToDateTime(timestamp);
    }

    // 判断传进来的时间戳参数转化的年份是否为闰年
    function isLeapYearByTimestamp(uint timestamp) public pure returns (bool leapYear) {
        leapYear = DateTimeLibrary.isLeapYear(timestamp);
    }
    
    // 判断传进来的年份参数是否为闰年
    function isLeapYearByYear(uint year) public pure returns (bool leapYear) {
        leapYear = DateTimeLibrary._isLeapYear(year);
    }

    // 判断传进来的时间戳参数转化的日期是否为工作日
    function isWeekDay(uint timestamp) public pure returns (bool weekDay) {
        weekDay = DateTimeLibrary.isWeekDay(timestamp);
    }

    // 判断传进来的时间戳参数转化的日期是否为休息日
    function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
        weekEnd = DateTimeLibrary.isWeekEnd(timestamp);
    }
 
    // 通过传进来的时间戳参数转化的月份 返回当月有多少天
    function getDaysInMonthByTimestamp(uint timestamp) public pure returns (uint daysInMonth) {
        daysInMonth = DateTimeLibrary.getDaysInMonth(timestamp);
    }

    // 通过传进来的年份和月份参数 返回当月有多少天
    function getDaysInMonthByYearAndMonth(uint year, uint month) public pure returns (uint daysInMonth) {
        daysInMonth = DateTimeLibrary._getDaysInMonth(year, month);
    }

    // 通过传进来的时间戳参数 返回当天是星期几
    function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
        dayOfWeek = DateTimeLibrary.getDayOfWeek(timestamp);
    }

    // 通过传进来的时间戳参数 返回当前的年份
    function getYear(uint timestamp) public pure returns (uint year) {
        year = DateTimeLibrary.getYear(timestamp);
    }

    // 通过传进来的时间戳参数 返回当前的月份
    function getMonth(uint timestamp) public pure returns (uint month) {
        month = DateTimeLibrary.getMonth(timestamp);
    }

    // 通过传进来的时间戳参数 返回当天是几号
    function getDay(uint timestamp) public pure returns (uint day) {
        day = DateTimeLibrary.getDay(timestamp);
    }

    // 通过传进来的时间戳参数 返回当前是几点
    function getHour(uint timestamp) public pure returns (uint hour) {
        hour = DateTimeLibrary.getHour(timestamp);
    }

    // 通过传进来的时间戳参数 返回当前是几分
    function getMinute(uint timestamp) public pure returns (uint minute) {
        minute = DateTimeLibrary.getMinute(timestamp);
    }

    // 通过传进来的时间戳参数 返回当前是几秒
    function getSecond(uint timestamp) public pure returns (uint second) {
        second = DateTimeLibrary.getSecond(timestamp);
    }

    // 返回当前时间加上传进来的年数之后的时间戳
    function addYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addYears(timestamp, _years);
    }

    // 返回当前时间加上传进来的月数之后的时间戳
    function addMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addMonths(timestamp, _months);
    }

    // 返回当前时间加上传进来的天数之后的时间戳
    function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addDays(timestamp, _days);
    }

    // 返回当前时间加上传进来的时数之后的时间戳
    function addHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addHours(timestamp, _hours);
    }

    // 返回当前时间加上传进来的分数之后的时间戳
    function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addMinutes(timestamp, _minutes);
    }

    // 返回当前时间加上传进来的秒数之后的时间戳
    function addSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.addSeconds(timestamp, _seconds);
    }

    // 返回当前时间减去传进来的年数之后的时间戳
    function subYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subYears(timestamp, _years);
    }

    // 返回当前时间减去传进来的月数之后的时间戳
    function subMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subMonths(timestamp, _months);
    }

    // 返回当前时间减去传进来的天数之后的时间戳
    function subDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subDays(timestamp, _days);
    }

    // 返回当前时间减去传进来的时数之后的时间戳
    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subHours(timestamp, _hours);
    }

    // 返回当前时间减去传进来的分数之后的时间戳
    function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subMinutes(timestamp, _minutes);
    }

    // 返回当前时间减去传进来的秒数之后的时间戳
    function subSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = DateTimeLibrary.subSeconds(timestamp, _seconds);
    }

    // 返回传进来的两个时间戳参数之间相差多少年  第一个参数必须比第二个参数大
    function diffYears(uint fromTimestamp, uint toTimestamp) public pure returns (uint _years) {
        _years = DateTimeLibrary.diffYears(fromTimestamp, toTimestamp);
    }

    // 返回传进来的两个时间戳参数之间相差多少个月  第一个参数必须比第二个参数大
    function diffMonths(uint fromTimestamp, uint toTimestamp) public pure returns (uint _months) {
        _months = DateTimeLibrary.diffMonths(fromTimestamp, toTimestamp);
    }

    // 返回传进来的两个时间戳参数之间相差多少天  第一个参数必须比第二个参数大
    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = DateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }

    // 返回传进来的两个时间戳参数之间相差多少个小时  第一个参数必须比第二个参数大
    function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
        _hours = DateTimeLibrary.diffHours(fromTimestamp, toTimestamp);
    }

    // 返回传进来的两个时间戳参数之间相差多少分钟  第一个参数必须比第二个参数大
    function diffMinutes(uint fromTimestamp, uint toTimestamp) public pure returns (uint _minutes) {
        _minutes = DateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }

    // 返回传进来的两个时间戳参数之间相差多少秒  第一个参数必须比第二个参数大
    function diffSeconds(uint fromTimestamp, uint toTimestamp) public pure returns (uint _seconds) {
        _seconds = DateTimeLibrary.diffSeconds(fromTimestamp, toTimestamp);
    }
}