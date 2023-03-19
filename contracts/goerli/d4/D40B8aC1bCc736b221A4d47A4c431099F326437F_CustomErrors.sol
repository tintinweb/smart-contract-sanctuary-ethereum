// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

error MyCustomError(uint var1, uint var2);

contract CustomErrors {
    function test() pure public {
        if (1 > 0) revert MyCustomError(1,2);
    }
}