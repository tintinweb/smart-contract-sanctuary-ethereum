// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract TestMath {
    //Precalculated rates (10% annual interest). They have 7 decimal places

    uint256[] rateList = [10002611, //1 day
                          10005223, //2 days
                          10010450, //4 days
                          10020911, //8 days
                          10041867, //16 days
                          10083909, //32 days
                          10168523, //64 days
                          10339886, //128 days
                          10691326, //256 days
                          11430445]; //512 days

    uint256[] dayList = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512];

    uint256 decimals = 1e7;
                    
    uint256 loan = 63830; 

    function calculateInterests(uint256 _days_passed) public view returns (uint256) {
        uint256 rate = loan;
        uint256 totalDays = _days_passed;
        uint256 accumulatedDecimals = 1;

        while(totalDays > 0) {
            for (uint i = dayList.length - 1; i >= 0; i--) {
                if (dayList[i] <= totalDays) {
                    rate *= rateList[i]; 
                    totalDays -= dayList[i];
                    accumulatedDecimals *= decimals;
                    if (i % 3 == 0) {
                        rate /= accumulatedDecimals;
                        accumulatedDecimals = 1;
                    }
                    break;
                }
            }
        }

        return rate / accumulatedDecimals;
    }
}