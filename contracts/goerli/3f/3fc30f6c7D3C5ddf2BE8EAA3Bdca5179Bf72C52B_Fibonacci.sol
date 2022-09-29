pragma solidity 0.8.16;
// SPDX-License-Identifier: UNLICENSED
contract Fibonacci {

    function fib(uint x) public pure returns(uint) {
        uint a = 0;
        uint b = 1;
        uint sum_a_b;
        assembly {
            for {let i:= 0 } lt(i, x)  {i := add(i, 1)} {
                sum_a_b := add(a, b)
                a := b
                b := sum_a_b
            }            
        }
        return b;
    }
}