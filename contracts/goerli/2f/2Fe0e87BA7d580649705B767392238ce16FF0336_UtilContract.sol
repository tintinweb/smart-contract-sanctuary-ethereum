/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract UtilContract {

    function getDate(uint timestamp) public pure returns (uint yearMonthDay) {
        uint year;
        uint month;
        uint day;
        uint secondsInADay = 60 * 60 * 24;
        uint daysSinceEpoch = timestamp / secondsInADay;
        uint yearSinceEpoch = daysSinceEpoch / 365;
        year = 1970 + yearSinceEpoch;
        uint daysSinceYearStart = daysSinceEpoch - (yearSinceEpoch * 365);

        for (uint i = 1970; i < year; i++) {
            if (i % 4 == 0 && (i % 100 != 0 || i % 400 == 0)) {
                daysSinceYearStart -= 1;
            }
        }

        if (daysSinceYearStart >= 59) { // Handle leap year
            if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
                daysSinceYearStart -= 1;
            }
        }
        uint8[12] memory daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        for (uint i = 0; i < 12; i++) {
            if (daysSinceYearStart < daysInMonth[i]) {
                month = i + 1;
                day = daysSinceYearStart + 1;
                break;
            }
            daysSinceYearStart -= daysInMonth[i];
        }

        yearMonthDay = year * 10000;
        yearMonthDay += (month * 100);
        yearMonthDay += day;
    }
}