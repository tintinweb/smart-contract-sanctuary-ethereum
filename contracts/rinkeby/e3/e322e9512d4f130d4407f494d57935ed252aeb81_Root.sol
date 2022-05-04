/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Root {

    constructor() {
    }

    // calculates a^(1/n) to dp decimal places
    // maxIts bounds the number of iterations performed
    function nthRoot(uint _a, uint _n, uint _dp, uint _maxIts) pure public returns(uint) {
        assert (_n > 1);

        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (a * (10 ^ ((dp + 1) * n))) ^ (1/n)
        // We calculate to one extra dp and round at the end
        uint one = 10 ** (1 + _dp);
        uint a0 = one ** _n * _a;

        // Initial guess: 1.0
        uint xNew = one;
        uint x = 0;

        uint iter = 0;
        while (xNew != x && iter < _maxIts) {
            x = xNew;
            uint t0 = x ** (_n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / _n;

            } else {
                xNew = x + (a0 / t0 - x) / _n;
            }
            ++iter;
        }

        // Round to nearest in the last dp.
        return (xNew + 5) / 10;
    }

    function mainFormular(uint _value1, uint _value2, uint _dp) pure public returns(uint,uint) {
      uint res1 = 625 * ( 10 ** (1 + _dp) ) * _value1 / 100;
      uint res2 = _value2 * nthRoot(_value2, 4, 9, 10);
      // uint res = res1 + res2;
      // uint result = res / nthRoot(res, 5, 9, 10) - value2;
      // return (result, value1, value2, res1, res2);
      return (res1, res2);
    }

}