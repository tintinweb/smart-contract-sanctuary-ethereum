//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {
    // return how many percent is y of the number x
    function PercentYofX(uint x, uint y) public pure returns (uint) {
        // make number with 18 zeros
        uint accuracy = 10 ** 18;
        // we calculate how much the number y is % of the number x
        // accuracy ** 2 because we need to multiply by accuracy and 
        // divide by accuracy but accuracy is < than (x * (accuracy) / y)
        // so without this we will get 0
        /*
            about how it works:
            $$      100%/z = 128/32          $$
            $$      z = 100% / (128 / 32)    $$
        */
        return (accuracy ** 2) / (x * (accuracy) / y);
        // for 'real' persent return should be divided by 10^16
    }
}