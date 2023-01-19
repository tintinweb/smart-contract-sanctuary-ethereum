// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Attack {
    function giveBool() external view returns (bool) {
        bool output;
        assembly {
            output := mod(gas(), 2)
        }
        return output;
    }
}